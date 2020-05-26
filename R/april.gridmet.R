#library(dfmip) # for splitter function #www.github.com/akeyel/dfmip
#library(rf1)                           #www.github.com/akeyel/rf1
#**# Need to re-enable these lines, both packages available on github. # Disabled to avoid having to add them as official dependencies
# when the primary purpose of this repository is the data sets, and not the data processing

# Define a function to run the process, because its a lot of code and it is in 2 places
process.month = function(rda.path, rda.april, rda.processed, weather.files, april.files, breaks, i){
  
  # Initialize weather.data object
  load(sprintf("%s/%s", rda.path, weather.files[i]))
  
  # Loads the this.state object
  state = substr(weather.files[i], 1, nchar(weather.files[i]) - 6)
  # Add location and location_year fields
  this.state$location_year = sprintf("%s-%s_%s", state, this.state$district, this.state$year)
  this.state$location = sprintf("%s-%s", state, this.state$district)
  all.counties = unique(this.state$location)
  
  most.data = this.state
  
  # Drop data from April 2020 to avoid it getting double counted
  drop.index = most.data$doy > 91 & most.data$year == 2020
  most.data = most.data[!drop.index, ]
  rm(this.state)
  
  ## PROCESS FOR APRIL 2020
  load(sprintf("%s/%s", rda.april, april.files[i]))
  state.april = substr(april.files[i], 1, nchar(april.files[i]) - 12)
  this.state$location_year = sprintf("%s-%s_%s", state.april, this.state$district, this.state$year)
  this.state$location = sprintf("%s-%s", state.april, this.state$district)
  all.counties.april = unique(this.state$location)
  
  if (state != state.april){
    stop(sprintf("%s and %s, what happened?", state, state.april))
  }
  
  # Join April data to Most Data
  most.data = rbind(most.data, this.state)
  
  state.quarterly = rf1:::convert.env.data(most.data, all.counties, breaks) #**# Could save this for faster re-use. How should I do that?

  # Change _2 to APRIL
  colnames(state.quarterly) = gsub("_2", "_APRIL", colnames(state.quarterly))
  
  save(state.quarterly, file = sprintf("%s/%s_gridmet.rda", rda.processed, state))
  return(state.quarterly)
}

identify.fips = function(){
  fips.lookup = wnvdata::fips.lookup
  fips.lookup[grep("Maryland-Baltimore", fips.lookup$location), ] #005 for Baltimore # 510 for Baltimore City
  fips.lookup[grep("Missouri-St. Louis", fips.lookup$location), ] # 189 for St. Louis, #510 for St. Louis City
  fips.lookup[grep("Virginia-Fairfax", fips.lookup$location), ] # 059 for Fairfax # 600 for Fairfax City
  fips.lookup[grep("Virginia-Franklin", fips.lookup$location), ] #067 for Franklin # 620 for Franklin City
  fips.lookup[grep("Virginia-Richmond", fips.lookup$location), ] #159 for Richmond # 760 for Richmond City
  fips.lookup[grep("Virginia-Roanoke", fips.lookup$location), ] #161 for Roanoke # 770 for Roanoke City
}


patch.name = function(this.state, problem.name, county.fips, city.fips){
  problem.id = sprintf("%s_%03d", problem.name, city.fips)
  new.name = sprintf("%s City", problem.name)
  
  this.state$district_fips = sprintf("%s_%03d", this.state$district, this.state$COUNTYFP)
  this.state$district_fips = gsub(problem.id, new.name, this.state$district_fips)
  this.state$district = sapply(this.state$district_fips, splitter, "_", 1, 1)
  return(this.state)
}

# Convert .csv to .rda
# Raw files included for NY to show methods, but due to file size, the rest were omitted from the data-raw folder
convert.to.rda = function(csv.path, rda.path, ending){
  for (my.file in list.files(csv.path)){
    this.file = sprintf("%s/%s", csv.path, my.file)
    this.state = read.csv(this.file)
    
    # if this.file is Maryland, Missouri, or Virginia, correct the county names based on the county fips
    if (my.file == "Maryland24.csv"){
      this.state = patch.name(this.state, "Baltimore", 005, 510)
    }
    if (my.file == "Missouri29.csv"){
      this.state = patch.name(this.state, "St. Louis", 189, 510)
    }
    if (my.file == "Virginia51.csv"){
      this.state = patch.name(this.state, "Fairfax", 059, 600) #059 for Fairfax # 600 for Fairfax City
      this.state = patch.name(this.state, "Franklin", 067, 620) #067 for Franklin # 620 for Franklin City
      this.state = patch.name(this.state, "Richmond", 159, 760) #159 for Richmond # 760 for Richmond City
      this.state = patch.name(this.state, "Roanoke", 161, 770) #161 for Roanoke # 770 for Roanoke City
    }
    # Drop the countyfp field if it is present
    this.state$COUNTYFP = NULL
    
    out.file = sprintf("%s/%s%s.rda", rda.path, substr(my.file, 1, (nchar(my.file) - 4)), ending)
    save(this.state, file = out.file)
  }
  
}

