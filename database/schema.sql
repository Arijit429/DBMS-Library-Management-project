
USE library_management;

-- ============================================================
-- SECTION 1: DROP TABLES (clean slate)
-- ============================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Fine;
DROP TABLE IF EXISTS Borrow_Transaction;
DROP TABLE IF EXISTS Book_Author;
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Author;
DROP TABLE IF EXISTS Publisher;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS Member;
DROP TABLE IF EXISTS Staff;
SET FOREIGN_KEY_CHECKS = 1;

-- SECTION 2: CREATE TABLES

CREATE TABLE Publisher (
    publisher_id    INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    address         VARCHAR(200),
    phone           VARCHAR(15) UNIQUE,
    email           VARCHAR(100) UNIQUE,
    established_year INT
);

CREATE TABLE Category (
    category_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,
    description     VARCHAR(200)
);

CREATE TABLE Author (
    author_id       INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    nationality     VARCHAR(50),
    birth_year      INT
);

CREATE TABLE Staff (
    staff_id        INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    role            ENUM('Librarian', 'Assistant', 'Manager') NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone           VARCHAR(15),
    hire_date       DATE NOT NULL
);

CREATE TABLE Member (
    member_id       INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone           VARCHAR(15),
    address         VARCHAR(200),
    membership_type ENUM('Student', 'Faculty', 'Public') NOT NULL,
    join_date       DATE NOT NULL,
    expiry_date     DATE NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE Book (
    book_id         INT AUTO_INCREMENT PRIMARY KEY,
    isbn            VARCHAR(20) UNIQUE NOT NULL,
    title           VARCHAR(200) NOT NULL,
    publisher_id    INT NOT NULL,
    category_id     INT NOT NULL,
    publication_year INT,
    edition         INT DEFAULT 1,
    total_copies    INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    shelf_location  VARCHAR(20),
    FOREIGN KEY (publisher_id) REFERENCES Publisher(publisher_id),
    FOREIGN KEY (category_id)  REFERENCES Category(category_id),
    CHECK (available_copies >= 0),
    CHECK (available_copies <= total_copies)
);

-- Junction table: M:N between Book and Author
CREATE TABLE Book_Author (
    book_id         INT NOT NULL,
    author_id       INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id)   REFERENCES Book(book_id),
    FOREIGN KEY (author_id) REFERENCES Author(author_id)
);

CREATE TABLE Borrow_Transaction (
    transaction_id  INT AUTO_INCREMENT PRIMARY KEY,
    member_id       INT NOT NULL,
    book_id         INT NOT NULL,
    staff_id        INT NOT NULL,
    borrow_date     DATE NOT NULL,
    due_date        DATE NOT NULL,
    return_date     DATE DEFAULT NULL,
    status          ENUM('Borrowed', 'Returned', 'Overdue') DEFAULT 'Borrowed',
    FOREIGN KEY (member_id) REFERENCES Member(member_id),
    FOREIGN KEY (book_id)   REFERENCES Book(book_id),
    FOREIGN KEY (staff_id)  REFERENCES Staff(staff_id)
);

CREATE TABLE Fine (
    fine_id         INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id  INT NOT NULL UNIQUE,
    amount          DECIMAL(8,2) NOT NULL,
    reason          VARCHAR(200),
    paid            BOOLEAN DEFAULT FALSE,
    paid_date       DATE DEFAULT NULL,
    FOREIGN KEY (transaction_id) REFERENCES Borrow_Transaction(transaction_id),
    CHECK (amount > 0)
);

-- ============================================================
-- SECTION 3: INDEXES
-- ============================================================
CREATE INDEX idx_book_title       ON Book(title);
CREATE INDEX idx_member_email     ON Member(email);
CREATE INDEX idx_borrow_status    ON Borrow_Transaction(status);
CREATE INDEX idx_borrow_dates     ON Borrow_Transaction(borrow_date, due_date);

-- ============================================================
-- SECTION 4: SAMPLE DATA (100+ records)
-- ============================================================

