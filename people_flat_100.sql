-- people_flat_100.sql
-- A flat, un-normalised table: 100 people, each with their job title written out
-- as text. This table is not normalised - in other words it is not optimised for storage,
-- or retrieval.

-- Import into an database with psql's \i:
--
--     psql -U postgres -d YOUR_DATABASE
--     YOUR_DATABASE=# \i people_flat_100.sql
--
-- or from the shell:
--
--     psql -U postgres -d YOUR_DATABASE -f people_flat_100.sql
--
-- Expected output: CREATE TABLE, then INSERT 0 100.
--
-- *** If people_flat ALREADY EXISTS in the target database, read this. ***
-- The CREATE TABLE fails with
--     ERROR: relation "people_flat" already exists
-- and psql does NOT stop there: it carries on to the INSERT, which succeeds. You
-- then have your old rows PLUS these 100, and no second error to warn you — e.g.
-- importing over an 8-row table leaves 108 rows while the CREATE TABLE error
-- scrolls past. So either import into an EMPTY database, or uncomment the DROP
-- below before importing (it deletes the table and everything in it):
-- DROP TABLE IF EXISTS people_flat;

CREATE TABLE people_flat (
    id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    firstname text NOT NULL,
    lastname  text NOT NULL,
    job_title text NOT NULL
);

