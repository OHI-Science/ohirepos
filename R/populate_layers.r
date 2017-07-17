## populate_layers.r

#' Populate new OHI repos with layers from global assessments
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param dir_repo full path of temporary OHI repo e.g. `~/github/clip-n-ship/gye`
#' @param lyrs_origin list of global layers to copy
#' @param dir_origin full local path of origin repo (e.g. global)
#' @param dir_scenario full path of temporary OHI repo and scenario, e.g. `~/github/clip-n-ship/gye`
#' @param multi_nation T/F whether to pull information from multiple nations
#'
#' @return populates OHI repo with layers from global assessments
#' @export
#'
#' @examples
#'
#'
populate_layers <- function(key, 
                            dir_repo,
                            gh_org = 'OHI-Science',
                            repo_registry,
                            dir_scenario, multi_nation = FALSE){

  ## create variables
  dir_origin    <- repo_registry$dir_origin
  lyrs_origin   <- readr::read_csv(file.path(dir_origin, 'layers.csv'))
  dir_scenario  <- file.path(dir_repo, repo_registry$scenario_name)
  dir_shp_files <- repo_registry$dir_shp_files
  
  ## clone repo master branch
  unlink(dir_repo, recursive=TRUE, force=TRUE)
  repo <- ohirepos::clone_repo(dir_repo,
                               sprintf('https://github.com/%s/%s.git',
                                       gh_org, key))
  
  ## copy layers.csv from global to tmp/ ----
  # write.csv(lyrs_origin, sprintf('%s/tmp/layers_%s.csv', dir_scenario, repo_registry$suffix_origin),   ### long term don't know if we need this
  #           na='', row.names=F)

  ## modify layers dataframe
  lyrs_key = lyrs_origin %>%
    select(
      targets, layer, filename, fld_value, units,
      name, description) %>% 
    mutate(
      layer_gl = layer,
      path_in  = file.path(dir_origin, 'layers', filename),
      rgns_in  = 'global',              ## TODO long term: don't think we need this rgns_in field
      filename = sprintf('%s_%s.csv', layer, repo_registry$suffix_origin)) %>%
    arrange(targets, layer)

  ## swap out rgn_area in directory; save a copy of the file
  lyr_area <- 'rgn_area'
  csv      <- 'rgn_offshore_data.csv'
  ix       <- which(lyrs_key$layer == lyr_area)
  lyrs_key$rgns_in[ix]  <-  'subcountry'
  lyrs_key$path_in[ix]  <-  file.path(dir_shp_files, csv) ## JSL 7/14 deleted: file.path(dir_shp_files, 'spatial', csv)
  lyrs_key$filename[ix] <-  sprintf('%s.csv', lyr_area)

  ## save a copy of rgn_area TODO: maybe move this to create_repo_map.r?
  dir.create(dir_scenario, showWarning=FALSE)
  dir.create(sprintf('%s/spatial', dir_scenario), showWarning=FALSE)
  rgns_list <- sprintf('%s/spatial/regions_list.csv', dir_scenario)
  file.copy(from =  lyrs_key$path_in[ix], to = rgns_list, overwrite=TRUE)

  ## drop cntry_* layers
  lyrs_key = filter(lyrs_key, !grepl('^cntry_', layer))

  ## drop all layers no longer being used (especially LE) ## TODO July 2017 JSL clean this up. 117 -> 102
  lyrs_le_rm = c(
    'le_gdp_pc_ppp','le_jobs_cur_adj_value','le_jobs_cur_base_value','le_jobs_ref_adj_value','le_jobs_ref_base_value',
    'le_rev_cur_adj_value','le_rev_cur_base_value','le_rev_cur_base_value','le_rev_ref_adj_value','le_rev_ref_base_value',
    'le_rev_sector_year','le_revenue_adj','le_wage_cur_adj_value','le_wage_cur_base_value','le_wage_ref_adj_value',
    'le_wage_ref_base_value','liveco_status','liveco_trend',
    'cntry_rgn', 'cntry_georegions')
  lyrs_key = filter(lyrs_key, !layer %in% lyrs_le_rm)


  ## match OHI+ regions to global regions ---- ## TODO do i want to rename
  rgns_key = read.csv(file.path(dir_shp_files, 'rgn_offshore_data.csv')) %>%
    select(rgn_id, rgn_name) %>%
    mutate(rgn_id_origin   = repo_registry$rgn_id_global, 
           rgn_name_origin = repo_registry$rgn_name_global)

  ## if OHI+ match not possible... ## TODO July 17 not sure this necessary now, what did it do? Did you need to indicate some country?
  # if (all(is.na(rgns_key$rgn_id_origin))){
  #   rgns_key = rgns_key %>%
  #     select(-rgn_id_global) %>%
  #     left_join(sc_studies %>%
  #                 select(gl_rgn_name = sc_name, rgn_id_global),
  #               by= 'gl_rgn_name')
  # }

  ## setup for copying layers over
  dir.create(sprintf('%s/layers', dir_scenario), showWarnings=FALSE)
  rlist <- readr::read_csv(rgns_list) ## TODO do I need this


  ## copy layers one by one, saving differently if multi_nation
  if (!multi_nation) {

    ## old global to new custom countries
    if (dim(rlist)[1] != dim(rgns_key)[1]) { # make sure Guayaquil doesn't match to both ECU and Galapagos
      sc_cntries = subset(sc_studies, sc_key == key, gl_rgn_key, drop=T)
      rgns_key <- rgns_key %>%
        filter(cntry_key %in% sc_cntries)
    }

    ## for each layer (not multi_nation)...
    for (lyr in lyrs_key$layer){ # lyr = "ao_access"   lyr = 'hd_subtidal_hb'  lyr = 'rgn_global'

      ## call copy_layer and write to layer to csv
      d <- ohirepos::copy_layer(lyr, 
                                rgns_key,
                                dir_origin, 
                                suffix = repo_registry$suffix_origin,
                                lyrs_key, 
                                write_to_csv = TRUE)

      ## update filename (will change if placeholder)
      lyrs_key$filename[lyrs_key$layer == lyr] <- basename(d)

    }

  } else { # multi_nation == TRUE

    ## overwrite rgns_key if multi_nation
    sc_rgns_lookup <- read.csv(sprintf('~/github/ohi-webapps/custom/%s/sc_rgns_lookup.csv', key))
    rgns_key = sc_rgns_lookup %>%
      merge(
        gl_rgns,
        by='gl_rgn_name', all.x=T) %>%
      select(rgn_id, sc_rgn_name, rgn_id_global, gl_rgn_name) %>%
      arrange(sc_rgn_name)

    ## old global to multi_nation
    rgns_key = rgns_key %>%
      group_by(cntry_key) %>%
      filter(row_number() == 1) %>%
      ungroup()
    if (dim(rlist)[1] != dim(rgns_key)[1]) { # so GYE doesn't match both ECU+Galapagos
      rgns_key = rgns_key %>%
        filter(cntry_key %in% unique(sc_rgns_lookup$gl_rgn_key))
    }

    ## for each layer...(multi_nation)
    for (lyr in lyrs_key$layer){ # lyr = "ao_access"

      ## call copy_layer and then write to layer to csv as separate step
      d <- ohirepos::copy_layer(lyr, rgns_key,
                      dir_origin, repo_registry$suffix_origin,
                      lyrs_key, write_to_csv = FALSE)
      if ('rgn_id' %in% names(d)) d = d %>% arrange(rgn_id)

      ## update filename (will change if placeholder)
      lyrs_key$filename[lyrs_key$layer == lyr] <- basename(d)

      ## write to csv as separate step
      csv_out = d
      #TODO update this so data and filename are returned
      write_csv(d, csv_out)

    }
  } ## end if (!multi_nation)



  ## create layers.csv registry ----
  lyrs_reg = lyrs_key %>%
    select(
      targets,
      layer,
      filename,
      fld_value,
      units,
      name,
      description,
     # clip_n_ship_disag,
    #  clip_n_ship_disag_description,
      layer_gl,
      path_in)

  ## save layers.csv
  layers_csv <- sprintf('%s/layers.csv', dir_scenario)
  readr::write_csv(lyrs_reg, layers_csv, na='')

  ## check for empty layers
  ohicore::CheckLayers(layers_csv, file.path(dir_scenario, 'layers'),
              flds_id=c('rgn_id','country_id','saup_id','fao_id','fao_saup_id'))
  lyrs = read.csv(layers_csv, na='')
  lyrs_empty = filter(lyrs, data_na==T)
  if (nrow(lyrs_empty) > 0){
    dir.create('tmp/layers-empty_global-values', showWarnings=F)
    write.csv(lyrs_empty, 'layers-empty_swapping-global-mean.csv', row.names=F, na='')
  }


  ## populate empty layers with global averages. ## TODO see if a better way...
  for (lyr in lyrs_empty$layer){ # lyr = lyrs_empty$layer[1]

    message(' for empty layer ', lyr, ', getting global mean with ', repo_registry$suffix_origin, 'suffix')

    ## get all global data for layer
    l = subset(lyrs, layer==lyr)
    l$filename <- paste0(str_split_fixed(l$filename, '\\.', 2)[1], 'mean.', str_split_fixed(l$filename, '\\.', 2)[2])
    csv_gl  = as.character(l$path_in)
    csv_tmp = sprintf('%s/tmp/layers-empty_global-values/%s', dir_scenario,l$filename)
    csv_out = sprintf('%s/layers/%s', dir_scenario, l$filename)
    file.copy(csv_gl, csv_tmp, overwrite=T)
    a = read.csv(csv_tmp)

    ## calculate global categorical means using non-standard evaluation, ie dplyr::*_()
    fld_key         = names(a)[1]
    fld_value       = names(a)[ncol(a)]
    flds_other = setdiff(names(a), c(fld_key, fld_value))

    if (class(a[[fld_value]]) %in% c('factor','character') & l$fld_val_num == fld_value){
      cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but registered as [fld_val_num] not [fld_val_chr].\n', lyr, fld_value))
    }

    ## exceptions
    if (lyr == 'mar_trend_years'){
      rgns_key %>%
        mutate(trend_yrs = '5_yr') %>%
        select(rgn_id = rgn_id, trend_yrs) %>%
        arrange(rgn_id) %>%
        write.csv(csv_out, row.names=F, na='')

      next
    }

    if (class(a[[fld_value]]) %in% c('factor','character')){
      cat(sprintf('  DOH! For empty layer "%s" field "%s" is factor/character but continuing with presumption of numeric.\n', lyr, fld_value))
    }

    ## get mean, presuming numeric...
    if (length(flds_other) > 0){
      b = a %>%
        group_by_(.dots=flds_other) %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s, na.rm=T)', fld_value),
            fld_value))
    } else {
      b = a %>%
        summarize_(
          .dots = setNames(
            sprintf('mean(%s, na.rm=T)', fld_value),
            fld_value))
    }

    ## bind many rgn_ids
    if ('rgn_id' %in% names(a) | 'cntry_key' %in% names(a)){
      b = b %>%
        merge(
          rgns_key %>%
            select(rgn_id = rgn_id),
          all=T) %>%
        select(one_of('rgn_id', flds_other, fld_value)) %>%
        arrange(rgn_id)
    }

    write.csv(b, csv_out, row.names=F, na='')

  } # end for (lyr in subset(lyrs, data_na, layer, drop=T))


  ## check again now empty layers now populated by global averages
  ohicore::CheckLayers(layers_csv, file.path(dir_scenario, 'layers'),
              flds_id=c('rgn_id','country_id','saup_id','fao_id','fao_saup_id'))

}
