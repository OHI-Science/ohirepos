% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/deploy_website.R
\name{deploy_website}
\alias{deploy_website}
\title{Deploy website to gh-pages branch in Github repository}
\usage{
deploy_website(repo_registry, clone = TRUE, push = TRUE)
}
\arguments{
\item{repo_registry}{data frame with information about the repo}

\item{clone}{T/F: do you want to add, commit, and push? Defaults to TRUE.}

\item{push}{T/F: do you want to add, commit, and push? Defaults to TRUE.}

\item{gh_org}{github organization to place the repo. Default: ohi-science}
}
\value{
Returns web_url (http://ohi-science.github.io/\link{key}) based on creating or
updating gh-pages branch of Github repository.
}
\description{
Deploy website to gh-pages branch in Github repository
}
