#' Score candidate matches
#'
#' @param candidates A tibble of candidates.
#' @param title_weight Weight for title score.
#' @param id_weight Weight for identifier score.
#' @param author_weight Weight for author score.
#' @param year_weight Weight for year score.
#' @param journal_weight Weight for journal score.
#'
#' @return The input tibble with a confidence_score column.
#' @export
score_candidates <- function(
    candidates,
    title_weight = 0.85,
    id_weight = 0.05,
    author_weight = 0.05,
    year_weight = 0.03,
    journal_weight = 0.02
) {
  candidates |>
    dplyr::mutate(
      title_score = dplyr::coalesce(.data$title_score, 0),
      id_score = dplyr::coalesce(.data$id_score, 0),
      author_score = dplyr::coalesce(.data$author_score, 0),
      year_score = dplyr::coalesce(.data$year_score, 0),
      journal_score = dplyr::coalesce(.data$journal_score, 0),
      confidence_score =
        title_weight * .data$title_score +
        id_weight * .data$id_score +
        author_weight * .data$author_score +
        year_weight * .data$year_score +
        journal_weight * .data$journal_score
    )
}