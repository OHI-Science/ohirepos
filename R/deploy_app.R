#' Deploy Shiny application
#'
#' @param gh_repo Github repository.
#' @param default_scenario The subfolder of the data branch which will be the default scenario of data displayed.
#' @param app_title The title for the app, which is typically the study area or place name.
#' @param gh_owner Github owner. Defaults to "OHI-Science".
#' @param gh_branch_data Github branch containing data. Defaults to "draft" and must already exist in the repo.
#' @param gh_branch_app Github branch to contain the app. Defaults to "app" and does not have to already exist in the repo.
#' @param app_url URL of the application
#' @param debug
#'
#' @return Returns URL of Shiny app if successfully deployed, otherwise errors out.
#' @examples
#' \dontrun{
#' deploy_app("bhi")
#' }
#' @import tidyverse devtools brew
#' @export
deploy_app <- function(
  gh_repo, default_scenario, app_title, gh_owner='OHI-Science',
  gh_branch_data='draft', gh_branch_app='app',
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  debug=F){

  library(tidyverse)

  # library(devtools); load_all(); debug=T;
  # gh_repo='bhi'; default_scenario='baltic2015'; app_title='Baltic'; gh_owner='OHI-Science'; gh_branch_data='draft'; gh_branch_app='app'; app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo)
  # gh_repo='ohi-global'; default_scenario='eez2015'; app_title='Global'; gh_owner='OHI-Science'; gh_branch_data='draft'; gh_branch_app='app'; app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo)

  # Copied from https://github.com/OHI-Science/ohi-webapps/blob/723ded3a6e1cfeb0addb3e8d88a3ccf1081daaa3/create_functions.R#L1045-L1116

  # old ----
  #key <<- key # assign key to the global namespace so available for other functions
  #source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))
  # delete old
  #dir_app_old <- sprintf('%s/git-annex/clip-n-ship/%s/shinyapps.io', dir_neptune, git_repo)
  #unlink(dir_app_old, recursive=T)

  # use temporary directory
  if (debug){
    tmpdir = '/var/folders/pj/l9cfhbn97xbcgqx6qyx0lr800000gn/T//Rtmpp9mCyh'
  } else {
    tmpdir = tempdir()
  }

  # construct vars
  dir_branches = file.path(tmpdir, gh_repo)
  dir_data     = file.path(tmpdir, gh_repo, gh_branch_data)
  dir_app      = file.path(tmpdir, gh_repo, gh_branch_app)
  dir_data_2   = file.path(tmpdir, gh_repo, gh_branch_app, gh_branch_data)
  gh_slug      = file.path('%s/%s', gh_owner, gh_repo)
  gh_url       = sprintf('https://github.com/%s.git', gh_slug)

  # extra bash commands
  rm_allnotgit = 'find . -path ./.git -prune -o -exec rm -rf {} \\; 2> /dev/null'

  # delete existing, if not in debug mode
  if (!debug){
    # clear existing
    if (file.exists(dir_branches)) unlink(dir_branches, recursive = T)

    # clone data branch, shallowly and quietly
    system(sprintf('git clone --quiet --depth 1 --branch %s %s %s', gh_branch_data, gh_url, dir_data))
  }

  # get remote branches
  remote_branches = read_tsv(
    paste(system(
      sprintf('cd %s;git ls-remote --heads origin', dir_data),
      intern=T), collapse='\n'),
    col_names=c('sha','ref')) %>%
    mutate(
      repo = stringr::str_replace(ref, 'refs/heads/', '')) %>%
    .$repo

  # create/clear app branch
  if (!'app' %in% remote_branches){

    # create orphan app branch
    system(sprintf(
      'cp -rf %s %s; cd %s; git checkout --orphan %s; rm -rf *; touch README.md; git add README.md; git commit -m "initialize %s branch"',
      dir_data, dir_app, dir_app, gh_branch_app, gh_branch_app))

  } else {

    # clone app branch, clear existing files
    system(sprintf(
      'git clone --quiet --depth 1 --branch %s %s %s; cd %s; rm -rf *', gh_branch_app, gh_url, dir_app, dir_app))

  }

  # copy shiny app files into dir_app
  suppressWarnings(file.copy(system.file('app', package='ohirepos'), dir_branches, recursive=T, overwrite=T))

  # get commit of ohirepos for Shiny app provenance
  ohirepos_commit = devtools:::local_sha('ohirepos')
  if (nchar(ohirepos_commit) != 40){
    stop(sprintf(paste(
      'Sorry, the ohirepos R library seems to have not been installed with:',
      '  devtools::install_github("ohi-science/ohirepos")',
      'based on devtools:::local_sha("ohirepos") of %s and not of normal Github commit length 40,',
      'which is necessary to associate the ohirepos commit with the Shiny app deployed.', collapse='\n'), ohirepos_commit))
  }
  # TODO: OLD -> NEW variable assignment
  # git_owner  = gh_owner       # 'jules32', #g[['GithubUsername']],   ## generalize-- DESCRIPTION not found...
  # git_repo   = gh_repo        # 'gye', # g[['GithubRepo']],
  # git_branch = gh_branch_data # 'draft', # g[['GithubRef']],
  # git_commit = gh_commit      # 'initial commit')) #g[['GithubSHA1']]))

  # ohicore_app=list(
  #   git_owner  = gh_owner,       # 'jules32', #g[['GithubUsername']],   ## generalize-- DESCRIPTION not found...
  #   git_repo   = gh_repo,        # 'gye', # g[['GithubRepo']],
  #   git_branch = gh_branch_data, # 'draft', # g[['GithubRef']],
  #   git_commit = gh_commit,      # 'initial commit')) #g[['GithubSHA1']]))
  #   ohirepos_commit = ohirepos_commit)
  # TODO: use ohirepos_commit to stamp which version of ohirepos was used to last modify the shiny app

  # brew app.yml configuration and introduction files, and delete brew templates
  brew(system.file('app/app.brew.yml' , package='ohirepos'), file.path(dir_app, 'app.yml'))
  brew(system.file('app/intro.brew.md', package='ohirepos'), file.path(dir_app, 'intro.md'))
  unlink(sprintf('%s/%s', dir_app, c('app.brew.yml','intro.brew.md')))

  # TODO: Travis?
  #brew::brew(system.file('app/travis.brew.yml', package='ohirepos'), file.path(dir_app, 'travis.yml'))

  # add Rstudio project and gitignore files
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s/%s.Rproj', dir_app, gh_repo))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData', gh_branch_data), file.path(dir_app, '.gitignore'))

  # TODO finish up from 2016-09-29.... ----

  # TODO next: move dir_data to dir_data_2

  # shiny::runApp()    # test app locally

  # clean up cloned / archived repos which get populated if testing app
  unlink(git_repo, recursive=T, force=T)
  unlink('github', recursive=T, force=T)

  # deploy
  # Error: You must register an account using setAccountInfo prior to proceeding. Sign in to shinyapps.io via Github as bbest, Settings > Tokens to use setAccountInfo('ohi-science',...). March 16 Error: did as above. In console: shinyapps::setAccountInfo(name='jules32', token='...', secret='...')
  deployApp(appDir='.', appName=app_name, upload=T, launch.browser=T, lint=F) # Change this with Nick Brand
  # copying over ssh to the server with Nick Brand. From terminal
  # rm first (rsync would be able to delete stuff that's missing)
  # scp -r gye jstewart@fitz:/srv/shiny-server/ # scp is how to copy over ssh,  -r is recursive

  # push files to github app branch
  system('git add -A; git commit -a -m "deployed app"')
  push_branch('app')
  system('git fetch')
  system('git branch --set-upstream-to=origin/app app')

  # restore wd
  setwd(wd)
}
