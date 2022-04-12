--SELECT  * 
--FROM coviddeaths
--order by 3,4

--SELECT *
--FROM covidvaccinations
--order by 3,4

--Select Data that I am going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
order by 1,2

--Looking at Total Cases vs Total Deaths
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From coviddeaths
order by 1,2

--Looking at Total Cases vs Population
Select Location, date, total_cases, Population, (total_cases/population)*100 AS CovidPercentage
From coviddeaths
--Where Location like '%states%'
order by 1,2

--Looking at what countries have the highest infection rates per population size
Select Location, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 AS InfectionPercentage
From coviddeaths
Group by Population, Location
order by InfectionPercentage

--Looking at countries wih Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From coviddeaths
Group by Location
Order by TotalDeathCount DESC

--Looking at infection percentage vs death percentage
Select Location, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 AS InfectionPercentage, MAX(total_deaths/total_cases)*100 AS DeathsPercentage
From coviddeaths
Group by Population, Location
Having Location like 'Norway'
order by DeathsPercentage

--Looking at cases percentage vs vaccination percentage per population
Select deaths.Location, MAX(deaths.total_cases/deaths.population)*100 AS InfectionPercentage, MAX(vac.people_vaccinated/deaths.population)*100 AS VaccPercentage
From coviddeaths deaths
Join covidvaccinations vac
On deaths.location = vac.location
Group by Population, deaths.location
Having (deaths.location like 'Canada' 
or deaths.location like '%states%'
or deaths.location like 'Sweden'
or deaths.location like 'Denmark'
or deaths.location like 'Switzerland'
or deaths.location like 'Norway')
Order by InfectionPercentage DESC

--Looking at death percentage vs vaccination percentage per population
Select deaths.Location, MAX(deaths.total_deaths/deaths.population)*100 AS DeathsPercentage, MAX(vac.people_vaccinated/deaths.population)*100 AS VaccPercentage
From coviddeaths deaths
Join covidvaccinations vac
On deaths.location = vac.location
Group by Population, deaths.location
Order by DeathsPercentage DESC

--death percentage vs vaccination percentage vs infection percentage
Select deaths.Location, MAX(deaths.total_cases/deaths.population)*100 AS InfectionPercentage, MAX(vac.people_vaccinated/deaths.population)*100 AS VaccPercentage, MAX(cast(deaths.total_deaths as int)/deaths.total_cases)*100 AS TotalDeathCount
From coviddeaths deaths
Join covidvaccinations vac
On deaths.location = vac.location
Group by Population, deaths.location
Having (deaths.location like 'Canada' 
or deaths.location like '%states%'
or deaths.location like 'Sweden'
or deaths.location like 'Denmark'
or deaths.location like 'Switzerland'
or deaths.location like 'Norway')
Order by InfectionPercentage DESC

--Countries with Highest Rate of Deaths
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From coviddeaths
Where continent is not null
Group by Location
Order by TotalDeathCount DESC

--Locations by Highest Rate of Deaths
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From coviddeaths
Where continent is null
Group by location
Order by TotalDeathCount DESC

--Continents with Highest Total Death Count
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From coviddeaths
Where continent is not null
Group by continent
Order by TotalDeathCount DESC

-- GLOBAL NUMBERS 
Select date,SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From coviddeaths
Where continent is not null
Group by date
Order by 1,2

--Join two tables together
Select * 
From coviddeaths dea
Join covidvaccinations vac
On dea.location = vac.location
and dea.date = vac.date

--Looking at total population vs vaccination
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From coviddeaths dea
Join covidvaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

--use CTE to calculate rolling vaccintation

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(float,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date)
as RollingPeopleVaccinated
From coviddeaths dea
Join covidvaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
and vac.new_vaccinations is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 AS PercentPeopleVaccinated
From PopvsVac

--TEMP TABLE
DROP TABLE IF exists #PercentVaccinated
Create table #PercentVaccinated
(Continent nvarchar(255), location nvarchar(255), date datetime, population numeric,
new_vaccinations numeric, RollingPeopleVaccinated numeric)

Insert into #PercentVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(float,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date)
as RollingPeopleVaccinated
From coviddeaths dea
Join covidvaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
and vac.new_vaccinations is not null

Select *, (RollingPeopleVaccinated/Population)*100 AS PercentPeopleVaccinated
From #PercentVaccinated

--Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(float,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date)
as RollingPeopleVaccinated
From coviddeaths dea
Join covidvaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
and vac.new_vaccinations is not null
