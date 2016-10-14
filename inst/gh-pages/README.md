# OHI gh-pages branch

These files provide the template for creating a website for an OHI repository per [Github Pages](http://pages.github.com) by populating the HTML files from Rmarkdown into the gh-pages branch of the Github repo.

Normally these files are translated from template files into the website using `ohirepos::deploy_website()` function, like so:

```r
library(ohirepos)

# ohi-global
deploy_website('ohi-global', 'Global', 'eez2015')

# baltic
deploy_website('ohi-global', 'Baltic', 'eez2015')
```

When [`rmarkdown::render_site(dir_web)`](http://rmarkdown.rstudio.com/rmarkdown_websites.html) runs, it knits each Rmarkdown (*.Rmd) based on parameters in `_site.R` and `_site.yml` before pushing the files back to Github. These Rmd files also pull from the `data_branch`, typically `draft`, that gets copied into `[gh_repo]_[gh_branch_data]`. 

## Development

In practice, for developing these Rmarkdown files, I launch RStudio with `ohirepos/inst/gh-pages/gh-pages.Rproj` to set the working directory here, and create the `_site.yml` and `_site.R` for whichever repo, knit with the Build tab in RStudio > Build Website, and add the `[gh_repo]_[gh_branch_data]` folder to `.gitignore`.

Here's how to generate the `_site.yml` and `_site.R` manually for local development in `ohirepos/inst/gh-pages`:

```r
# ohi-global
gh_repo='ohi-global'; web_title='Global'; dir_scenario='eez2015'

# bhi
gh_repo='bhi'       ; web_title='Baltic'; dir_scenario='baltic2015'

# vars
gh_owner='OHI-Science'; gh_branch_data='draft'; app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo); 
open_url=T; del_out=FALSE
dir_out='~/github/clip-n-ship' # dir_out='~/Desktop/ohirepos_tmp'
ohirepos_commit = devtools:::local_sha('ohirepos')

# brew config files
brew::brew(system.file('gh-pages/_site.brew.yml', package='ohirepos'), '_site.yml')
brew::brew(system.file('gh-pages/_site.brew.R'  , package='ohirepos'), '_site.R'  )

# render and launch
rmarkdown::render_site('.')
utils::browseURL('index.html')
```

