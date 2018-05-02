# populate_conf.r
#'
#' Populate OHI repo with configuration folder
#'
#' @param repo_registry data frame with information about the repo
#'
#' @return key's repo with config folder populated
#' @export
#'

populate_conf <- function(repo_registry) {

  ## create variables
  key             <- repo_registry$study_key
  dir_repo        <- repo_registry$dir_repo
  dir_origin      <- repo_registry$dir_origin
  dir_conf        <- file.path(dir_repo, repo_registry$scenario_name, 'conf')
  gh_org          <- 'OHI-Science'
  dir_scenario_gh <- sprintf(
    "https://raw.githubusercontent.com/%s/%s/master/%s",
    gh_org, key, repo_registry$scenario_name)


  ## create conf folder

  if (!dir.exists(dir_conf)) {
    dir.create(dir_conf, showWarning=FALSE)
  }

  ## list conf files to copy, except functions.r
  conf_files = c('functions.r',
                 'config.R', 'goals.csv',
                 'pressures_matrix.csv',  'pressure_categories.csv',
                 'resilience_matrix.csv', 'resilience_categories.csv',
                 'scenario_data_years.csv')

  for (f in conf_files){ # f = 'functions.R'

    file.copy(file.path(dir_origin, 'conf', f),
              file.path(dir_conf, f),
              overwrite=TRUE)
  }

  ## swap out custom functions ----
  fxn_swap    <- c(
    'LE'  = system.file('master/functions_LE.R', package='ohirepos'),
    'LIV_ECO' = system.file('master/functions_LIV_ECO.R', package='ohirepos'),
    'ICO' = system.file('master/functions_ICO.R', package='ohirepos'))

  s <- readLines(file.path(dir_conf, "functions.R"), warn=FALSE, encoding='UTF-8')

  ## iterate over goals with functions to swap
  for (g in names(fxn_swap)){ # g = names(fxn_swap)[2]

    message(sprintf("swapping %s function...", g))
    if (g == "LIV_ECO") message(sprintf("(separating LIV_ECO into LIV and ECO)"))

    ## get goal=line# index for functions.R (inside g for loop!)
    fxn_idx = setNames(
      grep('<- function', s),
      str_trim(str_replace(grep('<- function', s, value=TRUE), '<- function.*', '')))

    # read in new goal function
    s_g = readLines(fxn_swap[g], warn=FALSE, encoding='UTF-8')

    # get line numbers for current and next goal to begin and end excision
    ln_beg = fxn_idx[g] - 1
    ln_end = fxn_idx[which(names(fxn_idx)==g) + 1]

    # inject new goal function
    s = c(s[1:ln_beg], s_g, '\n', s[ln_end:length(s)])
  }

  # s <- s %>%
  #   str_replace("write.csv\\(tmp, 'temp/.*", '') %>%
  #   str_replace('^.*sprintf\\(\'temp\\/.*', '')

  ## substitute old layer names with new
  # lyrs_dif = lyrs_sc %>% filter(!layer %in% layer_gl) # changed from layer != layer_gl JSL 08-24-2015
  # for (i in 1:nrow(lyrs_dif)){ # i=1
  #   s = str_replace_all(s, fixed(lyrs_dif$layer_gl[i]), lyrs_dif$layer[i])
  # }

  writeLines(s, file.path(dir_conf, "functions.R"))


  ## swap our custom fields in goals.csv ----

  goal_swap   <- list(
    'LIV' = list(preindex_function="LIV(layers)"),
    'ECO' = list(preindex_function="ECO(layers)"))

  goals <- read_csv(file.path(dir_conf, "goals.csv"))

  for (g in names(goal_swap)){ # g = names(goal_swap)[1]
    for (fld in names(goal_swap[[g]])){
      goals[goals$goal==g, fld] = goal_swap[[g]][[fld]]
    }
  }
  write_csv(goals, file.path(dir_conf, "goals.csv"), na='')


  ## copy subfolders in goals folder for website ----
  goal_subfolders <- list.files(system.file('master/web/goals', package='ohirepos'))
  dir_web         <- file.path(dir_conf, 'web')
  dir_goals       <- file.path(dir_conf, 'web/goals')

  ## create goals dir if it doesn't already exist
  if(!file.exists(dir_web)) dir.create(dir_web)
  if(!file.exists(dir_goals)) dir.create(dir_goals)

  for (g in goal_subfolders){ # g <- "AO.Rmd"

    file.copy(system.file(sprintf('master/web/goals/%s', g),
                          package='ohirepos'),
              file.path(dir_goals, g), overwrite=TRUE)

  }

  ## brew the parent goals.Rmd file
  brew::brew(system.file(sprintf('master/web/goals.brew.Rmd'), package='ohirepos'),
             file.path(dir_web, 'goals.Rmd'))


}
