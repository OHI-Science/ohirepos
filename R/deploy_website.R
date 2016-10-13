#' Deploy website to gh-pages branch in Github repository
#'
#' @param gh_repo Github repository
#' @param web_title title for the website, which is typically the study area or place name
#' @param scenario_dir subfolder from data branch of repo that will be the default scenario to display on website
#' @param gh_owner Github owner. Defaults to "OHI-Science".
#' @param gh_branch_data Github branch containing data. Defaults to "draft" and must already exist in the repo.
#' @param app_url URL of Shiny application that gets embedded as iframe
#' @param open_url open the web browser to the web_url
#' @param debug debugging flag
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
  open_url=FALSE, debug=FALSE){

  # debug ----

  # history: from ohi-webapps, create_gh_repo.r https://github.com/OHI-Science/ohirepos/blob/07110dacad98fcc0a0080ca8f5ab248ae46e7f51/R/create_gh_repo.r

  # library(devtools); load_all();
  # gh_repo='bhi'       ; web_title='Baltic'; scenario_dir='baltic2015'
  # gh_repo='ohi-global'; web_title='Global'; scenario_dir='eez2015'
  # debug=T; gh_owner='OHI-Science'; gh_branch_data='draft'; app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo); open_url=T

  # library(ohirepos) # devtools::install_github('ohi-science/ohirepos')
  # deploy_website('ohi-global', 'Global', 'eez2015')
  # deploy_website('bhi',        'Baltic', 'baltic2015')

  # ----

  library(tidyverse)
  library(yaml)
  library(brew)

  # use temporary directory
  if (debug){
    dir_tmp = '/var/folders/pj/l9cfhbn97xbcgqx6qyx0lr800000gn/T//Rtmp9FeM5e'
  } else {
    dir_tmp = tempdir()
  }

  # construct vars
  web_url       = sprintf('http://%s.github.io/%s', gh_owner, gh_repo)
  gh_branch_web = 'gh-pages'
  dir_branches  = file.path(dir_tmp, gh_repo)
  dir_data      = file.path(dir_tmp, gh_repo, gh_branch_data)
  dir_web       = file.path(dir_tmp, gh_repo, gh_branch_web)
  dir_data_2    = file.path(dir_tmp, gh_repo, gh_branch_web, sprintf('%s_%s', gh_repo, gh_branch_data))
  dir_scenario  = sprintf('%s_%s/%s', gh_repo, gh_branch_data, scenario_dir)
  gh_slug       = sprintf('%s/%s', gh_owner, gh_repo)
  gh_url        = sprintf('https://github.com/%s.git', gh_slug)

  # delete existing, if not in debug mode
  if (!debug){
    # clear existing
    if (file.exists(dir_branches)) unlink(dir_branches, recursive = T)

    # clone data branch, shallowly and quietly
    dir.create(dir_branches, showWarnings = F)
    system(sprintf('git clone --quiet --depth 1 --branch %s %s %s', gh_branch_data, gh_url, dir_data))
  }

  # get remote branches
  remote_branches = gh_remote_branches(dir_data)

  # create/clear app branch
  if (!'gh-pages' %in% remote_branches){

    # create orphan app branch
    system(sprintf(
      'cp -rf %s %s; cd %s; git checkout --orphan %s; git rm -rf .; touch README.md; git add README.md; git commit -m "initialize %s branch"',
      dir_data, dir_web, dir_web, gh_branch_web, gh_branch_web))

  } else {

    # clone app branch, clear existing files
    system(sprintf(
      'git clone --quiet --depth 1 --branch %s %s %s; cd %s; git rm -rf .', gh_branch_web, gh_url, dir_web, dir_web))

  }

  # copy gh-pages web files into dir_web
  # debug: system(sprintf('cd %s; rm -rf *', dir_web))
  suppressWarnings(file.copy(system.file('gh-pages', package='ohirepos'), dir_branches, recursive=T, overwrite=T))

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
  unlink(sprintf('%s/_site.brew.%s', dir_web, c('yml','R')))

  # add Rstudio project file
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s/%s.Rproj', dir_web, gh_repo))

  # ensure .nojekyll file per http://rmarkdown.rstudio.com/rmarkdown_websites.html#publishing_websites
  system(sprintf('touch %s/.nojekyll', dir_web))

  # add gitignore file
  writeLines(c(
    '.Rproj.user', '.Rhistory', '.RData', 'rsconnect', '.DS_Store',
    sprintf('%s_%s', gh_repo, gh_branch_data)                # [repo]_[branch]/
  ), file.path(dir_web, '.gitignore'))

  # move dir_data to dir_data_2
  system(sprintf('mv %s %s', dir_data, dir_data_2))

  # render website
  rmarkdown::render_site(dir_web)

  # git commit and push to Github
  # DEBUG BHI: system(sprintf("dir_web=%s;cd ~github/bhi2; cp -R $dir_web/ ~/github/bhi2/; git add *; git commit -a -m 'updating app with ohihrepos commit %s'; git push", dir_web, substr(ohirepos_commit, 1, 7)))
  #   Doh! copied over bhi2/.git with bhi's .git
  system(sprintf("cd %s; git add *; git add .gitignore .nojekyll; git commit -a -m 'updating website with ohirepos commit %s'; git push origin gh-pages", dir_web, substr(ohirepos_commit, 1, 7)))

  # open website
  if (open_url) utils::browseURL(web_url)

  # return website
  return(web_url)
}
