# populate_conf.r
#'
#' Populate OHI repo with configuration folder
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param repo_registry 
#'
#' @return key's repo with config folder populated
#' @export
#'

populate_conf <- function(key, 
                          repo_registry) {

  ## create variables
  dir_origin <- repo_registry$dir_origin
  dir_conf   <- file.path(dir_repo, repo_registry$scenario_name, 'conf')
   
  
  ## create conf folder
  
  if (!dir.exists(dir_conf)) {
    dir.create(dir_conf, showWarning=FALSE)
  }

  ## list conf files to copy
  conf_files = c('config.R', 'goals.csv',
                 'pressures_matrix.csv',  'pressure_categories.csv',
                 'resilience_matrix.csv', 'resilience_categories.csv',
                 'scenario_data_years.csv') 
  ## TODO add 'functions.R' back


  for (f in conf_files){ # f = conf_files[1] f = "functions.R"

    f_in  <- file.path(dir_origin, 'conf', f)
    f_out <-file.path(dir_conf, f)

    # read in file
    s <- readLines(f_in, warn=FALSE, encoding='UTF-8')

    ## swap out custom functions ###TODO obsolete no fxn_swap
    if (f == 'functions.R'){

      ## TODO: delete eez2013 from functions. r --Setup()

      ## iterate over goals with functions to swap
      ## TODO: when update LIV_ECO approach, can delete csv_gl_rgn var from create_init.r
      for (g in names(fxn_swap)){ # g = names(fxn_swap)[1]

        ## get goal=line# index for functions.R
        fxn_idx = setNames(
          grep('= function', s),
          str_trim(str_replace(grep('= function', s, value=T), '= function.*', '')))

        # read in new goal function
        s_g = readLines(fxn_swap[g], warn=F, encoding='UTF-8')

        # get line numbers for current and next goal to begin and end excision
        ln_beg = fxn_idx[g] - 1
        ln_end = fxn_idx[which(names(fxn_idx)==g) + 1]

        # inject new goal function
        s = c(s[1:ln_beg], s_g, '\n', s[ln_end:length(s)])
      }


      ## rethink because ref points stuff might be useful. will find this:
      ## write.csv(d_check, sprintf('temp/cs_data_%s.csv', scenario), row.names=FALSE)
      s <-  s %>%
        str_replace("write.csv\\(tmp, 'temp/.*", '') %>%
        str_replace('^.*sprintf\\(\'temp\\/.*', '')

      ## TODO: Delete PreGlobalScores(): https://github.com/OHI-Science/ohicore/blob/master/R/CalculateAll.R#L217-L221

      del_begin <- s %>% str_locate("PreGlobalScores.*")
      del_begin <- which(!is.na(del_begin[,1]))
      del_ends <- s %>% str_locate("\\}")
      del_ends <- which(!is.na(del_ends[,1]))

     # Finish this logic: need to extract the del_ends that follows del_begin, then delete those lines from s.

    } ## end if(f == 'functions.R')


    writeLines(s, f_out)

  } # end for (f in conf_files)
 
  
  ### TODO: come back here...should I brew each one from a list or have each individual? How did Mel do it.
  ## create subfolders in goals folder
  dir.create(file.path(dir_conf, 'goals'), showWarnings=FALSE)
  goals_rmds = c('FIS', 'MAR', 'AO', 'NP', 'CS', 'CP', 'LIV', 'ECO', 'TR', 'CW',
                      'ICO', 'LSP', 'SPP', 'HAB')
  # sapply(file.path(dir_conf, 'goals', goals_subfolders), dir.create) don't do this...
  
  ## brew files  ...brew each one with a different name
  # brew::brew(system.file('gh-pages/_site.brew.yml', package='ohirepos'),
  #            sprintf('%s/_site.yml', dir_repo))
  
  ## And don't forget the parent goals.Rmd file

}
