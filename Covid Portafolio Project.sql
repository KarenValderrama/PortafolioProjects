Select *
From PortafolioProject..CovidDeaths$
Order by 3,4


-- Select Data that I will be using

Select location, date, total_cases, new_cases, total_deaths, population
From PortafolioProject..CovidDeaths$
Order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths,
CASE
        WHEN TRY_CONVERT(float, total_cases) = 0 THEN NULL  -- Avoid division by zero
        ELSE TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases)*100
    END AS DeathPercentage
From PortafolioProject..CovidDeaths$
Where location like '%Canada%'
Order by 1,2


-- Looking at the Total Cases vc Population
-- Shows what percentage of population got Covid
Select location, date, population, total_cases,
CASE
        WHEN TRY_CONVERT(float, total_cases) = 0 THEN NULL  -- Avoid division by zero
        ELSE TRY_CONVERT(float, total_cases) / TRY_CONVERT(float, population)*100
    END AS PopulationInfected
From PortafolioProject..CovidDeaths$
Where location like '%Canada%'
Order by 1,2

-- Looking at Countries with Higher Infections Rate compared to Population
SELECT
    location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    CASE
        WHEN MAX(population) = 0 OR MAX(total_cases) IS NULL THEN NULL  -- Avoid division by zero or NULL total_cases
        ELSE 
            CASE
                WHEN ISNUMERIC(MAX(population)) = 0 OR ISNUMERIC(MAX(total_cases)) = 0 THEN NULL  -- Filter out non-numeric values
                ELSE 
                    TRY_CAST(MAX(total_cases) AS FLOAT) * 100.0 / TRY_CAST(MAX(population) AS FLOAT) -- Perform the division
            END
    END AS PopulationInfected
FROM
    PortafolioProject..CovidDeaths$
GROUP BY
    location, population
ORDER BY
    PopulationInfected desc

-- Showing the Countries with Highest Death Count per Population
SELECT
    location, MAX(cast(total_deaths as int)) as TotalDeathCount 
FROM
    PortafolioProject..CovidDeaths$
Where continent is not null
GROUP BY
    location
ORDER BY
    TotalDeathCount desc


-- Showing the Continents with Highest Death Count per Population
SELECT
    continent, MAX(cast(total_deaths as int)) as TotalDeathCount 
FROM
    PortafolioProject..CovidDeaths$
Where continent is not null
GROUP BY
    continent
ORDER BY
    TotalDeathCount desc

-- GLOBAL NUMBERS
SELECT
    date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases) * 100
    END AS DeathPercentage
FROM
    PortafolioProject..CovidDeaths$
WHERE
    continent IS NOT NULL
GROUP BY
    date
HAVING
    SUM(new_cases) > 0
ORDER BY
    date;

-- GLOBAL NUMBERS TOTAL
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN NULL
        ELSE SUM(CAST(new_deaths AS FLOAT)) / SUM(new_cases) * 100
    END AS DeathPercentage
FROM
    PortafolioProject..CovidDeaths$
WHERE
    continent IS NOT NULL
ORDER BY
    1,2

-- Looking at Total Population vs Vaccinations
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
    PortafolioProject..CovidDeaths$ dea 
JOIN 
    PortafolioProject..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL 
ORDER BY 
    2, 3;

-- USE CTE
With PopvsVac (continent, location, date, population, New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
   dea.continent, 
   dea.location, 
   dea.date, 
   dea.population, 
   vac.new_vaccinations, 
   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
    PortafolioProject..CovidDeaths$ dea 
JOIN 
    PortafolioProject..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL 
--ORDER BY 2, 3
)
Select *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- TEMP TABLE
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccionations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
SELECT 
   dea.continent, 
   dea.location, 
   dea.date, 
   dea.population, 
   vac.new_vaccinations, 
   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
    PortafolioProject..CovidDeaths$ dea 
JOIN 
    PortafolioProject..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL 
--ORDER BY 2, 3

Select *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
Create View PercentPopulationVaccinated AS
SELECT 
   dea.continent, 
   dea.location, 
   dea.date, 
   dea.population, 
   vac.new_vaccinations, 
   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
    PortafolioProject..CovidDeaths$ dea 
JOIN 
    PortafolioProject..CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL 
--ORDER BY 2, 3

Select *
FROM PercentPopulationVaccinated