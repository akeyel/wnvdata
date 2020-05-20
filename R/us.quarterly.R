us.quarterly = function(){
  
  # Convert GRIDMET data to .rda 
  
  gridmet.path = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/DATA/CLIMATE/GRIDMET"
  rda.path = sprintf("%s/../GRIDMET_RDA", gridmet.path)
  # Working directory: "C:\Users\ak697777\University at Albany - SUNY\Elison Timm, Oliver - CCEID\CODE\wnv_data"
  
  # Quarterly US .rda files was copied manually into the wnv_data/data folder 
  # Convert from .csv format downloaded from Google Earth Engine to .rda format to make it easier to process in R
  
  # Raw files included for NY to show methods, but due to file size, the rest were omitted from the data-raw folder
  
  for (my.file in list.files(gridmet.path)){
    this.file = sprintf("%s/%s", gridmet.path, my.file)
    this.state = read.csv(this.file)
    out.file = sprintf("%s/%s.rda", rda.path, substr(my.file, 1, (nchar(my.file) - 4)))
    save(this.state, file = out.file)
  }
  
  # Compile data sets to be quarterly, as needed by the RF1 model
  library(rf1)
  
  # Set up inputs
  weekinquestion = "2020-04-05" # Create quarterly data for first quarter only, to avoid an error for 2020 (could create a quarterly file for the rest of the years, though)
  week.id = "USA" #**# This should be called analysis.id
  
  # Pull in weather data from GRIDMET
  weather.path = sprintf("%s/../data/climate/gridmet_rda", base.path)
  weather.files = list.files(weather.path)
  # Initialize weather.data object
  load(sprintf("%s/%s", weather.path, weather.files[1]))
  
  # Loads the this.state object
  state = substr(weather.files[1], 1, nchar(weather.files[1]) - 6)
  all.counties = unique(this.state$district)
  break.type = 'seasonal'
  breaks = rf1:::assign.breaks(weekinquestion, break.type)
  state.quarterly = rf1:::convert.env.data(this.state, all.counties, breaks) #**# Could save this for faster re-use. How should I do that?
  
  # Add location and location_year fields
  state.quarterly$location_year = sprintf("%s-%s", state, state.quarterly$county_year)
  state.quarterly$location = sprintf("%s-%s", state, state.quarterly$district)
  #**# Location is in all CAPS, as is district. This will cause problems on join
  save(state.quarterly, file = sprintf("%s/%s_quarter1_gridmet.rda", weather.path, state))
  
  # Intialize data frame for entire US
  us.quarterly = state.quarterly
  
  # merge in remaining weather files
  for (i in 2:length(weather.files)){ #
    my.file = weather.files[i]
    #this.state = read.csv(sprintf("%s/%s", weather.path, my.file))
    load(sprintf("%s/%s", weather.path, my.file)) # Loads this.state object
    all.counties = unique(this.state$district)
    state = substr(my.file, 1, nchar(my.file) - 6)
    state.quarterly = rf1:::convert.env.data(this.state, all.counties, breaks) #**# Could save this for faster re-use. How should I do that?
    
    # Add location and location_year fields
    state.quarterly$location_year = sprintf("%s-%s", state, state.quarterly$county_year)
    state.quarterly$location = sprintf("%s-%s", state, state.quarterly$district)
    save(state.quarterly, file = sprintf("%s/%s_quarter1_gridmet.rda", weather.path, state))
    
    us.quarterly = rbind(us.quarterly, state.quarterly)
  }
  
  # There was a problem for six counties that had City as part of the end. It is unclear to me if I introduced the error in the processing below
  # or if it was introduced during the extraction process. I decided it was faster to use nearby county data than track down the error.
  #values were substituted from nearby counties:
  # Baltimore City uses data from Baltimore County, Fairfax City uses data from Fairfax County, Roanoke City uses
  # data from Roanoke County, St. Louis City uses data from St. Louis County, Franklin City uses data from Southampton County,
  # and Richmond City uses data from Henrico County.
  
  #**# Might want to just fix the typos in the state names directly, although it looks like some were truncated, rather than typos.
  
  # Correct errors in us.quarterly and standardize names to Census data'
  us.quarterly$location_year = gsub("Coloado", "Colorado", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Connectic", "Connecticut", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Michican", "Michigan", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Massachussets", "Massachusetts", us.quarterly$location_year)
  us.quarterly$location_year = gsub("District of Columb-", "District of Columbia-", us.quarterly$location_year)
  grep("Massach", us.quarterly$location, value = 1)
  us.quarterly$location_year = gsub("Illinois-LaSalle", "Illinois-La Salle", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Indiana-DeKalb", "Indiana-De Kalb", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Indiana-LaPorte", "Indiana-La Porte", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Indiana-LaGrange", "Indiana-Lagrange", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Louisiana-LaSalle", "Louisiana-La Salle", us.quarterly$location_year)
  us.quarterly$location_year = gsub("New Mexico-De Baca", "New Mexico-DeBaca", us.quarterly$location_year)
  us.quarterly$location_year = gsub("New Mexico-DoÃ±a Ana", "New Mexico-Dona Ana", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Missouri-St. Louis City", "Missouri-St. Louis", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Virginia-Manassas City Park", "Virginia-Manassas Park City", us.quarterly$location_year)
  us.quarterly$location_year = gsub("Virginia-Norton", "Virginia-Norton City", us.quarterly$location_year) # Not fixed below because there was a typo the first time through
  us.quarterly$location_year = gsub("Virginia-Winchester", "Virginia-Winchester City", us.quarterly$location_year) # Apparently missed below
  
  # Update city mismatches
  add.city.vec1 = c("Virginia-Alexandria", "Virginia-Bristol", "Virginia-Buena Vista", "Virginia-Charlottesville", "Virginia-Chesapeake")
  add.city.vec2 = c("Virginia-Colonial Heights", "Virginia-Covington", "Virginia-Danville", "Virginia-Emporia", "Virginia-Fairfax")
  add.city.vec3 = c("Virginia-Falls Church", "Virginia-Fredericksburg", "Virginia-Galax", "Virginia-Hampton")
  add.city.vec4 = c("Virginia-Hopewell", "Virginia-Lexington", "Virginia-Harrisonburg", "Virginia-Lynchburg", "Virginia-Manassas")
  add.city.vec5 = c("Maryland-Baltimore", "Missouri-St. Louis")
  
  # "Virginia-Franklin", should not have added 'City' to this one - NOT THE SAME AREA
  # Ditto for: "Virginia-Richmond"
  
  add.v.city = c("Newport News", "Manassas Park", "Martinsville", "Norfolk", "Petersburg", "Poquoson")
  add.v.city2 = c("Portsmouth", "Radford", "Roanoke", "Salem", "Staunton", "Suffolk", "Virginia Beach", "Waynesboro", "Williamsburg")
  add.v.city.vec = c(add.v.city, add.v.city2)
  add.v.city.vec = sprintf("Virginia-%s", add.v.city.vec)
  
  add.city.vec = c(add.city.vec1, add.city.vec2, add.city.vec3, add.city.vec4, add.city.vec5, add.v.city.vec)
  
  for (city in add.city.vec){
    with.city = sprintf("%s City", city)
    us.quarterly$location_year = gsub(city, with.city, us.quarterly$location_year)
  }
  
  # Fix counties that legitimately have city in their name and overlap with a county
  us.quarterly$location = sapply(us.quarterly$location_year, dfmip::splitter, "_", 1, 1)
  
  grep("Maryland-Baltimore", us.quarterly$location, value = 1) # Currently renamed Baltimore City, but was from County originally - make the 2 match
  
  patch.county = function(us.quarterly, current.name, copy.name){
    
    # If copy.name is already present, do not re-run
    test = us.quarterly[us.quarterly$location == copy.name, ]
    if (nrow(test) > 0){
      stop(sprintf("%s is already in the data set, and adding it a second time will cause corruption", copy.name))
    }
    
    patch = us.quarterly[us.quarterly$location == current.name, ]  
    patch$location = gsub(current.name, copy.name, patch$location)
    patch$location_year = gsub(current.name, copy.name, patch$location_year)
    us.quarterly = rbind(us.quarterly, patch)
    
    return(us.quarterly)
  }
  
  us.quarterly.test = patch.county(us.quarterly, "Maryland-Baltimore City", "Maryland-Baltimore") # 68244 rows before trying, 68266 after
  us.quarterly.test = patch.county(us.quarterly.test, "Maryland-Baltimore City", "Maryland-Baltimore") # Errors when run a second time
  
  us.quarterly.test[grep("Maryland-Baltimore", us.quarterly.test$location), ] # Currently renamed Baltimore City, but was from County originally - make the 2 match
  # Worked, now can actually apply it
  
  us.quarterly = patch.county(us.quarterly, "Maryland-Baltimore City", "Maryland-Baltimore")
  us.quarterly = patch.county(us.quarterly, "Virginia-Fairfax City", "Virginia-Fairfax")
  us.quarterly = patch.county(us.quarterly, "Virginia-Roanoke City", "Virginia-Roanoke")
  us.quarterly = patch.county(us.quarterly, "Missouri-St. Louis", "Missouri-St. Louis City")
  
  
  us.quarterly$location_year = gsub("Virginia-Franklin City", "Virginia-Franklin", us.quarterly$location_year) # Revert to original name - this was 'corrected' above, but was an error
  us.quarterly$location = gsub("Virginia-Franklin City", "Virginia-Franklin", us.quarterly$location) # Revert to original name - this was 'corrected' above, but was an error
  us.quarterly = patch.county(us.quarterly, "Virginia-Southampton", "Virginia-Franklin City") # Franklin City is not in Franklin County, nearest county is Southhampton.
  
  us.quarterly$location_year = gsub("Virginia-Richmond City", "Virginia-Richmond", us.quarterly$location_year) # Revert to original name - this was 'corrected' above, but was an error
  us.quarterly$location = gsub("Virginia-Richmond City", "Virginia-Richmond", us.quarterly$location) # Revert to original name - this was 'corrected' above, but was an error
  us.quarterly = patch.county(us.quarterly, "Virginia-Henrico", "Virginia-Richmond City") #  Nearest county is Henrico.
  
  #save(us.quarterly, file = sprintf("%s/us_quarter1_gridmet.rda", weather.path))
  # manally renamed us.quarterly in the wnv_data/data copy
  
  usethis::use_data(us.quarterly, overwrite = TRUE)
  
  
  # Code used to identify missing counties relative to the CDC data:
  # # Line of code for checking counties
  # #grep("Maryland-Baltimore", analysis.counties, value = 1) # There should be 2, but only one in the GRIDMET data set
  # 
  # # Identify missing and mismatched counties
  # devtools::load_all(sprintf("%s/CODE/wnv_data", base.path))
  # us.quarterly = wnvdata::us.quarterly # Had not re-defined us.quarterly!
  # missing.vec = c()
  # for (location in analysis.counties){
  #   is.missing = 0
  #   #if (!location %in% unique(mosq.ranges$location)){
  #   #  message(sprintf("%s is missing for mosq.ranges", location))
  #   #}
  #   if (!location %in% unique(us.quarterly$location)){
  #     #message(sprintf("%s is missing for us.quarterly", location))
  #     is.missing = 1
  #   }
  #   #if (!location %in% unique(ac.data$location)){
  #   #  #message(sprintf("%s is missing for ac.data", location))
  #   #  is.missing = 1
  #   #}
  #   #if (!location %in% unique(census.data$location)){
  #   #  #message(sprintf("%s is missing for census.data", location))
  #   #  is.missing = 1
  #   #}
  #   if (is.missing == 1){
  #     missing.vec = c(missing.vec, location)
  #   }
  # }
  # length(missing.vec) # All should be fixed
  # 
  
  # 
  # grep("Alabama", mosq.ranges$location, value = 1)
  
}
