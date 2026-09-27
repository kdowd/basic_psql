-- basic_psql.sql — the complete script this lesson walks through.
-- Run it with:  psql -U postgres -f basic_psql.sql
--
-- This script is re-runnable. On a second run:
--   * CREATE DATABASE reports "database already exists" — expected, harmless,
--     and psql carries on because ON_ERROR_STOP is not set;
--   * the DROP TABLE in step 4 resets users back to exactly the eight rows
--     below, so you never end up with sixteen.
-- It only ever touches basic_psql.users. Any other table you create in this
-- database (books, from the transfer task) is left alone.

-- 1. Start from the maintenance database that always exists.
\c postgres

-- 2. Create your own database. Without this you would be creating tables
--    inside "postgres", which is where the server keeps its own business.
CREATE DATABASE basic_psql;

-- 3. Switch into it. Every command after this lands in basic_psql.
\c basic_psql

-- 4. Reset, then create the table. Four columns, one per fact you want to store.
--    The DROP is what makes this script safe to run twice; delete it once you
--    have data you care about.
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    firstname text,
    lastname  text,
    age       integer,
    email     text
);

-- 5. Add the dummy data. One INSERT, one statement, eight rows.
--    Note 'O''Brien': inside a string literal, a single quote is written twice.
INSERT INTO users (firstname, lastname, age, email) VALUES
    ('Mary',  'Johnson', 34,   'mary.johnson@example.com'),
    ('James', 'Smith',   41,   'james.smith@example.com'),
    ('Aroha', 'Ngata',   29,   'aroha.ngata@example.com'),
    ('Liam',  'O''Brien', 52,  'liam.obrien@example.com'),
    ('Priya', 'Sharma',  NULL, 'priya.sharma@example.com'),
    ('Tomas', 'Novak',   45,   NULL),
    ('Mary',  'Johnson', 34,   'Mary.Johnson@Example.Com'),
    ('Sofia', 'Rossi',   17,   'sofia.rossi@example.com');

-- 6. Read it back. This is the "simple select" — everything you ever do in
--    SQL is a variation on these four lines.
SELECT firstname, lastname, age, email FROM users;
