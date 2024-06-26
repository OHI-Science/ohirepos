#' Populate the repo with prep folder and subfolders and README files
#'
#' @param repo_registry data frame with information about the repo
#' @param push TRUE/FALSE: do you want to add, commit, and push? Defaults to TRUE.
#'
#' @return
#' @export
#'
#' @examples
#'
populate_prep <- function(repo_registry,
                          push = TRUE){

  ## create variables
  key      <- repo_registry$study_key
  gh_org   <- repo_registry$gh_org
  dir_repo <- repo_registry$dir_repo

  ## clone existing master branch
    unlink(dir_repo, recursive=TRUE, force=TRUE)
    repo <- ohirepos::clone_repo(dir_repo,
                                 sprintf('https://github.com/%s/%s.git',
                                         gh_org, key))

  ## create prep dir
  dir.create(file.path(dir_repo, 'prep'), showWarnings=FALSE)
  file.copy(system.file('master/README_prep.md', package='ohirepos'),
            file.path(dir_repo, 'prep/README.md'), overwrite=TRUE)

  ## create subfolders in prep folder
  prep_subfolders = c('FIS', 'MAR', 'AO', 'NP', 'CS_CP_HAB', 'LIV', 'ECO', 'TR',
                      'CW', 'LSP', 'SPP_ICO', '_pressures', '_resilience')
  sapply(file.path(dir_repo, 'prep', prep_subfolders), dir.create)

  ## populate prep folder's subfolders
  file.copy(system.file('master/README_prep_subfolders.md', package='ohirepos'),
            file.path(dir_repo, 'prep', prep_subfolders, 'README.md'), overwrite=TRUE)


  ## cd to dir_repo, git add, commit and push
  if (push) {

    ohirepos::commit_and_push(
      repo_registry,
      commit_message = sprintf("%s repo populated with prep folders", key),
      branch = 'master')
  }

  ## only return if created repo variable
  return(repo)

}
