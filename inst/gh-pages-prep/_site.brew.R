## load any libraries needed across website pages
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(knitr)
})

## brewed vars
study_area = "<%=study_area%>"
key        = "<%=key%>"

## derived vars
gh_url     = sprintf('https://github.com/OHI-Science/%s.git', key)

## knitr options for all webpages
knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE)

