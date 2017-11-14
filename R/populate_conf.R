# populate_conf.r
#'
#' Populate OHI repo with configuration folder
#'
#' @param repo_registry data frame with information about the repo
#'
#' @return key's repo with config folder populated
#' @export
#'

populate_conf <- function(repo_registry) {

  ## create variables
  key             <- repo_registry$study_key
  dir_repo        <- repo_registry$dir_repo
  dir_origin      <- repo_registry$dir_origin
  dir_conf        <- file.path(dir_repo, repo_registry$scenario_name, 'conf')
  gh_org          <- 'OHI-Science'
  dir_scenario_gh <- sprintf(
    "https://raw.githubusercontent.com/%s/%s/master/%s",
    gh_org, key, repo_registry$scenario_name)


  ## create conf folder

  if (!dir.exists(dir_conf)) {
    dir.create(dir_conf, showWarning=FALSE)
  }

  ## list conf files to copy, except functions.r
  conf_files = c('config.R', 'goals.csv',
                 'pressures_matrix.csv',  'pressure_categories.csv',
                 'resilience_matrix.csv', 'resilience_categories.csv',
                 'scenario_data_years.csv')

  for (f in conf_files){ # f = 'config.R'

    file.copy(file.path(dir_origin, 'conf', f),
              file.path(dir_conf, f),
              overwrite=TRUE)
  }

  
  ## copy functions.R from local curated version if from global
  if (dir_origin == "~/github/ohi-global/eez" ) {
    
    file.copy(base::system.file('inst/master/functions_tmp_eez2017.R',
                                package='ohirepos'),
              file.path(dir_conf, 'functions.R'), overwrite=TRUE)
    
    #   rethink ref points stuff to be useful?
    #   ## write.csv(d_check, sprintf('temp/cs_data_%s.csv', scenario), row.names=FALSE)
    #   s <-  s %>%
    #     str_replace("write.csv\\(tmp, 'temp/.*", '') %>%
    #     str_replace('^.*sprintf\\(\'temp\\/.*', '')
    #
    
    ## if not from global, copy directly
  } else {
    
    file.copy(file.path(dir_origin, 'conf/functions.r'),
              file.path(dir_conf, 'functions.r'),
              overwrite=TRUE)
  }

  ## copy subfolders in goals folder for website ----
  goal_subfolders <- list.files(system.file('master/web/goals', package='ohirepos'))
  dir_web         <- file.path(dir_conf, 'web')
  dir_goals       <- file.path(dir_conf, 'web/goals')

  ## create goals dir if it doesn't already exist
  if(!file.exists(dir_web)) dir.create(dir_web)
  if(!file.exists(dir_goals)) dir.create(dir_goals)

  for (g in goal_subfolders){ # g <- "AO.Rmd"

    file.copy(system.file(sprintf('master/web/goals/%s', g),
                          package='ohirepos'),
              file.path(dir_goals, g), overwrite=TRUE)

  }

  ## brew the parent goals.Rmd file
  brew::brew(system.file(sprintf('master/web/goals.brew.Rmd'), package='ohirepos'),
             file.path(dir_web, 'goals.Rmd'))


}
