% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/populate_layers.r
\name{populate_layers}
\alias{populate_layers}
\title{Populate new OHI repos with layers from global assessments}
\usage{
populate_layers(repo_registry, multi_nation = FALSE)
}
\arguments{
\item{repo_registry}{data frame with information about the repo}

\item{multi_nation}{T/F whether to pull information from multiple nations (i.e. Baltic, Arctic)}

\item{gh_org}{GitHub organization, defaults to 'OHI-Science'}
}
\value{
repo
}
\description{
Populate new OHI repos with layers from global assessments
}
