# ohirepos
To create OHI tailored repositories

To install this library, run:

```r
devtools::install_github('ohi-science/ohirepos')
```

Then you can do things like:

```r
library(ohirepos)

# Baltic
deploy_app('bhi', 'Baltic', 'baltic2015')

# Global
deploy_app('ohi-global', 'Global',
  c('eez2015','eez2012','eez2013','eez2014','eez2016'),
  projection='Mollweide')
```
