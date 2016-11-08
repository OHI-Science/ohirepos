# ohirepos
A package to create OHI tailored repositories

To install this library, run:

```r
devtools::install_github('ohi-science/ohirepos')
```

Then you can do things like build an OHI Shiny app for Global or Baltic Sea:

```r
library(ohirepos)

# Baltic
deploy_app('bhi', 'Baltic', 'baltic2015')

# Global
deploy_app('ohi-global', 'Global',
  c('eez2015','eez2012','eez2013','eez2014','eez2016'),
  projection='Mollweide')
```

These Shiny apps are created with the underlying 

Code to make Shiny apps: `ohirepos/inst/app`. 

Further, you can deploy an OHI website: 
```r
library(ohirepos)

# Baltic
deploy_website('bhi', 'Baltic', 'baltic2015')
```

Code to make OHI+ websites: `ohirepos/inst/gh-pages`. 
