SELECT *
FROM Covid19Project..CovidDeaths$
ORDER BY 3,4

--SELECT *
--FROM Covid19Project..CovidVaccinations$
--ORDER BY 3,4

-- Select Data that we will be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid19Project..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2 -- ordered by location and date

-- Update datatype of total_cases from nvarchar to float 
ALTER TABLE Covid19Project..CovidDeaths$
ALTER COLUMN total_cases float;

-- Update datatype of total_deaths from nvarchar to float 
ALTER TABLE Covid19Project..CovidDeaths$
ALTER COLUMN total_deaths float;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in the US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercentage
FROM Covid19Project..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2 

-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS populationInfected_percentage
FROM Covid19Project..CovidDeaths$
--WHERE location like '%states%'
ORDER BY 1,2 

-- Looking at Countries with Highest Infection Rates Compared to Population
SELECT location, population, MAX(total_cases) AS highestInfectionCount, MAX((total_cases/population))*100 AS populationInfected_percentage
FROM Covid19Project..CovidDeaths$
GROUP BY population, location
ORDER BY populationInfected_percentage desc -- largest to smallest %

-- Showing the Breakdown of Locations/Areas
SELECT location, MAX(CAST(total_deaths AS int)) AS totalDeathCount --cast changes the datatype
FROM Covid19Project..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY totalDeathCount desc

-- Showing the Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) AS totalDeathCount --cast changes the datatype
FROM Covid19Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY totalDeathCount desc

-- Showing the Continents with the Highest Death Count per Population
-- Issue? Queries North America numbers as only those of the USA
SELECT continent, MAX(CAST(total_deaths AS int)) AS totalDeathCount --cast changes the datatype
FROM Covid19Project..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent 
ORDER BY totalDeathCount desc

-- 1.
-- Global STATS, TOTAL CASES

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS totalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS globalDeathPercentage
FROM Covid19Project..CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- 2. Total Deaths Based on Continent

SELECT Location, SUM(CAST(new_deaths AS int)) AS total_deaths
FROM Covid19Project..CovidDeaths$
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_deaths desc


--3. Population Infected
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM Covid19Project..CovidDeaths$
-- WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected desc


--4. 
SELECT Location, Population, date, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM Covid19Project..CovidDeaths$
--WHERE location like '%states%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected desc

-- JOINING DEATHS AND VACCINES TABLES TOGETHER
SELECT *
FROM Covid19Project..CovidDeaths$ AS deaths
JOIN Covid19Project..CovidVaccinations$ AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date

-- Looking at Total Population vs. Vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CONVERT(float,vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location
, deaths.date) AS AccumulatePeopleVaccinated
FROM Covid19Project..CovidDeaths$ AS deaths
JOIN Covid19Project..CovidVaccinations$ AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3;

-- COMMON TABLE EXPRESSION (CTE)
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativePeopleVaccinated)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CONVERT(float,vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location,
deaths.date) AS CumulativePeopleVaccinated
FROM Covid19Project..CovidDeaths$ AS deaths
JOIN Covid19Project..CovidVaccinations$ AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (CumulativePeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
CumulativePeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CONVERT(float,vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location,
deaths.date) AS CumulativePeopleVaccinated
FROM Covid19Project..CovidDeaths$ AS deaths
JOIN Covid19Project..CovidVaccinations$ AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
--WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (CumulativePeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- CREATING VIEWS TO STORE DATA FOR LATER VIZ
CREATE VIEW PercentPopulationVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CONVERT(float,vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location,
deaths.date) AS CumulativePeopleVaccinated
FROM Covid19Project..CovidDeaths$ AS deaths
JOIN Covid19Project..CovidVaccinations$ AS vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
