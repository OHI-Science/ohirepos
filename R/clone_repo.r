# clone_repo.r

#' Clone existing repo building from git2r's clone()
#'
#' @param dir_repo local directory where you want to clone the repo (probably somewhere temporary)
#' @param git_url url of repo (e.g. "https://github.com/OHI-Science/arc.git")
#'
#' @return TBD
#' @export
#'
#' @examples
#' \dontrun{# TBD}

clone_repo <- function(dir_repo, git_url) {

  ## clone repo
  unlink(dir_repo, recursive=TRUE, force=TRUE)
  repo = git2r::clone(git_url, normalizePath(dir_repo, mustWork=FALSE))

  ## get remote branches # JSL commented out 05/12 to test something
  # remote_branches = sapply(git2r::branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])

  return(repo)
}
