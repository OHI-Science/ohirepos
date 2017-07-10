## populate_init.r

#' Title
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#'
#' @return
#' @export
#'
#' @examples
populate_init <- function(key, dir_repo, push = TRUE){
  
  ## clone repo from github.com/ohi-science to local
  unlink(dir_repo, recursive=TRUE, force=TRUE)
  repo <- git2r::clone(sprintf('https://github.com/OHI-Science/%s', key), 
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
  brew::brew(file   = 'exec/README.brew.md', 
             output = file.path(dir_repo, 'README.md'))
  
  if (push) {
    ## cd to dir_repo, git add, commit and push
    
    cat("after cd'ing to repo, git add, commit, and push")
    system(sprintf('cd %s; git add -A; git commit -a -m "%s repo populated with initial files"', dir_repo, key))
    system(sprintf('cd %s; git push origin master', dir_repo))
  }
  
}
