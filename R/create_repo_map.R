## create_repo_map.r

#' Title
#'
#' @param repo_registry data frame with information about the repo
#' @param push TRUE/FALSE: do you want to add, commit, and push? Defaults to TRUE.
#'
#' @return repo
#' @export
#'
#' @examples
#'
create_repo_map <- function(repo_registry,
                            push   = TRUE){

  ## create variables ----
  key             <- repo_registry$study_key
  gh_org          <- repo_registry$gh_org
  dir_repo        <- repo_registry$dir_repo
  dir_scenario    <- file.path(repo_registry$dir_repo, repo_registry$scenario_name)
  dir_scenario_sp <- file.path(dir_scenario, 'spatial')
  dir_conf        <- file.path(dir_scenario, 'conf')
  dir_web         <- file.path(dir_conf, 'web')
  dir_shp_in      <- file.path(repo_registry$dir_shp_in)
  dir_shp_out     <- file.path(repo_registry$dir_shp_out)
  shp_name        <- repo_registry$name_shp_files


  ## clone repo master branch ----
  unlink(dir_repo, recursive=TRUE, force=TRUE)
  repo <- ohirepos::clone_repo(dir_repo,
                               sprintf('https://github.com/%s/%s.git',
                                       gh_org, key))


  ## create directories if they don't already exist ----
  if (!file.exists(dir_scenario))    dir.create(dir_scenario)
  if (!file.exists(dir_scenario_sp)) dir.create(dir_scenario_sp)
  if (!file.exists(dir_conf))        dir.create(dir_conf)
  if (!file.exists(dir_web))         dir.create(dir_web)


  ## process shapefiles; ensure projection and rename ----
  shp_orig = rgdal::readOGR(dsn=dir_shp_in, layer=shp_name)
  crs = sp::CRS("+proj=longlat +datum=WGS84")
  shp = sp::spTransform(shp_orig,crs)
  ## consider from Jamie Oct 2:
  # crs = sp::CRS("+proj=longlat +datum=WGS84")
  # shp_orig = sf::st_read(dsn=path.expand(dir_shp_in), layer=shp_name) %>%
  #   sf::st_transform(crs)


  ## try to rename columns
  d <- stringr::str_detect(names(shp),
                      pattern = stringr::str_to_lower('label'))
  names(shp)[d] <- 'rgn_name'


  ## final check that all column names present
  if (!all(c('rgn_id', 'rgn_name', 'area_km2') %in% names(shp) )) {
    stop('Please ensure the shp@data columns names include "rgn_id", "rgn_name", and "area_km2"')
  }


  ## drop other column names
  shp@data <- shp@data %>%
    dplyr::select(rgn_id, rgn_name, area_km2) # don't arrange by rgn_id unless using sf


  ## write shapefile to git-annex ----
  rgdal::writeOGR(shp, dsn=dir_shp_out,
                  'rgn_offshore_gcs', driver='ESRI Shapefile', overwrite=TRUE)


  ## write geojson to git-annex and copy it to repo/spatial ----
  f_geojson <- file.path(dir_shp_out, 'regions_gcs.geojson')
  geojsonio::geojson_json(shp) %>%
    geojsonio::geojson_write(file = f_geojson)

   file.copy(from = f_geojson,
            to   = file.path(dir_scenario_sp, basename(f_geojson)),
            overwrite=TRUE)

   ## write .csv file to repo and git-annex and copy/rename it to repo/spatial----
   f_data <- file.path(dir_shp_out, 'rgn_offshore_data.csv')
   regions_list <- shp@data %>%
     arrange(rgn_id)
   readr::write_csv(regions_list, f_data)

   file.copy(from = f_data,
             to   = file.path(dir_scenario_sp, "regions_list.csv"),
             overwrite=TRUE)


  ## brew viz_config.r with map centroid and zoom level ----

  shp_bb    <- data.frame(shp@bbox) # max of 2.25
  shp_range <- dplyr::transmute(shp_bb, range = max - min)
  shp_ctr   <- rowMeans(shp_bb)
  shp_zoom  <- 12 - as.integer(
    cut(max(shp_range),
        breaks = c(0, 0.25, 0.5, 1, 2.5, 5, 10, 20, 40, 80, 160, 320, 360)))

  brew::brew(system.file(sprintf('master/web/viz_config.brew.r'), package='ohirepos'),
             file.path(dir_web, 'viz_config.R'))

  ## cd to dir_repo, git add, commit and push
  if (push) {

    ohirepos::commit_and_push(
      repo_registry,
      commit_message = sprintf("%s repo geojson map created", key),
      branch = 'master')
  }

  return(repo)

}