standarize.names = function(in.data){
  # Standardize names to CDC data'
  in.data$location_year = gsub("Illinois-LaSalle", "Illinois-La Salle", in.data$location_year)
  in.data$location_year = gsub("Indiana-DeKalb", "Indiana-De Kalb", in.data$location_year)
  in.data$location_year = gsub("Indiana-LaPorte", "Indiana-La Porte", in.data$location_year)
  in.data$location_year = gsub("Indiana-LaGrange", "Indiana-Lagrange", in.data$location_year)
  in.data$location_year = gsub("Louisiana-LaSalle", "Louisiana-La Salle", in.data$location_year)
  in.data$location_year = gsub("New Mexico-De Baca", "New Mexico-DeBaca", in.data$location_year)
  in.data$location_year = gsub("New Mexico-DoÃ±a Ana", "New Mexico-Dona Ana", in.data$location_year)
  in.data$location_year = gsub("Virginia-Manassas City Park", "Virginia-Manassas Park City", in.data$location_year)
  
  # Update city mismatches
  add.city.vec1 = c("Virginia-Alexandria", "Virginia-Bristol", "Virginia-Buena Vista", "Virginia-Charlottesville", "Virginia-Chesapeake")
  add.city.vec2 = c("Virginia-Colonial Heights", "Virginia-Covington", "Virginia-Danville", "Virginia-Emporia")
  add.city.vec3 = c("Virginia-Falls Church", "Virginia-Fredericksburg", "Virginia-Galax", "Virginia-Hampton")
  add.city.vec4 = c("Virginia-Hopewell", "Virginia-Lexington", "Virginia-Harrisonburg", "Virginia-Lynchburg", "Virginia-Manassas")
  add.city.vec5 = c("Virginia-Norton", "Virginia-Winchester")
  
  add.v.city = c("Newport News", "Manassas Park", "Martinsville", "Norfolk", "Petersburg", "Poquoson")
  add.v.city2 = c("Portsmouth", "Radford", "Salem", "Staunton", "Suffolk", "Virginia Beach", "Waynesboro", "Williamsburg")
  add.v.city.vec = c(add.v.city, add.v.city2)
  add.v.city.vec = sprintf("Virginia-%s", add.v.city.vec)
  
  add.city.vec = c(add.city.vec1, add.city.vec2, add.city.vec3, add.city.vec4, add.city.vec5, add.v.city.vec)
  
  for (city in add.city.vec){
    with.city = sprintf("%s City", city)
    in.data$location_year = gsub(city, with.city, in.data$location_year)
  }
  
  # Fix location based on location-year corrections
  in.data$location = sapply(in.data$location_year, dfmip::splitter, "_", 1, 1)
  
  return(in.data)
}


