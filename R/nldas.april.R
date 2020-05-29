# Process downloaded NLDAS data into a form that can be used for predicting WNV in the US
#library(ncdf4) # need to re-enable this line. Not adding as a package dependency, because this is primarily for documentation.


create.grid.lookup = function(){
  
  #centroid_file = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/DATA/GIS/Civil/CENSUS/tl_2017_us_county_LOWER_48_centroid_mod.shp"
  centroid_file = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/DATA/GIS/NLDAS/Census_albers.shp" # Had to project it for the distance calculations
  nc.file = "C:/hri/Data/NLDAS_2015_2020/DATA/NLDAS_NOAH0125_M.A201601.002.grb.SUB.nc4" # All should be on the same grid, so one file is sufficient

  grid.file = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/CODE/wnvdata/data-raw/nldas_latlon.csv"
  make.grid.index(centroid_file, nc.file, grid.file, lon.name = "LON", lat.name = "LAT")
  
 
  nldas.centroid.lookup = read.csv("C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/CODE/wnvdata/data-raw/nldas.centroid.lookup.csv")
  # REmove junk columns
  nldas.centroid.lookup2 = nldas.centroid.lookup[ , c(4,5, 22,23,24,25,26)]
  nldas.centroid.lookup2$FIPS = sprintf("%02d%03d", nldas.centroid.lookup2$STATEFP, nldas.centroid.lookup2$COUNTYFP)
  
  fips.lookup = wnvdata::fips.lookup
  fips.lookup$FIPS = sprintf("%05d", as.numeric(as.character(fips.lookup$fips))) # Add leading 0's for merge
  nldas.centroid.lookup3 = merge(nldas.centroid.lookup2, fips.lookup, by = 'FIPS')
  
  # Remove junk columns and put in desired order
  nldas.centroid.lookup = data.frame(nldas.centroid.lookup3$location, nldas.centroid.lookup3$LON,
                                nldas.centroid.lookup3$LAT, nldas.centroid.lookup3$ROW_ID,
                                nldas.centroid.lookup3$COL_ID, nldas.centroid.lookup3$fips, nldas.centroid.lookup3$MOD)
  colnames(nldas.centroid.lookup) = c("location", "LON", "LAT", "ROW_ID", "COL_ID", "FIPS", "MOD") 

  usethis::use_data(nldas.centroid.lookup, overwrite = TRUE)
}
  

#' Create grid lookup
#' 
#' Modified from wnv_WRF_hlpr.R (not in repository)
#' Not all netcdfs use the same format, some adjustments may be necessary for other files
#' 
#' @noRd
#' 
make.grid.index = function(centroid_file, nc.file, grid.file, lon.name = "lon", lat.name = "lat"){
  
  # Read in WRF control run
  nc1 = ncdf4::nc_open(nc.file)
  
  lon = ncdf4::ncvar_get(nc1,lon.name)
  lat = ncdf4::ncvar_get(nc1,lat.name)
  
  nc_close(nc1)
  
  # Put lat, lon, and grid ID into a data frame for ArcGIS
  # Grid numbers should go from top to bottom, by columns. Watch for alignment issues.
  #n.points = nrow(lon) * ncol(lon)
  #col.id = sort(rep(seq(1,ncol(lon)),nrow(lon)))
  #row.id = rep(seq(1,nrow(lon)),ncol(lon))
  n.points = nrow(lon) * nrow(lat)
  col.id = sort(rep(seq(1,nrow(lon)),nrow(lat)))
  row.id = rep(seq(1,nrow(lat)),nrow(lon))
  LON = sort(rep(lon, nrow(lat)))
  LAT = rep(lat, nrow(lon))
  #my.df = data.frame(LON = matrix(lon, ncol = 1), LAT = matrix(lat, ncol = 1), ROW_ID = row.id, COL_ID = col.id)
  my.df = data.frame(LON = LON, LAT = LAT, ROW_ID = row.id, COL_ID = col.id)
  
  write.table(my.df, sep = ',', col.names = TRUE, row.names = FALSE, append = FALSE,
              file = grid.file)
  
  # Output a message describing the ArcGIS processing that needs to be done  
  m1 = sprintf("Please add data file %s to ArcGIS.\n", grid.file)
  m2 = "Use the display XY data option to geocode the data\n"
  m3 = sprintf("Then use a spatial join to join to the centroid file: %s", centroid_file)
  stop(sprintf("%s%s%s", m1, m2, m3)) #**# Needs to halt code - the user needs to take steps in ArcGIS
  
  
  # For spatial join:  Match option: Closest. Both were in WGS 1984 / NAD 83 (same datum in North America) #**# Didn't work
  # Everything convereted to NAD_1983_Contiguous_USA_Albers projection
}

