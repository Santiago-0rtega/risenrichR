#' Resolve the best candidate per record
#'
#' @param candidates A scored candidate tibble.
#' @param min_score Minimum confidence score for acceptance.
#'
#' @return A tibble of resolved records.
#' @export
resolve_fields <- function(candidates, min_score = 0.80) {
  if (nrow(candidates) == 0) {
    return(tibble::tibble())
  }
  
  candidates |>
    dplyr::group_by(.data$record_id) |>
    dplyr::arrange(dplyr::desc(.data$confidence_score), .by_group = TRUE) |>
    dplyr::slice(1) |>
    dplyr::ungroup() |>
    dplyr::transmute(
      record_id = .data$record_id,
      title_resolved = .data$title,
      authors_resolved = .data$authors,
      year_resolved = .data$year,
      journal_resolved = .data$journal,
      volume_resolved = .data$volume,
      publisher_resolved = .data$publisher,
      doi_resolved = .data$doi,
      abstract_resolved = .data$abstract,
      best_api = .data$source_api,
      best_score = .data$confidence_score,
      match_status = dplyr::if_else(.data$confidence_score >= min_score, "matched", "low_confidence")
    )
}