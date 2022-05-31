
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

-- DROP TABLE IF EXISTS workDB.PAIR_A_H CASCADE;
-- CREATE TABLE workDB.PAIR_A_H (
--     pair_A_H_id   serial     PRIMARY KEY,
--     author_id INTEGER   NOT NULL,
--     house_id  INTEGER   NOT NULL,
--     FOREIGN KEY (author_id) REFERENCES workDB.AUTHORS (author_id),
--     FOREIGN KEY (house_id) REFERENCES workDB.PUBLISHING_HOUSES (house_id)
-- );
--
-- DROP TABLE IF EXISTS workDB.PAIR_H_S CASCADE;
-- CREATE TABLE workDB.PAIR_H_S (
--     pair_H_S_id   serial     PRIMARY KEY,
--     house_id  INTEGER   NOT NULL,
--     shop_id   INTEGER   NOT NULL,
--     FOREIGN KEY (house_id) REFERENCES workDB.PUBLISHING_HOUSES (house_id),
--     FOREIGN KEY (shop_id) REFERENCES workDB.SHOPS (shop_id)
-- );

--Заполнение--

COPY workDB.AUTHORS FROM '/var/lib/postgresql/data/bd/AUTHORS.csv' WITH (FORMAT csv);
COPY workDB.WORKS FROM '/var/lib/postgresql/data/bd/WORKS.csv' WITH (FORMAT csv);
COPY workDB.SHOPS FROM '/var/lib/postgresql/data/bd/SHOPS.csv' WITH (FORMAT csv);
COPY workDB.PUBLISHING_HOUSES FROM '/var/lib/postgresql/data/bd/PUBLISHING_HOUSES.csv' WITH (FORMAT csv);
COPY workDB.BOOKS FROM '/var/lib/postgresql/data/bd/BOOKS.csv' WITH (FORMAT csv);

SELECT * FROM workDB.AUTHORS;
SELECT * FROM workDB.WORKS limit 1003;
SELECT * FROM workDB.SHOPS limit 5;
SELECT * FROM workDB.PUBLISHING_HOUSES limit 5;
SELECT * FROM workDB.BOOKS limit 5;


INSERT INTO workDB.authors(author_id, author_name, author_sex, author_number_of_works, author_date_of_birth, author_age) values
('101', 'Камиль Лотфуллин','М','3','2000-11-09', 21);

INSERT INTO workDB.works(work_id, work_name, work_author_id, work_creating_date, work_number_of_words) values
('1001', 'Как выживать на физтехе 4 года', '101', '2023-04-10', 1),
('1002', 'Ослик суслик паукан', '101', '2020-02-02', 3),
('1003', 'Рыжие девочки прекрасны', '101', '2022-03-15', 14);

DROP TABLE IF EXISTS workDB.PAIR_A_H CASCADE;
WITH a AS (
    SELECT DISTINCT author_id AS pair_author_id, book_house_id AS pair_house_id FROM workDB.AUTHORS
JOIN workDB.WORKS ON authors.author_id = works.work_author_id
JOIN workDB.BOOKS ON works.work_id = books.book_work_id
) SELECT row_number() over (ORDER BY pair_author_id) as pair_A_H_id, * INTO workDB.PAIR_A_H FROM a
ORDER BY pair_author_id;

DROP TABLE IF EXISTS workDB.PAIR_H_S CASCADE;
WITH a AS (
    SELECT DISTINCT house_id AS pair_house_id, book_shop_id AS pair_shop_id FROM workDB.PUBLISHING_HOUSES
JOIN workDB.BOOKS ON publishing_houses.house_id = books.book_house_id
) SELECT row_number() over (ORDER BY pair_house_id) AS pair_H_S_id, * INTO workDB.PAIR_H_S FROM a
ORDER BY pair_house_id;

--Запросы--

/* 1. Для каждого автора вывести все книги, продающиеся в интернет магазине.
   В итоговом запросе таблица автор-название произведения-магазин, строки сортируются по автору и произведению. */

