const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'frontend')));

// ── DB CONNECTION ──────────────────────────────────────────
const db = mysql.createConnection({
  host: '127.0.0.1',
  port: 3306,
  user: 'root',
  password: 'library123',
  database: 'library_management'
});

db.connect((err) => {
  if (err) { console.error('DB connection failed:', err); return; }
  console.log('Connected to MySQL');
});

// ── DASHBOARD STATS ────────────────────────────────────────
app.get('/api/stats', (req, res) => {
  const sql = `
    SELECT
      (SELECT COUNT(*) FROM Book)                                      AS total_books,
      (SELECT SUM(available_copies) FROM Book)                         AS available_books,
      (SELECT COUNT(*) FROM Member WHERE is_active = TRUE)             AS active_members,
      (SELECT COUNT(*) FROM Borrow_Transaction WHERE status='Borrowed' OR status='Overdue') AS active_borrows,
      (SELECT COUNT(*) FROM Borrow_Transaction WHERE status='Overdue') AS overdue_count,
      (SELECT SUM(amount) FROM Fine WHERE paid = FALSE)                AS pending_fines
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0]);
  });
});

// ── BOOKS ──────────────────────────────────────────────────
app.get('/api/books', (req, res) => {
  const search = req.query.search ? `%${req.query.search}%` : '%';
  const sql = `
    SELECT
      b.book_id, b.isbn, b.title,
      GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
      p.name AS publisher,
      c.name AS category,
      b.publication_year, b.edition,
      b.total_copies, b.available_copies, b.shelf_location
    FROM Book b
    JOIN Book_Author ba ON b.book_id      = ba.book_id
    JOIN Author      a  ON ba.author_id   = a.author_id
    JOIN Publisher   p  ON b.publisher_id = p.publisher_id
    JOIN Category    c  ON b.category_id  = c.category_id
    WHERE b.title LIKE ? OR a.first_name LIKE ? OR a.last_name LIKE ?
    GROUP BY b.book_id
    ORDER BY b.title
  `;
  db.query(sql, [search, search, search], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ── MEMBERS ────────────────────────────────────────────────
app.get('/api/members', (req, res) => {
  const sql = `
    SELECT
      m.*,
      COUNT(bt.transaction_id) AS total_borrows,
      SUM(CASE WHEN bt.status IN ('Borrowed','Overdue') THEN 1 ELSE 0 END) AS active_borrows
    FROM Member m
    LEFT JOIN Borrow_Transaction bt ON m.member_id = bt.member_id
    GROUP BY m.member_id
    ORDER BY m.first_name
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ── ACTIVE BORROWS ─────────────────────────────────────────
app.get('/api/borrows/active', (req, res) => {
  const sql = `
    SELECT bt.transaction_id, bt.member_id,
           CONCAT(m.first_name,' ',m.last_name) AS member_name,
           m.membership_type,
           b.title AS book_title,
           bt.borrow_date, bt.due_date, bt.status
    FROM Borrow_Transaction bt
    JOIN Member m ON bt.member_id = m.member_id
    JOIN Book   b ON bt.book_id   = b.book_id
    WHERE bt.status IN ('Borrowed','Overdue')
    ORDER BY bt.status DESC, bt.due_date ASC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ── OVERDUE ────────────────────────────────────────────────
app.get('/api/borrows/overdue', (req, res) => {
  db.query('SELECT * FROM vw_overdue_with_fines', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ── FINES ──────────────────────────────────────────────────
app.get('/api/fines', (req, res) => {
  const sql = `
    SELECT
      f.fine_id,
      CONCAT(m.first_name, ' ', m.last_name) AS member_name,
      b.title AS book_title,
      bt.borrow_date, bt.due_date,
      f.amount, f.reason, f.paid, f.paid_date
    FROM Fine f
    JOIN Borrow_Transaction bt ON f.transaction_id = bt.transaction_id
    JOIN Member m ON bt.member_id = m.member_id
    JOIN Book   b ON bt.book_id   = b.book_id
    ORDER BY f.paid ASC, f.amount DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ── ISSUE BOOK ─────────────────────────────────────────────
app.post('/api/borrow', (req, res) => {
  const { member_id, book_id, staff_id } = req.body;
  const borrow_date = new Date().toISOString().split('T')[0];
  const due = new Date(); due.setDate(due.getDate() + 14);
  const due_date = due.toISOString().split('T')[0];

  db.beginTransaction(err => {
    if (err) return res.status(500).json({ error: err.message });

    db.query(
      `INSERT INTO Borrow_Transaction (member_id, book_id, staff_id, borrow_date, due_date, status)
       VALUES (?, ?, ?, ?, ?, 'Borrowed')`,
      [member_id, book_id, staff_id, borrow_date, due_date],
      (err) => {
        if (err) return db.rollback(() => res.status(500).json({ error: err.message }));

        db.query(
          `UPDATE Book SET available_copies = available_copies - 1 WHERE book_id = ? AND available_copies > 0`,
          [book_id],
          (err, result) => {
            if (err || result.affectedRows === 0) {
              return db.rollback(() => res.status(400).json({ error: 'Book not available' }));
            }
            db.commit(err => {
              if (err) return db.rollback(() => res.status(500).json({ error: err.message }));
              res.json({ success: true, message: 'Book issued successfully', due_date });
            });
          }
        );
      }
    );
  });
});

// ── RETURN BOOK ────────────────────────────────────────────
app.post('/api/return/:transaction_id', (req, res) => {
  const { transaction_id } = req.params;
  const return_date = new Date().toISOString().split('T')[0];

  db.beginTransaction(err => {
    if (err) return res.status(500).json({ error: err.message });

    db.query(
      `SELECT bt.*, DATEDIFF(CURDATE(), bt.due_date) AS days_overdue
       FROM Borrow_Transaction bt WHERE transaction_id = ?`,
      [transaction_id],
      (err, rows) => {
        if (err || !rows.length) return db.rollback(() => res.status(404).json({ error: 'Transaction not found' }));
        const tx = rows[0];
        const days_overdue = tx.days_overdue;

        db.query(
          `UPDATE Borrow_Transaction SET return_date=?, status='Returned' WHERE transaction_id=?`,
          [return_date, transaction_id],
          (err) => {
            if (err) return db.rollback(() => res.status(500).json({ error: err.message }));

            db.query(
              `UPDATE Book SET available_copies = available_copies + 1 WHERE book_id = ?`,
              [tx.book_id],
              (err) => {
                if (err) return db.rollback(() => res.status(500).json({ error: err.message }));

                const fineFn = (cb) => {
                  if (days_overdue > 0) {
                    const fine_amount = days_overdue * 10;
                    db.query(
                      `INSERT INTO Fine (transaction_id, amount, reason) VALUES (?, ?, ?)
                       ON DUPLICATE KEY UPDATE amount=VALUES(amount)`,
                      [transaction_id, fine_amount, `Returned ${days_overdue} days late`],
                      cb
                    );
                  } else cb(null);
                };

                fineFn((err) => {
                  if (err) return db.rollback(() => res.status(500).json({ error: err.message }));
                  db.commit(err => {
                    if (err) return db.rollback(() => res.status(500).json({ error: err.message }));
                    res.json({
                      success: true,
                      fine: days_overdue > 0 ? days_overdue * 10 : 0,
                      message: days_overdue > 0
                        ? `Book returned. Fine of ₹${days_overdue * 10} generated.`
                        : 'Book returned on time.'
                    });
                  });
                });
              }
            );
          }
        );
      }
    );
  });
});

// ── MEMBER AUTH (find by email) ────────────────────────────
app.get('/api/member/login', (req, res) => {
  const { email } = req.query;
  db.query('SELECT * FROM Member WHERE email = ? AND is_active = TRUE', [email], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!rows.length) return res.status(404).json({ error: 'Member not found or inactive' });
    res.json(rows[0]);
  });
});

// ── MEMBER BORROWS ─────────────────────────────────────────
app.get('/api/members/:id/borrows', (req, res) => {
  const sql = `
    SELECT bt.transaction_id, b.title AS book_title, b.isbn, b.shelf_location,
           c.name AS category,
           bt.borrow_date, bt.due_date, bt.return_date, bt.status
    FROM Borrow_Transaction bt
    JOIN Book     b ON bt.book_id   = b.book_id
    JOIN Category c ON b.category_id = c.category_id
    WHERE bt.member_id = ?
    ORDER BY bt.borrow_date DESC
  `;
  db.query(sql, [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// ── MEMBER FINES ───────────────────────────────────────────
app.get('/api/members/:id/fines', (req, res) => {
  const sql = `
    SELECT f.fine_id, f.amount, f.reason, f.paid, f.paid_date,
           b.title AS book_title, bt.due_date, bt.return_date
    FROM Fine f
    JOIN Borrow_Transaction bt ON f.transaction_id = bt.transaction_id
    JOIN Book b ON bt.book_id = b.book_id
    WHERE bt.member_id = ?
    ORDER BY f.paid ASC, f.amount DESC
  `;
  db.query(sql, [req.params.id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.listen(3000, () => console.log('Server running at http://localhost:3000'));