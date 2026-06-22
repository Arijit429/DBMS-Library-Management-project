# 📚 Library Management System
### Database Management Systems | B.Tech CSE Capstone Project
### PW Institute of Innovation, Medhavi Skills University | Semester 2 | 2026

---

## 👥 Team Members

| Name | Roll Number |
|------|-------------|
| Avinash MK | 2501010040 |
| Shyam Nath Patro | 2501010130 |
| Arijit Deb | 2501010037 |
| Shaswat Dwivedi | 2501010090 |
| Priyanshu Singh | 2501010017 |

**Guide:** Rishav Upadhyay

---

## 📌 Project Overview

A full-stack, database-driven web application designed to automate and streamline the complete operations of a modern library — replacing manual paper-based systems with a robust, normalized relational database infrastructure.

The system manages the entire lifecycle of library operations: cataloging books, registering members, issuing and returning books, and automatically calculating overdue fines — all through a clean, responsive dark-themed web interface.

---

## ✨ Features

| Module | Description |
|--------|-------------|
| 📊 **Dashboard** | Real-time stats — total books, available copies, active members, borrows, overdue count, pending fines |
| 📖 **Book Catalog** | Search books by title or author with availability badges and full details |
| 👥 **Member Management** | View all members with membership type, status, and borrow history |
| 🔄 **Issue Book** | Transactional book issuing with automatic 14-day due date calculation |
| ↩️ **Return Book** | Process returns with automatic fine calculation (₹10/day overdue) |
| 💰 **Fine Tracking** | View all fines with paid/pending status |
| ⚠️ **Overdue Report** | Real-time overdue report powered by SQL Views |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Database** | MySQL 8.0 (Docker) |
| **Backend** | Node.js + Express.js REST API |
| **Frontend** | HTML5 + CSS3 + Vanilla JavaScript |
| **Dev Tools** | Docker, TablePlus, VS Code |

---

## 🗄️ Database Design

### Entity Overview
```
Publisher ──→ Book ←── Category
               ↓
          Book_Author ←── Author   (M:N junction table)
               ↓
      Borrow_Transaction ←── Member
               ↓                ↓
             Fine             Staff
```

### Tables (9 total | 151+ records)

| Table | Records | Purpose |
|-------|---------|---------|
| Publisher | 10 | Book publishers |
| Category | 8 | Book genres |
| Author | 15 | Book authors |
| Staff | 5 | Library staff |
| Member | 25 | Registered members |
| Book | 20 | Book catalog |
| Book_Author | 25 | M:N junction (book ↔ author) |
| Borrow_Transaction | 35 | Borrow/return records |
| Fine | 8 | Overdue fine records |

### Normalization
- ✅ **1NF** — All attributes atomic, no repeating groups
- ✅ **2NF** — All non-key attributes fully dependent on primary key
- ✅ **3NF** — No transitive dependencies (publisher details in Publisher table, not Book)

---

## 🚀 Getting Started

### Prerequisites
- Docker Desktop
- Node.js (v18+)
- TablePlus (optional, for DB visualization)

### 1. Start MySQL with Docker

```bash
docker run --name library-db \
  -e MYSQL_ROOT_PASSWORD=library123 \
  -e MYSQL_DATABASE=library_management \
  -p 3306:3306 \
  -d mysql:8.0
```

### 2. Load the Database Schema

Open TablePlus → Connect with:
```
Host:     127.0.0.1
Port:     3306
User:     root
Password: library123
Database: library_management
```
Paste the contents of `database/schema.sql` and run it.

### 3. Install Dependencies & Start Server

```bash
npm install
node backend/server.js
```

### 4. Open the App

```
http://localhost:3000
```

---

## 📁 Project Structure

```
DBMS-Library-Management-project/
├── backend/
│   └── server.js                         # Express REST API
├── database/
│   └── schema.sql                        # Full MySQL schema + data + queries
├── frontend/
│   └── index.html                        # SPA dark-themed dashboard
├── Library_Management_System_Report.pdf  # Project report
├── package.json
└── README.md
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/stats` | Dashboard statistics |
| GET | `/api/books?search=` | Book catalog with search |
| GET | `/api/members` | All members |
| GET | `/api/borrows/active` | Active borrows (via View) |
| GET | `/api/borrows/overdue` | Overdue report (via View) |
| POST | `/api/borrow` | Issue a book (transactional) |
| POST | `/api/return/:id` | Return a book + auto fine |
| GET | `/api/fines` | All fines |

---

## 🧠 Key DBMS Concepts Demonstrated

- **Relational Schema Design** with proper PKs and FKs
- **Many-to-Many** relationship resolved via `Book_Author` junction table
- **3NF Normalization** with functional dependency analysis
- **ACID Transactions** for borrow/return operations with ROLLBACK on failure
- **SQL Views** — `vw_active_borrows`, `vw_overdue_with_fines`, `vw_book_availability`
- **Advanced Queries** — JOINs (4-table), nested subqueries, `GROUP_CONCAT`, `GROUP BY + HAVING`
- **Constraints** — CHECK, UNIQUE, ENUM, NOT NULL, Foreign Keys
- **Indexes** on title, email, status, and borrow dates

---

## 📊 SQL Query Categories Implemented

| Category | Example |
|----------|---------|
| **JOINs** | Books with all authors + publisher (4-table JOIN) |
| **Nested Queries** | Members who borrowed more than average |
| **Aggregate Functions** | Total fines collected vs pending |
| **GROUP BY + HAVING** | Members with more than 2 borrows |
| **Views** | Active borrows, overdue report, book availability |

---

*Submitted for DBMS Capstone Project | Course 203MDS | PW Institute of Innovation*
