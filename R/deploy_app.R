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
#' @param app_server the secure copy (scp) server location given by username@server:/dir/
#' @param run_app run the Shiny app locally
#' @param open_url open the web browser to the app_url
#' @param dir_out top-level directory to use for populating git repo folder and branch subfolders within, defaults to tmpdir()
#' @param del_out whether to delete output directory when done, defaults to TRUE
#' @param dir_server directory on the app_server
#'
#' @return Returns URL of Shiny app if successfully deployed, otherwise errors out. Requires git credentials to push to Github repository,
#' and SSH keys for secure copying to server.
#' Suggestions to update Shiny app:
#' \enumerate{
#'  \item Ensure permissions are set for you and shiny on fitz:
#'  \verb{
#'  ssh jstewart@fitz
#'  sudo chown -R jstewart /srv/shiny-server/ohi-global
#'  sudo chmod -R 775 .
#'  sudo chgrp -R shiny .}
#'  \item Copy your repo to dir_out locally. For example, if input argument \code{dir_out='~/Desktop/ohirepos_tmp'},
#'        copy \code{'~/github/ohi-global'} to \code{dir_out='~/Desktop/ohirepos_tmp/ohi-global/draft'}.
#' }
#' @examples
#' \dontrun{
#' deploy_app('ohi-global', 'Global', c('eez2015','eez2012','eez2013','eez2014','eez2016'), projection='Mollweide')
#' deploy_app(       'bhi', 'Baltic', 'baltic2015')
#' }
#' @import tidyverse yaml devtools
#' @export
deploy_app <- function(
  gh_repo, app_title, scenario_dirs,
  gh_owner='OHI-Science', gh_branch_data='draft', gh_branch_app='app',
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  app_server='jstewart@128.111.84.76', dir_server='/srv/shiny-server',
  projection='Mercator', map_shrink_pct=10,
  run_app=F, open_url=T,
  dir_out=tempdir(), del_out=T){

  library(tidyverse)
  library(yaml)

  # debug ----

  # history: derived from ohi-webapps [create_functions.R#L1045-L1116](https://github.com/OHI-Science/ohi-webapps/blob/723ded3a6e1cfeb0addb3e8d88a3ccf1081daaa3/create_functions.R#L1045-L1116)

  # library(devtools); load_all();
  # gh_repo='bhi'; app_title='Baltic'; scenario_dirs='baltic2015'; projection='Mercator'
  # gh_repo='ohi-global'; app_title='Global'; scenario_dirs=c('eez2015','eez2012','eez2013','eez2014','eez2016'); projection='Mollweide'
  # gh_owner='OHI-Science'; gh_branch_data='draft'; gh_branch_app='app'
  # app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo)
  # app_server='bbest@128.111.84.76'; dir_server='/srv/shiny-server'
  # map_shrink_pct=10
  # run_app=T; open_url=T
  # dir_out='~/Desktop/ohirepos_tmp'; del_out=F

  # library(devtools); load_all(); # library(ohirepos) # devtools::install_github('ohi-science/ohirepos')
  # deploy_app(
  #   'ohi-global', 'Global', c('eez2015','eez2012','eez2013','eez2014','eez2016'), projection='Mollweide',
  #   app_server='bbest@128.111.84.76',
  #   dir_out='~/Desktop/ohirepos_tmp', del_out=F, run_app=T)
  # deploy_app(
  #   'bhi', 'Baltic', 'baltic2015',
  #   app_server='bbest@128.111.84.76',
  #   dir_out='~/Desktop/ohirepos_tmp', del_out=F, run_app=T)
  #
  # jlowndes latest after `mkdir ~/github/clip-n-ship/bhi; cp -rf ~/github/bhi ~/github/clip-n-ship/bhi/draft`
  # deploy_app(
  #   'bhi', 'Baltic', 'baltic2015',
  #   dir_out='~/github/clip-n-ship', del_out=F)
  # ----

  # construct vars
  dir_branches = file.path(dir_out, gh_repo)
  dir_data     = file.path(dir_out, gh_repo, gh_branch_data)
  dir_app      = file.path(dir_out, gh_repo, gh_branch_app)
  dir_data_2   = file.path(dir_out, gh_repo, gh_branch_app, sprintf('%s_%s', gh_repo, gh_branch_data))
  gh_slug      = sprintf('%s/%s', gh_owner, gh_repo)
  gh_url       = sprintf('https://github.com/%s.git', gh_slug)

  # extra bash commands
  rm_allnotgit = 'find . -path ./.git -prune -o -exec rm -rf {} \\; 2> /dev/null'

  # ensure top level dir exists
  dir.create(dir_branches, showWarnings = F, recursive = T)

  run_cmd = function(cmd){
    cat(sprintf('running command:\n  %s\n', cmd))
    system.time(system(cmd))
  }

  # check if app branch dir already exists
  if (file.exists(dir_app)){

    if (file.exists(dir_data_2)){

      # move dir_data_2 inside dir_app back out to dir_data as sibling to dir_app
      run_cmd(sprintf('mv %s %s', dir_data_2, dir_data))
    }
  }

  # data branch: fetch existing, or clone new
  if (!file.exists(dir_data)){

    # clone data branch, shallowly and quietly
    run_cmd(sprintf('git clone -q --depth 1 --branch %s %s %s', gh_branch_data, gh_url, dir_data))
  } else {

    # git fetch & overwrite
    run_cmd(sprintf('cd %s; git fetch -q; git reset -q --hard origin/%s; git checkout -q %s; git pull -q', dir_data, gh_branch_data, gh_branch_data))
  }

  # get remote branches
  remote_branches = gh_remote_branches(dir_data)

  if (!file.exists(dir_app)){

    # dir_app: copy from dir_data, if needed
    run_cmd(sprintf('cp -rf %s %s', dir_data, dir_app))
  }

  if (!'app' %in% remote_branches){

    # create orphan app branch, if needed
    run_cmd(sprintf(
      'cd %s; git checkout -q --orphan %s; rm -rf *; touch README.md; git add README.md; git commit -q -m "initialize %s branch"; git push -q origin %s',
      dir_app, gh_branch_app, gh_branch_app, gh_branch_app))
  }

  if ('app' %in% remote_branches){

    # checkout app branch and clear files
    run_cmd(sprintf(
      'cd %s; git fetch -q; git checkout -q %s; git reset -q --hard origin/%s; rm -rf *',
      dir_app, gh_branch_app, gh_branch_app))
  }

  # copy shiny app files into dir_app, excluding all files in .gitignore
  cat('\ncopying app files from ohirepos package\n')
  run_cmd(
    sprintf(
      'cd %s; rsync -rv --exclude=.git/ --exclude-from=.gitignore . %s',
      system.file('app', package='ohirepos'), dir_app))

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
  cat('\nwriting app.yml')
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

  # add Rstudio project file
  cat('\nwriting Rproj, gitignore files\n')
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

  commands = c(
    # move dir_data to dir_data_2
    sprintf('mv %s %s', dir_data, dir_data_2),
    # prompt restart
    sprintf('touch %s/restart.txt', dir_app),
    # git commit and push to Github
    sprintf(
      "cd %s; git add --all; git commit -q -a -m 'updating app with ohirepos commit %s'; git push -q origin %s",
      dir_app, substr(ohirepos_commit, 1, 7), gh_branch_app),
    # push to server using remote sync recursively (-r), and update permissions so writable by shiny user
    sprintf(
      'cd %s; rsync -r --exclude .git --exclude-from=.gitignore . %s:%s/%s',
      dir_app, app_server, dir_server, gh_repo),
    cat(sprintf('ssh %s "cd %s/%s; chmod -R 775 .; chgrp -R shiny ."', app_server, dir_server, gh_repo))
  )
  for (cmd in commands){ # commands[1:2]
    run_cmd(cmd)
  }

  # run app, local and remote
  cat('run app locally (run_app=T) or remotely (open_url=T)')
  if (run_app)  shiny::runApp(dir_app)
  if (open_url) utils::browseURL(app_url)

  # remove temp files
  cat('rm temp files if del_out==T')
  if (del_out) unlink(dir_branches, recursive=T, force=T)
}
