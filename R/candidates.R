#' Extract candidate matches
#'
#' @param x An `enriched_refs` object.
#'
#' @return A tibble of candidate matches.
#' @export
candidates <- function(x) {
  x$candidates
}