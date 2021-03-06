#' Get remote branches on Github from local repository.
#'
#' @param dir_repo local directory where you have cloned the repo
#'
#' @return Returns character vector of branches
#' @export
#'
#' @import readr dplyr
gh_remote_branches = function(dir_repo){
  
  remote_branches =
    read_tsv(
      paste(
        system(
          sprintf('cd %s;git ls-remote --heads origin', dir_repo), intern=T),
        collapse='\n'),
      col_names=c('sha','ref')) %>%
    mutate(
      repo = stringr::str_replace(ref, 'refs/heads/', '')) %>%
    .$repo
}
