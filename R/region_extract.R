#load the libraries:

library(raster)
library(rgdal)
library(sf)

# This sources our spatial data from Mazu (so this requires a connection to Mazu), 
# This gets the most up-to-date files!: 
source("https://raw.githubusercontent.com/OHI-Science/ohiprep_v2018/master/src/R/spatial_common.R")

# The primary spatial polygon file is "regions" (which is a simple feature object)
regions

sort(unique(regions$rgn_name))

# filter the regions you want:
regions_new <- regions[regions$rgn_name == "Italy", ]

# check to make sure this is what you want:
regions_new
plot(regions_new[, 1])

# save the output (saving as an ESRI Shapefile):

write_sf(regions_new, "italy.shp")

