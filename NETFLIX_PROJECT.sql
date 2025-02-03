/* Formatted on 2/3/2025 5:26:04 Õ (QP5 v5.391) */
--NETFLIX PROJECT : 

-- CREATE TABLE NETFLIX AND IMPORT DATE USED TOAD APP.

CREATE TABLE NETFLIX
(
    show_id         VARCHAR2 (6),
    TYPE            VARCHAR2 (10),
    title           VARCHAR2 (150),
    director        VARCHAR2 (208),
    CAST            VARCHAR2 (1000),
    country         VARCHAR2 (150),
    date_added      VARCHAR2 (50),
    release_year    NUMBER,
    rating          VARCHAR2 (10),
    duration        VARCHAR2 (15),
    listed_in       VARCHAR2 (250),
    description     VARCHAR2 (1000)
);

--CHECK DUPLICATE

WITH
    DUPLICATE_CTE
    AS
        (SELECT SHOW_ID,
                TYPE,
                TITLE,
                DIRECTOR,
                CAST,
                COUNTRY,
                DATE_ADDED,
                RELEASE_YEAR,
                RATING,
                DURATION,
                LISTED_IN,
                DESCRIPTION,
                ROW_NUMBER ()
                    OVER (PARTITION BY SHOW_ID,
                                       TYPE,
                                       TITLE,
                                       DIRECTOR,
                                       CAST,
                                       COUNTRY,
                                       DATE_ADDED,
                                       RELEASE_YEAR,
                                       RATING,
                                       DURATION,
                                       LISTED_IN,
                                       DESCRIPTION
                          ORDER BY SHOW_ID)    AS ROW_NUM
           FROM NETFLIX)
SELECT *
  FROM DUPLICATE_CTE
 WHERE ROW_NUM > 1;


SELECT *
  FROM NETFLIX
 WHERE    SHOW_ID IS NULL
       OR TYPE IS NULL
       OR TITLE IS NULL
       OR DIRECTOR IS NULL
       OR CAST IS NULL
       OR COUNTRY IS NULL
       OR DATE_ADDED IS NULL
       OR RELEASE_YEAR IS NULL
       OR RATING IS NULL
       OR DURATION IS NULL
       OR LISTED_IN IS NULL
       OR DESCRIPTION IS NULL;


--FIX NULLS USED IF-STATMMENT PLSQL : 

BEGIN
    FOR rec
        IN (SELECT show_id,
                   director,
                   CAST,
                   country,
                   date_added,
                   release_year,
                   rating,
                   duration,
                   listed_in,
                   description
              FROM netflix)
    LOOP
        UPDATE netflix
           SET director =
                   CASE
                       WHEN rec.director IS NULL THEN 'Unknown Director'
                       ELSE rec.director
                   END,
               CAST =
                   CASE
                       WHEN rec.CAST IS NULL THEN 'Unknown Cast'
                       ELSE rec.CAST
                   END,
               country =
                   CASE
                       WHEN rec.country IS NULL THEN 'Unknown Country'
                       ELSE rec.country
                   END,
               date_added =
                   CASE
                       WHEN rec.date_added IS NULL THEN 'Not Available'
                       ELSE rec.date_added
                   END,
               release_year =
                   CASE
                       WHEN rec.release_year IS NULL THEN -1
                       ELSE rec.release_year
                   END,
               rating =
                   CASE
                       WHEN rec.rating IS NULL THEN 'Unrated'
                       ELSE rec.rating
                   END,
               duration =
                   CASE
                       WHEN rec.duration = 'Unknown' THEN '0'
                       ELSE rec.duration
                   END,
               listed_in =
                   CASE
                       WHEN rec.listed_in IS NULL THEN 'Uncategorized'
                       ELSE rec.listed_in
                   END,
               description =
                   CASE
                       WHEN rec.description IS NULL
                       THEN
                           'No Description Available'
                       ELSE
                           rec.description
                   END
         WHERE show_id = rec.show_id;
    END LOOP;

    COMMIT;
END;
/

-- DATA EXPLORATION : 

--Business Problems & Solutions :

--1. Count the number of Movies vs TV Shows:

  SELECT TYPE, COUNT (*) AS CONTANT_TYPE
    FROM NETFLIX
GROUP BY TYPE;

--2. Find the most common rating for movies and TV shows :

SELECT TYPE, RATING
  FROM (  SELECT TYPE,
                 RATING,
                 COUNT (*)                                                         AS COUNT_RATING,
                 DENSE_RANK () OVER (PARTITION BY TYPE ORDER BY COUNT (*) DESC)    AS RANKING
            FROM NETFLIX
        GROUP BY TYPE, RATING)
 WHERE RANKING = 1;

--3. List all movies released in a specific year (e.g., 2020):

  SELECT *
    FROM NETFLIX
   WHERE TYPE LIKE 'Mo%' AND RELEASE_YEAR = '2020'
ORDER BY SHOW_ID;

