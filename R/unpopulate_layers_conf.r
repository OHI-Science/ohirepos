# unpopulate_layers_conf.r

#' Unpopulate existing layers and conf folders and files
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param dir_repos full path of temporary folder for OHI repos, e.g. `~/github/clip-n-ship`
#' @param dir_repo full path of temporary OHI repo e.g. `~/github/clip-n-ship/gye`
#' @param git_url url of key's github repository
#' @param default_scenario key's scenario folder
#'
#' @return key's repo after unpopulating layers and conf information
#' @export
#'
#' @examples
#'
unpopulate_layers_conf <- function(key, dir_repos, dir_repo,
                                   git_url, default_scenario) {

  ## delete all the things
  to_delete <- paste(dir_repo, default_scenario,
                    c('layers', 'layers.csv', 'conf', 'scores.csv',
                      'layers-empty_swapping-global-mean.csv',
                      'install_ohicore.r', 'calculate_scores.r', 'configure_toolbox.r',
                      'launch_app_code.r', 'session.txt'), sep = '/')

  cat(sprintf(' Deleting contents of repo, including /layers and /conf folders... '))

  unlink(to_delete, recursive = TRUE, force = TRUE)

}