-- Publishers (10)
INSERT INTO Publisher (name, address, phone, email, established_year) VALUES
('Penguin Random House', 'New York, USA',        '9800000001', 'contact@prh.com',        1927),
('HarperCollins',        'London, UK',           '9800000002', 'info@harpercollins.com', 1817),
('Oxford University Press','Oxford, UK',         '9800000003', 'info@oup.com',           1586),
('McGraw-Hill',          'Chicago, USA',         '9800000004', 'info@mcgraw.com',        1888),
('Pearson Education',    'London, UK',           '9800000005', 'info@pearson.com',       1844),
('Tata McGraw-Hill',     'New Delhi, India',     '9800000006', 'info@tatamcgraw.com',    1970),
('Wiley',                'New Jersey, USA',      '9800000007', 'info@wiley.com',         1807),
('Springer',             'Berlin, Germany',      '9800000008', 'info@springer.com',      1842),
('Macmillan',            'London, UK',           '9800000009', 'info@macmillan.com',     1843),
('Cambridge Univ Press', 'Cambridge, UK',        '9800000010', 'info@cup.com',           1534);

-- Categories (8)
INSERT INTO Category (name, description) VALUES
('Computer Science',  'Programming, algorithms, data structures'),
('Mathematics',       'Pure and applied mathematics'),
('Fiction',           'Novels and short stories'),
('Science',           'Physics, chemistry, biology'),
('History',           'World and regional history'),
('Self Help',         'Personal development and motivation'),
('Database Systems',  'DBMS, SQL, data modeling'),
('Networks',          'Computer networking and protocols');

-- Authors (15)
INSERT INTO Author (first_name, last_name, nationality, birth_year) VALUES
('Thomas',    'Cormen',      'American',  1956),
('Abraham',   'Silberschatz','American',  1952),
('Ramez',     'Elmasri',     'American',  1950),
('James',     'Kurose',      'American',  1956),
('Andrew',    'Tanenbaum',   'Dutch',     1944),
('George',    'Orwell',      'British',   1903),
('J.K.',      'Rowling',     'British',   1965),
('Stephen',   'Hawking',     'British',   1942),
('Yuval',     'Harari',      'Israeli',   1976),
('Robert',    'Sedgewick',   'American',  1946),
('Date',      'C.J.',        'British',   1941),
('Forouzan',  'Behrouz',     'Iranian',   1944),
('Knuth',     'Donald',      'American',  1938),
('Navathe',   'Shamkant',    'Indian',    1945),
('Pressman',  'Roger',       'American',  1940);

-- Staff (5)
INSERT INTO Staff (first_name, last_name, role, email, phone, hire_date) VALUES
('Meera',   'Nair',    'Manager',    'meera@library.com',   '9700000001', '2018-06-01'),
('Rajan',   'Sharma',  'Librarian',  'rajan@library.com',   '9700000002', '2019-03-15'),
('Priya',   'Menon',   'Librarian',  'priya@library.com',   '9700000003', '2020-07-10'),
('Arjun',   'Das',     'Assistant',  'arjun@library.com',   '9700000004', '2021-01-05'),
('Sneha',   'Pillai',  'Assistant',  'sneha@library.com',   '9700000005', '2022-08-20');

