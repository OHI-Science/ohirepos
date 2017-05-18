#' Deploy website to gh-pages branch in Github repository
#'
#' @param gh_repo Github repository
#' @param study_area place name of the entire study area
#' @param gh_owner Github owner. Defaults to "OHI-Science".
#' @param dir_out top-level directory to use for populating git repo folder and branch subfolders within, defaults to tmpdir()
#' @param del_out whether to delete output directory when done, defaults to TRUE

#'
#' @return Returns web_url (http://[gh_owner].github.io/[gh_repo]) based on creating or
#' updating gh-pages branch of Github repository. Please also visit
#' \link[=https://github.com/OHI-Science/ohirepos/blob/master/inst/gh-pages/README.md]{gh-pages/README.md} for more details.
#'
#' @examples
#' \dontrun{
#' deploy_website_prep('arc', 'The Arctic')
#' }
#'
#' @import tidyverse yaml devtools brew stringr
#' @export
deploy_website_prep <- function(
  gh_repo, study_area,
  gh_owner='OHI-Science', gh_branch_data='master',
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  open_url=FALSE,
  dir_out='~/github/clip-n-ship', del_out=TRUE){

  ## debug ---

  # library(devtools); load_all();
  # gh_repo='ohibc';  study_area='British Columbia';
  # dir_out='~/github/clip-n-ship'; gh_owner='OHI-Science'
  # library(tidyverse)
  # library(yaml)
  # library(brew)
  # library(git2r)
  # library(stringr)

  ## construct vars
  web_url       = sprintf('http://%s.github.io/%s', gh_owner, gh_repo)
  gh_branch_web = 'gh-pages'
  dir_repo      = file.path(dir_out, gh_repo)
  gh_slug       = sprintf('%s/%s', gh_owner, gh_repo)
  gh_url        = sprintf('https://github.com/%s.git', gh_slug)


  ## ensure top level dir exists
  dir.create(dir_out, showWarnings = TRUE, recursive = TRUE)

  run_cmd = function(cmd){
    cat(sprintf('running command:\n  %s\n', cmd))
    system.time(system(cmd))
  }


  ## clone existing master branch

  repo <- clone_repo(dir_repo, gh_url) ## TODO: add ohirepos::
  branches(repo)

  ## if (!'gh-pages' %in% remote_branches){ ## JSL TODO: update this check x <- branches(repo)

  ## create gh-pages branch
  system(sprintf('cd %s; git branch gh-pages; git checkout gh-pages', dir_repo))

  ## figure out how to keep the files we want -- don't keep .Rproj because add it back below. maybe don't keep anything.
  do.call(file.remove, list(list.files(dir_repo, full.names = TRUE)))
  # sapply(list.files(dir_repo, full.names=TRUE), file.remove) # figure out how to delete the scenario folder too

  ## copy gh-pages web files into dir_repo, excluding all files in .gitignore
  run_cmd( ##
    sprintf(
      'cd %s; rsync -rq \\
      --exclude=_site.brew.R --exclude=_site.brew.yml --exclude=index.brew.Rmd --exclude=_other/ --exclude=.gitignore \\
      --include=_footer.html --exclude-from=.gitignore \\
      . %s',
      system.file('gh-pages-prep', package='ohirepos'), dir_repo))

  ## brew files
  brew(system.file('gh-pages-prep/_site.brew.yml', package='ohirepos'), sprintf('%s/_site.yml', dir_repo))
  brew(system.file('gh-pages-prep/_site.brew.R'  , package='ohirepos'), sprintf('%s/_site.R'  , dir_repo))
  brew(system.file('gh-pages-prep/index.brew.Rmd'  , package='ohirepos'), sprintf('%s/index.Rmd'  , dir_repo))

  ## add Rstudio project file
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s/%s.Rproj', dir_repo, gh_repo))

  ## ensure .nojekyll file per http://rmarkdown.rstudio.com/rmarkdown_websites.html#publishing_websites
  system(sprintf('touch %s/.nojekyll', dir_repo))

  ## add gitignore file
  writeLines(c(
    '.Rproj.user', '.Rhistory', '.RData', 'rsconnect', '.DS_Store',
    basename(dir_repo)
  ), file.path(dir_repo, '.gitignore'))

  ## render website
  rmarkdown::render_site(dir_repo)

  ## git commit and push to Github
  run_cmd(sprintf(
    "cd %s; git add --all; git add .gitignore .nojekyll;
    git commit -m 'creating prep website with ohirepos';
    git push origin gh-pages",
    dir_repo))

}
