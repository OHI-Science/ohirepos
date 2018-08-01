# populate_etc.r

#' Populate other items in OHI repos.
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
  dir_repo      <- repo_registry$dir_repo
  study_area    <- repo_registry$study_area
  scenario      <- repo_registry$scenario_name
  scenario_year <- repo_registry$scenario_year
  dir_scenario  <- file.path(dir_repo, scenario)
  dir_reports   <- file.path(dir_scenario, "reports")
  dir_figures   <- file.path(dir_reports, "figures")

  ## brew R filenames, not extensions
  brew_files = c("calculate_scores")

  for (f in brew_files){ # f = "calculate_scores"

    brew::brew(
      file   = system.file(sprintf("inst/master/%s.brew.Rmd", f),
                           package="ohirepos"),
      output = sprintf("%s/%s.Rmd", dir_scenario, f))

  }

  ## create reports folder and subfolder(s)
  if (!dir.exists(dir_reports)) {
    dir.create(dir_reports, showWarning=FALSE)
    dir.create(dir_figures, showWarning=FALSE)
  }

  ## TODO decide whether keep this and how it works
  # ## copy temp/referencePoints.csv
  # fn <- 'referencePoints.csv'
  # dir_temp = file.path(dir_scenario, 'temp')
  # dir.create(dir_temp)
  # file.copy(file.path('~/github/ohi-webapps/inst', fn),
  #           file.path(dir_temp, fn), overwrite=TRUE)

}
