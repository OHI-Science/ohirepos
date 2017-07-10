#' Create GitHub Repo
#'
#' @param key OHI assessment identifier, e.g. 'gye' for 'Gulf of Guayaquil'
#' @param gh_token GitHub Token
#' @param github_user GitHub User, set in create_init.r
#'
#' @return
#' @export
#'
#' @examples
create_gh_repo <- function(key, gh_token, github_user){

  ## TODO delete this no longer needed, do by hand. But make sure rebuild package successfully

  # ## Create a temporary directory to hold the repository
  # path <- path.expand(file.path('~/github/clip-n-ship', key))
  # dir.create(path)
  #
  # ## clone existing repo (put warning and waiting message)
  # repo <- git2r::clone(url = sprintf('https://github.com/OHI-Science/%s', key),
  #                      local_path = path)
  #
  # #
  # # ## Initialize the repository
  # # repo <- git2r::init(path)
  #
  # #   ## Display a brief summary of the new repository
  # #   repo
  # #
  # #   ## Config user and commit a file
  # #   git2r::config(repo, user.name="jules32", user.email="lowndes@nceas.ucsb.edu")
  # #
  # #
  # #   git2r::is_bare(repo)
  # #   git2r::is_empty(repo)
  # #
  # writeLines("Hello world!", file.path(path, "test.txt"))
  #
  # ## Add file and commit
  # git2r::add(repo, "test.txt")
  # git2r::commit(repo, "Commit README")
  # #
  # #   git2r::branches(repo)
  # # git2r::branch_get_upstream(head(repo))
  # #
  # git2r::push(repo) #, "master", "origin/master")
  # #
  # #
  # #   ## from push help BOO
  # #   # path_bare <- file.path('~/github/clip-n-ship/bare')
  # #   # path_repo <- file.path('~/github/clip-n-ship', key)
  # #   # dir.create(path_bare)
  # #   # dir.create(path_repo)
  # #   # repo_bare <- git2r::init(path_bare, bare = TRUE)
  # #   # repo <- git2r::clone(path_bare, path_repo)
  # #
  # #
  # #   ## ORIG BELOW
  # #
  # #
  # #   cmd <- sprintf('git ls-remote git@github.com:ohi-science/%s.git', key)
  # #   res <- system(cmd, ignore.stderr=T, intern=T)
  # #   repo_exists <- ifelse(length(res)!=0, T, F)
  # #
  # #   ## create and run command call using Github API: https://developer.github.com/v3/repos/#create
  # #   if (!repo_exists){
  # #     message(sprintf('%s: creating github repo -- %s', key, format(Sys.time(), '%X')))
  # #
  # #     ## create command
  # #     cmd <- sprintf('curl --silent -u "%s:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'',
  # #                    github_user, gh_token, key)
  # #     ## run command
  # #     cmd_res = paste(capture.output(jsonlite::fromJSON(system(cmd, intern=T))), collapse='\n')
  # #
  # #   } else{
  # #     message(sprintf('%s: repo already exists.', key))
  # #
  # #   }

}
