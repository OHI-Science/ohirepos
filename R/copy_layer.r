#' Copy OHI Layer
#'
#' @param lyr OHI data layer to be copied
#' @param rgns_key regions list for key
#' @param dir_origin full local path of origin repo (e.g. ohi-global/eez)
#' @param lyrs_key layers.csv data object
#' @param write_to_csv whether to write to .csv; default is TRUE
#'
#' @return
#' @export
#'
#' @examples
copy_layer <- function(lyr = lyr, 
                       rgns_key,
                       dir_origin, 
                       dir_scenario, 
                       lyrs_key, 
                       write_to_csv = TRUE){

  ## setup
  csv_in        <- sprintf('%s/layers/%s.csv', dir_origin, lyr)
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

  
  # if ('cntry_key' %in% names(d)){ ## TODO july 2017: ohi-global still uses this in LE but maybe since swap files can get around it, and remove if statement above
  #   # convert cntry_key to rgn_id, drop cntry_key
  #   d = d %>%
  #     mutate(cntry_key = as.character(cntry_key)) %>%
  #     inner_join(
  #       rgns_key %>%
  #         mutate(cntry_key = as.character(cntry_key)),
  #       by='cntry_key') %>%
  #     dplyr::rename(rgn_id=sc_rgn_id) %>%
  #     select_(.dots = as.list(c('rgn_id', setdiff(names(d), 'cntry_key')))) %>%
  #     arrange(rgn_id)
  # }

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

  ## TODO: comment out for now; see if this is actually happening.
  ## downweight: area_offshore, equal, equal, population_inland25km,
  # shp = '/Volumes/data_edit/git-annex/clip-n-ship/data/Albania/rgn_inland25km_mol.shp'
  # downweight = str_trim(lyrs_key$clip_n_ship_disag[lyrs_key$layer == lyr])
  # downweightings = c('area_offshore'='area-offshore', 'population_inland25km'='popn-inland25km')
  # if (downweight %in% names(downweightings) & nrow(d) > 0){
  #
  #   ## update data frame with downweighting
  #   i.v  = ncol(d) # assume value in right most column
  #   #if (downweight=='population_inland25km') browser()
  #   d = inner_join(d, get(downweight), by='rgn_id')
  #   i.dw = ncol(d) # assume downweight in right most column after join
  #   d[i.v] = d[i.v] * d[i.dw]
  #   d = d[,-i.dw]
  #
  #   ## update layer filename to reflect downweighting
  #   csv_out = file.path(
  #     'layers',
  #     str_replace(
  #       lyrs_key$filename[lyrs_key$layer == lyr],
  #       fixed('_gl2016.csv'),
  #       sprintf('_sc2014-%s.csv', downweightings[downweight])))
  #   lyrs_key$filename[lyrs_key$layer == lyr] = basename(csv_out)
  # }

  ## fill with placeholder data if d is empty ----
  if (nrow(d) < 1) {

    ## create layer full of NAs
    dtmp <- rgns_key %>%
      select(rgn_id) %>%
      bind_rows(d)

    ## fill 0 as placeholder for pressures and resilience
    if (any(names(dtmp) %in% c('pressures.score', 'pressure_score', 'resilience.score'))) {
      dtmp[is.na(dtmp)] <- as.integer(0)
    }

    ## handle hd_subtidal_hb --TODO CHECK THIS FIX
    if (lyr =='hd_subtidal_hb'){
      dtmp[is.na(dtmp)] <- as.integer(0)
    }

    ## fill 'cf' as placeholder for LIV/ECO
    if ('sector' %in% names(dtmp)) {
      dtmp$sector[is.na(dtmp$sector)] <- 'cf'
    }

    ## fill 'seagrass' as placeholder for HAB
    if ('habitat' %in% names(dtmp)) {
      dtmp$habitat[is.na(dtmp$habitat)] <- 'seagrass'
    }

    ## fill global year as placeholder for year
    if ('year' %in% names(dtmp)) {
      dtmp$year <- as.integer(stringr::str_extract(dir_origin, "\\d{4}"))
    }

    ## fill global year as placeholder for any others
    dtmp[is.na(dtmp)] <- as.integer(stringr::str_extract(dir_origin, "\\d{4}"))

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