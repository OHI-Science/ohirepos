#' Deploy website to gh-pages branch in Github repository
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param dir_repo local directory where you have cloned the repo (probably somewhere temporary)
#' @param gh_org github organization to place the repo. Default: ohi-science
#' @param dir_scenario_gh web url of raw master branch scenario, e.g. 'https://raw.githubusercontent.com/OHI-Science/mhi/master/region2017'
#' @param study_area name of entire assessment, e.g. 'Gulf of Guayaquil'
#' @param clone T/F: do you want to add, commit, and push? Defaults to TRUE.
#' @param push T/F: do you want to add, commit, and push? Defaults to TRUE.
#'
#' @return Returns web_url (http://ohi-science.github.io/[key]) based on creating or
#' updating gh-pages branch of Github repository.
#'
#' @examples
#'
#' @import tidyverse yaml devtools brew stringr
#' @export
deploy_website <- function(key,
                           dir_repo,
                           gh_org          = 'OHI-Science',
                           dir_scenario_gh = sprintf(
                             "https://raw.githubusercontent.com/%s/%s/master/%s",
                             gh_org, key, repo_registry$scenario_name),
                           study_area      = repo_registry$study_area,
                           clone           = TRUE,
                           push            = TRUE){

  
  ## clone existing master branch
  if (clone) {
    unlink(dir_repo, recursive=TRUE, force=TRUE)
    repo <- ohirepos::clone_repo(dir_repo,
                                 sprintf('https://github.com/%s/%s.git',
                                         gh_org, key))
  }
  
  ## create empty gh-pages branch
  remote_branches <- git2r::branches(repo)
  
  if ('gh-pages' %in% remote_branches){
    
    ## if gh-pages branch exists, ask if user wants to overwrite
    cat("gh-pages branch already exists, would you like to overwrite it?")
    
  } else {
    
    ## if gh-pages branch does not exist
    
    system(sprintf('cd %s; git checkout --orphan gh-pages;  git rm -rf .', dir_repo))
    
    ## copy gh-pages web files into dir_repo, excluding all files in .gitignore
    system.time(system(
      sprintf(
        'cd %s; rsync -rq \\
      --exclude=_site.brew.R --exclude=_site.brew.yml --exclude=index.brew.Rmd --exclude=scores.brew.Rmd --exclude=_other/ --exclude=.gitignore \\
      --include=_footer.html --exclude-from=.gitignore \\
      . %s',
        system.file('gh-pages', package='ohirepos'), dir_repo)))
    
    ## brew files
    brew::brew(system.file('gh-pages/_site.brew.yml', package='ohirepos'),
               sprintf('%s/_site.yml', dir_repo))
    brew::brew(system.file('gh-pages/_site.brew.R', package='ohirepos'),
               sprintf('%s/_site.R', dir_repo))
    brew::brew(system.file('gh-pages/index.brew.Rmd', package='ohirepos'),
               sprintf('%s/index.Rmd', dir_repo))
    brew::brew(system.file('gh-pages/scores.brew.Rmd', package='ohirepos'),
               sprintf('%s/scores.Rmd', dir_repo))
    
    
    ## add Rstudio project file
    file.copy(system.file('templates/template.Rproj', package='devtools'),
              sprintf('%s/%s.Rproj', dir_repo, key))
    
    ## .nojekyll file rmarkdown.rstudio.com/rmarkdown_websites.html#publishing_websites
    system(sprintf('touch %s/.nojekyll', dir_repo))
    
    ## add gitignore file
    writeLines(c(
      '.Rproj.user', '.Rhistory', '.RData', 'rsconnect', '.DS_Store',
      basename(dir_repo)
    ), file.path(dir_repo, '.gitignore'))
    
    ## render website
    rmarkdown::render_site(dir_repo)
    
    ## cd to dir_repo, git add, commit and push rendered website
    if (push) {
      
      ## make sure .gitignore and .nojekyll get added
      system(sprintf(
        "cd %s; git add --all; git add .gitignore .nojekyll"))
      
      ## commit and push
      ohirepos::commit_and_push(
        key, 
        dir_repo,
        commit_message = sprintf("push %s rendered website", key), 
        branch = 'gh-pages')
      
    }
    
  }
}
