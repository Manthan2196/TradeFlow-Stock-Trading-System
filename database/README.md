# Database Files

Use `schema.sql` for normal project setup. It is the clean, combined schema for TradeFlow and includes:

- core tables
- indexes
- views
- triggers
- stored functions
- company-role additions
- admin reporting views

`backup/backup.tar` is a full PostgreSQL backup archive. Use it only when you want to restore the complete dumped database with data.

Keep this folder focused: use `schema.sql` for setup, and use `backup/backup.tar` only when a full database restore is needed.
