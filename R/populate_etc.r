# populate_etc.r

#' Populate other items in OHI repos
#'
#' @param repo_registry data frame with information about the repo 
#'
#' @return TBD
#' @export
#'
#' @examples
#' \dontrun{# TBD}
populate_etc <- function(repo_registry) {

  ## create variables, some used for brewing below
  dir_repo     <- repo_registry$dir_repo
  study_area   <- repo_registry$study_area
  scenario     <- repo_registry$scenario_name 
  dir_scenario <- file.path(dir_repo, scenario)
  
  ## brew R filenames, not extensions
  brew_files = c("calculate_scores", "configure_toolbox") 
  
  for (f in brew_files){ # f = "config.R"
    
    brew::brew(
      file   = system.file(sprintf("inst/master/%s.brew.R", f), package="ohirepos"),
      output = sprintf("%s/%s.R", dir_scenario, f))
    
  }

  ## copy install_ohicore.R
  fn <- 'install_ohicore.R'
  file.copy(system.file(file.path('inst/master', fn), package="ohirepos"),
            file.path(dir_repo, fn), overwrite=TRUE)

  ## TODO decide whether keep this and how it works
  # ## copy temp/referencePoints.csv
  # fn <- 'referencePoints.csv'
  # dir_temp = file.path(dir_scenario, 'temp')
  # dir.create(dir_temp)
  # file.copy(file.path('~/github/ohi-webapps/inst', fn),
  #           file.path(dir_temp, fn), overwrite=TRUE)

}
