#' Deploy Shiny application
#'
#' @param gh_organization Github organization. Defaults to "OHI-Science".
#' @param gh_repo Github repository
#' @param gh_branch_app Github branch that contains the app. Defaults to "master" and
#' does not have to already exist in the repo.
#' @param app_url URL of the application
#' @param app_server the secure copy (scp) server location given by username@server:/dir/
#' @param run_app run the Shiny app locally
#' @param open_url open the web browser to the app_url
#' @param dir_out top-level directory to use for populating git repo folder
#'   and branch subfolders within, defaults to tmpdir()
#' @param del_out whether to delete output directory when done, defaults to TRUE
#' @param dir_server directory on the app_server
#' @param gh_data_commit commit of gh_branch_data for freezing the app,
#'   ie do not automatically update
#'
#' @return Returns URL of Shiny app if successfully deployed, otherwise errors
#'   out. Requires git credentials to push to Github repository,
#' and SSH keys for secure copying to server.
#' Suggestions to update Shiny app:
#' \enumerate{
#'  \item Ensure permissions are set for you and shiny on fitz:
#'        \verb{ssh jstewart@fitz
#'              sudo chown -R jstewart /srv/shiny-server/ohi-global
#'              sudo chmod -R 775 .
#'              sudo chgrp -R shiny .}
#'  \item Copy your repo to dir_out locally. For example, if input
#'        argument \code{dir_out = '~/Desktop/ohirepos_tmp'},
#'        copy \code{'~/github/ohi-global'}
#'        to \code{dir_out = '~/Desktop/ohirepos_tmp/ohi-global/draft'}.
#' }
#'  Please also visit
#' \link[=https://github.com/OHI-Science/ohirepos/blob/master/inst/app/README.md]{app/README.md}
#'   for more details.
#'
#' @examples
#' \dontrun{
#' deploy_app('ohi-global', 'Global', c('eez2015','eez2012','eez2013','eez2014','eez2016'),
#'   projection = 'Mollweide')
#' deploy_app(       'bhi', 'Baltic', 'baltic2015')
#' }
#' @import tidyverse yaml devtools
#' @export

