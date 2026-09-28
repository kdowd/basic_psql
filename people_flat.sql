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