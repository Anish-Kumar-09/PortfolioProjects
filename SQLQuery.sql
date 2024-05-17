SELECT *
FROM DA..coviddeaths
ORDER BY 3,4

--SELECT *
--FROM DA..covidvaccinations
--ORDER BY 3,4

--SELECT DATA THAT WE ARE GOING TO USE

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population
FROM DA..coviddeaths
order by 1,2

-- TOTAL CASES VS TOTAL DEATHS

ALTER TABLE DA..coviddeaths
ALTER COLUMN total_cases float;

ALTER TABLE DA..coviddeaths
ALTER COLUMN total_deaths float;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM DA..coviddeaths
WHERE location like '%INDIA%'
order by 1,2

ALTER TABLE DA..coviddeaths
ALTER COLUMN population float;

--LOOKING AT TOTAL CASES VS POPULATION
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentageInfected
FROM DA..coviddeaths
WHERE location like '%INDIA%'
order by 1,2

--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMARED TO POPULATION
SELECT location, population, MAX(total_cases) as InfectionCount, MAX((total_cases/population)*100) as PercentageInfected
FROM DA..coviddeaths
GROUP BY location, population
order by PercentageInfected desc

--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE PER POPULATION
SELECT location, MAX(total_deaths) as DeathCount
FROM DA..coviddeaths
WHERE continent is not null
GROUP BY location
order by DeathCount desc

--LOOKING AT CONTINENT WITH HIGHEST INFECTION RATE PER POPULATION
SELECT location, MAX(total_deaths) as DeathCount
FROM DA..coviddeaths
WHERE continent is null
GROUP BY location
order by DeathCount desc

--LOOKING AT TOTAL POPULATION VS VACCINATIONS

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TOTALVACCINATEDINLOCATION
, (SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)/(dea.population))*100 as VaccinationPercentage
From DA..coviddeaths as dea
JOIN DA..covidvaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
Order by 1,2

--SAME AS ABOVE USING CTE

WITH POPVSVAC(LOCATION, DATE, POPULATION, NEW_VACCINATIONS, TOTALVACCINATEDINLOCATION)
as
(
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TOTALVACCINATEDINLOCATION
From DA..coviddeaths as dea
JOIN DA..covidvaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (TOTALVACCINATEDINLOCATION/POPULATION)*100 as VaccinationPercentage
FROM POPVSVAC

--SAME AS ABOVE USING TEMP TABLE

DROP TABLE if exists #VaccinationPercentage
CREATE TABLE #VaccinationPercentage
(
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
TOTALVACCINATEDINLOCATION numeric
)
Insert into #VaccinationPercentage
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TOTALVACCINATEDINLOCATION
From DA..coviddeaths as dea
JOIN DA..covidvaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 1,2

SELECT *, (TOTALVACCINATEDINLOCATION * 100) / CAST(POPULATION AS int) as VaccinationPercentagePerLocation
FROM #VaccinationPercentage

--CREATE VIEW

CREATE VIEW VaccinationPercentage as
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as TOTALVACCINATEDINLOCATION
, (SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)/(dea.population))*100 as VaccinationPercentagePerLocation
From DA..coviddeaths as dea
JOIN DA..covidvaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--Order by 1,2

SELECT *
FROM VaccinationPercentage