deploy_app <- function(gh_organization = 'OHI-Science',
                       gh_repo,
                       gh_shiny_dir   = '',
                       gh_branch_app  = 'app',
                       gh_data_commit = NULL,
                       app_url    = sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
                       app_server = 'jstewart@128.111.84.76',
                       dir_server = '/srv/shiny-server',
                       run_local  = FALSE,
                       open_url   = TRUE,
                       dir_out    = tempdir(),
                       del_out    = TRUE) {

  ### QUESTIONS:
  ### * How to make sure the app directory on Fitz matches the app directory
  ###   in GitHub but without the intervening folders?
  ### * the original version takes the repo name and uses that for the app name
  ### * the new version takes the shiny_dir basename and uses that for the app name;
  ###   if shiny_dir = '' (or NULL?) use the repo name instead.

  library(tidyverse)
  library(yaml)

  ### construct locations
  dir_branches <- file.path(dir_out, gh_repo)
  ### base repo location, where .Rproj goes?
  dir_app      <- file.path(dir_out, gh_repo, gh_branch_app, gh_shiny_dir)
  ### folder for shiny app files
  gh_slug      <- sprintf('%s/%s', gh_organization, gh_repo)
  gh_url       <- sprintf('https://github.com/%s.git', gh_slug)

  # # extra bash commands
  ### NOT USED
  # rm_allnotgit <- 'find . -path ./.git -prune -o -exec rm -rf {} \\; 2> /dev/null'

  # ensure top level dir exists for local copy
  dir.create(dir_branches, showWarnings = FALSE, recursive = TRUE)

  run_cmd <- function(cmd){
    message('running command:\n  ', cmd)
    message('...elapsed time: ', system.time(system(cmd))[3], ' sec')
  }

  ### NO DATA BRANCH - ditch this stuff
  # data branch: fetch existing, or clone new
  if (!file.exists(dir_app)){
    # clone app branch, shallowly and quietly
    run_cmd(sprintf('git clone -q --depth 1 --branch %s %s %s', gh_branch_app, gh_url, dir_app))
  } else {
    # git fetch & overwrite
    run_cmd(sprintf('cd %s; git fetch -q; git reset -q --hard origin/%s; git checkout -q %s; git pull -q', dir_data, gh_branch_data, gh_branch_data))
  }

  # # get remote branches
  # remote_branches <- gh_remote_branches(dir_data) # @oharac: = 'master'

  # if (!file.exists(dir_app)){
  #   # dir_app: copy from dir_data, if needed
  #   run_cmd(sprintf('cp -rf %s %s', dir_data, dir_app))
  # }

  # if (!'app' %in% remote_branches){
  #   # create orphan app branch, if needed
  #   run_cmd(sprintf(
  #     'cd %s; git checkout -q --orphan %s; rm -rf *; touch README.md; git add README.md; git commit -q -m "initialize %s branch"; git push -q origin %s',
  #     dir_app, gh_branch_app, gh_branch_app, gh_branch_app))
  # } else {

  # checkout app branch and clear files
  run_cmd(sprintf(
    'cd %s; git fetch -q; git checkout -q %s; git reset -q --hard origin/%s; rm -rf *',
    dir_app,                        gh_branch_app,                gh_branch_app))
  # }

  # copy shiny app files into dir_app, excluding all files in .gitignore
  run_cmd(sprintf(
    'cd %s; rsync -rq --exclude=.git/ --exclude-from=.gitignore . %s',
    system.file('app', package = 'ohirepos'),                 dir_app)
  )

  ### let's skip shiny app provenance
  # get commit of ohirepos for Shiny app provenance
  # ohirepos_commit <- devtools:::local_sha('ohirepos')
  # if (nchar(ohirepos_commit) != 40){
  #   stop(sprintf(paste(
  #     'Sorry, the ohirepos R library seems to have not been installed with:',
  #     '  devtools::install_github("ohi-science/ohirepos")',
  #     'based on devtools:::local_sha("ohirepos") of %s and not of normal Github commit length 40,',
  #     'which is necessary to associate the ohirepos commit with the Shiny app deployed.', collapse = '\n'), ohirepos_commit))
  # }

  # write app.yml configuration
  message('...writing app.yml')
  write_file(
    as.yaml(list(
      gh_organization = gh_organization,
      gh_repo         = gh_repo,
      gh_shiny_dir    = gh_shiny_dir,
      gh_branch_app   = gh_branch_app,
      app_url         = app_url,
      debug           = FALSE,
      last_updated    = Sys.Date())),
    file.path(dir_app, 'app.yml'))

  # add Rstudio project file
  message('...writing Rproj, gitignore files')
  file.copy(system.file('templates/template.Rproj', package = 'devtools'),
            sprintf('%s/%s.Rproj', dir_app, gh_repo))

  # add gitignore file
  writeLines(c(
    '.Rproj.user', '.Rhistory', '.RData', 'rsconnect', '.DS_Store',
    basename(dir_data_2),                                     # [repo]_[branch]/
    sprintf('%s_%s.Rdata', gh_repo, scenario_dirs),           # [repo]_[scenario].Rdata
    sprintf('%s_%s_remote_sha.txt', gh_repo, gh_branch_data)  # [repo]_[scenario]_remote_sha.txt
  ), file.path(dir_app, '.gitignore'))

  # TODO: Travis?
  #brew::brew(system.file('app/travis.brew.yml', package = 'ohirepos'), file.path(dir_app, 'travis.yml'))

  commands <- c(
    # # copy dir_data to dir_data_2
    # sprintf('cd %s; rsync -rq ./ %s', dir_data, dir_data_2),
    # prompt restart
    sprintf('touch %s/restart.txt', dir_app),
    # git commit and push to Github
    sprintf(
      "cd %s; git add --all; git commit -q -a -m 'updating app with ohirepos commit %s'; git push -q origin %s",
      dir_app, substr(ohirepos_commit, 1, 7), gh_branch_app),
    # push to server using remote sync recursively (-r), and update permissions so writable by shiny user
    sprintf(
      'cd %s; rsync -rq --exclude .git --exclude-from=.gitignore . %s:%s/%s',
      dir_app, app_server, dir_server, gh_repo),
    cat(sprintf('ssh %s "cd %s/%s; chmod -R 775 .; chgrp -R shiny ."', app_server, dir_server, gh_repo))
  )
  for (cmd in commands){ # cmd <- commands[3]
    run_cmd(cmd)
  }

  # run app, local and remote
  message('run app locally (run_app = TRUE) or remotely (open_url = TRUE)')
  if (open_url) utils::browseURL(app_url)
  if (run_app)  shiny::runApp(dir_app)

  # remove temp files
  message('rm temp files if del_out == T')
  if (del_out) unlink(dir_branches, recursive = TRUE, force = TRUE)
}
