
--Инициализация--

DROP SCHEMA IF EXISTS workDB CASCADE;
CREATE SCHEMA workDB;
SET SEARCH_PATH = workDB;

DROP TABLE IF EXISTS workDB.AUTHORS CASCADE;
CREATE TABLE workDB.AUTHORS (
    author_id   serial   PRIMARY KEY,
    author_name VARCHAR(100)    NOT NULL,
    author_sex  VARCHAR(10),
    author_number_of_works INTEGER,
    author_date_of_birth   DATE,
    author_age  INTEGER,
    CONSTRAINT author_number_of_works_limit CHECK ( author_number_of_works >= 0 ),
    CONSTRAINT author_age_limit CHECK ( author_age >= 0 )
);

DROP TABLE IF EXISTS workDB.WORKS CASCADE;
CREATE TABLE workDB.WORKS (
    work_id  serial     PRIMARY KEY,
    work_name   VARCHAR(100)   NOT NULL,
    work_author_id   INTEGER   NOT NULL,
    work_creating_date   DATE,
    work_number_of_words   INTEGER,
    FOREIGN KEY (work_author_id) REFERENCES workDB.AUTHORS (author_id),
    CONSTRAINT work_number_of_words_limit CHECK ( work_number_of_words >= 0 )
);

DROP TABLE IF EXISTS workDB.SHOPS CASCADE;
CREATE TABLE workDB.SHOPS (
    shop_id     serial  PRIMARY KEY,
    shop_name   VARCHAR(100)  NOT NULL,
    shop_adress VARCHAR(100),
    shop_web_store  BOOLEAN
);

DROP TABLE IF EXISTS workDB.PUBLISHING_HOUSES CASCADE;
CREATE TABLE workDB.PUBLISHING_HOUSES (
    house_id   serial       PRIMARY KEY,
    house_name VARCHAR(100) NOT NULL,
    house_opening_date      DATE,
    house_number_of_books   INTEGER,
    CONSTRAINT house_number_of_books_limit CHECK ( house_number_of_books >= 0 )
);

DROP TABLE IF EXISTS workDB.BOOKS CASCADE;
CREATE TABLE workDB.BOOKS (
    book_id  serial     PRIMARY KEY,
    book_shop_id   INTEGER   NOT NULL,
    book_work_id   INTEGER   NOT NULL,
    book_house_id  INTEGER   NOT NULL,
    book_publishing_date    DATE,
    book_price  INTEGER,
    book_hard   BOOLEAN,
    book_in_store  INTEGER,
    book_rating    INTEGER,
    FOREIGN KEY (book_work_id) REFERENCES workDB.WORKS (work_id),
    FOREIGN KEY (book_shop_id) REFERENCES workDB.SHOPS (shop_id),
    FOREIGN KEY (book_house_id) REFERENCES workDB.PUBLISHING_HOUSES (house_id),
    CONSTRAINT book_price_limit CHECK ( book_price >= 0 ),
    CONSTRAINT book_rating_limit CHECK ( book_rating >= 0 )
);

DROP TABLE IF EXISTS workDB.PAIR_A_H CASCADE;
CREATE TABLE workDB.PAIR_A_H (
    pair_A_H_id   serial     PRIMARY KEY,
    author_id INTEGER   NOT NULL,
    house_id  INTEGER   NOT NULL,
    FOREIGN KEY (author_id) REFERENCES workDB.AUTHORS (author_id),
    FOREIGN KEY (house_id) REFERENCES workDB.PUBLISHING_HOUSES (house_id)
);

DROP TABLE IF EXISTS workDB.PAIR_H_S CASCADE;
CREATE TABLE workDB.PAIR_H_S (
    pair_H_S_id   serial     PRIMARY KEY,
    house_id  INTEGER   NOT NULL,
    shop_id   INTEGER   NOT NULL,
    FOREIGN KEY (house_id) REFERENCES workDB.PUBLISHING_HOUSES (house_id),
    FOREIGN KEY (shop_id) REFERENCES workDB.SHOPS (shop_id)
);

--Заполнение--

COPY workDB.AUTHORS FROM '/var/lib/postgresql/data/bd/AUTHORS.csv' WITH (FORMAT csv);
COPY workDB.WORKS FROM '/var/lib/postgresql/data/bd/WORKS.csv' WITH (FORMAT csv);
COPY workDB.SHOPS FROM '/var/lib/postgresql/data/bd/SHOPS.csv' WITH (FORMAT csv);
COPY workDB.PUBLISHING_HOUSES FROM '/var/lib/postgresql/data/bd/PUBLISHING_HOUSES.csv' WITH (FORMAT csv);
COPY workDB.BOOKS FROM '/var/lib/postgresql/data/bd/BOOKS.csv' WITH (FORMAT csv);

-- SELECT * FROM workDB.AUTHORS limit 5;
-- SELECT * FROM workDB.WORKS limit 5;
-- SELECT * FROM workDB.SHOPS limit 5;
-- SELECT * FROM workDB.PUBLISHING_HOUSES limit 5;
-- SELECT * FROM workDB.BOOKS limit 5;
