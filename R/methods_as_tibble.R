#' Convert enriched_refs components to a tibble
#'
#' @param x An `enriched_refs` object.
#' @param what Which component to return.
#' @param ... Unused.
#'
#' @return A tibble.
#' @importFrom tibble as_tibble
#' @exportS3Method tibble::as_tibble
as_tibble.enriched_refs <- function(
    x,
    what = c("resolved", "candidates", "provenance", "diagnostics", "failures"),
    ...
) {
  what <- match.arg(what)
  tibble::as_tibble(x[[what]])
}