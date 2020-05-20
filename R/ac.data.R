# Wrapped in a function to prevent running on package build
ac.data = function(){
  #### AC DATA ####
  # Create a .rda for Air Conditioning regions (didn't I dismiss this earlier due to insufficient variation?
  # Except was the scope national at that point? For the forecast it will be national, and so this could help
  # However, it might be confounded with region - hard to assign to A/C use.
  # Load Data file
  ac.data.raw = read.csv("data-raw/EIA_climate_zones.csv")
  fips.lookup = wnvdata::fips.lookup
  
  # Clean up column names
  ac.data = cbind(as.character(ac.data.raw$NAME), ac.data.raw$STATE_NAME, as.character(ac.data.raw$FIPS), as.character(ac.data.raw$BA_Climate))
  colnames(ac.data) = c("County", "State", "fips", "Climate_Region")
  
  ac.data.2 = merge(ac.data, fips.lookup, by = "fips", all.y = TRUE) # Make sure there is a record for every county (except one - one is missing)
  
  # Check merge worked
  test2 = ac.data.2[is.na(ac.data.2$Climate_Region) , ] # nrow = 1, which is expected - Oglala Lakota is missing from the EIS data set
  target.row = as.numeric(rownames(test2))
  # Fix Oglala Lakota to have the appropriate value
  ac.data.2$Climate_Region[target.row] = "Cold"
  ac.data.2$County = as.character(ac.data.2$County)
  ac.data.2$State = as.character(ac.data.2$State)
  ac.data.2$County[target.row] = "Oglala Lakota"
  ac.data.2$State[target.row] = "South Dakota"
  
  # Assign regions based on the Energy survey's classification
  old.regions = c("Mixed-Humid", "Hot-Humid", "Cold", "Very Cold", "Hot-Dry", "Mixed-Dry", "Marine")
  new.regions = c("Mixed-Humid", "Hot-Humid", "Cold_VeryCold", "Cold_VeryCold", "MixedDry_HotDry", "MixedDry_HotDry", "Marine")
  region.lookup = data.frame(Climate_Region = old.regions, region = new.regions)
  ac.data.3 = merge(ac.data.2, region.lookup, by = "Climate_Region")
  
  test3 = ac.data.3[is.na(ac.data.3$region), ] #nrow(test3) = 0
  
  # Join to A/C use
  #regions = unique(new.regions)
  ## Check that nothing has changed, check.regions were copy-pasted from regions printed to the console
  #check.regions = c("Mixed-Humid", "Hot-Humid", "Cold_VeryCold", "MixedDry_HotDry", "Marine" )
  #if (paste(regions, collapse = "") != paste(check.regions, collapse = "")){
  #  stop("Regions have changed, something needs to be done differntly for merging in A/C data")
  #}
  #AC.values = 
  #ac.lookup = data.frame(region = regions, AC = AC.values)
  ac.lookup = read.csv(sprintf("%swnv_data_dev/ac_by_region_average.csv", base.path))
  ac.data.4 = merge(ac.data.3, ac.lookup, by = "region")
  
  #test merge
  test4 = ac.data.4[is.na(ac.data.4$AC_avg), ] # nrow(test4) = 0 # Good.
  
  # Drop unused columns
  ac.data.4$Climate_Region = NULL
  ac.data.4$State = NULL
  ac.data.4$state.fips = NULL
  ac.data.4$county = NULL
  ac.data.4$County = NULL
  
  # Overwrite once data set is finalized
  ac.data = ac.data.4
  
  # Save as data
  usethis::use_data(ac.data)
  
}


