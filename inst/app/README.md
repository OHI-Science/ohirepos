# OHI Shiny app

These files provide the template for creating a Shiny app that visualizes a data branch of an Ocean Health Index (OHI) repository.

Normally these files are translated from template files into a live Shiny app using the `ohirepos::deploy_app()` function, like so:

```r
# ohi-global
deploy_app('ohi-global', 'eez2015', 'Global')

# baltic
deploy_app('ohi-global', 'baltic2015', 'Baltic')
```

To quickly run your own Shiny app from an existing OHI repository containing a data branch, you simply need to create working configuration (`app.yml`) and introduction (`intro.md`) files from the templates. This is done in the `ohirepos::deploy_app()` function with [`brew::brew()`](https://www.rdocumentation.org/packages/brew/versions/1.0-6/topics/brew) after setting variables like so:

```r
brew(system.file('app/app.brew.yml' , package='ohirepos'), file.path(dir_app, 'app.yml'))
brew(system.file('app/intro.brew.md', package='ohirepos'), file.path(dir_app, 'intro.md'))
```

When the Shiny app first launches (eg with [`shiny::runApp()`](https://www.rdocumentation.org/packages/shiny/versions/0.13.2/topics/runApp)), the github repository specified in `app.yml` will get downloaded from Github with `git clone` and all data read in and presented in the app.

## Credit

The majority of this Shiny application was coded by [Ben Best](http://benbestphd.com) with significant inputs from Julie Lowndes. Special thanks to Herman Sontrop who developed the [ohi-aster](https://github.com/FrissAnalytics/ohi-aster) htmlwidget and these [Shiny JavaScript tutorials](http://shiny.rstudio.com/tutorial/).

## Sidenote on GeoJSON Simplification

The initial loading time and overall performance of the Shiny app in a web browser is very dependent on the size of the GeoJSON file used to render the regions spatially. The path of this geojson file is specified as the `geojson` variable in the `config.R` of the data branch's scenario subfolder (eg for Baltic draft branch, baltic2015 scenario: [config.R](https://github.com/OHI-Science/bhi/blob/673f8b67f1eb0e42e7e59117880cb07032aaf750/baltic2015/conf/config.R#L26) -> 
[spatial/regions_gcs.geojson](https://github.com/OHI-Science/bhi/blob/draft/baltic2015/spatial/regions_gcs.geojson):

```r
geojson = 'spatial/regions_gcs.geojson'
```

Here's how the high resolution global EEZ shapefile was greatly simplified with the excellent [`rmapshaper::ms_simplify`](https://github.com/ateucher/rmapshaper#usage) to [ohi-global/rgn_offshore_gcs_mapshaper-simplify_x2_eez-only.geojson](https://github.com/OHI-Science/ohi-global/blob/b2abb0b63822c94c447bc04afa3c901511c48a6c/eez2015/spatial/rgn_offshore_gcs_mapshaper-simplify_x2_eez-only.geojson)...

<script src="https://embed.github.com/view/geojson/OHI-Science/ohi-global/b2abb0b63822c94c447bc04afa3c901511c48a6c/eez2015/spatial/rgn_offshore_gcs_mapshaper-simplify_x2_eez-only.geojson"></script>

```r
## install.packages("devtools")
library(dplyr)
library(sp)
library(rgdal)
library(geojsonio)  # install_github("ropensci/geojsonio")
library(rmapshaper) # install_github("ateucher/rmapshaper")

# downloaded from sftp://neptune.nceas.ucsb.edu/var/data/ohi/git-annex/Global/NCEAS-Regions_v2014/data/rgn_offshore_gcs.shp
shp = '~/Documents/OHI/spatial/rgn_offshore_gcs.shp'

# read in polygon
ply = readOGR(normalizePath(dirname(shp)), basename(tools::file_path_sans_ext(shp)), verbose=F)

# subset
sub = ply[ply@data$rgn_name %in% c('Costa Rica','Nicaragua'),]

# plot
plot(sub, col='gray')

# simplify using default parameters
ply_simp0 = ms_simplify(ply)
plot(ply_simp0, col='gray')

# write out as geojson
geojson_write(ply_simp0, file='data/rgn_offshore_gcs_mapshaper-simplify.geojson')
})

# simplify from existing geojson, plot and write out
ply_simp0 = readOGR('data/rgn_offshore_gcs_mapshaper-simplify.geojson', 'OGRGeoJSON', verbose=F)
plot(ply_simp0, col='gray')
ply_simp1 = ms_simplify(ply_simp0)
plot(ply_simp1, col='gray')
geojson_write(ply_simp1, file='data/rgn_offshore_gcs_mapshaper-simplify_x2.geojson')

# remove non-eez shapes
ply_simp2 = ply_simp1[ply_simp1$rgn_type=='eez' & ply_simp1$rgn_name!='Antarctica',]
plot(ply_simp2, col='gray')
geojson_write(ply_simp2, file='data/rgn_offshore_gcs_mapshaper-simplify_x2_eez-only.geojson')
```
