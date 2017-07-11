#' Populate the repo with prep folder and subfolders and README files
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param dir_repo local directory where you have cloned the repo (probably somewhere temporary) 
#' @param push TRUE/FALSE: do you want to add, commit, and push? Defaults to TRUE. 
#'
#' @return
#' @export
#'
#' @examples
populate_prep <- function(key, 
                          dir_repo, 
                          push = TRUE){

  ## clone repo
  if (!file.exists(dir_repo)) system(sprintf('git clone https://github.com/OHI-Science/%s', key, dir_repo))
  
  repo = git2r::repository(dir_repo)

  # pull the latest from master branch
  system(sprintf('cd %s; git checkout master; git pull', dir_repo))

  ## create prep dir
  dir.create(file.path(dir_repo, 'prep'), showWarnings=FALSE)
  file.copy(system.file('inst/master/README_prep.md', package='ohirepos'),
            file.path(dir_repo, 'prep/README.md'), overwrite=TRUE)

  ## create subfolders in prep folder
  prep_subfolders = c('FIS', 'MAR', 'AO', 'NP', 'CS', 'CP', 'LIV', 'ECO', 'TR', 'CW',
                      'ICO', 'LSP', 'SPP', 'HAB', 'pressures', 'resilience')
  sapply(file.path(dir_repo, 'prep', prep_subfolders), dir.create)

  ## populate prep folder's subfolders
  file.copy(system.file('inst/master/README_prep_subfolders.md', package='ohirepos'),
            file.path(dir_repo, 'prep', prep_subfolders, 'README.md'), overwrite=TRUE)

  ## cd to dir_repo, git add, commit and push
  if (push) {
    
    cat(sprintf("git add, commit, and push %s repo", key))
    system(sprintf('cd %s; git add -A; git commit -a -m "%s repo populated with prep folders"', dir_repo, key))
    system(sprintf('cd %s; git push origin master', dir_repo))
  }
  
  ## TO ADD
  # ## create and populate prep/tutorials folder
  # dir_tutes = file.path(dir_github, 'ohimanual/tutorials/R_tutes')
  #
  # dir.create(file.path(dir_repo, default_scenario, 'prep/tutorials'))
  # file.copy(file.path(dir_tutes, 'R_tutes_all.md'),
  #           file.path(default_scenario, 'prep/tutorials', 'R_intro.md'), overwrite=T)
  # readLines(file.path(dir_tutes, 'R_tutes.r')) %>%
  #   str_replace("setwd.*",
  #               paste0("setwd('", file.path(dir_github, key, default_scenario, 'prep/tutorials'), "')")) %>%
  #   writeLines(file.path(default_scenario, 'prep/tutorials', 'R_tutorial.r'))
  #

}
