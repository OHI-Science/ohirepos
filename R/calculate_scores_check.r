## calculate_scores_check

#' Calculate scores for OHI repository
#'
#' @param repo_registry data frame with information about the repo 
#'
#' @return TBD
#' @export
#'
#' @examples
#' \dontrun{# TBD}
calculate_scores_check <- function(repo_registry){

  ## create variables
  dir_scenario <- file.path(dir_repo, repo_registry$scenario_name )
  
  ## TODO this is just temp until Mel merges dev to regular
  remove.packages("ohicore")
  devtools::install_github('ohi-science/ohicore@dev')
  library(ohicore)

  ## ensure on master branch
  #git2r::checkout(repo, 'master')

  # iterate through all scenarios (by finding layers.csv)
  dirs_scenario = normalizePath(dirname(
    list.files(dir_scenario, '^layers.csv$', recursive=TRUE, full.names=TRUE)))
  
  for (dir_scen in dirs_scenario){ # dir_scen=dirs_scenario[1]

    # set working directory to scenario
    setwd(dir_scen)
    cat('\n\nCALCULATE SCORES for SCENARIO', basename(dir_scen), '\n')

    # load scenario configuration
    conf <<- ohicore::Conf('conf')

    # run checks on scenario layers
    ohicore::CheckLayers('layers.csv', 'layers', flds_id=conf$config$layers_id_fields)

    # load scenario layers
    layers <<- ohicore::Layers('layers.csv', 'layers')

    # calculate scenario scores
    scores = ohicore::CalculateAll(conf, layers)
    write.csv(scores, 'scores.csv', na='', row.names=FALSE)

    # document versions of packages and specifics of ohicore
    cat(
      capture.output(sessionInfo()), '\n\n',
      readLines(file.path(system.file(package='ohicore'), 'DESCRIPTION')),
      file='session.txt', sep='\n')
  }

}
