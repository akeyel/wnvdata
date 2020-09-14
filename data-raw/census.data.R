library("tidyverse")
library("lubridate")
library("censusapi")
library("usmap")
data("countypop")
# requires api key in .Renviron ... or maybe not if doing less than 500 calls per day
# listCensusMetadata("pep/int_population", type = "variables", vintage = 2000)
# listCensusMetadata("pep/int_population", type = "geography", vintage = 2000)
# listCensusMetadata("pep/population", type = "variables", vintage = 2019)

## things to fix
## 46102 Shannon County, SD becomes 46113 Oglala Lakota in 2010
## 51019/51515	Bedford/Bedford City merge into
# need to have an API key in environment variable for this to work.
pre2010 <- getCensus("pep/int_population", vintage = 2000,
                     vars = c("GEONAME","DATE_","DATE_DESC", "POP"),
                     region = "county") %>%
  rename(DATE_CODE = DATE_,
         county_fips = county,
         state_fips = state) %>%
  filter(DATE_CODE %in% as.character(2:11)) %>%  # remove the weirdos
  mutate(fips = paste0(state_fips, county_fips),
         DATE = mdy(str_extract(DATE_DESC, "^\\d{1,2}\\/\\d{1,2}\\/\\d{4}"))) %>%
  left_join(select(countypop, fips, abbr, county), by = "fips")


post2010 <- getCensus("pep/population", vintage = 2019,
                      vars = c("DATE_CODE","DATE_DESC", "POP"),
                      region = "county") %>%
  rename(county_fips = county,
         state_fips = state) %>%
  filter(DATE_CODE %in% as.character(3:12)) %>%  # remove the weirdos
  mutate(fips = paste0(state_fips, county_fips),
         DATE = mdy(str_extract(DATE_DESC, "^\\d{1,2}\\/\\d{1,2}\\/\\d{4}"))) %>%
  left_join(select(countypop, fips, abbr, county), by = "fips")

county_popn <- bind_rows(pre2010,post2010) %>%
  mutate(year = year(DATE),
         fips = if_else(fips %in% c("46102","46113"), "46102/46113", fips),
         fips = if_else(fips %in% c("51019","51515"), "51019/51515", fips)) %>%
  group_by(fips, year) %>%
  summarize(state_fips = first(state_fips),
            state_abbr = first(abbr),
            county = first(county),
            pop = sum(as.numeric(POP))) %>%
  ungroup() %>%
  filter(!(state_fips %in% c("02","15","72"))) # remove AK, HI, and PR


## Code for checking wnvdata census.data -- why is it smaller?
# library(wnvdata)
# test <- county_popn %>%
#   mutate(year = lubridate::year(DATE),
#          fips = as.character(as.numeric(fips))) %>%
#   anti_join(census.data, by = c("year", "fips"))

