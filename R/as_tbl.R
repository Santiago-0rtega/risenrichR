#' Extract a component of enriched_refs as a tibble
#'
#' @param x An `enriched_refs` object.
#' @param what Which component to extract.
#'
#' @return A tibble.
#' @export
as_tbl <- function(
    x,
    what = c("resolved", "candidates", "provenance", "diagnostics", "failures")
) {
  what <- match.arg(what)
  tibble::as_tibble(x[[what]])
}