#' Census Data by year
#'
#' Census data came from US Census Bureau Population Estimation Program accessed using
#' library(censusapi) (requires api key in .Renviron ... or maybe not if doing less than 500 calls per day)
#' listCensusMetadata("pep/int_population", type = "variables", vintage = 2000)
#' listCensusMetadata("pep/int_population", type = "geography", vintage = 2000)
#' listCensusMetadata("pep/population", type = "variables", vintage = 2019)
#' The variables do change somewhat because they change between “vintages” of the data.
#' There might be a better way to pull that together.
#' Each dataset only covers a decade, so to get longer periods you have to stich them together.
#' 
#' See census.data.R for details on processing from data set received from Drew Tyre described above.
#' 
#' @docType data
#'
#' @source US Census Bureau Population Estimation Program
#'
"census.data"


#' Air Conditioning data from EIA survey
#'
#' Air conditioning data were taken from the Residential Energy Consumption Survey (RECS) from the U.S. Energy Information Administration
#' Data averaged from 2009 and 2015. Data were also available for 2001 and 2005, but used a different climate region system
#' Data were joined spatially based on a Climate region shapefile (see below).
#' 
#' See ac.data.R for details on data processing from EIA_climate_zones.csv, which was exported from ArcGIS.
#' Averages were computed in MS Excel.
#' 
#' The data layer used for spatial information was from the Building America website:
#' https://www.arcgis.com/home/item.html?id=8e5c3c6e1fa94e379553e199dcc4e777#overview
#' Details on the climate zone methods are here: https://www.energy.gov/sites/prod/files/2015/10/f27/ba_climate_region_guide_7.3.pdf
#' Climate Zones also appear to be available here: https://www.eia.gov/maps/layer_info-m.php
#' @docType data
#'
#' @source \url{https://www.eia.gov/consumption/residential/data/2015/}, 
#' \url{https://www.arcgis.com/home/item.html?id=8e5c3c6e1fa94e379553e199dcc4e777#overview}
#'
"ac.data"

#' FIPS Lookup Table
#' 
#' FIPS codes and CDC locations to facilitate merging data sets by either FIPS or by location
#' FIPS Lookup was derived from:
#' https://www.census.gov/geographies/reference-files/2017/demo/popest/2017-fips.html
#' Link: 2017 State, County, Minor Civil Division, and Incorporated Place FIPS Codes
#' file: all-geocodes-v2017.xlsx
#' Changes were made manually in Excel in order to condense to four columns ready to use for
#' the CDC forecast challenge.
#' "South Dakota-Oglala Lakota/Shannon" was replaced with "South Dakota-Oglala Lakota" using R
#' county gives the state and county, fips the census fips (without a leading zero), the state
#' fips (also without a leading zero), and the location (which is the same as the county field,
#' but with the name location for easier joining to forecast challenge data)
#'
#' @docType data
#' 
#' @source \url{https://www.census.gov/geographies/reference-files/2017/demo/popest/2017-fips.html}
'fips.lookup'

#' Mosquito Ranges
#' 
#' Merge by fips column, note that location column is not present
#' Mosquito Range Maps were digitized from Kramer and Bernard 2001 using ArcGIS.
#' County level data used counties form the U.S. Census (tl_2017_us_county_LOWER_48.shp), which were updated with a column for each mosquito species
#' Mosquito_Ranges.shp
#' Presence/absence only was determined.
#' Note that range maps are out of date, as they are based on Darsie and Ward 1981 and 1989 (from 2001), and are relatively coarse.
#' No maps of Cx. restuans, although this species is known to be important in WNV transmission
#' Data were exported to Mosquito_Ranges.csv, which was then cleaned up in R (see mosquito.ranges.R, note the script was not run
#' in its final form, but was run interactively, so it is possible it will not exactly reproduce th output)
#' 
#' @docType data
#' 
#' @source Bernard, K. and Kramer L. 2001 West Nile virus activity in the United States, 2001. Viral Immunology 14: 319-338.
#' Darsie, R.F., Jr., and R.A. Ward. 1981. Identification and geographical distribution of the mosquitoes of North America,
#' north of Mexico. Supplement to Mosquito Systematics 1:1-313.
#' Darsie, R.F., Jr., and R.A. Ward. 1989. Review of new Nearctic mosquito distributional records north of Mexico,
#' with notes on additions and taxonomic changes of the fauna, 1982-89. J. Am. Mosq. Control Assoc. 5:552-557
'mosquito.ranges'

#' US Quarterly GRIDMET data
#'
#' Data from the GRIDMET project, downloaded from Google Earth Engine daily by county using the
#' GRIDMET Viewer and Downloader Version 1.1 tool in the ArboMAP package (www.github.com/ecograph/ArboMAP).
#' The downloader was modified to include the COUNTYFP field in the output for the 3 counties where it mattered:
#' L199 var oldnames = ["NAME", "COUNTYFP", "doy", "year", "tminc", "tmeanc", "tmaxc", "pr", "rmean", "vpd"];
#' L200 var newnames = ["district", "COUNTYFP", "doy", "year", "tminc", "tmeanc", "tmaxc", "pr", "rmean", "vpd"];
#' COUNTYFP was then used to disambiguate the 6 county pairs that had the same names for the county and the city.
#' Converted to quarterly data using the RF1 package tool convert.env.data tool designed to take data
#' from the ArboMAP daily format and put it into the RF1 input format.
#' The .csv downloaded from Google Earth Engine is included in the data-raw folder for New York State (New York36.csv)
#' The converted .rda file is also included New York36.rda.
#' The .csv and .rda files for the other states can be made available upon request (as of 2020-05-19).
#' (not included due to their large file sizes to keep the repository small size-wise)
#' Currently does not include the anomaly data (these were calculated directly in R)
#' 
#' _1 refers to first quarter data, from Jan - Mar, _APRIL refers to data from April
#' 
#' See april.gridmet.R for processing details.
#'
#' @docType data
#'
#' @source \url{https://developers.google.com/earth-engine/datasets/catalog/IDAHO_EPSCOR_GRIDMET}
#'
'us.quarterly'

