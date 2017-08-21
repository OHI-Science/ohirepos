## load any libraries needed across website pages
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(knitr)
})

## brewed vars
study_area      <- "<%=study_area%>"
key             <- "<%=key%>"
dir_scenario_gh <- "<%=dir_scenario_gh%>"

## knitr options for all webpages
knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE)

## read in variables
scores <- readr::read_csv(file.path(dir_scenario_gh, 'scores.csv'))
layers <- readr::read_csv(file.path(dir_scenario_gh, 'layers.csv'))
weight <- readr::read_csv(file.path(dir_scenario_gh, 'conf/goals.csv')) %>%
  select(goal, weight)

## save local copy of conf/goals.Rmd
conf_goals <- readr::read_lines(file.path(dir_scenario_gh, 'conf/web/goals.Rmd'))
readr::write_lines(conf_goals, path = 'conf_goals.Rmd', append = FALSE)