-- Members (25)
INSERT INTO Member (first_name, last_name, email, phone, address, membership_type, join_date, expiry_date, is_active) VALUES
('Aditya',   'Kumar',    'aditya@email.com',   '9600000001', 'Bangalore', 'Student',  '2023-01-10', '2025-01-10', TRUE),
('Sneha',    'Reddy',    'sneha@email.com',    '9600000002', 'Bangalore', 'Student',  '2023-02-15', '2025-02-15', TRUE),
('Rahul',    'Verma',    'rahul@email.com',    '9600000003', 'Mysore',    'Faculty',  '2022-06-01', '2024-06-01', TRUE),
('Pooja',    'Singh',    'pooja@email.com',    '9600000004', 'Bangalore', 'Student',  '2023-03-20', '2025-03-20', TRUE),
('Kiran',    'Nair',     'kiran@email.com',    '9600000005', 'Bangalore', 'Public',   '2022-11-05', '2024-11-05', TRUE),
('Vijay',    'Menon',    'vijay@email.com',    '9600000006', 'Chennai',   'Faculty',  '2021-08-12', '2023-08-12', FALSE),
('Ananya',   'Iyer',     'ananya@email.com',   '9600000007', 'Bangalore', 'Student',  '2023-05-01', '2025-05-01', TRUE),
('Rohit',    'Sharma',   'rohit@email.com',    '9600000008', 'Delhi',     'Public',   '2022-09-18', '2024-09-18', TRUE),
('Divya',    'Pillai',   'divya@email.com',    '9600000009', 'Bangalore', 'Student',  '2023-07-22', '2025-07-22', TRUE),
('Suresh',   'Babu',     'suresh@email.com',   '9600000010', 'Hyderabad', 'Faculty',  '2020-04-30', '2024-04-30', TRUE),
('Lakshmi',  'Devi',     'lakshmi@email.com',  '9600000011', 'Bangalore', 'Student',  '2023-08-14', '2025-08-14', TRUE),
('Arjun',    'Patel',    'arjunp@email.com',   '9600000012', 'Pune',      'Public',   '2022-12-01', '2024-12-01', TRUE),
('Kavitha',  'Rao',      'kavitha@email.com',  '9600000013', 'Bangalore', 'Student',  '2023-01-25', '2025-01-25', TRUE),
('Manoj',    'Tiwari',   'manoj@email.com',    '9600000014', 'Lucknow',   'Public',   '2023-02-10', '2025-02-10', TRUE),
('Sita',     'Krishnan', 'sita@email.com',     '9600000015', 'Bangalore', 'Faculty',  '2019-06-15', '2024-06-15', TRUE),
('Deepak',   'Joshi',    'deepak@email.com',   '9600000016', 'Bangalore', 'Student',  '2023-09-01', '2025-09-01', TRUE),
('Nithya',   'Sundaram', 'nithya@email.com',   '9600000017', 'Chennai',   'Student',  '2023-10-05', '2025-10-05', TRUE),
('Vikram',   'Bose',     'vikram@email.com',   '9600000018', 'Kolkata',   'Public',   '2022-07-20', '2024-07-20', TRUE),
('Swathi',   'Gowda',    'swathi@email.com',   '9600000019', 'Bangalore', 'Student',  '2023-11-12', '2025-11-12', TRUE),
('Prasad',   'Hegde',    'prasad@email.com',   '9600000020', 'Mangalore', 'Faculty',  '2021-03-08', '2025-03-08', TRUE),
('Riya',     'Shah',     'riya@email.com',     '9600000021', 'Mumbai',    'Student',  '2023-04-17', '2025-04-17', TRUE),
('Ganesh',   'Murthy',   'ganesh@email.com',   '9600000022', 'Bangalore', 'Public',   '2022-10-30', '2024-10-30', TRUE),
('Harini',   'Venkat',   'harini@email.com',   '9600000023', 'Bangalore', 'Student',  '2024-01-08', '2026-01-08', TRUE),
('Sanjay',   'Kulkarni', 'sanjay@email.com',   '9600000024', 'Pune',      'Faculty',  '2020-09-22', '2024-09-22', TRUE),
('Meghna',   'Agarwal',  'meghna@email.com',   '9600000025', 'Bangalore', 'Student',  '2024-02-14', '2026-02-14', TRUE);

-- Books (20)
INSERT INTO Book (isbn, title, publisher_id, category_id, publication_year, edition, total_copies, available_copies, shelf_location) VALUES
('978-0262033848', 'Introduction to Algorithms',            1, 1, 2009, 3, 5, 3, 'A1'),
('978-0073523323', 'Database System Concepts',              4, 7, 2010, 6, 4, 2, 'B1'),
('978-0136019701', 'Fundamentals of Database Systems',      5, 7, 2010, 6, 3, 1, 'B2'),
('978-0136421429', 'Computer Networking: Top-Down Approach',5, 8, 2020, 8, 4, 4, 'C1'),
('978-0132126953', 'Computer Networks',                     1, 8, 2010, 5, 3, 2, 'C2'),
('978-0451524935', '1984',                                  1, 3, 1949, 1, 6, 5, 'D1'),
('978-0439708180', 'Harry Potter and the Sorcerer Stone',   9, 3, 1997, 1, 5, 3, 'D2'),
('978-0553380163', 'A Brief History of Time',               1, 4, 1988, 1, 4, 2, 'E1'),
('978-0062316110', 'Sapiens: A Brief History of Humankind', 2, 5, 2011, 1, 5, 4, 'F1'),
('978-0201896831', 'The Art of Computer Programming',       1, 1, 1997, 3, 2, 1, 'A2'),
('978-0201633610', 'Design Patterns',                       1, 1, 1994, 1, 3, 3, 'A3'),
('978-0071315388', 'Data Communications and Networking',    4, 8, 2012, 5, 4, 2, 'C3'),
('978-0132350884', 'Clean Code',                            1, 1, 2008, 1, 4, 3, 'A4'),
('978-0201485677', 'The Mythical Man-Month',                1, 1, 1995, 2, 3, 2, 'A5'),
('978-0135957059', 'The Pragmatic Programmer',              5, 1, 2019, 2, 4, 4, 'A6'),
('978-0198503828', 'An Introduction to Database Systems',   3, 7, 2004, 8, 3, 1, 'B3'),
('978-0073376226', 'Discrete Mathematics',                  4, 2, 2011, 7, 5, 3, 'G1'),
('978-1491950357', 'Python Data Science Handbook',          7, 1, 2016, 1, 3, 2, 'A7'),
('978-0547928227', 'The Hobbit',                            2, 3, 1937, 1, 5, 4, 'D3'),
('978-0130352620', 'Software Engineering',                  5, 1, 2010, 8, 4, 2, 'A8');

