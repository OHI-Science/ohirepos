#' Deploy website to gh-pages branch in Github repository
#'
#' @param repo_registry data frame with information about the repo
#' @param gh_org github organization to place the repo. Default: ohi-science
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
deploy_website <- function(repo_registry,
                           clone  = TRUE,
                           push   = TRUE){

  ## create variables
  key             <- repo_registry$study_key
  study_area      <- repo_registry$study_area
  gh_org          <- repo_registry$gh_org
  dir_repo        <- repo_registry$dir_repo
  dir_scenario_gh <- sprintf(
    "https://raw.githubusercontent.com/%s/%s/main/%s",
    gh_org, key, repo_registry$scenario_name)


  ## clone existing main branch
  if (clone) {
    unlink(dir_repo, recursive=TRUE, force=TRUE)
    repo <- ohirepos::clone_repo(dir_repo,
                                 sprintf('https://github.com/%s/%s.git',
                                         gh_org, key))
  }

  ## create empty gh-pages branch
  remote_branches <- git2r::branches(repo)

  if ('gh-pages' %in% names(remote_branches)){

    ## if gh-pages branch exists, ask if user wants to overwrite <-  this is not working at the moment,
    stop("gh-pages branch already exists, delete branch first to overwrite")

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


    ## brew this list of files
    to_brew <- c('_site.brew.yml', '_site.brew.R',
                 'index.brew.Rmd', 'about.brew.Rmd',
                 'faq.brew.Rmd',   'scores.brew.Rmd')

    for (tb in to_brew) { # tb <- to_brew[1]

      ## remove brew from filename
      tb_out <- stringr::str_replace_all(tb, 'brew.', '')

      ## brew!
      brew::brew(system.file(sprintf('gh-pages/%s', tb), package='ohirepos'),
                 sprintf('%s/%s', dir_repo, tb_out))

    }


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
        "cd %s; git add --all; git add .gitignore .nojekyll", dir_repo))

      ## commit and push
      ohirepos::commit_and_push(
        repo_registry,
        commit_message = sprintf("push %s rendered website", key),
        branch = 'gh-pages')

    }

    ## switch back to main branch locally
    system(sprintf('cd %s; git checkout main', dir_repo))

  }
}
