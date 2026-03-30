#' Enrich scholarly references using open APIs
#'
#' @param input A file path, data frame, tibble, or character vector.
#' @param input_type Input type.
#' @param fields Fields to enrich.
#' @param apis APIs to query.
#' @param fuzzy Whether to use fuzzy title matching.
#' @param return_candidates Whether to retain candidate matches.
#' @param best_match_min_score Minimum score required for a confident match.
#' @param cache Whether to use caching.
#' @param parallel Whether to use parallel processing.
#' @param use_python_fallback Whether to use the packaged Python backend if needed.
#' @param return_format Output format.
#'
#' @return An object of class `enriched_refs` or a tibble.
#' @export
enrich_refs <- function(
    input,
    input_type = c("auto", "ris", "bib", "csv", "json", "data.frame", "titles", "doi", "pmid", "pmcid", "arxiv"),
    fields = c("abstract", "doi", "journal", "authors", "volume", "publisher", "year"),
    apis = c("openalex", "crossref", "openaire"),
    fuzzy = TRUE,
    return_candidates = TRUE,
    best_match_min_score = 0.70,
    cache = TRUE,
    parallel = FALSE,
    use_python_fallback = TRUE,
    return_format = c("enriched_refs", "tibble")
) {
  input_type <- match.arg(input_type)
  return_format <- match.arg(return_format)
  
  records <- read_input_refs(input, input_type = input_type)
  
  if (!"title" %in% names(records)) {
    stop("Current prototype expects a 'title' column or title-like input.")
  }
  
  if (!"title_quality" %in% names(records)) {
    records$title_quality <- flag_title_quality(records$title)
  }
  
  records_ok <- records |>
    dplyr::filter(.data$title_quality == "ok")
  
  records_bad <- records |>
    dplyr::filter(.data$title_quality != "ok")
  
  candidate_tables <- list()
  
  if ("openalex" %in% apis && nrow(records_ok) > 0) {
    candidate_tables[["openalex"]] <- query_openalex(records_ok)
  }
  
  if ("crossref" %in% apis && nrow(records_ok) > 0) {
    candidate_tables[["crossref"]] <- query_crossref(records_ok)
  }
  
  if ("openaire" %in% apis && nrow(records_ok) > 0) {
    candidate_tables[["openaire"]] <- query_openaire(records_ok)
  }
  
  candidates_tbl <- dplyr::bind_rows(candidate_tables)
  
  if (nrow(candidates_tbl) > 0) {
    candidates_tbl <- score_candidates(candidates_tbl)
    
    candidates_tbl <- candidates_tbl |>
      dplyr::group_by(.data$record_id) |>
      dplyr::arrange(dplyr::desc(.data$confidence_score), .by_group = TRUE) |>
      dplyr::mutate(match_rank = dplyr::row_number()) |>
      dplyr::ungroup()
    
    resolved_tbl <- resolve_fields(candidates_tbl, min_score = best_match_min_score)
  } else {
    resolved_tbl <- tibble::tibble(record_id = records_ok$record_id)
  }
  
  resolved_tbl <- records |>
    dplyr::left_join(resolved_tbl, by = "record_id")
  
  has_doi <- "doi" %in% names(resolved_tbl)
  
  failures_api <- resolved_tbl |>
    dplyr::filter(
      .data$title_quality == "ok" &
        (is.na(.data$best_score) | .data$match_status != "matched")
    ) |>
    dplyr::transmute(
      record_id = .data$record_id,
      title_original = .data$title,
      doi_original = if (has_doi) .data$doi else NA_character_,
      reason = dplyr::case_when(
        is.na(.data$best_score) ~ "no_candidate_found",
        .data$match_status != "matched" ~ "low_confidence_match",
        TRUE ~ "unknown"
      )
    )
  
  failures_qc <- records_bad |>
    dplyr::transmute(
      record_id = .data$record_id,
      title_original = .data$title,
      doi_original = if ("doi" %in% names(records_bad)) .data$doi else NA_character_,
      reason = .data$title_quality
    )
  
  failures_tbl <- dplyr::bind_rows(failures_api, failures_qc) |>
    dplyr::arrange(.data$record_id)
  
  out <- new_enriched_refs(
    resolved = resolved_tbl,
    candidates = if (isTRUE(return_candidates)) candidates_tbl else tibble::tibble(),
    provenance = tibble::tibble(),
    diagnostics = tibble::tibble(),
    failures = failures_tbl,
    summary = list(),
    config = list(
      input_type = input_type,
      fields = fields,
      apis = apis,
      fuzzy = fuzzy,
      cache = cache,
      parallel = parallel,
      use_python_fallback = use_python_fallback
    )
  )
  
  if (return_format == "tibble") {
    return(out$resolved)
  }
  
  out
}