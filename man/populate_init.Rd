% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/populate_init.r
\name{populate_init}
\alias{populate_init}
\title{Populate initial files including README and .Rproj}
\usage{
populate_init(repo_registry, push = TRUE)
}
\arguments{
\item{repo_registry}{data frame with information about the repo}

\item{push}{TRUE/FALSE: do you want to add, commit, and push? Defaults to TRUE.}
}
\description{
First delete any local copy in your directory and clone the repo from github.com/OHI-Science.
}