-- Book_Author (M:N junction — 25 records)
INSERT INTO Book_Author (book_id, author_id) VALUES
(1,  1),   -- Introduction to Algorithms → Cormen
(2,  2),   -- DB System Concepts → Silberschatz
(3,  3),   -- Fundamentals of DB → Elmasri
(3,  14),  -- Fundamentals of DB → Navathe
(4,  4),   -- Networking Top-Down → Kurose
(5,  5),   -- Computer Networks → Tanenbaum
(6,  6),   -- 1984 → Orwell
(7,  7),   -- Harry Potter → Rowling
(8,  8),   -- Brief History → Hawking
(9,  9),   -- Sapiens → Harari
(10, 13),  -- Art of Comp Prog → Knuth
(11, 1),   -- Design Patterns → Cormen (co-author)
(12, 12),  -- Data Comm → Forouzan
(13, 10),  -- Clean Code → Sedgewick
(14, 1),   -- Mythical Man Month → Cormen
(15, 10),  -- Pragmatic Programmer → Sedgewick
(16, 11),  -- Intro to DB Systems → C.J. Date
(17, 1),   -- Discrete Mathematics → Cormen
(18, 10),  -- Python DS Handbook → Sedgewick
(19, 7),   -- The Hobbit → Rowling (different author, reuse for data)
(20, 15),  -- Software Engineering → Pressman
(2,  14),  -- DB System Concepts also → Navathe
(4,  3),   -- Networking also → Elmasri
(6,  9),   -- 1984 also → Harari (fictional co-entry for data variety)
(9,  6);   -- Sapiens also → Orwell (fictional co-entry)

-- Borrow Transactions (35 records)
INSERT INTO Borrow_Transaction (member_id, book_id, staff_id, borrow_date, due_date, return_date, status) VALUES
(1,  1,  2, '2024-01-05', '2024-01-19', '2024-01-18', 'Returned'),
(2,  2,  3, '2024-01-08', '2024-01-22', '2024-01-25', 'Returned'),
(3,  3,  2, '2024-01-10', '2024-01-24', NULL,          'Overdue'),
(4,  6,  4, '2024-01-12', '2024-01-26', '2024-01-24', 'Returned'),
(5,  7,  3, '2024-01-15', '2024-01-29', '2024-01-30', 'Returned'),
(6,  8,  2, '2024-01-18', '2024-02-01', '2024-02-05', 'Returned'),
(7,  4,  5, '2024-01-20', '2024-02-03', NULL,          'Overdue'),
(8,  9,  3, '2024-01-22', '2024-02-05', '2024-02-04', 'Returned'),
(9,  5,  2, '2024-01-25', '2024-02-08', '2024-02-08', 'Returned'),
(10, 10, 4, '2024-02-01', '2024-02-15', NULL,          'Overdue'),
(11, 1,  3, '2024-02-03', '2024-02-17', '2024-02-15', 'Returned'),
(12, 2,  2, '2024-02-05', '2024-02-19', '2024-02-20', 'Returned'),
(13, 11, 5, '2024-02-08', '2024-02-22', '2024-02-22', 'Returned'),
(14, 12, 3, '2024-02-10', '2024-02-24', '2024-02-23', 'Returned'),
(15, 13, 2, '2024-02-12', '2024-02-26', NULL,          'Borrowed'),
(16, 14, 4, '2024-02-15', '2024-03-01', '2024-03-05', 'Returned'),
(17, 6,  3, '2024-02-18', '2024-03-03', '2024-03-01', 'Returned'),
(18, 7,  5, '2024-02-20', '2024-03-05', '2024-03-06', 'Returned'),
(19, 15, 2, '2024-02-22', '2024-03-07', '2024-03-07', 'Returned'),
(20, 3,  3, '2024-02-25', '2024-03-10', NULL,          'Overdue'),
(21, 16, 4, '2024-03-01', '2024-03-15', '2024-03-14', 'Returned'),
(22, 17, 2, '2024-03-05', '2024-03-19', '2024-03-20', 'Returned'),
(23, 18, 3, '2024-03-08', '2024-03-22', '2024-03-22', 'Returned'),
(24, 19, 5, '2024-03-10', '2024-03-24', '2024-03-23', 'Returned'),
(25, 20, 2, '2024-03-12', '2024-03-26', NULL,          'Borrowed'),
(1,  4,  3, '2024-03-15', '2024-03-29', '2024-03-28', 'Returned'),
(2,  5,  4, '2024-03-18', '2024-04-01', '2024-04-03', 'Returned'),
(3,  9,  2, '2024-03-20', '2024-04-03', NULL,          'Overdue'),
(4,  10, 3, '2024-03-22', '2024-04-05', '2024-04-04', 'Returned'),
(5,  11, 5, '2024-03-25', '2024-04-08', '2024-04-08', 'Returned'),
(7,  12, 2, '2024-04-01', '2024-04-15', NULL,          'Borrowed'),
(8,  13, 3, '2024-04-05', '2024-04-19', '2024-04-18', 'Returned'),
(9,  1,  4, '2024-04-08', '2024-04-22', '2024-04-22', 'Returned'),
(10, 6,  2, '2024-04-10', '2024-04-24', NULL,          'Overdue'),
(11, 7,  3, '2024-04-12', '2024-04-26', '2024-04-25', 'Returned');