#' Aggregate matrix
#' 
#' Function to give options for raster aggregation. Modified from wnv_hlpr.R (not in repository)
#' 
#' @noRd
#' 
aggregate.matrix = function(raster.matrix, day.data, aggregation.type, day.count = NA){

  # CUMULATIVE MIGHT BE APPROPRIATE FOR PPT.
  if (aggregation.type == "sum" | aggregation.type == "cumulative"){
    raster.matrix = raster.matrix + day.data
  }
  
  # Growing degree days most likely the most relevant for temperature  
  if (aggregation.type == "GDD.10"){
    #apply.threshold = function(x, threshold, direction)
    day.data.mod = apply(day.data, c(1,2), apply.threshold, 10, "positive")
    raster.matrix = raster.matrix + day.data.mod
  }
  
  # Min temperature for winter #**# Do we want the absolute min or the mean min?
  #**# does it matter? Might. May want to go with absolute min, which would be a composite of trange_mean
  #**# Start with mean min because it is easy and likely correlated with absolute min
  if (aggregation.type == "min"){
    #**# need to compare day data to raster.matrix for each cell and take the minimum
    #**# Seems like something the plyr package might be good for? No, just use apply!
    #**# uh oh - 0's can't be used to initialize raster.matrix for this
    
    # Convert matrices to vectors
    n.row = nrow(day.data) # Get number of rows for restoring the matrices
    day.vec = matrix(day.data, nrow = 1)
    rast.vec = matrix(raster.matrix, nrow = 1)
    min.vec = mapply("min", day.vec, rast.vec, MoreArgs = list(na.rm = TRUE))
    
    # Convert raster.matrix back to a matrix (this should preserve column order!)
    raster.matrix = matrix(min.vec, nrow = n.row)
  }
  
  if (aggregation.type == "max"){
    n.row = nrow(day.data)
    day.vec = matrix(day.data, nrow = 1)
    rast.vec = matrix(raster.matrix, nrow = 1)
    max.vec = mapply("max", day.vec, rast.vec, MoreArgs = list(na.rm = TRUE))
    
    raster.matrix = matrix(max.vec, nrow = n.row)
  }
  
  # Calculate a mean (used for the mean minimum and mean maximum temperatures)
  if (aggregation.type == "mean"){
    
    # Check if entire raster.matrix is NA. If so, replace with day.data if day.count is 1. Otherwise, throw an error
    rast.vec = matrix(raster.matrix, nrow = 1)
    if (sum(!is.na(rast.vec)) == 0){
      if (day.count == 1){ raster.matrix = day.data  }
      if (day.count != 1){ stop("Something went wrong with computing a mean value: all NA values for the raster matrix")}
    }else{
      # Compute a mean as a weighted average
      raster.matrix = (raster.matrix * (day.count - 1) + day.data) / day.count
    }
  }
  
  #**# Script out other aggregation types as appropriate
  
  return(raster.matrix)
}



daily.to.monthly = function(this.data){
  days = length(this.data[1,1, ]) # third column is the days column. the row and column selection is arbitrary, as number of days will not vary as these change
  raster.matrix = matrix(0, nrow = nrow(this.data), ncol = ncol(this.data))
  day.count.matrix = matrix(0, nrow = nrow(this.data), ncol = ncol(this.data))
  
  for (day in 1:days){
    day.data = this.data[,,day]
    raster.matrix = aggregate.matrix(raster.matrix, day.data, "sum")
    day.count.matrix = day.count.matrix + 1 # increment the day.count.matrix
  }
  
  raster.matrix = raster.matrix / day.count.matrix # Get an average based on the number of days in the monthly aggregation

  return(raster.matrix)      
}

    

#' Extract the netcdf data into R
#' 
#' Modified from wnv_hlpr.R (not in repository)
#' 
#' @noRd
#' 
get.nc.data = function(nc.file, ncvarname){
  nc1 = nc_open(nc.file)
  
  lon = ncvar_get(nc1,"lon")
  lat = ncvar_get(nc1,"lat")
  data1 = ncvar_get(nc1, ncvarname)
  
  # Check that the grid is as expected
  if (length(lon) != 464){
    stop("Longitude is based on a different grid. Please adjust extraction accordingly")
  }
  if (length(lat) != 224){
    stop("Latitude is based on a different grid than the one used initially. Please adjust the extraction procedure accordingly")
  }
  
  nc_close(nc1) # Close the file
  
  return(data1)
}

extract.netcdf = function(nc.file, centroid.lookup, ncvarname, year, month,
                          old.data = 0){
  daily = FALSE
  scale.factor = 1
  if (old.data == 1){
    scale.factor = 0.1
    daily = TRUE
  }
  
  all.data = get.nc.data(nc.file, ncvarname)
  
  month.data = data.frame(location = NA, location_year = NA, year = NA, month = NA, value = NA)
  
  # If there are daily values, they must be converted to a monthly mean before proceeding
  if (daily == TRUE){
    all.data = daily.to.monthly(all.data)
  }
  centroid.lookup$location = as.character(centroid.lookup$location)
  locations = as.character(centroid.lookup$location)
  for (i in 1:length(locations)){
    # Extract values for each county from the netcdf and add to a data frame
    this.location.record = centroid.lookup[i, ]
    this.location = centroid.lookup$location[i]
    this.location.year = sprintf("%s_%s", this.location, year)
    this.row = this.location.record$ROW_ID
    this.col = this.location.record$COL_ID
    
    if (old.data == 0){
      this.value = all.data[this.col, this.row, 1] # NEEDS TO BE ADJUSTED for each differently formatted netcdf.
    }else{
      this.value = all.data[this.col, this.row] # NEEDS TO BE ADJUSTED for each differently formatted netcdf.
      this.value = this.value * scale.factor
    }
    
    this.record = c(this.location, this.location.year, year, month, this.value)
    month.data = rbind(month.data, this.record)
  }
 
  # Remove first NA row
  month.data = month.data[2:nrow(month.data), ]
   
  return(month.data)  
}


