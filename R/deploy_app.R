#' Deploy Shiny application
#'
#' @param gh_repo Github repository.
#' @param gh_owner Github owner. Defaults to "OHI-Science"
#' @return Returns URL of Shiny app if successfully deployed, otherwise errors out.
#' @examples
#' \dontrun{
#' deploy_app("bhi")
#' }
#' @import git2r
#' @export
deploy_app <- function(gh_repo, gh_owner='OHI-Science', gh_branch_data='draft', gh_branch_app='app', debug=F){
  # gh_repo='bhi'; gh_owner='OHI-Science'; gh_branch_data='draft'; gh_branch_app='app'; debug=F

  library(tidyverse)
  library(git2r)

  # Copied from https://github.com/OHI-Science/ohi-webapps/blob/723ded3a6e1cfeb0addb3e8d88a3ccf1081daaa3/create_functions.R#L1045-L1116

  #key <<- key # assign key to the global namespace so available for other functions
  #source(file.path(dir_github, 'ohi-webapps/create_init_sc.R'))

  # delete old
  #dir_app_old <- sprintf('%s/git-annex/clip-n-ship/%s/shinyapps.io', dir_neptune, git_repo)
  #unlink(dir_app_old, recursive=T)

  # use temporary directory
  if (debug){
    tmpdir = '/var/folders/pj/l9cfhbn97xbcgqx6qyx0lr800000gn/T//RtmpnHDDDD/'
  } else {
    tmpdir = tempdir()
  }

  # construct vars
  dir_branches = sprintf('%s/%s'   , tmpdir, gh_repo)
  dir_data     = sprintf('%s/%s/%s', tmpdir, gh_repo, gh_branch_data)
  dir_app      = sprintf('%s/%s/%s', tmpdir, gh_repo, gh_branch_app)
  gh_url = sprintf('https://github.com/%s/%s.git', gh_owner, gh_repo)

  # delete existing, if not in debug mode
  if (!debug){
    if (file.exists(dir_repo)) unlink(dir_branches, recursive = T)
    dir.create(dir_branches)
  }

  # clone data branch, shallowly and quietly
  system(sprintf('git clone --quiet --depth 1 --branch %s %s %s', gh_branch_data, gh_url, dir_data))

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
      'cp -rf %s %s; cd %s; git checkout --orphan app; rm -rf *; touch README.md; git add README.md; git commit -m "initialize app branch"',
      dir_data, dir_app, dir_app))

  } else {

    # clear existing app branch
    system(sprintf(
      'cp -rf %s %s; cd %s; git checkout app; rm -rf *',
      dir_data, dir_app, dir_app))
  }

  # copy installed ohicore shiny app files
  # good to have latest dev ohicore first:
  devtools::install_github('ohi-science/ohicore@dev')  # update by JSL March 19. Could cause problems since need to make sure pulled latest version
  dir_ohicore_app = '~/github/ohicore/inst/shiny_app' #file.path(system.file(package='ohicore'), 'shiny_app') #
  shiny_files = list.files(dir_ohicore_app, recursive=T)
  for (f in shiny_files){ # f = shiny_files[1]
    dir.create(dirname(f), showWarnings=F, recursive=T)
    suppressWarnings(file.copy(file.path(dir_ohicore_app, f), f, overwrite=T, recursive=T, copy.mode=T, copy.date=T))
  }

  # get commit version of ohicore app files
  lns = readLines(file.path(dir_ohicore_app, '../../DESCRIPTION'))
  g = sapply(str_split(lns[grepl('^Github', lns)], ': '), function(x) setNames(x[2], x[1]))
  #ohicore_app_commit = sprintf('%s/%s@%s,%.7s', g[['GithubUsername']], g[['GithubRepo']], , g[['GithubSHA1']])
  ohicore_app = list(ohicore_app=list(
    git_owner  = 'jules32', #g[['GithubUsername']],   ## generalize-- DESCRIPTION not found...
    git_repo   = 'gye', # g[['GithubRepo']],
    git_branch = 'draft', # g[['GithubRef']],
    git_commit = 'initial commit')) #g[['GithubSHA1']]))

  brew(file.path(dir_github, 'ohi-webapps/app.brew.yml'), 'app.yml')
  file.copy(file.path(dir_github, 'ohi-webapps/travis_app.yml'), '.travis.yml') # overwrite=T)

  # add Rstudio project files. cannabalized devtools::add_rstudio_project() which only works for full R packages.
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s.Rproj', key))
  writeLines(c('.Rproj.user', '.Rhistory', '.RData', 'github', git_repo), '.gitignore')

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
