-- Base Queries for SQL Project regarding Covid statistics

-- Examine total cases vs total deaths
SELECT location
      ,date
	  ,total_cases
	  ,total_deaths
	  ,population
	  ,CASE
			WHEN total_cases = 0 
			THEN NULL
			ELSE CAST(total_deaths as real)/CAST(total_cases as real)
			END
			as DeathPerc
      
  FROM CovidData.dbo.CovidDeaths
  WHERE location = 'United States'
  ORDER BY location, date
  
-- Examine total cases vs population
SELECT location
      ,date
	  ,total_cases
	  ,population
	  ,CASE
			WHEN total_cases = 0 
			THEN NULL
			ELSE CAST(total_cases as real)/CAST(population as real)
			END
			as InfectedPerc
      
  FROM CovidData.dbo.CovidDeaths
  WHERE location = 'United States'
  ORDER BY location, date
    
-- Examine countries with highest infection rates
SELECT location
      ,MAX(total_cases) as HighestInfectionCount
	  ,population
	  ,MAX(CASE
			WHEN population = 0 
			THEN NULL
			ELSE CAST(total_cases as real)/CAST(population as real)
			END)
			as InfectedPerc
      
  FROM CovidData.dbo.CovidDeaths
  GROUP BY location, population
  ORDER BY InfectedPerc DESC

  -- Examine countries with highest death count
SELECT location
      ,MAX(total_deaths) as TotalDeathCount
      
  FROM CovidData.dbo.CovidDeaths
  WHERE continent <> ''
  GROUP BY location
  ORDER BY TotalDeathCount DESC

  -- Examine continents and aggregate locations with total death count
SELECT location
      ,MAX(total_deaths) as TotalDeathCount
      
  FROM CovidData.dbo.CovidDeaths
  WHERE continent = ''
  GROUP BY location
  ORDER BY TotalDeathCount DESC

-- Create Views for use with Visualizations
DROP VIEW IF EXISTS dbo.PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
	SELECT deat.continent
		, deat.location
		, deat.date
		, deat.population
		, vacc.new_vaccinations
		, SUM(vacc.new_vaccinations) OVER (Partition by deat.location ORDER BY deat.location, deat.date) as RollingPopVaccinated

	FROM CovidData.dbo.CovidDeaths as deat
	INNER JOIN CovidData.dbo.CovidVaccinations vacc
		ON deat.location = vacc.location
		and deat.date = vacc.date
		
-- For use in Tableau visualization 

-- 1. Calculate total stats for World
Select SUM(CAST(new_cases as real)) as total_cases
		, SUM(CAST(new_deaths as real)) as total_deaths
		, SUM(CAST(new_deaths as real))/SUM(CAST(new_cases as real)) as DeathPerc
      
  FROM CovidData.dbo.CovidDeaths
  WHERE continent <> ''

-- 2. Calc total deaths by continent
Select location
	, SUM(cast(new_deaths as real)) as TotalDeathCount

	FROM CovidData.dbo.CovidDeaths
	WHERE continent = '' 
	and location not in ('World', 'European Union', 'International')
	and location not like '%income'
	
	GROUP BY location
	ORDER BY TotalDeathCount desc


-- 3. Infection Stats by Location
SELECT location
      ,MAX(total_cases) as HighestInfectionCount
	  ,population
	  ,MAX(CASE
			WHEN population = 0 
			THEN NULL
			ELSE CAST(total_cases as real)/CAST(population as real)
			END)
			as InfectedPerc
      
  FROM CovidData.dbo.CovidDeaths
  GROUP BY location, population
  ORDER BY InfectedPerc DESC


-- 4. Infection Stats by Location by Date
SELECT location
	  ,date
      ,MAX(total_cases) as HighestInfectionCount
	  ,population
	  ,MAX(CASE
			WHEN population = 0 
			THEN NULL
			ELSE CAST(total_cases as real)/CAST(population as real)
			END)
			as InfectedPerc
      
  FROM CovidData.dbo.CovidDeaths
  GROUP BY location, population, date
  ORDER BY InfectedPerc DESC

