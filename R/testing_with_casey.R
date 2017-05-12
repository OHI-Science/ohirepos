# testing with Casey

## current
deploy_app(
  gh_repo = 'IUCN-AquaMaps',
  study_area = 'IUCN-AquaMaps',
  scenario_dirs = 'shiny_am_iucn',
  gh_owner='OHI-Science',
  gh_branch_data='master',
  gh_branch_app ='dummy',
  gh_data_commit=NULL,
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  app_server='jstewart@128.111.84.76',
  dir_server='/srv/shiny-server',
  projection='Mercator',
  map_shrink_pct=10,
  run_app=F, open_url=T,
  dir_out=tempdir(), del_out=T)

## new function
deploy_app_generic(
  gh_repo = 'IUCN-AquaMaps',
  dir_shiny = 'shiny_am_iucn',
  gh_owner='OHI-Science',
  branch_shiny = 'master',
  gh_data_commit=NULL,
  app_url=sprintf('http://ohi-science.nceas.ucsb.edu/%s', gh_repo),
  app_server='jstewart@128.111.84.76',
  dir_server='/srv/shiny-server',
  run_app=F, open_url=T,
  dir_out=tempdir(), del_out=T)
