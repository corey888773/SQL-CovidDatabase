select * from coviddeaths order by 3,4;

select location, date, total_cases, new_cases,
       total_deaths, population
from coviddeaths;

-- stosunek zakażeń do śmierci
-- pokazuje prawdopodobieństwo śmierci jeśli ktoś zostanie zarażony
select location, date, total_cases, total_deaths,
       (total_deaths/total_cases) * 100 as death_percentage
from coviddeaths
where location like '%States%' and continent is not null
order by location, date;

-- stosunek zakażeń do populacji
select location, date, population, total_cases,
       (total_cases/population) * 100 as infection_percentage
from coviddeaths;

-- kraje z największym stosunkiem zakażeń w porównaniu do populacji
select location, population, MAX(total_cases) as highest_infection_rate,
      MAX((total_cases/population)) * 100 as infection_percentage
from coviddeaths
group by location, population order by infection_percentage desc ;

-- zakazenie w polsce
select location, date, population, total_cases, coviddeaths.total_cases/coviddeaths.population * 100 as infection_percentage
from coviddeaths
where location LIKE 'Poland' order by infection_percentage desc;

-- kraje z najwyzszym stosunkiem smierci
select location, population, MAX(total_deaths) as highest_death_rate,
      MAX((total_deaths/population)) * 100 as death_percentage
from coviddeaths
where continent is not null
group by location, population order by highest_death_rate desc;

-- KONTYNENTY z najwyzszym stosunkiem smierci
select location, MAX(total_deaths) as highest_death_rate
from coviddeaths
where continent is null
group by location order by highest_death_rate desc;

-- Do okoła świata
select date, SUM(new_cases),
       SUM(new_deaths), SUM(new_deaths)/ SUM(new_cases) * 100 as death_percentage
from coviddeaths
where continent is not null
group by date order by 1,2;
-- Kompletna Suma
select SUM(new_cases),
       SUM(new_deaths), SUM(new_deaths)/ SUM(new_cases) * 100 as death_percentage
from coviddeaths
where continent is not null
order by 1,2;

-- populacja vs zaszczepieni
-- wykorzystując tablice porównawczą CTE table

with PopulationVsVaccination (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
as(
    select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
           SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
    from coviddeaths dea join covidvaccinations vac
    on dea.location = vac.location and dea.date = vac.date
    where dea.continent is not null
)
select *, RollingPeopleVaccinated/Population * 100 as VaccinationPercentage
from PopulationVsVaccination;

-- wykorzystując tablice pomocniczą TEMP table
drop table if exists TempPercentPopulationVaccinated;
create table TempPercentPopulationVaccinated
(
 Continent nvarchar(255),
 Location nvarchar(255),
 Date date,
 Population numeric,
 NewVaccinations numeric,
 RollingPeopleVaccinated numeric
);
insert into TempPercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
           SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
    from coviddeaths dea join covidvaccinations vac
    on dea.location = vac.location and dea.date = vac.date
    where dea.continent is not null;

select *, RollingPeopleVaccinated/Population * 100 as VaccinationPercentage
from TempPercentPopulationVaccinated;


-- tworzę podglądy do późniejszego wykorzystania
create view PercentPopulationVaccinated as
    select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
           SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
    from coviddeaths dea join covidvaccinations vac
    on dea.location = vac.location and dea.date = vac.date
    where dea.continent is not null;

create view PolandInfections as
    select location, date, population, total_cases, coviddeaths.total_cases/coviddeaths.population * 100 as infection_percentage
    from coviddeaths
    where location LIKE 'Poland' order by infection_percentage desc;