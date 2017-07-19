## calculate_scores.R

## This script calculates OHI scores with the `ohicore` package.
## - configure_toolbox.r ensures your files are properly configured for `ohicore`.
## - The `ohicore` function CalculateAll() calculates OHI scores.


## run the configure_toolbox.r script to check configuration
setwd("~/github/<%=key%>/<%=scenario%>")

source('configure_toolbox.r')

## calculate scenario scores
scores = ohicore::CalculateAll(conf, layers)

## save scores as scores.csv
write.csv(scores, 'scores.csv', na='', row.names=FALSE)



## visualize scores ----

## source from ohibc until added to ohicore, see https://github.com/OHI-Science/ohibc/blob/master/regionHoweSound/ohibc_howesound_2016.Rmd
source('https://raw.githubusercontent.com/OHI-Science/ohibc/master/src/R/common.R')
source('plot_flower_local.R')

## regions info
regions <- bind_rows(
  data_frame(                # order regions to start with whole study_area
    region_id   = 0,
    region_name = '<%=study_area%>'),
  read_csv('spatial/regions_list.csv') %>%
    select(region_id   = rgn_id,
           region_name = rgn_name))

## set figure name
regions <- regions %>%
  mutate(flower_png = sprintf('reports/figures/flower_%s.png',
                              str_replace_all(region_name, ' ', '_')))
readr::write_csv(regions, 'reports/figures/regions_figs.csv')

## save flower plot for each region
for (i in regions$region_id) { # i = 0

  ## fig_name to save
  fig_name <- regions$flower_png[regions$region_id == i]

  ## scores info
  score_df <- scores %>%
    filter(dimension == 'score') %>%
    filter(region_id == i)

  ## flower plot
  plot_obj <- plot_flower(score_df,
                          filename    = fig_name,
                          goals_csv   = 'conf/goals.csv',
                          incl_legend = TRUE)

}