# test1 <- county_popn %>%
#   mutate(year = lubridate::year(DATE)) %>%
#   filter(year == 2010,
#          !(state_fips %in% c("02","72","15")))
# View(anti_join(test1, neurownv2000_2018, by = "fips"))
# View(anti_join(neurownv2000_2018, test1, by = "fips"))


  # Census data were provided by A. Tyre in partially processed format
  # Below are the data manipulations used to finish processing the Census data
  
  # Note that cdc.raw refers to data provided by the CDC as part of the forecasting challenge.
  # These data are not provided here as they are sensitive and are not authorized to be shared.
  
  
  # Work on getting CENSUS data merged
  #county_popn$state = sapply(county_popn$GEONAME, splitter, ', ', 2, 1)
  
  # Add a column with state for each abbreviation
  #state.lookup.file = sprintf('%s/../data-raw/stateCodes.csv', drew.path)
  #state.lookup = read.csv(state.lookup.file, header = FALSE)
  #names(state.lookup) = c("number", "state2", 'abbr')
  
  # Update states from those with no GEONAME, but that have an abbreviation
  county_popn.b = merge(county_popn, state.lookup, by = 'abbr', all.x = TRUE)
  county_popn.b$missing = is.na(county_popn.b$state)
  index.b = grep(TRUE, county_popn.b$missing)
  county_popn.b$state[index.b] = as.character(county_popn.b$state2[index.b])
  
  # Update 'state' for District of Columbia records
  dc.index = grep("District of", county_popn.b$county)
  county_popn.b$state[dc.index] = "District of Columbia"
  
  # Update records for Shannon County, South Dakota (missing county field); Use new county name
  shannon.co = grep("Shannon County, South Dakota", county_popn.b$GEONAME)
  county_popn.b$county[shannon.co] = "Oglala Lakota"
  
  # Drop AK, HI, and Puerto Rico and NA
  county_popn2 = county_popn.b[county_popn.b$state %in% as.character(cdc.states), ] # Down to the 49, this worked. # up to 62160 rows. More than in the CDC data set. Good.
  
  # Drop the word "COUNTY" from counties
  county_popn2$county2 = gsub(" County", "", county_popn2$county)
  # Drop the word "Parish" from counties
  county_popn2$county2 = gsub(" Parish", "", county_popn2$county2)
  
  # Correct city to City in county_popn2
  county_popn2$county2 = gsub("city", "City", county_popn2$county2)
  
  # Create location join field
  county_popn2$location = sprintf("%s-%s", county_popn2$state, county_popn2$county2)
  
  # Change LaSalle to La Salle to match CDC data
  county_popn2$location = gsub("Illinois-LaSalle", "Illinois-La Salle", county_popn2$location)
  county_popn2$location = gsub("Louisiana-LaSalle", "Louisiana-La Salle", county_popn2$location)
  
  # Change De Kalb, La Porte, Lagrange to match CDC data (only for Indiana, the others are DeKalb in the cdc data)
  county_popn2$location = gsub("Indiana-DeKalb", "Indiana-De Kalb", county_popn2$location)
  county_popn2$location = gsub("Indiana-LaPorte", "Indiana-La Porte", county_popn2$location)
  county_popn2$location = gsub("Indiana-LaGrange", "Indiana-Lagrange", county_popn2$location)
  
  # Correct others to match CDC
  county_popn2$location = gsub("New Mexico-Do?a Ana", "New Mexico-Dona Ana", county_popn2$location) #**# Watch for problems with encoding for special character
  county_popn2$location = gsub("New Mexico-De Baca", "New Mexico-DeBaca", county_popn2$location)
  
  
  # Add Location-year field
  county_popn2$year = sapply(as.character(county_popn2$DATE), splitter, "-", 1, 0)
  county_popn2$location_year = sprintf("%s:%s", county_popn2$location, county_popn2$year)
  
  # Add join field to cdc data
  #cdc.raw object is not added in this script because it is proprietary, the reference is here to document what was done with it.
  # it was used to confirm that the census data could be merged with the forecast challenge data
  cdc.raw$location_year = sprintf("%s:%s", cdc.raw$location, cdc.raw$year)
  
  #cdc.raw has 59052 rows
  #county_popn2 has 62160 rows now that we merge on GEONAME and abbr
  
  #unique(test2$county.y) # 49 entries.
  
  # Test merge with CDC data & Check that everything merged correctly
  test = merge(county_popn2, cdc.raw, by = 'location_year', all.y = TRUE)
  max(is.na(test$POP)) # At least some have NA
  test2 = test[is.na(test$POP), ] # Down to 29 # Down to 180, now. #Formerly 940 failed joins
  
  # Reformat census data to essential fields
  census.data = cbind(county_popn2$location_year, county_popn2$location, county_popn2$year, county_popn2$POP)
  colnames(census.data) = c("district_year", "location", "year", "POP")
  census.data = as.data.frame(census.data)
  census.data$year = as.numeric(as.character(census.data$year))
  census.data$POP = as.numeric(as.character(census.data$POP))
  
  # merge in fips to facilitate joins
  census.data.2 = base::merge(census.data, fips.lookup, by = "location")
  
  census.data = census.data.2 # convert back to census.data name after troubleshooting any problems
  usethis::use_data(census.data) # Must be in the wnv_data directory
  
  
}
