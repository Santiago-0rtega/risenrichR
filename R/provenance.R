#' Extract provenance information
#'
#' @param x An `enriched_refs` object.
#'
#' @return A tibble of field-level provenance.
#' @export
provenance <- function(x) {
  x$provenance
}