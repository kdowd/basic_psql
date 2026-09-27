-- intermediate_usage.sql — the complete script this lesson walks through.
-- Run it with:  psql -U postgres -f intermediate_usage.sql
--
-- Re-runnable. On a second run CREATE DATABASE reports "already exists"
-- (harmless — psql keeps going) and the DROP TABLE below resets the catalogue
-- back to its 16 starting rows, so you never end up with duplicates.
--
-- The games are invented. Nothing here describes a real product or price.

-- 1. A database of its own, so nothing here can touch your other work.
\c postgres
CREATE DATABASE gamevault;

\c gamevault

-- 2. Reset and create the table. Eight columns, five different types.
DROP TABLE IF EXISTS games;
CREATE TABLE games (
    id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        text    NOT NULL,
    genre        text    NOT NULL,
    price        numeric(6,2) NOT NULL,
    released     date    NOT NULL,
    rating       numeric(3,1),
    hours_played integer NOT NULL DEFAULT 0,
    finished     boolean NOT NULL DEFAULT false
);

-- 3. Fill it. One statement, sixteen rows.
--    Note what is missing where: two games have no rating yet, one has never
--    been played, and one title was imported twice by mistake.
INSERT INTO games (title, genre, price, released, rating, hours_played, finished) VALUES
    ('Neon Drift',    'Roguelike',  24.99, '2021-03-18', 4.5,  62,  true),
    ('Hollow Keep',   'RPG',        59.99, '2023-11-02', 4.8, 118,  false),
    ('Paper Skies',   'Platformer', 14.99, '2019-06-21', 4.0,   9,  true),
    ('Static Bloom',  'Puzzle',      9.99, '2022-01-14', NULL,  3,  false),
    ('Iron Verdict',  'Shooter',    39.99, '2024-09-05', 3.6,  47,  false),
    ('Salt & Cinder', 'RPG',        49.99, '2020-08-30', 4.2,  96,  true),
    ('Tiny Kingdoms', 'Sim',        19.99, '2018-04-12', 3.9, 210,  true),
    ('Redline Zero',  'Shooter',    69.99, '2025-02-27', 4.1,  12,  false),
    ('Echo Vault',    'Puzzle',     12.99, '2023-05-09', 4.4,  31,  true),
    ('Glasshouse',    'Sim',        27.50, '2021-11-19', NULL,  0,  false),
    ('Nightbus',      'Platformer',  7.99, '2017-10-03', 3.2,   5,  true),
    ('Paper Skies',   'Platformer', 14.99, '2019-06-21', 4.0,   9,  true),
    ('Dust & Diesel', 'Sim',        34.99, '2022-07-15', 3.8,  24,  false),
    ('Velvet Static', 'Roguelike',  17.99, '2024-04-08', 4.6,  55,  false),
    ('Cold Open',     'RPG',        29.99, '2019-01-25', 4.3,  71,  true),
    ('Marrow',        'Shooter',    22.50, '2023-08-11', NULL,  8,  false);

-- 4. Confirm it landed.
SELECT count(*) AS rows_loaded FROM games;