april.gridmet = function(){
  
  # Convert GRIDMET data to .rda 
  
  # Working directory: "C:\Users\ak697777\University at Albany - SUNY\Elison Timm, Oliver - CCEID\CODE\wnvdata"
  climate.path = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/DATA/CLIMATE"
  gridmet.path = sprintf("%s/GRIDMET", climate.path)
  april.path = sprintf("%s/GRIDMET_MONTHLY/APRIL", climate.path)
  rda.path = sprintf("%s/GRIDMET_RDA", climate.path)
  rda.april = sprintf("%s/APRIL", rda.path)
  rda.processed = sprintf("%s/GRIDMET_RDA_processed", climate.path)
  
  # Convert from .csv format downloaded from Google Earth Engine to .rda format to make it easier to process in R
  # Also patches the 6 county pairs where the county name is the same for two distinct counties
  convert.to.rda(gridmet.path, rda.path, "")
  convert.to.rda(april.path, rda.april, "_april")
    
  # Compile data to be monthly

  # Check that all files match up
  # Pull in weather data from GRIDMET
  weather.files = list.files(rda.path)
  weather.files = weather.files[weather.files != "APRIL"]
  weather.files = weather.files[weather.files != "QUARTER1"]
  weather.files = weather.files[weather.files != "APRIL_processed"]
  april.files = list.files(rda.april)
  breaks = c(90, 120) # Specify Before April and April.

  err.vec = c()
  is.error = 0
  for (i in 1:length(weather.files)){
    weather.file = weather.files[i]
    
    state = substr(weather.files[i], 1, nchar(weather.files[i]) - 6)
    state.april = substr(april.files[i], 1, nchar(april.files[i]) - 12)
    
    if (state != state.april){
      err.vec = c(err.vec, state, state.april)
      is.error = 1
    }
  }
  if (is.error == 1){
    stop(sprintf("States do not match up. Problem state pairs are %s", paste(err.vec, collapse = ", ")))
  }
    
  ## PROCESS FOR 2000 - 2019 data  
  state.quarterly = process.month(rda.path, rda.april, rda.processed, weather.files, april.files, breaks, 1)
  # Intialize data frames for entire US
  us.quarterly = state.quarterly
  
  # merge in remaining weather files
  for (i in 2:length(weather.files)){
    state.quarterly = process.month(rda.path, rda.april, rda.processed, weather.files, april.files, breaks, i)
    us.quarterly = rbind(us.quarterly, state.quarterly)
  }
  
  us.quarterly = standarize.names(us.quarterly)
  
  # Test merge with CDC data
  cdc.path = "C:/hri_no_backup/WNV_CHALLENGE"
  cdc.file = sprintf("%s/neurownv_by_county_2000-2018_full_working_copy.csv", cdc.path)
  cdc.raw = read.csv(cdc.file)
  cdc.2019 = read.csv(sprintf("%s/wnv_by_county_2019_provisional_full.csv", cdc.path))
  colnames(cdc.2019)[1] = "fips"
  
  cdc.raw$fips = as.character(cdc.raw$fips)
  cdc.raw$county = as.character(cdc.raw$county)
  cdc.raw$state = as.character(cdc.raw$state)
  cdc.raw$location = as.character(cdc.raw$location)
  cdc.raw$year = as.numeric(as.character(cdc.raw$year))
  cdc.raw$count = as.numeric(as.character(cdc.raw$count))
  cdc.raw$location_year = sprintf("%s_%s", cdc.raw$location, cdc.raw$year)
  cdc.raw$location = gsub("South Dakota-Oglala Lakota/Shannon", "South Dakota-Oglala Lakota", cdc.raw$location)
  cdc.raw$location = gsub("Virginia-Bedford/Bedford City", "Virginia-Bedford", cdc.raw$location)
  cdc.raw$location_year = gsub("South Dakota-Oglala Lakota/Shannon", "South Dakota-Oglala Lakota", cdc.raw$location_year)
  cdc.raw$location_year = gsub("Virginia-Bedford/Bedford City", "Virginia-Bedford", cdc.raw$location_year)
  
  nrow(cdc.raw) #59052 
  
  # Test merge for the main CDC data
  us.quarterly.subset = us.quarterly[us.quarterly$year < 2019, ]
  us.quarterly.subset = us.quarterly.subset[us.quarterly.subset$year > 1999, ]
  nrow(us.quarterly.subset) # 59052
  test = merge(cdc.raw, us.quarterly, by = "location_year")
  nrow(test) #59033 missing 19 rows #58995. Lost 57 rows!
  
  missing.vec = c()
  for (i in 1:nrow(us.quarterly.subset)){
    this.locyear = us.quarterly.subset$location_year[i]
    test = grep(this.locyear, cdc.raw$location_year)
    
    #if (!this.locyear %in% cdc.raw$location_year){
    if (length(test) == 0){
      missing.vec = c(missing.vec, this.locyear)
    }
  }
  
  # This line was in standardize.names, not sure why it did not work there. Running it a second time here solved the issue.
  us.quarterly$location_year = gsub("Virginia-Manassas City Park", "Virginia-Manassas Park City", us.quarterly$location_year)
  us.quarterly$location = gsub("Virginia-Manassas City Park", "Virginia-Manassas Park City", us.quarterly$location)
  test = merge(cdc.raw, us.quarterly, by = "location_year")
  nrow(test) #59052
  
  
  usethis::use_data(us.quarterly, overwrite = TRUE)
  
}
  