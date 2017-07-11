#' Deploy website to gh-pages branch in Github repository
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param dir_repo local directory where you have cloned the repo (probably somewhere temporary)
#' @param gh_org github organization to place the repo. Default: ohi-science
#' @param push TRUE/FALSE: do you want to add, commit, and push? Defaults to TRUE.
#'
#' @return Returns web_url (http://ohi-science.github.io/[key]) based on creating or
#' updating gh-pages branch of Github repository. Please also visit
#' \link[=https://github.com/OHI-Science/ohirepos/blob/master/inst/gh-pages/README.md]{gh-pages/README.md} for more details.
#'
#' @examples
#' \dontrun{
#' deploy_website_prep('arc', 'The Arctic')
#' }
#'
#' @import tidyverse yaml devtools brew stringr
#' @export
deploy_website_prep <- function(key,
                                dir_repo,
                                gh_org = 'OHI-Science',
                                push = TRUE){

  run_cmd = function(cmd){
    cat(sprintf('running command:\n  %s\n', cmd))
    system.time(system(cmd))
  }


  ## clone existing master branch
  repo <- ohirepos::clone_repo(dir_repo,
                               sprintf('https://github.com/%s/%s.git',
                                       gh_org, key))
  ## create empty gh-pages branch
  remote_branches <- git2r::branches(repo)
  if (!'gh-pages' %in% remote_branches){

    system(sprintf('cd %s; git checkout --orphan gh-pages;  git rm -rf .', dir_repo))

    ## copy gh-pages web files into dir_repo, excluding all files in .gitignore
    run_cmd( ##
      sprintf(
        'cd %s; rsync -rq \\
      --exclude=_site.brew.R --exclude=_site.brew.yml --exclude=index.brew.Rmd --exclude=_other/ --exclude=.gitignore \\
      --include=_footer.html --exclude-from=.gitignore \\
      . %s',
        system.file('gh-pages-prep', package='ohirepos'), dir_repo))

    ## brew files
    brew::brew(system.file('gh-pages-prep/_site.brew.yml', package='ohirepos'),
               sprintf('%s/_site.yml', dir_repo))
    brew::brew(system.file('gh-pages-prep/_site.brew.R', package='ohirepos'),
               sprintf('%s/_site.R', dir_repo))
    brew::brew(system.file('gh-pages-prep/index.brew.Rmd', package='ohirepos'),
               sprintf('%s/index.Rmd', dir_repo))

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

      cat(sprintf("git add, commit, and push rendered website for %s repo", key))
      run_cmd(sprintf(
        "cd %s; git add --all; git add .gitignore .nojekyll;
    git commit -m 'creating prep website with ohirepos';
    git push origin gh-pages",
        dir_repo))
    }

  } else {
    cat("gh-pages branch and website already exists; exiting so as not to overwrite.")
  }
}