--4. Find the top 5 countries with the most content on Netflix:

        -- Splitting the values separated by a comma (,) in the COUNTRY column:

    SELECT SHOW_ID,
           TRIM (REGEXP_SUBSTR (country,
                                '[^,]+',
                                1,
                                LEVEL))    AS COUNTRY
      FROM NETFLIX
CONNECT BY     LEVEL <= REGEXP_COUNT (COUNTRY, ',') + 1
           AND PRIOR SHOW_ID = SHOW_ID
           AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL;


            --CHECK COUNT FOR Unknown Country

  SELECT COUNTRY, COUNT (COUNTRY)
    FROM NETFLIX
   WHERE COUNTRY = 'Unknown Country'
GROUP BY COUNTRY;

    -- THE FULL SOLUTION:

    SELECT TRIM (REGEXP_SUBSTR (country,
                                '[^,]+',
                                1,
                                LEVEL))    AS NEW_COUNTRY,
           COUNT (SHOW_ID)                 AS TOTAL_CONTANT
      FROM NETFLIX
CONNECT BY     LEVEL <= REGEXP_COUNT (COUNTRY, ',') + 1
           AND PRIOR SHOW_ID = SHOW_ID
           AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL
  GROUP BY TRIM (REGEXP_SUBSTR (country,
                                '[^,]+',
                                1,
                                LEVEL))
  ORDER BY COUNT (SHOW_ID) DESC
     FETCH FIRST 5 ROWS ONLY;

--5. Identify the longest movie

  SELECT *
    FROM NETFLIX
   WHERE TYPE LIKE 'Mo%' AND DURATION = (SELECT MAX (DURATION) FROM NETFLIX)
ORDER BY SHOW_ID;

--6. Find content added in the last 5 years:

SELECT *
  FROM NETFLIX
 WHERE TO_DATE (TRIM (DATE_ADDED),
                'Month DD, YYYY',
                'NLS_DATE_LANGUAGE = ENGLISH') >=
       ADD_MONTHS (TRUNC (SYSDATE), -60);

--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!:

SELECT *
  FROM NETFLIX
 WHERE DIRECTOR LIKE '%Rajiv Chilaka%';

--8. List all TV shows with more than 5 seasons

UPDATE NETFLIX
   SET DURATION = TRIM (DURATION);

SELECT *
  FROM NETFLIX
 WHERE     TYPE LIKE '%TV%'
       AND CAST (REGEXP_SUBSTR (DURATION, '^\d+') AS INT) >= 5;

--9. Count the number of content items in each genre :

    SELECT TRIM (REGEXP_SUBSTR (LISTED_IN,
                                '[^,]+',
                                1,
                                LEVEL))    AS NEW_LISTED,
           COUNT (SHOW_ID)                 AS TOTAL_CONTANT
      FROM NETFLIX
CONNECT BY     LEVEL <= REGEXP_COUNT (LISTED_IN, ',') + 1
           AND PRIOR SHOW_ID = SHOW_ID
           AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL
  GROUP BY TRIM (REGEXP_SUBSTR (LISTED_IN,
                                '[^,]+',
                                1,
                                LEVEL));

--11.List all movies that are documentaries

SELECT *
  FROM NETFLIX
 WHERE LISTED_IN LIKE '%Documentaries%';

--12.Find all content without a director

SELECT *
  FROM NETFLIX
 WHERE DIRECTOR LIKE 'Unknown Director';

--13.Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT *
  FROM NETFLIX
 WHERE     TYPE LIKE '%Mo%'
       AND CAST LIKE '%Salman Khan%'
       AND RELEASE_YEAR >= EXTRACT (YEAR FROM SYSDATE) - 10;

--14.Find the top 10 actors who have appeared in the highest number of movies produced in India.

    SELECT TRIM (REGEXP_SUBSTR (CAST,
                                '[^,]+',
                                1,
                                LEVEL))    AS NEW_CAST,
           COUNT (*)                       TOTAL_CONTANT
      FROM NETFLIX
     WHERE CAST NOT LIKE '%Unknown Cast%' AND COUNTRY LIKE '%India%'
CONNECT BY     LEVEL <= REGEXP_COUNT (CAST, ',') + 1
           AND PRIOR SHOW_ID = SHOW_ID
           AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL
  GROUP BY TRIM (REGEXP_SUBSTR (CAST,
                                '[^,]+',
                                1,
                                LEVEL))
  ORDER BY 2 DESC
     FETCH FIRST 10 ROWS ONLY;

/*
15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/

WITH
    NEW_TABLE
    AS
        (SELECT CASE
                    WHEN    DESCRIPTION LIKE '%kill%'
                         OR DESCRIPTION LIKE '%violence%'
                    THEN
                        'Bad Content'
                    ELSE
                        'Good Content'
                END    AS CATEGORY
           FROM NETFLIX)
  SELECT CATEGORY, COUNT (*) AS TOTAL_CONTENT
    FROM NEW_TABLE
GROUP BY CATEGORY
ORDER BY 1 DESC;

--******************** POWERD BY AHMAD AL SMADI *****************************
