-- Playing around with Covid-19 Data

select * 
from `Covid-19 Project`.coviddeaths;

select * 
from `Covid-19 Project`.covidvaccinations;

-- Select data for Analysis
select location, date, total_cases, new_cases, total_deaths, population
from `Covid-19 Project`.coviddeaths
order by 1,3; 

-- Total Cases vs Total Deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from `Covid-19 Project`.coviddeaths
where location like '%Nigeria%'
order by 3 asc; 

-- Total Cases vs Population
select location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected
from `Covid-19 Project`.coviddeaths
order by 5 desc; 

-- Countries with Highest Infection Rate compared to Population
select location, cast(population as signed), max(cast(total_cases as signed)) as HighestInfectionCount, max((total_cases/population))*100 as PercentagePopulationInfected
from `Covid-19 Project`.coviddeaths
group by location, population
order by PercentagePopulationInfected desc; 

-- Countries with Highest Death Count per Population
select location, population, max(total_deaths) as TotalDeathCount, max((total_deaths/population))*100 as PercentPopMortality
from `Covid-19 Project`.coviddeaths
group by location, population
order by PercentPopMortality desc; 

-- OR 
select location, max(cast(total_deaths as signed)) as TotalDeathCount
from `Covid-19 Project`.coviddeaths
where location not in ('High income', 'Low income', 'Asia', 'Africa', 'Oceania', 'Europe', 'North America', 'South America', 'European Union')
group by location
order by TotalDeathCount desc; 

-- BREAKING DOWN BY CONTINENT
-- Showing Continent With Highest Death Count
select continent, max(cast(total_deaths as signed)) as TotalDeathCount
from `Covid-19 Project`.coviddeaths
where continent in ('Asia', 'Africa', 'Oceania', 'Europe', 'North America', 'South America')
group by continent
order by TotalDeathCount desc; 

-- GLOBAL NUMBERS
select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
from `Covid-19 Project`.coviddeaths
where continent in ('Asia', 'Africa', 'Oceania', 'Europe', 'North America', 'South America')
-- group by date
order by 2,3;

-- Combining the two tables
-- Looking at Total Populations vs Vaccinations, and calculating a new column for total vaccinations for each country using partition
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations, 
       SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS rolling_people_vaccinated
FROM `Covid-19 Project`.coviddeaths dea
JOIN `Covid-19 Project`.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
ORDER BY 1, 2, 3;

-- USE CTE
with PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations, 
       SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
FROM `Covid-19 Project`.coviddeaths dea
JOIN `Covid-19 Project`.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
ORDER BY 1, 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- USE TEMP TABLE
/*DROP Table if exists #PercentPopulationVaccinated
CREATE TEMPORARY TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert INTO #PercentPopulationVaccinated
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations, 
       SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingPeopleVaccinated
FROM `Covid-19 Project`.coviddeaths dea
JOIN `Covid-19 Project`.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated*/

-- Creating a view to store for vizualization on Tableau - allowing drill down
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM `Covid-19 Project`.coviddeaths dea
JOIN `Covid-19 Project`.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date 

-- Test the stored view
Select*
From PercentPopulationVaccinated