#' commit_and_push
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param dir_repo local directory where you have cloned the repo (probably somewhere temporary)
#' @param commit_message short message in quotes to accompany commit
#' @param branch GitHub branch to push, defaults to 'master'
#'
#' @return
#' @export
#'
#' @examples
commit_and_push <- function(key, 
                            dir_repo, 
                            commit_message, 
                            branch = 'master'){
  
  ## let us know what's going on
  cat(sprintf("git add, commit, and push rendered website for %s repo, ", key))
  cat(sprintf("with commit message '%s'\n", commit_message))
  
  ## cd to dir_repo, git add, commit and push rendered website
  system.time(system(sprintf(
    "cd %s; git add --all;
      git commit -m '%s';
      git push origin %s",
    dir_repo, commit_message, branch)))
  
}
