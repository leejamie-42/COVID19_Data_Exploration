/*
COVID 19 Data Exploration
Skills used: Joins, CTE's, Temp Tables, Aggregate functions, Converting Data Types
*/

-- Taking a look at our data
Select * 
From PortfolioProject..CovidDeaths
Order by 3,4

-- Select data that we are going to be using
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in various countries
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From PortfolioProject..CovidDeaths
Order by 1,2

-- Looking at Total Cases vs Total Deaths in Indonesia specifically
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From PortfolioProject..CovidDeaths
Where location like 'Indonesia'
Order by 2


-- Looking at Total Cases vs Population
-- Shows what percentage of Indonesian population got COVID
Select location, date, population, total_cases, (total_cases/population)*100 as percent_population_infected
From PortfolioProject..CovidDeaths
Where location like 'Indonesia'
Order by 2

-- Looking at Countries with Highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population)*100) as highest_percent_population_infected
From PortfolioProject..CovidDeaths
Group by location, population
Order by 4 Desc

-- Showing Countries with Highest Death Count per Population
Select location, MAX(CAST(total_deaths as int)) as total_death_count
From PortfolioProject..CovidDeaths
Where continent is not null     -- ensures that we are only looking at countries, not continents
Group by location
Order by total_death_count Desc

-- Looking at Highest Death Count by Continent
Select location, MAX(CAST(total_deaths as int)) as total_death_count
From PortfolioProject..CovidDeaths
Where continent is null AND location not like '%income'
Group by location
Order by total_death_count Desc

-- Global numbers
Select date, SUM(new_cases) as total_cases, 
SUM(CAST(new_deaths as int)) as total_deaths, 
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as death_percentage --need to cast new_deaths to int because new_deaths stored as nvarchar
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2




-- Taking a look at CovidVaccinations table
Select * 
From PortfolioProject..CovidVaccinations

-- Join Deaths and Vaccinations table
Select * 
From PortfolioProject..CovidVaccinations vac
Join PortfolioProject..CovidDeaths death
	On vac.location = death.location AND vac.date = death.date


-- Total Population vs Vaccinations
-- Get rolling total for the number of people who has received at least one COVID vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query
-- Look at Percentage of Population that has received at least one COVID vaccine
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100 as percentage_people_vaccinated
From PopvsVac




-- Using Temp Table to perform Calculation on Partition By in previous query
-- Look at Percentage of Population that has received at least one COVID vaccine
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by death.location Order by death.location, death.date) as rolling_people_vaccinated
From PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vac
	On death.location = vac.location
	and death.date = vac.date
where death.continent is not null
Select *, (rolling_people_vaccinated/population)*100 as percentage_people_vaccinated
From #PercentPopulationVaccinated


