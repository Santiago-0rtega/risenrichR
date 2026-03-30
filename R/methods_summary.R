#' Summarize an enriched_refs object
#'
#' @param object An `enriched_refs` object.
#' @param ... Unused.
#'
#' @return A summary list, invisibly.
#' @export
summary.enriched_refs <- function(object, ...) {
  resolved <- object$resolved
  candidates <- object$candidates
  failures <- object$failures
  
  n_total <- nrow(resolved)
  n_fail <- nrow(failures)
  n_resolved <- n_total - n_fail
  
  cat("<enriched_refs summary>\n")
  cat("Records processed:", n_total, "\n")
  cat("Resolved:", n_resolved, "\n")
  cat("Unresolved:", n_fail, "\n")
  cat("Candidate rows:", nrow(candidates), "\n")
  
  if (nrow(resolved) > 0 && "best_api" %in% names(resolved)) {
    cat("\nTop sources used:\n")
    print(sort(table(resolved$best_api), decreasing = TRUE))
  }
  
  invisible(list(
    records_processed = n_total,
    resolved = n_resolved,
    unresolved = n_fail,
    candidate_rows = nrow(candidates)
  ))
}