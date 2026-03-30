#' Create an enriched_refs object
#'
#' @param resolved A tibble of resolved records.
#' @param candidates A tibble of candidate matches.
#' @param provenance A tibble of field-level provenance.
#' @param diagnostics A tibble of run and API diagnostics.
#' @param failures A tibble of unresolved or partially resolved records.
#' @param summary A list of summary statistics.
#' @param config A list of run configuration values.
#'
#' @return An object of class `enriched_refs`.
#' @export
new_enriched_refs <- function(
    resolved = tibble::tibble(),
    candidates = tibble::tibble(),
    provenance = tibble::tibble(),
    diagnostics = tibble::tibble(),
    failures = tibble::tibble(),
    summary = list(),
    config = list()
) {
  structure(
    list(
      resolved = resolved,
      candidates = candidates,
      provenance = provenance,
      diagnostics = diagnostics,
      failures = failures,
      summary = summary,
      config = config
    ),
    class = "enriched_refs"
  )
}

#' @export
print.enriched_refs <- function(x, ...) {
  n_total <- nrow(x$resolved)
  n_fail <- nrow(x$failures)
  n_ok <- n_total - n_fail
  
  cat("<enriched_refs>\n")
  cat("Records:", n_total, "\n")
  cat("Resolved:", n_ok, "\n")
  cat("Failures:", n_fail, "\n")
  cat("Candidates:", nrow(x$candidates), "\n")
  invisible(x)
}