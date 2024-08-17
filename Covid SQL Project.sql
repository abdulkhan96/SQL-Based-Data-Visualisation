

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at total cases vs total deaths Case Fatality Rate (CFR) : Likelihood of dying if you get contact to covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CFR
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;
-- Looking at Total cases vs Population: Infection Rate: likehood of getting an infection
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
AND location = 'India'
ORDER BY 1,2;

-- Countries with highesh infection rate compared to population
SELECT location, population, MAX(total_cases) as Highest_infection_count, MAX((total_cases/population))*100 AS Max_infection_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Max_infection_rate DESC;

-- Countries with Highest Mortality Rate
SELECT location, 
       MAX(cast(total_deaths as int)) AS Highest_death_count, 
       (MAX(cast(total_deaths as int)) / MAX(total_cases)) * 100 AS Mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_death_count DESC;

-- Countries with Highest Death Counts
SELECT location, 
       MAX(cast(total_deaths as int)) AS Highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_death_count DESC;

-- LETS BREAK THINGS BY CONTINENT
SELECT continent, 
       MAX(cast(total_deaths as int)) AS Highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Highest_death_count DESC;
--- Highest death count per population
SELECT continent, 
       SUM(CAST(total_deaths AS int)) AS Total_deaths,
       SUM(population) AS Total_Population,
       (SUM(CAST(total_deaths AS int)) / SUM(population)) * 100 AS Crude_Mortality_Rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Crude_Mortality_Rate DESC;


-- Global Numbers on each day

SELECT date, 
       SUM(new_cases) AS Sum_of_new_cases, 
       SUM(CAST(new_deaths AS int)) AS Sum_of_new_deaths, 
       (SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Overall Data of totalcases, total deaths and death percentage
SELECT 
       SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS int)) AS Total_deaths, 
       (SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL;

-- Using both tables: Looking at total population vs vaccinations: Rolling column
WITH covidroll AS (
    SELECT 
        a.continent, 
        a.location, 
        a.date, 
        a.population, 
        b.new_vaccinations, 
        SUM(CAST(b.new_vaccinations AS int)) 
            OVER (PARTITION BY a.location ORDER BY a.location, a.date) AS Rolling_Vaccination_count
    FROM 
        CovidDeaths AS a
    JOIN 
        CovidVaccinations AS b 
        ON a.date = b.date 
        AND a.location = b.location
    WHERE 
        a.continent IS NOT NULL AND a.location ='India'
)
SELECT 
    *,(Rolling_Vaccination_count / CAST(Population AS float)) * 100 AS Rolling_Percentage
FROM 
    covidroll;

-- TEMP TABLE

CREATE TABLE PercentPopulationVaccinated_1
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopulationVaccinated_1
SELECT 
        a.continent, 
        a.location, 
        a.date, 
        a.population, 
        b.new_vaccinations, 
        SUM(CAST(b.new_vaccinations AS int)) 
            OVER (PARTITION BY a.location ORDER BY a.location, a.date) AS RollingPeopleVaccinated
    FROM 
        CovidDeaths AS a
    JOIN 
        CovidVaccinations AS b 
        ON a.date = b.date 
        AND a.location = b.location
    WHERE 
        a.continent IS NOT NULL

SELECT 
    *,(RollingPeopleVaccinated / CAST(Population AS float)) * 100 AS Rolling_Percentage
FROM PercentPopulationVaccinated_1
WHERE New_vaccinations IS NOT NULL 
	AND RollingPeopleVaccinated IS NOT NULL
	AND (RollingPeopleVaccinated / CAST(Population AS float)) * 100 is NOT NULL;


-- Creating view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated as
SELECT 
        a.continent, 
        a.location, 
        a.date, 
        a.population, 
        b.new_vaccinations, 
        SUM(CAST(b.new_vaccinations AS int)) 
            OVER (PARTITION BY a.location ORDER BY a.location, a.date) AS RollingPeopleVaccinated
    FROM 
        CovidDeaths AS a
    JOIN 
        CovidVaccinations AS b 
        ON a.date = b.date 
        AND a.location = b.location
    WHERE 
        a.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;

--- View for Global Numbers

CREATE VIEW Global_numbers as
SELECT 
       SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS int)) AS Total_deaths, 
       (SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL;

--View for Global Numbers for each day
CREATE VIEW Global_numbers_per_day as
SELECT date, 
       SUM(new_cases) AS Sum_of_new_cases, 
       SUM(CAST(new_deaths AS int)) AS Sum_of_new_deaths, 
       (SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date;

-- View for CMR-Crud Mortality Rate
CREATE VIEW Crude_mortality_rate as
SELECT continent, 
       MAX(CAST(total_deaths as int)) AS Highest_death_count, 
       (MAX(CAST(total_deaths as int)) / MAX(population)) * 100 AS Crude_Mortality_Rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent;

-- View for Highest Death counts per continent
CREATE VIEW Max_death_count_per_continent as
SELECT continent, 
       MAX(cast(total_deaths as int)) AS Highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent;

-- View for Countries with Highest Death Counts
CREATE VIEW Max_death_count_per_country as
SELECT location, 
       MAX(cast(total_deaths as int)) AS Highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location;

-- View for countries with highest mortality rates
CREATE VIEW Max_mortality_rate_per_country as
SELECT location, 
       MAX(cast(total_deaths as int)) AS Highest_death_count, 
       (MAX(cast(total_deaths as int)) / MAX(total_cases)) * 100 AS Mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location;

-- View for Highest infection rate per country
CREATE VIEW Max_infection_rate_per_country as
SELECT location, population, MAX(total_cases) as Highest_infection_count, MAX((total_cases/population))*100 AS Max_infection_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
--WHERE location = 'India'
GROUP BY location, population
;
--View for Case Fatality Rate (CFR) : Likelihood of dying
CREATE VIEW case_fatality_rate_per_day_country as
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM CovidDeaths
WHERE continent IS NOT NULL;
