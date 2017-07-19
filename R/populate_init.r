#' Populate initial files including README and .Rproj
#'
#' First delete any local copy in your directory and clone the repo from github.com/OHI-Science.
#'
#' @param repo_registry data frame with information about the repo 
#' @param gh_org github organization to place the repo. Default: ohi-science
#' @param push TRUE/FALSE: do you want to add, commit, and push? Defaults to TRUE.
#'
#' @export
#'
populate_init <- function(repo_registry,
                          gh_org = 'OHI-Science',
                          push = TRUE){

  ## create variables
  key        <- repo_registry$study_key
  study_area <- repo_registry$study_area
  dir_repo   <- repo_registry$dir_repo
  
  ## clone repo from github.com/ohi-science to local
  unlink(dir_repo, recursive=TRUE, force=TRUE)
  repo <- ohirepos::clone_repo(dir_repo,
                               sprintf('https://github.com/%s/%s.git',
                                       gh_org, key))
  ## if this error, make sure you created the repo online!
  # Error in git2r::clone(git_url, normalizePath(dir_repo, mustWork = FALSE)) : 
  # Error in 'git2r_clone': Unable to authenticate with supplied credentials 
  
  ## get remote branches
  remote_branches <- sapply(git2r::branches(repo, 'remote'), function(x) stringr::str_split(x@name, '/')[[1]][2])

  ## initialize repo
  if (length(remote_branches)==0){
    system('touch README.md')
    system('git add -A; git commit -m "first commit"')
    try(system('git remote rm origin')) # stackoverflow.com/questions/1221840/remote-origin-already-exists-on-git-push-to-new-repository
    system(sprintf('git remote add origin https://github.com/OHI-Science/%s.git', key))
    system('git push -u origin master')
    system('git pull')
    remote_branches = sapply(branches(repo, 'remote'), function(x) str_split(x@name, '/')[[1]][2])
  }

  ## recreate empty dir, except hidden .git (all.files=FALSE)
  for (f in list.files(dir_repo, all.files=FALSE)) {
    unlink(file.path(dir_repo, f), recursive=TRUE, force=TRUE)
  }

  ## add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData'), '.gitignore')

  ## README
  brew::brew(file   = system.file('inst/master/README.brew.md', package='ohirepos'),
             output = file.path(dir_repo, 'README.md'))

  ## cd to dir_repo, git add, commit and push
  if (push) {

    cat(sprintf("git add, commit, and push %s repo", key))
    system(sprintf('cd %s; git add -A; git commit -a -m "%s repo populated with initial files"', dir_repo, key))
    system(sprintf('cd %s; git push origin master', dir_repo))
  }

  return(repo)
  
}
