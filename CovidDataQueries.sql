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



  -- The following additional queries show examples of data manipulation through Update and Delete statements
  -- Make a copy of current CovidDeaths data for update and delete manipulation

-- Select database to use
USE CovidData

-- Make a copy of the source table for cleansing
DROP TABLE IF EXISTS dbo.CovidDeathsCleansed
SELECT * INTO dbo.CovidDeathsCleansed FROM dbo.CovidDeaths
GO

SELECT Distinct continent
FROM CovidData.dbo.CovidDeathsCleansed
--WHERE continent = ''  
	--and location IN ('Oceania', 'Europe', 'North America', 'South America', 'Africa', 'Asia')

UPDATE CovidData.dbo.CovidDeathsCleansed
SET continent = 'Continent'
WHERE continent = ''  
	and location IN ('Oceania', 'Europe', 'North America', 'South America', 'Africa', 'Asia')

UPDATE CovidData.dbo.CovidDeathsCleansed
SET continent = 'World'
WHERE location = 'World'  

UPDATE CovidData.dbo.CovidDeathsCleansed
SET continent = 'European Un'
WHERE location = 'European Union'  
	
-- Calculate summary values for all continents
SELECT continent, location, FORMAT(population,'###,###,###,###.') as Population, FORMAT(SUM(new_cases),'###,###,###,###') as Total_new_cases
FROM CovidData.dbo.CovidDeathsCleansed

-- Filter out continent and aggregate categories
GROUP BY continent, location, population
HAVING population > 100000000 and SUM(new_cases) > 1000000
ORDER BY SUM(new_cases) DESC


-- Delete records that relate to income levels as location

-- Start by validating what will be deleted
SELECT * 
FROM dbo.CovidDeathsCleansed
WHERE location like '%income%'

-- Delete the records
DELETE FROM dbo.CovidDeathsCleansed
WHERE location like '%income%'

-- Rerun the aggregate selection
-- Calculate summary values for all continents
SELECT continent, location, FORMAT(population,'###,###,###,###.') as Population, FORMAT(SUM(new_cases),'###,###,###,###') as Total_new_cases
FROM CovidData.dbo.CovidDeathsCleansed

-- Filter out continent and aggregate categories
GROUP BY continent, location, population
HAVING population > 100000000 and SUM(new_cases) > 1000000
ORDER BY SUM(new_cases) DESC
