# Library Management Database

A MySQL 8.0 database design for common library workflows, including catalogue management, physical copies, members, loans, reservations, fines, payments, and audit records.

## Design Summary

- 13 business tables and 1 audit-log table.
- Primary keys, foreign keys, unique constraints, and composite indexes.
- 5 user-defined functions.
- 5 stored procedures for creating loans, adding and returning items, renewing items, and paying fines.
- 5 views for active loans, inventory, member fines, popular books, and reservation queues.
- 14 triggers for audit logging.
- Transaction and rollback handling in core borrowing and payment workflows.

## Requirements

- MySQL 8.0 or later
- A database account permitted to create databases, routines, views, and triggers

## Run

From a terminal:

```bash
mysql -u root -p < library_management.sql
```

Alternatively, open `library_management.sql` in MySQL Workbench and run the script as a whole. It recreates a database named `library_portfolio` and includes fictional demonstration records.

## Privacy Note

Names, phone numbers, email addresses, and identification numbers in the seed section are fictional demonstration data. Personal course identifiers have been removed from this public version.