INSERT INTO Fine (transaction_id, amount, reason, paid, paid_date) VALUES
(2,  30.00, 'Returned 3 days late',  TRUE,  '2024-01-28'),
(5,  10.00, 'Returned 1 day late',   TRUE,  '2024-02-01'),
(6,  40.00, 'Returned 4 days late',  FALSE, NULL),
(12, 10.00, 'Returned 1 day late',   TRUE,  '2024-02-22'),
(16, 40.00, 'Returned 4 days late',  FALSE, NULL),
(18, 10.00, 'Returned 1 day late',   TRUE,  '2024-03-08'),
(22, 10.00, 'Returned 1 day late',   FALSE, NULL),
(27, 20.00, 'Returned 2 days late',  TRUE,  '2024-04-05');

-- View 1: Currently borrowed books
CREATE OR REPLACE VIEW vw_active_borrows AS
SELECT
    bt.transaction_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.membership_type,
    b.title AS book_title,
    bt.borrow_date,
    bt.due_date,
    bt.status
FROM Borrow_Transaction bt
JOIN Member m ON bt.member_id = m.member_id
JOIN Book   b ON bt.book_id   = b.book_id
WHERE bt.status IN ('Borrowed', 'Overdue');

-- View 2: Overdue books with fine details
CREATE OR REPLACE VIEW vw_overdue_with_fines AS
SELECT
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email,
    b.title,
    bt.due_date,
    f.amount AS fine_amount,
    f.paid
FROM Borrow_Transaction bt
JOIN Member m ON bt.member_id = m.member_id
JOIN Book   b ON bt.book_id   = b.book_id
LEFT JOIN Fine f ON f.transaction_id = bt.transaction_id
WHERE bt.status = 'Overdue';

-- View 3: Book availability summary
CREATE OR REPLACE VIEW vw_book_availability AS
SELECT
    b.book_id,
    b.title,
    c.name AS category,
    b.total_copies,
    b.available_copies,
    (b.total_copies - b.available_copies) AS borrowed_copies
FROM Book b
JOIN Category c ON b.category_id = c.category_id;

-- Q1: All books with their authors and publisher
SELECT
    b.title,
    GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    p.name AS publisher,
    b.publication_year
FROM Book b
JOIN Book_Author ba ON b.book_id    = ba.book_id
JOIN Author      a  ON ba.author_id = a.author_id
JOIN Publisher   p  ON b.publisher_id = p.publisher_id
GROUP BY b.book_id, b.title, p.name, b.publication_year
ORDER BY b.title;

-- Q2: All borrow transactions with member and book info
SELECT
    bt.transaction_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member,
    b.title,
    bt.borrow_date,
    bt.due_date,
    bt.status
