#' @title Population estimates for Continental US Counties
#' @description Annual population estimates from US Census Bureau from 2000 to 2019.
#' @format A data frame with 62160 rows and 6 variables:
#' \describe{
#'   \item{\code{district_year}}{combination field for matching CDC data}
#'   \item{\code{location}}{combination of state and county name for matching CDC data}
#'   \item{\code{year}}{numeric year of estimate}
#'   \item{\code{POP}}{numeric Population estimate of county}
#'   \item{\code{fips}}{character 5 digit fips for both state and county. See details for exceptions.}
#'}
#' @details There are a number of issues that arise because of changes to the
#' dataset between 2000-2009 and 2010-2019. These include
#' \itemize{
#'   \item 46102 Shannon County, SD becomes 46113 Oglala Lakota in 2010
#'   \item 51019/51515	Bedford/Bedford City in 2000-2009 merge into 51019 2010-2019
#' }
#' In the Neuroinvasive cases data frame these have dual fips codes separated with "/", so were treated
#' the same here.
#' @docType data
#'
#' @source US Census Bureau Population Estimation Program
"county_popn"
