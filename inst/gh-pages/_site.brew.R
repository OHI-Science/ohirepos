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
scores <- readr::read_csv(file.path(dir_scenario, 'scores.csv'))
layers <- readr::read_csv(file.path(dir_scenario, 'layers.csv'))
weight <- readr::read_csv(file.path(dir_scenario, 'conf/goals.csv')) %>%
  select(goal, weight)