FROM Borrow_Transaction bt
JOIN Member m ON bt.member_id = m.member_id
JOIN Book   b ON bt.book_id   = b.book_id;

-- Q3: Members who have unpaid fines (LEFT JOIN)
SELECT
    CONCAT(m.first_name, ' ', m.last_name) AS member,
    m.email,
    f.amount,
    f.reason
FROM Fine f
JOIN Borrow_Transaction bt ON f.transaction_id = bt.transaction_id
JOIN Member m              ON bt.member_id      = m.member_id
WHERE f.paid = FALSE;

-- ── NESTED QUERIES ───────────────────────────────────────────

-- Q4: Members who borrowed more books than the average
SELECT
    CONCAT(m.first_name, ' ', m.last_name) AS member,
    COUNT(bt.transaction_id) AS total_borrows
FROM Member m
JOIN Borrow_Transaction bt ON m.member_id = bt.member_id
GROUP BY m.member_id
HAVING COUNT(bt.transaction_id) > (
    SELECT AVG(borrow_count)
    FROM (
        SELECT COUNT(transaction_id) AS borrow_count
        FROM Borrow_Transaction
        GROUP BY member_id
    ) AS avg_table
);

-- Q5: Books that have never been borrowed
SELECT title, isbn, shelf_location
FROM Book
WHERE book_id NOT IN (
    SELECT DISTINCT book_id FROM Borrow_Transaction
);

-- Q6: Members with fines greater than average fine amount
SELECT CONCAT(m.first_name, ' ', m.last_name) AS member, f.amount
FROM Fine f
JOIN Borrow_Transaction bt ON f.transaction_id = bt.transaction_id
JOIN Member m              ON bt.member_id      = m.member_id
WHERE f.amount > (SELECT AVG(amount) FROM Fine);

-- Q7: Total fines collected vs pending
SELECT
    SUM(CASE WHEN paid = TRUE  THEN amount ELSE 0 END) AS total_collected,
    SUM(CASE WHEN paid = FALSE THEN amount ELSE 0 END) AS total_pending,
    COUNT(*) AS total_fines
FROM Fine;

-- Q8: Most borrowed book
SELECT b.title, COUNT(bt.transaction_id) AS borrow_count
FROM Book b
JOIN Borrow_Transaction bt ON b.book_id = bt.book_id
GROUP BY b.book_id
ORDER BY borrow_count DESC
LIMIT 5;

-- Q9: Average fine amount per membership type
SELECT
    m.membership_type,
    AVG(f.amount) AS avg_fine,
    COUNT(f.fine_id) AS fine_count
FROM Fine f
JOIN Borrow_Transaction bt ON f.transaction_id = bt.transaction_id
JOIN Member m              ON bt.member_id      = m.member_id
GROUP BY m.membership_type;

-- ── GROUP BY + HAVING ────────────────────────────────────────

-- Q10: Members who borrowed more than 2 books
SELECT
    CONCAT(m.first_name, ' ', m.last_name) AS member,
    m.membership_type,
    COUNT(bt.transaction_id) AS total_borrows
FROM Member m
JOIN Borrow_Transaction bt ON m.member_id = bt.member_id
GROUP BY m.member_id, m.first_name, m.last_name, m.membership_type
HAVING COUNT(bt.transaction_id) > 2
ORDER BY total_borrows DESC;

-- Q11: Categories with more than 2 books available
SELECT
    c.name AS category,
    COUNT(b.book_id)      AS total_books,
    SUM(b.available_copies) AS total_available
FROM Category c
JOIN Book b ON c.category_id = b.category_id
GROUP BY c.category_id, c.name
HAVING SUM(b.available_copies) > 2;

-- Q12: Staff who processed more than 5 transactions
SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS staff_member,
    s.role,
    COUNT(bt.transaction_id) AS transactions_handled
FROM Staff s
JOIN Borrow_Transaction bt ON s.staff_id = bt.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name, s.role
HAVING COUNT(bt.transaction_id) > 5;

-- ── VIEWS USAGE ──────────────────────────────────────────────

-- Q13: Use active borrows view
SELECT * FROM vw_active_borrows;

-- Q14: Use overdue view
SELECT * FROM vw_overdue_with_fines;

-- Q15: Book availability from view
SELECT * FROM vw_book_availability ORDER BY available_copies ASC;


