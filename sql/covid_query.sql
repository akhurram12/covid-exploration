select *
from CovidExploration.dbo.covid_deaths
where continent is not null --When continent is NULL, location specifies a grouping in the data and not an actual country
order by 3,4 -- order by 3rd and 4th column

--select *
--from CovidExploration.dbo.covid_vaccinations
--order by 3,4

--Select data that we will use
select Location, date, total_cases, new_cases, total_deaths, population
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
order by 1,2

--Likelihood of death if you contract covid in the United States
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
and Location like '%states'
order by 1,2

--Percent of population that got Covid
select Location, date, total_cases, population, (total_cases/population)*100 as percent_infected
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
and Location like '%states'
order by 1,2

--Countries with highest infection rate compared to population
select Location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population)*100) as percent_infected
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
group by location, population
order by percent_infected desc

--Countries with highest death count
select Location, MAX(cast(total_deaths as int)) as total_death_count
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
group by location
order by total_death_count desc

--Countries with highest death rate
select Location, MAX((cast(total_deaths as int)/population)*100) as death_rate
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
group by location
order by death_rate desc

--BREAK IT DOWN BY CONTINENT
select continent, MAX(cast(total_deaths as int)) as total_death_count
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
group by continent
order by total_death_count desc

--In the above query, the numbers don't look right; let's use location and where
--continent is NULL
select location, MAX(cast(total_deaths as int)) as total_death_count
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is null
group by location
order by total_death_count desc

--GLOBAL NUMBERS 
--total cases and deaths by date
select date, SUM(new_cases), SUM(cast(new_deaths as int)) 
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
group by date
order by 1,2

--death percentage by date
select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
			100*SUM(cast(new_deaths as int))/SUM(new_cases) as death_percentage
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
group by date
order by 1,2

--death percentage overall
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
			100*SUM(cast(new_deaths as int))/SUM(new_cases) as death_percentage
from CovidExploration.dbo.covid_deaths
where 1=1
and continent is not null
order by 1,2

--Looking at total population v. vaccination
select dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations
		, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location, dea.date) as rolling_count_vaccinated
from CovidExploration.dbo.covid_deaths as dea
join CovidExploration.dbo.covid_vaccinations as vac
	on dea.Location = vac.Location
	and dea.date = vac.date
where 1=1
and dea.continent is not null
order by 1,2,3

--USE Common Table Expression (CTE)
with PopvsVac (continent, Location, date, population, new_vaccinations, rolling_count_vaccinated)
as 
(
select dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations
		, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location, dea.date) as rolling_count_vaccinated
from CovidExploration.dbo.covid_deaths as dea
join CovidExploration.dbo.covid_vaccinations as vac
	on dea.Location = vac.Location
	and dea.date = vac.date
where 1=1
and dea.continent is not null
)
select *, 100*rolling_count_vaccinated/population
from PopvsVac
--Note: above query is giving >100% for some countries since rolling_count_vaccinated is greater than population.
--try to use a different variable instead. Tried other variables as well like people_vaccinated and total_vaccinations
--but seems like the rolling count on these also does not work. 
--total_vaccinations for Bhutan, e.g., are greater than the population so may be including booster shots as well. 



--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_count_vaccinated numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations
		, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location, dea.date) as rolling_count_vaccinated
from CovidExploration.dbo.covid_deaths as dea
join CovidExploration.dbo.covid_vaccinations as vac
	on dea.Location = vac.Location
	and dea.date = vac.date
where 1=1
and dea.continent is not null
select *, 100*rolling_count_vaccinated/population
from #PercentPopulationVaccinated


-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
Use CovidExploration --create view in the correct database
Go
Create View percent_population_vaccinated as 
select dea.continent, dea.Location, dea.date, dea.population, vac.new_vaccinations
		, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.Location order by dea.Location, dea.date) as rolling_count_vaccinated
from CovidExploration.dbo.covid_deaths as dea
join CovidExploration.dbo.covid_vaccinations as vac
	on dea.Location = vac.Location
	and dea.date = vac.date
where 1=1
and dea.continent is not null

--We can now query the view
select *
from percent_population_vaccinated