process.nldas = function(){
  # Set up data paths
  first.path = "C:/hri/Data/NLDAS_1999_2015"
  second.path = "C:/hri/Data/NLDAS_2015_2020/DATA"
  
  # Read in Lookup grid of county centroids
  centroid.lookup = wnvdata::nldas.centroid.lookup
  ncvarname = "SOILM"
  
  # Create a data frame to hold the results
  nldas.SOILM = data.frame(location = NA, location_year = NA, year = NA, month = NA, value = NA)
  
  # Loop through years
  analysis.years = seq(1999, 2020)
  for (year in analysis.years){
  
    message(year)
  # Loop through months
    for (month in seq(1,12)){
      do.not.run = 0
      
      # Read in netcdf
      
      #Use first path for data before 2015
      if (year < 2015){
        nc.file = sprintf("%s/SOILM_0_200_cm_%s%02d.nc", first.path, year, month)
        month.data = extract.netcdf(nc.file, centroid.lookup, ncvarname, year, month, old.data = 1)
      }
      
      # Use second data path for data after 2015
      if (year > 2015){

        if (year == 2020 & month > 4){  do.not.run = 1  }
        
        # Only run if it is before May 2020
        if (do.not.run == 0){
          nc.file = sprintf("%s/NLDAS_NOAH0125_M.A%s%02d.002.grb.SUB.nc4", second.path, year, month)
          month.data = extract.netcdf(nc.file, centroid.lookup, ncvarname, year, month)
        }
      }      
      
      # Use both data paths for data in 2015
      if (year == 2015){
        
        nc.file1 = sprintf("%s/SOILM_0_200_cm_%s%02d.nc", first.path, year, month)
        nc.file2 = sprintf("%s/NLDAS_NOAH0125_M.A%s%02d.002.grb.SUB.nc4", second.path, year, month)
        month.data = extract.netcdf(nc.file1, centroid.lookup, ncvarname, year, month, old.data = 1)
        month.data2 = extract.netcdf(nc.file2, centroid.lookup, ncvarname, year, month)

        month.data$value = as.numeric(as.character(month.data$value))
        month.data2$value = as.numeric(as.character(month.data2$value))
                
        # Check that data from Park Williams is matching the recently downloaded data
        # i.e. that we are comparing the same quantities

        count = 0
        na.vec = c()
        unmatch.vec = c()
        for (i in 1:nrow(month.data)){
          
          #test1 = round(month.data$value[i],0)
          #test2 = round(month.data2$value[i], 0)
          test1 = month.data$value[i]
          test2 = month.data2$value[i]
          
          if (is.na(test1) | is.na(test2)){
            message(sprintf("i = %s, name = %s, value1 = %s, value2= %s", i, month.data$location_year[i], round(month.data$value[i],2), round(month.data2$value[i], 2)))
            na.vec = c(na.vec, month.data$location[i])
            count = count + 1
          }else{
            if (abs(test1 - test2) > 0.5){
              message(sprintf("i = %s, name = %s, value1 = %s, value2= %s", i, month.data$location_year[i], round(month.data$value[i],2), round(month.data2$value[i], 2)))
              unmatch.vec = c(unmatch.vec, month.data$location[i])
              count = count + 1
            }
          }
        }
         
        if (length(na.vec) > 0 | length(unmatch.vec > 0)){
          stop(sprintf("Data sets are not matching for %s %s", month, year))
        } 
      }

      # Update data frame (if data were processed for this month)
      if(do.not.run == 0){
        nldas.SOILM = rbind(nldas.SOILM, month.data)
      }
    }
  }
  
  nldas.SOILM = nldas.SOILM[2:nrow(nldas.SOILM), ]
  nldas.april = nldas.SOILM[nldas.SOILM$month == 4, ]
  colnames(nldas.april)[5] = "SOILM_APRIL"
  
  # Convert values to numeric
  nldas.april$SOILM_APRIL = as.numeric(as.character(nldas.april$SOILM_APRIL))
  nldas.SOILM$value = as.numeric(as.character(nldas.SOILM$value))
  
  # Add anomalies
  analysis.counties = unique(nldas.SOILM$location)
  vars1 = c("value")
  nldas.SOILM = add.anomaly(nldas.SOILM, vars1, analysis.counties)
  
  # Add anomalies
  analysis.counties = unique(nldas.april$location)
  vars2 = c("SOILM_APRIL")
  nldas.april = add.anomaly(nldas.april, vars2, analysis.counties)
  
  # Output NLDAS data
  usethis::use_data(nldas.SOILM, overwrite = TRUE)
  usethis::use_data(nldas.april, overwrite = TRUE)
  
}
  