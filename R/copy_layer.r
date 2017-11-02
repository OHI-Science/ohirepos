#' Copy OHI Layer
#'
#' @param lyr OHI data layer to be copied
#' @param rgns_key regions list for key
#' @param dir_origin full local path of origin repo (e.g. 'ohi-global/eez')
#' @param dir_scenario full local path of repo scenario (e.g. 'test/region2017')
#' @param lyrs_key layers.csv data object
#' @param write_to_csv whether to write to .csv; default is TRUE
#'
#' @return
#' @export
#'
#' @examples
copy_layer <- function(lyr, 
                       rgns_key,
                       dir_origin, 
                       dir_scenario, 
                       lyrs_key, 
                       write_to_csv = TRUE){

  ## setup
  csv_in        <- lyrs_key$path_in[lyrs_key$layer == lyr]
  origin_rgn_id <-  unique(rgns_key$rgn_id_origin)

  ## read in layer, identify fields to keep 
  d    <- readr::read_csv(csv_in) 
  flds <- names(d)

  ## join d$rgn_id with rgns_key$rgn_id_origin, filter, select, and end with d$rgn_id
  if ('rgn_id' %in% names(d)){
    d <- d %>%
      dplyr::rename(rgn_id_origin = rgn_id) %>%
      filter(rgn_id_origin %in% origin_rgn_id) %>%
      left_join(rgns_key, by = 'rgn_id_origin') %>%
      dplyr::select(flds) %>%
      arrange(rgn_id)
  }
  
  ## TODO: add if statement that if rgn_id_origin == NA, assign to default of US and state it? and call it rgn_id_global?

  
  ## convert cntry_key to rgn_id, drop cntry_key ## must keep 2017, revisit when fix LE
  if ('cntry_key' %in% names(d)){ 
    
    global_lookup <- readr::read_csv(
      system.file('global_rgn_lookup_v2014.csv', package='ohirepos')) %>%
      filter(rgn_id == unique(rgns_key$rgn_id_origin))
    
    rgns_key <- rgns_key %>%
      mutate(cntry_key = global_lookup$cntry_key)
        
    d <- d %>%
      mutate(cntry_key = as.character(cntry_key)) %>%
      inner_join(
        rgns_key,
        by='cntry_key') %>%
      select_(.dots = as.list(c('rgn_id', setdiff(names(d), 'cntry_key')))) %>%
      arrange(rgn_id)
  }

  ## update rgn_labels
  if (lyr =='rgn_labels'){
    csv_out = sprintf('%s/layers/rgn_labels.csv', dir_scenario)
    lyrs_key$filename[lyrs_key$layer == lyr] = basename(csv_out)
    d <- d %>%
      merge(rgns_key, by='rgn_id') %>%
      select(rgn_id, type, label=rgn_name) %>%
      arrange(rgn_id)
  }

  ## update rgn_global csv name
  if (lyr =='rgn_global'){
    csv_out = sprintf('%s/layers/rgn_global.csv', dir_scenario)
    lyrs_key$filename[lyrs_key$layer == lyr] = basename(csv_out)
  }

  
  ## fill with placeholder data if d is empty ----
  if ( nrow(d) < 1 ) {

    ## create layer full of NAs
    dtmp <- rgns_key %>%
      select(rgn_id) %>%
      bind_rows(d)

    ## fill 0 as placeholder for pressures and resilience
    if (any(names(dtmp) %in% c('pressures.score', 'pressure_score', 'resilience.score'))) {
      dtmp[is.na(dtmp)] <- as.integer(0)
    }

    ## handle hd_subtidal_hb 
    if (lyr =='hd_subtidal_hb'){
      dtmp[is.na(dtmp)] <- as.integer(0)
    }

    ## fill 'cf' as placeholder for LIV/ECO
    if ('sector' %in% names(dtmp)) {
      dtmp$sector[is.na(dtmp$sector)] <- 'cf'
    }

    ## fill 'seagrass' as placeholder for HAB
    if ('habitat' %in% names(dtmp)) {
      
      hab_type <- stringr::str_split(lyr, '_') %>%
        purrr::flatten_chr()
      
      dtmp$habitat[is.na(dtmp$habitat)] <- hab_type[2]
    }

    ## fill global year as placeholder for year
    if ('year' %in% names(dtmp)) {
      dtmp$year <- as.integer(repo_registry$scenario_year)
    }

    ## fill global year as placeholder for any others
    dtmp[is.na(dtmp)] <- as.integer(repo_registry$scenario_year)

    ## replace d with dtmp
    d <- dtmp

    ## rename layername
    placeholder_csv <- stringr::str_replace(lyrs_key$filename[lyrs_key$layer == lyr], '\\.', 'placeholder.')
    lyrs_key$filename[lyrs_key$layer == lyr] = placeholder_csv

  }

  ## create csv_out (with or without placeholder added)
  csv_out <- sprintf('%s/layers/%s', dir_scenario, lyrs_key$filename[lyrs_key$layer == lyr])

  d$rgn_id <- as.integer(d$rgn_id)

  ## write to csv if TRUE
  if (write_to_csv) {

    readr::write_csv(d, csv_out, na='')
    return(csv_out)

  } else {

    ## TODO needs to return csv_out and d as a list
    return(csv_out)
  }
}