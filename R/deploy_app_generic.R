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
                       gh_shiny_dir    = NULL,
                       gh_branch_app   = 'master',
                       app_base_url    = 'http://ohi-science.nceas.ucsb.edu',
                       app_name_remote = NULL,
                       app_server, #      = 'jstewart@128.111.84.76',
                       dir_server      = '/srv/shiny-server',
                       run_local       = FALSE,
                       open_url        = TRUE,
                       dir_out         = tempdir(),
                       del_out         = TRUE) {

  # gh_organization <- 'OHI-Science'; gh_repo <- 'IUCN-Aquamaps'; gh_shiny_dir <- 'shiny_am_iucn'
  # gh_branch_app   <- 'master'; app_base_url    <- 'http://ohi-science.nceas.ucsb.edu'; app_name_remote <- 'marine_maps'
  # app_server <- 'ohara@fitz.nceas.ucsb.edu'; dir_server <- '/srv/shiny-server';
  # run_local <- FALSE; open_url <- TRUE; dir_out <- tempdir(); del_out <- TRUE

  ### TO DO:
  ### * check installed packages on Fitz
  ### * check required packages in scripts
  ### * if required packages are missing, report back so Nick can install 'em

  library(tidyverse)
  library(yaml)


  ################################################.
  ##### construct local and remote locations #####
  dir_branches <- file.path(dir_out, gh_repo)
    ### local repo location; this will get deleted at the end of the function
    ### if del_out == TRUE
  dir_repo_local <- file.path(dir_out, gh_repo, gh_branch_app)
    ### local folder to copy the repo into
  dir_app_local  <- file.path(dir_repo_local, gh_shiny_dir)
    ### local folder where the app files reside
  gh_url <- sprintf('https://github.com/%s/%s.git', gh_organization, gh_repo)
    ### url of the repo from which app will be pulled

  if(is.null(app_name_remote)) {
    dir_app_remote <- file.path(gh_repo, gh_shiny_dir)
      ### the folder on Fitz where the shiny app will reside; if no explicit
      ### name is given, will default to the repo name/shiny folder name
  } else {
    dir_app_remote <- app_name_remote
  }

  app_url <- file.path(app_base_url, dir_app_remote)



  ###################################################.
  ##### fetch app from GitHub location to local #####
  # ensure top level dir exists for local copy
  dir.create(dir_repo_local, showWarnings = FALSE, recursive = TRUE)

  run_cmd <- function(cmd){
    message('running command:\n  ', cmd)
    message('...elapsed time: ', system.time(system(cmd))[3] %>% round(3), ' sec')
  }

  # data branch: fetch existing, or clone new if app isn't in local repo copy
  if (!file.exists(dir_app_local)){
    # clone app branch, shallowly and quietly
    run_cmd(sprintf('git clone -q --depth 1 --branch %s %s %s', gh_branch_app, gh_url, dir_repo_local))
  } else {
    # git fetch & overwrite
    run_cmd(sprintf('cd %s; git fetch -q; git reset -q --hard origin/%s; git checkout -q %s; git pull -q',
                    dir_repo_local, gh_branch_app, gh_branch_app))
  }


  #######################################.
  ##### write app.yml configuration #####
  ### Determine required packages from library() or require() in any R scripts
  script_files <- list.files(dir_app_local, pattern = '\\.R$|\\.r$', full.names = TRUE)
  pkgs_rqd <- lapply(script_files, FUN = function(x) {
      grep("library|require", readLines(x), value = TRUE) %>%
        stringr::str_extract('(?<=\\().*?(?=\\))')
    }) %>%
    unlist() %>%
    unique()

  message('...writing app.yml')
  write_file(
    as.yaml(list(
      gh_organization = gh_organization,
      gh_repo         = gh_repo,
      gh_shiny_dir    = gh_shiny_dir,
      gh_branch_app   = gh_branch_app,
      app_url         = app_url,
      debug           = FALSE,
      pkgs_required   = paste(pkgs_rqd, collapse = ', '),
      last_updated    = Sys.Date())),
    file.path(dir_repo_local, 'app.yml'))

  ######################################################.
  ##### Check that required packages are installed #####
  pkg_check <- sprintf("ssh %s Rscript -e 'installed.packages\\(\\)[,1]'", app_server)
  pkgs_installed <- system(pkg_check, intern = TRUE) %>%
    stringr::str_split('[\\" ]+') %>%
    unlist() %>%
    unique()

  pkgs_missing <- pkgs_rqd[!pkgs_rqd %in% pkgs_installed]
  if(length(pkgs_missing) > 0) {
    message('The following required packages are not installed on the remote server:')
    message('  ', paste(pkgs_missing, collapse = ', '))
    message('Contact the remote server admin to install those packages.')
  }

  #############################################.
  ##### copy app files from local to Fitz #####
  cmds <- c(
    sprintf('cd %s; rsync -rq --exclude .git %s:%s/%s',
            dir_app_local,                   app_server, dir_server, dir_app_remote) # ,
    # cat(sprintf('ssh %s "cd %s/%s; chmod -R 775 .; chgrp -R shiny ."', app_server, dir_server, gh_repo))
  )
  for (cmd in cmds){
    run_cmd(cmd)
  }


  # run app, local and remote
  message('run app locally (run_app = TRUE) or remotely (open_url = TRUE)')
  if (open_url)  utils::browseURL(app_url)
  if (run_local) shiny::runApp(dir_app_local)

  # remove temp files
  message('rm temp files if del_out == TRUE')
  if (del_out) unlink(dir_branches, recursive = TRUE, force = TRUE)
}