-- 100 rows, 13 distinct job titles:
--
--     Electrician  18      Nurse         8      Welder        3
--     Plumber      12      Teacher       8      Farmer        1
--     Actor        11      Chef          7      Potter        1
--     Musician     11      Mountaineer   6
--     Carpenter     9      Gangster      5
--
-- Four things in here are deliberate, and they are teaching aids rather than
-- mistakes: the same job title is stored over and over (Electrician 18 times);
-- two different people are both called Dave Smith; three surnames contain an
-- apostrophe, written '' inside the string; and three names carry accents
-- (José, Zoë, Schröder), which also proves the file's UTF-8 arrived intact.
INSERT INTO people_flat (firstname, lastname, job_title) VALUES
    ('Dave',      'Smith',        'Electrician'),
    ('Tenzing',   'Norgay',       'Mountaineer'),
    ('Anne',      'Wilson',       'Electrician'),
    ('Ta',        'Mok',          'Gangster'),
    ('Viv',       'Richards',     'Plumber'),
    ('Jane',      'Campion',      'Electrician'),
    ('Shakib',    'Khan',         'Actor'),
    ('Ayub',      'Bachchu',      'Musician'),
    ('Elena',     'Fischer',      'Electrician'),
    ('Marcus',    'Bell',         'Plumber'),
    ('Yusuf',     'Demir',        'Actor'),
    ('Ana',       'Ferreira',     'Musician'),
    ('Tomas',     'Kowalski',     'Carpenter'),
    ('Grace',     'Mbeki',        'Nurse'),
    ('Hiroshi',   'Tanaka',       'Teacher'),
    ('Sofia',     'Marchetti',    'Chef'),
    ('Ingrid',    'Larsen',       'Electrician'),
    ('Kwame',     'Osei',         'Mountaineer'),
    ('Vera',      'Novak',        'Plumber'),
    ('Declan',    'O''Brien',     'Actor'),
    ('Priya',     'Raman',        'Musician'),
    ('Andre',     'Silva',        'Carpenter'),
    ('Fatima',    'Noor',         'Nurse'),
    ('Peter',     'Novak',        'Electrician'),
    ('Leila',     'Haddad',       'Teacher'),
    ('Sven',      'Eriksson',     'Chef'),
    ('Rosa',      'Delgado',      'Gangster'),
    ('Anika',     'Sharma',       'Plumber'),
    ('Joe',       'Whitfield',    'Welder'),
    ('Miriam',    'Cohen',        'Electrician'),
    ('Tomasz',    'Nowak',        'Actor'),
    ('Zoë',       'Fischer',      'Musician'),
    ('Ahmed',     'Zaki',         'Carpenter'),
    ('Lucia',     'Moreno',       'Nurse'),
    ('Daniel',    'Okafor',       'Teacher'),
    ('Katrin',    'Vogel',        'Chef'),
    ('Ravi',      'Menon',        'Mountaineer'),
    ('Nadia',     'Petrova',      'Electrician'),
    ('Sam',       'Whitaker',     'Plumber'),
    ('Chiara',    'Rossi',        'Actor'),
    ('Pablo',     'Herrera',      'Musician'),
    ('Hana',      'Suzuki',       'Carpenter'),
    ('Omar',      'Farouk',       'Nurse'),
    ('Ulla',      'Berg',         'Teacher'),
    ('Viktor',    'Petrov',       'Electrician'),
    ('Grace',     'Adeyemi',      'Chef'),
    ('Liam',      'O''Connor',    'Gangster'),
    ('Mei',       'Lin',          'Plumber'),
    ('Arjun',     'Kapoor',       'Actor'),
    ('Sara',      'Lindqvist',    'Musician'),
    ('Paul',      'Dubois',       'Carpenter'),
    ('Amina',     'Diallo',       'Nurse'),
    ('Karl',      'Schmidt',      'Teacher'),
    ('Isabella',  'Costa',        'Electrician'),
    ('Nikolai',   'Volkov',       'Welder'),
    ('Farida',    'Khan',         'Chef'),
    ('José',      'Martínez',     'Plumber'),
    ('Emma',      'Nyberg',       'Actor'),
    ('Chen',      'Wei',          'Musician'),
    ('Robert',    'Mwangi',       'Carpenter'),
    ('Elena',     'Popescu',      'Nurse'),
    ('David',     'Chen',         'Teacher'),
    ('Yasmin',    'Ali',          'Electrician'),
    ('Bjorn',     'Halvorsen',    'Mountaineer'),
    ('Rita',      'Fernandes',    'Gangster'),
    ('Oliver',    'Grant',        'Chef'),
    ('Nadia',     'Rahman',       'Plumber'),
    ('Stefan',    'Horvath',      'Actor'),
    ('Amara',     'Nwosu',        'Musician'),
    ('Luca',      'Bianchi',      'Carpenter'),
    ('Hannah',    'Meyer',        'Nurse'),
    ('Vikram',    'Singh',        'Teacher'),
    ('Sofia',     'Almeida',      'Electrician'),
    ('Tomasz',    'Lis',          'Welder'),
    ('Leila',     'Ahmadi',       'Chef'),
    ('Jamie',     'Sutherland',   'Plumber'),
    ('Maria',     'Santos',       'Actor'),
    ('Johan',     'Bergstrom',    'Musician'),
    ('Priya',     'Nair',         'Carpenter'),
    ('Ahmed',     'Hassan',       'Nurse'),
    ('Claire',    'Fontaine',     'Teacher'),
    ('Dave',      'Smith',        'Plumber'),
    ('Sita',      'Devi',         'Electrician'),
    ('Mark',      'O''Neill',     'Actor'),
    ('Anna',      'Kowalczyk',    'Musician'),
    ('Tariq',     'Aziz',         'Carpenter'),
    ('Ingrid',    'Solberg',      'Electrician'),
    ('Mateo',     'Alvarez',      'Plumber'),
    ('Zoe',       'Anderson',     'Actor'),
    ('Rahim',     'Uddin',        'Musician'),
    ('Sunita',    'Rai',          'Mountaineer'),
    ('Bruno',     'Costa',        'Electrician'),
    ('Alice',     'Thompson',     'Plumber'),
    ('Kofi',      'Mensah',       'Gangster'),
    ('Nadia',     'Belkacem',     'Electrician'),
    ('Erik',      'Johansson',    'Mountaineer'),
    ('Harpreet',  'Kaur',         'Electrician'),
    ('Lucia',     'Ferrer',       'Electrician'),
    ('Peter',     'Vogel',        'Farmer'),
    ('Anna',      'Schröder',     'Potter');
