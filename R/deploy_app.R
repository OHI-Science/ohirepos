#' Deploy Shiny application
#'
#' @param gh_repo Github repository
#' @param scenario_dirs character vector of subfolders from the data branch that will be scenarios available for display. The first one will become the default viewed.
#' @param app_title title for the app, which is typically the study area or place name
#' @param gh_owner Github owner. Defaults to "OHI-Science".
#' @param gh_branch_data Github branch containing data. Defaults to "draft" and must already exist in the repo.
#' @param gh_branch_app Github branch to contain the app. Defaults to "app" and does not have to already exist in the repo.
#' @param app_url URL of the application
#' @param projection defaults to Mercator, or could be specified as Mollweide, which may be more appropriate for global results
#' @param map_shrink_pct percentage of shrinkage to apply to study area for default map view
#' @param debug produces a Message box with various debug outputs to evaluate reactivity of the app
#' @param app_server the secure copy (scp) server location given by username@server:/dir/
#' @param run_app run the Shiny app locally
#' @param open_url open the web browser to the app_url
#'
#' @return Returns URL of Shiny app if successfully deployed, otherwise errors out. Requires git credentials to push to Github repository,
#' and SSH keys for secure copying to server.
#' @examples
#' \dontrun{
#' deploy_app('ohi-global', 'Global', c('eez2015','eez2012','eez2013','eez2014','eez2016'), projection='Mollweide')
#' deploy_app(       'bhi', 'Baltic', 'baltic2015')
#' }
#' @import tidyverse yaml devtools brew
#' @export
deploy_app <- function(
  gh_repo, app_title, scenario_dirs,
  gh_owner='OHI-Science', gh_branch_data='draft', gh_branch_app='app',
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  app_server='jstewart@fitz.nceas.ucsb.edu:/srv/shiny-server/',
  projection='Mercator', map_shrink_pct=10,
  run_app=F, open_url=T, debug=F){

  library(tidyverse)
  library(yaml)
  library(brew)

  # debug ----

  # history: derived from ohi-webapps [create_functions.R#L1045-L1116](https://github.com/OHI-Science/ohi-webapps/blob/723ded3a6e1cfeb0addb3e8d88a3ccf1081daaa3/create_functions.R#L1045-L1116)

  # library(devtools); load_all();
  # gh_repo='bhi'       ; app_title='Baltic'; projection='Mercator';  scenario_dirs='baltic2015'
  # gh_repo='ohi-global'; app_title='Global'; projection='Mollweide'; scenario_dirs=c('eez2015','eez2012','eez2013','eez2014','eez2016')
  # gh_owner='OHI-Science'; gh_branch_data='draft'; gh_branch_app='app'; app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo)
  # debug=T; run_app=T; open_url=T; map_shrink_pct=10; app_server='bbest@fitz.nceas.ucsb.edu:/srv/shiny-server/'

  # library(ohirepos) # devtools::install_github('ohi-science/ohirepos')
  # deploy_app('ohi-global', 'Global', c('eez2015','eez2012','eez2013','eez2014','eez2016'), projection='Mollweide', app_server='bbest@fitz.nceas.ucsb.edu:/srv/shiny-server/')
  # deploy_app(       'bhi', 'Baltic', 'baltic2015', app_server='bbest@fitz.nceas.ucsb.edu:/srv/shiny-server/')

  # ----

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
  dir_data_2   = file.path(tmpdir, gh_repo, gh_branch_app, sprintf('%s_%s', gh_repo, gh_branch_data))
  gh_slug      = sprintf('%s/%s', gh_owner, gh_repo)
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
  remote_branches = gh_remote_branches(dir_data)

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

  # write app.yml configuration
  write_file(
    as.yaml(list(
      gh_repo         = gh_repo,
      app_title       = app_title,
      scenario_dirs   = scenario_dirs,
      gh_owner        = gh_owner,
      gh_branch_data  = gh_branch_data,
      gh_branch_app   = gh_branch_app,
      app_url         = app_url,
      projection      = projection,
      map_shrink_pct  = map_shrink_pct,
      debug           = F,
      ohirepos_commit = ohirepos_commit,
      last_updated    = Sys.Date())),
    file.path(dir_app, 'app.yml'))

  # brew intro.md
  brew(system.file('app/intro.brew.md', package='ohirepos'), sprintf('%s/%s_intro.md', dir_app, gh_repo))

  # cleanup unused files
  unlink(sprintf('%s/%s', dir_app, c('intro.brew.md')))

  # add Rstudio project file
  file.copy(system.file('templates/template.Rproj', package='devtools'), sprintf('%s/%s.Rproj', dir_app, gh_repo))

  # add gitignore file
  writeLines(c(
    '.Rproj.user', '.Rhistory', '.RData', 'rsconnect', '.DS_Store',
    sprintf('%s_%s.Rdata', gh_repo, scenario_dirs),           # [repo]_[scenario].Rdata
    sprintf('%s_%s', gh_repo, gh_branch_data),                # [repo]_[branch]/
    sprintf('%s_%s_remote_sha.txt', gh_repo, gh_branch_data)  # [repo]_[scenario]_remote_sha.txt
    ), file.path(dir_app, '.gitignore'))

  # TODO: Travis?
  #brew::brew(system.file('app/travis.brew.yml', package='ohirepos'), file.path(dir_app, 'travis.yml'))

  # move dir_data to dir_data_2
  system(sprintf('mv %s %s', dir_data, dir_data_2))

  # prompt restart
  system(sprintf('touch %s/restart.txt', dir_app))

  # git commit and push to Github
  system(sprintf("cd %s; git add *; git commit -a -m 'updating app with ohihrepos commit %s'; git push", dir_app, substr(ohirepos_commit, 1, 7)))

  # push to server using secure copy (scp) recursively (-r), and update permissions so writable by shiny user
  system(sprintf('scp -r %s %s%s/', dir_app, app_server, gh_repo))
  system(sprintf('ssh bbest@fitz.nceas.ucsb.edu "cd /srv/shiny-server/%s; chmod -R 775 ."', gh_repo))

  # run app, local and remote
  if (run_app)  shiny::runApp(dir_app)
  if (open_url) utils::browseURL(app_url)

  # remove temp files
  if (!debug) unlink(dir_branches, recursive=T, force=T)
}
