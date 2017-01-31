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


## Notes on package building
*from Hadley Wickham's R Packages: r-pkgs.had.co.nz*

- `devtools::use_package` to add packages to DESCRIPTION

- NAMESPACE Workflow
    - Add roxygen comments to your .R files.
    - Run devtools::document() (or press Ctrl/Cmd + Shift + D in RStudio) to convert roxygen comments to .Rd files.
    - Look at NAMESPACE and run tests to check that the specification is correct.
    - Rinse and repeat until the correct functions are exported.


### Troubleshooting

If something like `Error ... : lazy-load database '.......rdb' is corrupt`, [stackoverflow](http://stackoverflow.com/questions/30424608/error-in-fetchkey-lazy-load-database) says:
I think the explanation for what is causing this is [here](https://github.com/hadley/devtools/pull/1001). It's related to devtools.

Fix: delete the .rdb package and RESTART R

```
cd ~/Rlibs/descopl/help
rm *.rdb
```
Restart R. Look at the help for the package again. Fixed!
