#' Deploy bookdown to gh-pages branch in Github repository
#'
#' @param gh_repo Github repository
#' @param gh_owner Github owner. Defaults to "OHI-Science".
#' @param gh_branch_data Github branch containing data. Defaults to "draft" and must already exist in the repo.
#' @param open_url open the web browser to the web_url
#' @param dir_out top-level directory to use for populating git repo folder and branch subfolders within, defaults to tmpdir()
#' @param del_out whether to delete output directory when done, defaults to TRUE

#' @return Returns web_url (http://[gh_owner].github.io/[gh_repo]) based on creating or
#' updating gh-pages branch of Github repository. Please also visit
#' \link[=https://github.com/OHI-Science/ohirepos/blob/master/inst/gh-pages/README.md]{gh-pages/README.md} for more details.
#'
#' @examples
#' \dontrun{
#' deploy_bookdown(gh_repo = 'toolbox-training', dir_out = '~/github/clip-n-ship')
#' }
#'
#' @import tidyverse yaml devtools brew
#' @export
#' 
deploy_bookdown <- function(
  gh_repo, # study_area, scenario_dir,
  gh_owner='OHI-Science', gh_branch_data='master',
  # app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  open_url=FALSE,
  dir_out=tempdir(), del_out=TRUE){
  
  library(tidyverse)
  library(yaml)
  library(brew)
  library(ohirepos)
  
  # construct vars
  web_url       = sprintf('http://%s.github.io/%s', gh_owner, gh_repo)
  gh_branch_web = 'gh-pages'
  # dir_branches  = file.path(dir_out, gh_repo)
  dir_training  = '~/github/toolbox-training'
  dir_book      = '~/github/toolbox-training/_book'
  dir_web       = file.path(dir_out, gh_repo, gh_branch_web)
  dir_data_2    = file.path(dir_out, gh_repo, gh_branch_web, sprintf('%s_%s', gh_repo, gh_branch_data))
  gh_slug       = sprintf('%s/%s', gh_owner, gh_repo)
  gh_url        = sprintf('https://github.com/%s.git', gh_slug)
  
  # ensure top level dir exists
  dir.create(dir_web, showWarnings = F, recursive = T)
  
  # verbose command
  run_cmd = function(cmd){
    cat(sprintf('running command:\n  %s\n', cmd))
  }
  
  # data branch: fetch existing, or clone new
  if (!file.exists(dir_training)){
    
    # clone data branch, shallowly and quietly
    run_cmd(sprintf('git clone -q --depth 1 --branch %s %s %s', gh_branch_data, gh_url, dir_training))
    
  } else {
    
    # git fetch & overwrite
    run_cmd(sprintf('cd %s; git fetch -q; git reset -q --hard origin/%s; git checkout -q %s; git pull -q', dir_training, gh_branch_data, gh_branch_data))
  
  }
  
  # # check if web branch dir already exists JSL not sure necess
  # if (file.exists(dir_web)){
  #   
  #   if (file.exists(dir_data_2) & !file.exists(dir_book)){
  #     
  #     # copy dir_data_2 back to dir_book as sibling to gh-pages
  #     run_cmd(sprintf('cp -rf %s %s', dir_data_2, dir_book))
  #   }
  # }
  
  # get remote branches # not sure needed 
  # remote_branches = gh_remote_branches(dir_training)
  
  if (!file.exists(dir_web)){
    
    # dir_app: copy from dir_book, if needed
    run_cmd(sprintf('cp -rf %s %s', dir_book, dir_web))
  }
  
  if (!'gh-pages' %in% remote_branches){
    
    # create orphan gh-pages branch, if needed
    run_cmd(sprintf(
      'cd %s; git checkout -q --orphan %s; rm -rf *; touch README.md; git add README.md; git commit -q -m "initialize %s branch"; git push -q origin %s',
      dir_web, gh_branch_web, gh_branch_web, gh_branch_web))
  } else {
    
    # checkout gh-pages branch and clear files
    run_cmd(sprintf('cd %s', dir_web))
    run_cmd('git fetch -q') 
    run_cmd(sprintf('git checkout -q %s', gh_branch_web))
    run_cmd(sprintf('git reset -q --hard %s', gh_branch_web))
    run_cmd('rm -rf *')

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
  
  # copy dir_book to dir_data_2
  run_cmd(sprintf('cd %s; rsync -rq ./ %s', dir_book, dir_data_2))
  
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
  
  # # remove temp files
  # if (del_out){
  #   run_cmd(sprintf('rm -rf %s', dir_branches))
  # }
  
  # return website
  return(web_url)
}
