suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sp)
  library(geojsonio)
  library(leaflet)
  library(htmltools)
  library(DT)
})

# brewed vars
title           = "<%=web_title%>"
gh_repo         = "<%=gh_repo%>"
gh_branch_data  = "<%=gh_branch_data%>"
scenario_dir    = "<%=scenario_dir%>"
app_url         = "<%=app_url%>"
ohirepos_commit = "<%=ohirepos_commit%>"
map_shrink_pct  = 5

# derived vars
dir_data        = sprintf('%s_%s', gh_repo, gh_branch_data)
dir_scenario    = sprintf('%s/%s', dir_data, scenario_dir)

# knitr options
knitr::opts_chunk$set(echo = F, message = F, warning = F)

# if dir_data not found, then git clone
if (!file.exists(dir_data)){
  system(sprintf('git clone https://github.com/ohi-science/%s.git %s', dir_data))
}

# read config
config = new.env()
source(file.path(dir_scenario, 'conf/config.R'), config)


