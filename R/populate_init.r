#' Populate initial files including README and .Rproj
#'
#' First delete any local copy in your directory and clone the repo from github.com/OHI-Science.
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param dir_repo local directory where you have cloned the repo (probably somewhere temporary)
#' @param gh_org github organization to place the repo. Default: ohi-science
#' #' @param push TRUE/FALSE: do you want to add, commit, and push? Defaults to TRUE.
#'
#' @export
#'
populate_init <- function(key,
                          dir_repo,
                          gh_org = 'OHI-Science',
                          push = TRUE){

  ## clone repo from github.com/ohi-science to local
  unlink(dir_repo, recursive=TRUE, force=TRUE)
  repo <- git2r::clone(sprintf('https://github.com/%s/%s', gh_org, key),
                       normalizePath(dir_repo, mustWork=FALSE))

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

}
