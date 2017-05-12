#' Deploy website to gh-pages branch in Github repository
#'
#' @param gh_repo Github repository
#' @param study_area place name of the entire study area
#' @param scenario_dir subfolder from data branch of repo that will be the default scenario to display on website
#' @param gh_owner Github owner. Defaults to "OHI-Science".
#' @param gh_branch_data Github branch containing data. Defaults to "master" and must already exist in the repo.
#' @param app_url URL of Shiny application that gets embedded as iframe
#' @param open_url open the web browser to the web_url
#' @param dir_out top-level directory to use for populating git repo folder and branch subfolders within, defaults to tmpdir()
#' @param del_out whether to delete output directory when done, defaults to TRUE

#'
#' @return Returns web_url (http://[gh_owner].github.io/[gh_repo]) based on creating or
#' updating gh-pages branch of Github repository. Please also visit
#' \link[=https://github.com/OHI-Science/ohirepos/blob/master/inst/gh-pages/README.md]{gh-pages/README.md} for more details.
#'
#' @examples
#' \dontrun{
#' deploy_website('ohi-global', 'Global', 'eez2015')
#' deploy_website('bhi',        'Baltic', 'baltic2015')
#' }
#'
#' @import tidyverse yaml devtools brew
#' @export
deploy_website <- function(
  gh_repo, study_area, # scenario_dir,
  gh_owner='OHI-Science', gh_branch_data='master',
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  open_url=FALSE,
  dir_out='~/github/clip-n-ship/tmp', del_out=TRUE){

  # debug ---

  # library(devtools); load_all();
  gh_repo='arc'       ; study_area='Arctic';
  dir_out='~/github/clip-n-ship/tmp/%s'
  gh_owner='OHI-Science'; gh_branch_data='master'

  # library(ohirepos) # devtools::install_github('ohi-science/ohirepos')
  # deploy_website('ohi-global', 'Global', 'eez2015'   , dir_out='~/Desktop/ohirepos_tmp', del_out=F, open_url=T)
  # deploy_website('bhi',        'Baltic', 'baltic2015', dir_out='~/Desktop/ohirepos_tmp', del_out=F, open_url=T)

  # ----

  library(tidyverse)
  library(yaml)
  library(brew)
  library(git2r)
  library(stringr)

  # construct vars
  web_url       = sprintf('http://%s.github.io/%s', gh_owner, gh_repo)
  gh_branch_web = 'gh-pages'
  dir_repo      = file.path(dir_out, gh_repo)
  # dir_data      = file.path(dir_out, gh_repo, gh_branch_data)
  # dir_web       = file.path(dir_out, gh_repo, gh_branch_web)
  # dir_data_2    = file.path(dir_out, gh_repo, gh_branch_web, sprintf('%s_%s', gh_repo, gh_branch_data))
  gh_slug       = sprintf('%s/%s', gh_owner, gh_repo)
  gh_url        = sprintf('https://github.com/%s.git', gh_slug)

  ## ensure top level dir exists
  dir.create(dir_repo, showWarnings = F, recursive = T)

  run_cmd = function(cmd){
    cat(sprintf('running command:\n  %s\n', cmd))
    system.time(system(cmd))
  }


  ## clone existing master branch

  repo <- clone_repo(dir_repo, gh_url) ## TODO: add ohirepos::
  branches(repo)

  # if (!'gh-pages' %in% remote_branches){ ## JSL TODO: update this check x <- branches(repo)
  ## create gh-pages branch
  system(sprintf('cd %s; git branch gh-pages; git checkout gh-pages', dir_repo))

  ## figure out how to keep the files we want
  # files_to_keep = list.files(dir_out, pattern = c("\\.Rproj$", "\\.git$", "\\.gitignore$"), all.files=TRUE)


  # copy gh-pages web files into dir_web, excluding all files in .gitignore
  # run_cmd( ## NOT SURE WE NEED
  #   sprintf(
  #     'cd %s; rsync -rq \\
  #     --exclude=_site.brew.R --exclude=_site.brew.yml --exclude=_other/ --exclude=.gitignore \\
  #     --include=_footer.html --exclude-from=.gitignore \\
  #     . %s',
  #     system.file('gh-pages', package='ohirepos'), dir_web))

  # get commit of ohirepos for website provenance
  # ohirepos_commit = devtools:::local_sha('ohirepos') ## NOT SURE WE NEED
  # if (nchar(ohirepos_commit) != 40){
  #   stop(sprintf(paste(
  #     'Sorry, the ohirepos R library seems to have not been installed with:',
  #     '  devtools::install_github("ohi-science/ohirepos")',
  #     'based on devtools:::local_sha("ohirepos") of %s and not of normal Github commit length 40,',
  #     'which is necessary to associate the ohirepos commit with the Shiny app deployed.', collapse='\n'), ohirepos_commit))
  # }

  # brew _site.* files
  brew(system.file('gh-pages/_site.brew.yml', package='ohirepos'), sprintf('%s/_site.yml', dir_repo))
  brew(system.file('gh-pages/_site.brew.R'  , package='ohirepos'), sprintf('%s/_site.R'  , dir_repo))

  # add Rstudio project file
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s/%s.Rproj', dir_web, gh_repo))

  # ensure .nojekyll file per http://rmarkdown.rstudio.com/rmarkdown_websites.html#publishing_websites
  system(sprintf('touch %s/.nojekyll', dir_web))

  # add gitignore file
  writeLines(c(
    '.Rproj.user', '.Rhistory', '.RData', 'rsconnect', '.DS_Store',
    basename(dir_data_2)
  ), file.path(dir_web, '.gitignore'))

  # copy dir_data to dir_data_2
  run_cmd(sprintf('cd %s; rsync -rq ./ %s', dir_data, dir_data_2))

  # render website
  rmarkdown::render_site(dir_web)

  # git commit and push to Github
  run_cmd(sprintf(
    "cd %s; git add --all; git add .gitignore .nojekyll;
    git commit -m 'updating website with ohirepos commit %s';
    git push origin gh-pages",
    dir_web, substr(ohirepos_commit, 1, 7)))

  # open website
  if (open_url) utils::browseURL(web_url)

  # remove temp files
  if (del_out){
    run_cmd(sprintf('rm -rf %s', dir_repo))
  }

  # return website
  return(web_url)
}
