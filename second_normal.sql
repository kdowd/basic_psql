-- second_normal.sql — the complete script this lesson walks through.
-- Run it with:  psql -U postgres -f second_normal.sql
--
-- Re-runnable. On a second run CREATE DATABASE reports "already exists"
-- (harmless — psql keeps going) and the DROP TABLEs reset both stages to
-- their starting rows, so you never end up with duplicates.
--
-- The people are a mix of real names and invented job matches. It is sample
-- data for teaching table structure, nothing more.

\c postgres
CREATE DATABASE jobsdb;

\c jobsdb

-- ============================================================
-- STAGE 1 — everything in one table, the way you would first write it
-- ============================================================
DROP TABLE IF EXISTS people;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS people_flat;

CREATE TABLE people_flat (
    id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    firstname text NOT NULL,
    lastname  text NOT NULL,
    job_title text NOT NULL
);

INSERT INTO people_flat (firstname, lastname, job_title) VALUES
    ('Dave',    'Smith',    'Electrician'),
    ('Tenzing', 'Norgay',   'Mountaineer'),
    ('Anne',    'Wilson',   'Electrician'),
    ('Ta',      'Mok',      'Gangster'),
    ('Viv',     'Richards', 'Plumber'),
    ('Jane',    'Campion',  'Electrician'),
    ('Shakib',  'Khan',     'Actor'),
    ('Ayub',    'Bachchu',  'Musician');

-- ============================================================
-- STAGE 2 — the same information, split into two tables with a foreign key
-- ============================================================

-- The job titles get their own table. UNIQUE stops the same title twice.
CREATE TABLE jobs (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title text NOT NULL UNIQUE
);

INSERT INTO jobs (title) VALUES
    ('Electrician'),
    ('Mountaineer'),
    ('Gangster'),
    ('Plumber'),
    ('Actor'),
    ('Musician');

-- The people table keeps the name and points at a job by its id.
-- REFERENCES is the foreign key: job_id must exist in jobs.
CREATE TABLE people (
    id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    firstname text    NOT NULL,
    lastname  text    NOT NULL,
    job_id    integer NOT NULL REFERENCES jobs(id)
);

INSERT INTO people (firstname, lastname, job_id) VALUES
    ('Dave',    'Smith',    1),
    ('Tenzing', 'Norgay',   2),
    ('Anne',    'Wilson',   1),
    ('Ta',      'Mok',      3),
    ('Viv',     'Richards', 4),
    ('Jane',    'Campion',  1),
    ('Shakib',  'Khan',     5),
    ('Ayub',    'Bachchu',  6);

-- Confirm both stages landed.
SELECT count(*) AS flat_rows FROM people_flat;
SELECT (SELECT count(*) FROM people) AS people_rows,
       (SELECT count(*) FROM jobs)   AS job_rows;
