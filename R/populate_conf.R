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
  dir_origin <- repo_registry$dir_origin
  dir_conf   <- file.path(dir_repo, repo_registry$scenario_name, 'conf')
   
  
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
  
  
  ## copy functions.R from local curated version
  file.copy(system.file('inst/master/functions_ohi-webapps_dev_eez2016.R', 
                        package='ohirepos'),
            file.path(dir_conf, 'functions.R'), overwrite=TRUE)
  
    #   rethink ref points stuff to be useful?
    #   ## write.csv(d_check, sprintf('temp/cs_data_%s.csv', scenario), row.names=FALSE)
    #   s <-  s %>%
    #     str_replace("write.csv\\(tmp, 'temp/.*", '') %>%
    #     str_replace('^.*sprintf\\(\'temp\\/.*', '')
    # 

  ### TODO: come back here...should I brew each one from a list or have each individual? How did Mel do it.
  ## create subfolders in goals folder
  dir.create(file.path(dir_conf, 'goals'), showWarnings=FALSE)
  goals_rmds = c('FIS', 'MAR', 'AO', 'NP', 'CS', 'CP', 'LIV', 'ECO', 'TR', 'CW',
                      'ICO', 'LSP', 'SPP', 'HAB')
  # sapply(file.path(dir_conf, 'goals', goals_subfolders), dir.create) don't do this...
  
  ## brew files  ...brew each one with a different name
  # brew::brew(system.file('gh-pages/_site.brew.yml', package='ohirepos'),
  #            sprintf('%s/_site.yml', dir_repo))
  
  ## And don't forget the parent goals.Rmd file

}
