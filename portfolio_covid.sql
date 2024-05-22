USE sql_covid;


-- DATE DATE RANGE
SELECT min(date) AS data_start_date, max(date) AS data_end_date
FROM covid_deaths;


-- TOTAL CASES VS POPULATION IN UAE
SELECT location,
	date,
	total_cases,
    total_deaths,
    population,
    (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location LIKE '%emirates%'
ORDER BY 3,4;

-- TOTAL CASES VS POPULATION IN UAE

SELECT location,
	date,
    population,
	total_cases,
    total_deaths,
    (total_cases/population)*100 AS case_percentage
FROM covid_deaths
WHERE location LIKE '%emirates%'
ORDER BY 3,4;


-- HIGHEST CASE PERCENTAGE AGAINST POPULATION PER COUNTRY
SELECT location,
    population,
	MAX(total_cases) AS highest_number_of_cases
FROM covid_deaths
GROUP BY location,
    population
ORDER BY 4 DESC;


-- RUNNING DEATH COUNT AND DEATH RATE PER COUNTRY 
SELECT location,
	population,
    MAX(CAST(total_deaths AS unsigned)) current_death_count,
    (MAX(CAST(total_deaths AS unsigned))/population)*100 AS max_death_percentage
FROM covid_deaths
WHERE continent <> ''
GROUP BY location, population
ORDER BY max_deaths DESC;

-- GET TOTAL DEATH COUNT BY CONTINENT
SELECT 
    location,
    MAX(CAST(total_deaths AS UNSIGNED)) AS current_death_count
FROM
    covid_deaths
WHERE
    continent = '' AND location <> ''
GROUP BY location , continent
ORDER BY current_death_count DESC;


-- 	GLOBAL DATA - NEW CASES, NEW DEATH AND DAILY DEATH % AGAINST NEW CASES

SELECT date,
	SUM(new_cases) AS world_cases_per_day,
    SUM(total_cases) AS world_total_cases,
    SUM(CAST(new_deaths AS UNSIGNED)) AS death_per_day,
    SUM(CAST(total_deaths AS UNSIGNED)) AS total_death_per_day,
    (SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases))*100 AS death_rate_per_world_new_case
FROM covid_deaths
WHERE continent <> ''
GROUP BY date
ORDER BY date;

-- WORLD VACCINATION PERCENTAGE

SELECT cd.continent,
	cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS UNSIGNED)) 
    OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as running_vaccinations
FROM covid_deaths cd
JOIN covid_vaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.location IS NOT NULL
ORDER BY 2,3;


-- USING CTE

WITH vaccination_percentage (
	continent,
	location,
    date,
	population,
    new_vaccinations,
    running_vaccinations
)
AS (
SELECT cd.continent,
	cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS UNSIGNED)) 
    OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as running_vaccinations
FROM covid_deaths cd
JOIN covid_vaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.location IS NOT NULL
)
SELECT *, (running_vaccinations/population)*100 AS running_vaccinations_percentage
FROM vaccination_percentage;
	
    
    
-- USING TEMP TABLE
DROP TABLE IF EXISTS temp_vaccination_percentage;
CREATE TEMPORARY TABLE temp_vaccination_percentage 
( 
	continent varchar(255),
	location varchar(255),
    date datetime,
    population int,
	new_vaccinations int,
    running_vaccinations int
);


INSERT INTO temp_vaccination_percentage 
SELECT cd.continent,
	cd.location,
    cd.date,
    cd.population,
    CAST(NULLIF(cv.new_vaccinations, '') AS UNSIGNED),
    SUM(CAST(NULLIF(cv.new_vaccinations, '') AS UNSIGNED)) 
        OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
FROM covid_deaths cd
JOIN covid_vaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.location IS NOT NULL;



SELECT *, (running_vaccinations/population)*100 AS running_vaccinations_percentage
FROM temp_vaccination_percentage;




-- CREATE VIEW FOR DATA VISUALIZATION LATER

DROP VIEW IF EXISTS view_vaccination_percentage;
CREATE VIEW view_vaccination_percentage
AS
WITH vaccination_percentage (
	continent,
	location,
    date,
	population,
    new_vaccinations,
    running_vaccinations
)
AS (
SELECT cd.continent,
	cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS UNSIGNED)) 
    OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as running_vaccinations
FROM covid_deaths cd
JOIN covid_vaccinations cv
	ON cd.location = cv.location 
    AND cd.date = cv.date
WHERE cd.location IS NOT NULL
)
SELECT *, (running_vaccinations/population)*100 AS running_vaccinations_percentage
FROM vaccination_percentage;