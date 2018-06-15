#' Extract global data stored on Mazu for a specified region
#'
#' This requires access to the NCEAS MAZU server
#'
#' @param mazu_filename filepath from MAZU's git-annex
#' @param rgn_name region name from OHI Global Assessment
#' @param save_local_dir local filepath to save extracted data
#'
#' @return
#' @export
#'
#' @examples
#' ohicore::extract_mazu_by_rgn(
#'    mazu_filename = "globalprep/fis/v2017/int/stock_catch_by_rgn.csv",
#'    rgn_name = "Kenya",
#'    save_local_dir = "~/github/ken/global_explore/data")
#'
#'
extract_mazu_by_rgn <- function(mazu_filename,
                              rgn_name,
                              save_local_dir) {

  ## set the mazu and neptune data_edit share based on operating system
  dir_M             <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
                         'Darwin'  = '/Volumes/ohi',    ### connect (cmd-K) to smb://mazu/ohi
                         'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]]

  # warning if Mazu directory doesn't exist
  if (Sys.info()[['sysname']] != 'Linux' & !file.exists(dir_M)){
    warning(sprintf("The Mazu directory dir_M set in src/R/common.R does not exist. Do you need to mount Mazu: %s?", dir_M))
  }


  ## identify rgn_id
  rgn_global <- read_csv("https://raw.githubusercontent.com/OHI-Science/ohi-global/draft/eez/layers/rgn_global.csv")

  rgn_extract <- rgn_global %>%
    filter(label == rgn_name)

  if (nrow(rgn_extract) != 1) {
    print(sprintf("`%s` is not found in the OHI Global regions list, please double-check spelling and capitalization", rgn_name))
    print("https://github.com/OHI-Science/ohi-global/blob/draft/eez/layers/rgn_global.csv")
  }

  ## read rgn_spp_gl.csv from mazu
  data_all <- read_csv(file.path(dir_M, "git-annex", mazu_filename))

  ## filter out rgn_id
  data_rgn <- data_all %>%
    dplyr::filter(rgn_id == rgn_extract$rgn_id)

  ## save as .csv in key/global_explore
  filesave <- basename(mazu_filename)
  filesave <- file.path(save_local_dir, filesave)

  write_csv(data_rgn, filesave)

}
