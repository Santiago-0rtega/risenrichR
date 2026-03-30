#' Bind multiple enriched_refs objects
#'
#' @param ... Objects of class `enriched_refs`.
#'
#' @return A combined `enriched_refs` object.
#' @export
bind_enriched <- function(...) {
  xs <- list(...)
  
  stopifnot(all(vapply(xs, inherits, logical(1), what = "enriched_refs")))
  
  new_enriched_refs(
    resolved = dplyr::bind_rows(lapply(xs, function(z) z$resolved)),
    candidates = dplyr::bind_rows(lapply(xs, function(z) z$candidates)),
    provenance = dplyr::bind_rows(lapply(xs, function(z) z$provenance)),
    diagnostics = dplyr::bind_rows(lapply(xs, function(z) z$diagnostics)),
    failures = dplyr::bind_rows(lapply(xs, function(z) z$failures)),
    summary = list(),
    config = list()
  )
}