#' Deploy website to gh-pages branch in Github repository
#'
#' @param gh_repo Github repository
#' @param web_title title for the website, which is typically the study area or place name
#' @param scenario_dir subfolder from data branch of repo that will be the default scenario to display on website
#' @param gh_owner Github owner. Defaults to "OHI-Science".
#' @param gh_branch_data Github branch containing data. Defaults to "draft" and must already exist in the repo.
#' @param app_url URL of Shiny application that gets embedded as iframe
#' @param open_url open the web browser to the web_url
#' @param dir_out top-level directory to use for populating git repo folder and branch subfolders within, defaults to tmpdir()
#' @param del_out whether to delete output directory when done, defaults to TRUE

#'
#' @return Returns web_url (http://[gh_owner].github.io/[gh_repo]) based on creating or
#' updating gh-pages branch of Github repository.
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
  gh_repo, web_title, scenario_dir,
  gh_owner='OHI-Science', gh_branch_data='draft',
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  open_url=FALSE,
  dir_out=tempdir(), del_out=TRUE){

  # debug ----

  # history: from ohi-webapps, create_gh_repo.r https://github.com/OHI-Science/ohirepos/blob/07110dacad98fcc0a0080ca8f5ab248ae46e7f51/R/create_gh_repo.r

  # library(devtools); load_all();
  # gh_owner='OHI-Science'; gh_branch_data='draft'; app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo); open_url=T; del_out=FALSE
  # dir_out='~/github/clip-n-ship' # dir_out='~/Desktop/ohirepos_tmp'
  # gh_repo='bhi'       ; web_title='Baltic'; scenario_dir='baltic2015'
  # gh_repo='ohi-global'; web_title='Global'; scenario_dir='eez2015'

  # library(ohirepos) # devtools::install_github('ohi-science/ohirepos')
  # deploy_website('ohi-global', 'Global', 'eez2015')
  # deploy_website('bhi',        'Baltic', 'baltic2015')

  # ----

  library(tidyverse)
  library(yaml)
  library(brew)

  # construct vars
  web_url       = sprintf('http://%s.github.io/%s', gh_owner, gh_repo)
  gh_branch_web = 'gh-pages'
  dir_branches  = file.path(dir_out, gh_repo)
  dir_data      = file.path(dir_out, gh_repo, gh_branch_data)
  dir_web       = file.path(dir_out, gh_repo, gh_branch_web)
  dir_data_2    = file.path(dir_out, gh_repo, gh_branch_web, sprintf('%s_%s', gh_repo, gh_branch_data))
  dir_scenario  = sprintf('%s_%s/%s', gh_repo, gh_branch_data, scenario_dir)
  gh_slug       = sprintf('%s/%s', gh_owner, gh_repo)
  gh_url        = sprintf('https://github.com/%s.git', gh_slug)

  # ensure top level dir exists
  dir.create(dir_branches, showWarnings = F, recursive = T)

  run_cmd = function(cmd){
    cat(sprintf('running command:\n  %s\n', cmd))
    system.time(system(cmd))
  }

  # data branch: fetch existing, or clone new
  if (!file.exists(dir_data)){

    # clone data branch, shallowly and quietly
    run_cmd(sprintf('git clone -q --depth 1 --branch %s %s %s', gh_branch_data, gh_url, dir_data))
  } else {

    # git fetch & overwrite
    run_cmd(sprintf('cd %s; git fetch -q; git reset -q --hard origin/%s; git checkout -q %s; git pull -q', dir_data, gh_branch_data, gh_branch_data))
  }

  # check if web branch dir already exists
  if (file.exists(dir_web)){

    if (file.exists(dir_data_2)){

      # move dir_data_2 inside dir_app back out to dir_data as sibling to dir_app
      run_cmd(sprintf('mv %s %s', dir_data_2, dir_data))
    }
  }

  # get remote branches
  remote_branches = gh_remote_branches(dir_data)

  if (!file.exists(dir_web)){

    # dir_app: copy from dir_data, if needed
    run_cmd(sprintf('cp -rf %s %s', dir_data, dir_web))
  }

  if (!'gh-pages' %in% remote_branches){

    # create orphan gh-pages branch, if needed
    run_cmd(sprintf(
      'cd %s; git checkout -q --orphan %s; rm -rf *; touch README.md; git add README.md; git commit -q -m "initialize %s branch"; git push -q origin %s',
      dir_web, gh_branch_web, gh_branch_web, gh_branch_web))
  } else {

    # checkout gh-pages branch and clear files
    run_cmd(sprintf(
      'cd %s; git fetch -q; git checkout -q %s; git reset -q --hard origin/%s; rm -rf *',
      dir_web, gh_branch_web, gh_branch_web))
  }

  # copy gh-pages web files into dir_web, excluding all files in .gitignore
  run_cmd(
    sprintf(
      'cd %s; rsync -rq \\
      --exclude=_site.brew.R --exclude=_site.brew.yml --exclude=_other/ --exclude=.gitignore \\
      --include=_footer.html --exclude-from=.gitignore \\
      . %s',
      system.file('gh-pages', package='ohirepos'), dir_web))

  # get commit of ohirepos for website provenance
  ohirepos_commit = devtools:::local_sha('ohirepos')
  if (nchar(ohirepos_commit) != 40){
    stop(sprintf(paste(
      'Sorry, the ohirepos R library seems to have not been installed with:',
      '  devtools::install_github("ohi-science/ohirepos")',
      'based on devtools:::local_sha("ohirepos") of %s and not of normal Github commit length 40,',
      'which is necessary to associate the ohirepos commit with the Shiny app deployed.', collapse='\n'), ohirepos_commit))
  }

  # brew _site.* files
  brew(system.file('gh-pages/_site.brew.yml', package='ohirepos'), sprintf('%s/_site.yml', dir_web))
  brew(system.file('gh-pages/_site.brew.R'  , package='ohirepos'), sprintf('%s/_site.R'  , dir_web))

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
    "cd %s; git add --all; git add .gitignore .nojekyll; \\
    git commit -a -m -q 'updating website with ohirepos commit %s'; \\
    git push -q origin gh-pages",
    dir_web, substr(ohirepos_commit, 1, 7))
    )

  # open website
  if (open_url) utils::browseURL(web_url)

  # remove temp files
  cat('rm temp files if del_out==T')
  if (del_out) unlink(dir_branches, recursive=T, force=T)

  # return website
  return(web_url)
}
