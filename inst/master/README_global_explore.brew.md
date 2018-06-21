## README <%=study_area%> [<%=key%>]

This folder contains information for <%=study_area%> from the OHI global assessments. [View the explore_data file](https://rawgit.com/OHI-Science/<%=key%>/master/global_explore/explore_data.html) that will let you explore data directly from the `ohi-global` repository, or modify the `.Rmd` file. In OHI global assessments, <%=study_area%> has a region identifier (rgn_id) of <%=rgn_id_global%>.

In a few cases, data files are saved locally as `.csv` files for <%=study_area%> only because data for all regions are too big and are not kept on GitHub.

- `explore-data.Rmd` extracts and displays OHI global information for <%=study_area%> by goal, and can be [viewed as an html here](https://rawgit.com/OHI-Science/<%=key%>/master/global_explore/explore_data.html)
- `stock_catch_by_rgn.csv` data by year included in the global assessments' fisheries sub-goal
- `fis_meancatch_lookup` the species included in the global assessments' fisheries sub-goal
- `fis_b_bmsy_lookup` lists the species that have B/Bmsy scores that are included in the global assessments' fisheries sub-goal
- `rgn_spp_gl.csv` the species included in global assessments' species sub-goal

