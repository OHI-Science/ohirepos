#' Extract global region (without subregions)
#' Extract global regions, to be used in Tier 1 assessments
#' @param repo_registry data frame with information about the repo
#' @param save_dir directory to save the shapefile
#'
#' @return
#' @export
#'
#' @examples
extract_global_region <- function(repo_registry,
                                  dir_save) {

  ## create variables
  rgn_name_global <- repo_registry$rgn_name_global

  ## extract if regions object exists
  if(exists("regions")) {

  ## filter the regions you want
  regions_extract <- regions[regions$rgn_name == rgn_name_global, ]
  # regions_extract <- regions[regions$rgn_name %in% c("Italy", "France"), ]

  ## turn into ESRI shapefile
  regions_extract <- as(regions_extract, 'Spatial')

  ## plot to make sure this is what you want
  plot(regions_extract[, 1])

  ## save the output (saving as an ESRI Shapefile):
  sf::write_sf(regions_extract,
               file.path(dir_save, paste0(rgn_name_global, ".shp")))

  } else {
    print('please source `spatial_common.R` first, you will need Mazu privileges')
    print('source("https://raw.githubusercontent.com/OHI-Science/ohiprep_v2018/master/src/R/spatial_common.R")')
  }
}
