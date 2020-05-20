# Wrap in function to prevent automatic running
mosq.ranges = function(){
  
  #### MOSQUITO RANGES ####
  
  # Bring in mosquito data and save as .rda after cleanup
  mosquito.ranges = read.csv(sprintf("%swnv_data_dev/Mosquito_Ranges.csv", base.path))
  
  # Drop FID
  mosquito.ranges$FID = NULL
  mosquito.ranges$COUNTYNS = NULL
  mosquito.ranges$GEOID = NULL
  mosquito.ranges$NAMELSAD = NULL
  colnames(mosquito.ranges) = c("state_fips", "county_fips", "County", "Cx.pip", "Cx.tar", "Cx.qnq", "Cx.sal", "Cx.nig")
  mosquito.ranges$fips = sprintf("%02d%03d", mosquito.ranges$state_fips, mosquito.ranges$county_fips)
  
  # Test-merge with CDC data
  test5 = merge(cdc.raw, mosquito.ranges, by = "fips", all.x = TRUE)
  test5 = test5[is.na(test5$Cx.pip), ]  # 0 errors
  
  # Merge in locations field for random forest model merges
  fips.lookup$fips = sprintf("%05d", as.numeric(as.character(fips.lookup$fips)))
  mosquito.ranges.2 = merge(mosquito.ranges, fips.lookup, by = "fips")
  mosquito.ranges.2$state_fips = NULL # Make it so only one remains
  mosquito.ranges.2$County = NULL # remove the non-compliant county field
  mosquito.ranges.2$county = NULL # redundant with location field
  
  mosquito.ranges = mosquito.ranges.2 # Replace the original object once all changes have been looked over (want a simple name)
  # Save as data
  usethis::use_data(mosquito.ranges, overwrite = TRUE)
  

}