WITH a AS ( /* Сначала сделаем таблицу с авторами и их книгами, доступными для покупки в интернете */
    SELECT DISTINCT author_name, work_name, shop_name FROM workDB.WORKS
    JOIN workDB.BOOKS ON WORKS.work_id = BOOKS.book_work_id
    JOIN workDB.AUTHORS ON AUTHORS.author_id = WORKS.work_author_id
    JOIN workDB.SHOPS ON BOOKS.book_shop_id = SHOPS.shop_id
    WHERE shop_web_store = true
), b AS ( /* Теперь сделаем таблицу с группировкой книг по автору и создадим внутреннюю нумерацию */
    SELECT *, row_number() over(PARTITION BY author_name ORDER BY work_name) AS num
    FROM a
    ORDER BY author_name
) SELECT CASE WHEN num=1 THEN b.author_name ELSE ('') END AS author_name, work_name, shop_name
FROM b;

/* 2. Для каждого автора вывести суммарное кол-во слов во всех его произведениях и отсортировать по нему по убыванию вывод.
   В итоговом запросе таблица автор-сумма слов в его произведениях, строки сортируются по кол-ву слов. */

SELECT author_name, SUM(work_number_of_words) AS sum_of_words FROM workDB.AUTHORS
JOIN workDB.WORKS ON authors.author_id = works.work_author_id
GROUP BY author_name
ORDER BY sum_of_words DESC;

/* 3. Количество книг в жестком и мягком переплете.
   В итоговом запросе таблица с двумя столбцами и двумя значениями в них. */

WITH h AS (
    SELECT SUM(1) AS hard FROM workDB.BOOKS
    WHERE book_hard
), s AS (
    SELECT SUM(1) AS soft FROM workDB.BOOKS
    WHERE book_hard=false
) SELECT hard, soft FROM h, s;

/* 4. Вывести список издательств, открытых после 2000 года и сотрудничающих с более чем 50 магазинами.
   В итоговом запросе таблица издательство-сумма магазинов, строки сортируются по издательствам по алфавиту. */

WITH a AS (
    SELECT DISTINCT house_name, shop_name FROM workDB.PUBLISHING_HOUSES
    JOIN workDB.BOOKS ON publishing_houses.house_id = books.book_house_id
    JOIN workDB.SHOPS ON books.book_shop_id = shops.shop_id
    WHERE house_opening_date >= '1970-01-01'
) SELECT house_name, SUM(1) AS sum FROM a GROUP BY house_name HAVING SUM(1) > 50
ORDER BY house_name;

/* 5. Средний рейтинг книг для каждого автора до 20 лет
   В итоговом запросе таблица автор-средний рейтинг, строки сортируются по рейтингу. */

WITH a AS (
    SELECT author_name, author_age, book_rating FROM workDB.BOOKS
    JOIN workDB.WORKS ON books.book_work_id = works.work_id
    JOIN workDB.AUTHORS ON works.work_author_id = authors.author_id
    WHERE author_age <= 20
) SELECT author_name, AVG(book_rating) as avg_bookrate FROM a GROUP BY author_name
ORDER BY avg_bookrate DESC;

--Замазывание полей--
DROP FUNCTION IF EXISTS secret_subsuffix(
    secret_text varchar,
    left_bound int,
    shadow_symbol character
);
CREATE FUNCTION secret_subsuffix(
    secret_text varchar,
    bounds int default 2,
    shadow_symbol character default '*'
) RETURNS VARCHAR AS
$$DECLARE secret_info varchar = ''; input_len int; n_symbols int;
begin
    input_len = char_length(secret_text);
    n_symbols = input_len - bounds * 2;
    secret_info = repeat(shadow_symbol, n_symbols);
    secret_text = overlay(
        secret_text placing secret_info
        from bounds + 1 for n_symbols
    );
    return secret_text;
end$$ language plpgsql;
---

/* 6. Вывести всех авторов женского пола, замазав имя, если возраст > 40 */

SELECT CASE WHEN author_age > 40 THEN secret_subsuffix(author_name) ELSE author_name END AS author_name, author_age
FROM workDB.AUTHORS WHERE author_sex = 'Ж';
