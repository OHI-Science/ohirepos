# ohirepos

# Overview

The `ohirepos` package is for creating OHI repos to be used for OHI assessments. These repos by default are created within the [OHI-Science](https://github.com/OHI-Science/) GitHub organization, and to do so you will need be part of the OHI team with administration privileges. To request a repository, please follow [these instructions](http://ohi-science.org/manual/#requesting-your-repositories).

The `ohirepos` package is called from the [`ohirepos-log`](https://github.com/OHI-Science/ohirepos-log) repo, where there are supporting scripts to call these `ohirepos` functions to create new repos templated with data from other OHI assessments. 

# Installation

```{r, eval = FALSE}
# install.packages("devtools")
devtools::install_github("ohi-science/ohirepos")
```

