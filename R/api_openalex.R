#' Query OpenAlex for candidate metadata
#'
#' @param records A tibble with at least record_id and title.
#'
#' @return A tibble of candidate matches.
#' @export
query_openalex <- function(records) {
  purrr::map_dfr(seq_len(nrow(records)), function(i) {
    rec <- records[i, , drop = FALSE]
    
    title <- rec$title[[1]]
    if (is.na(title) || title == "") {
      return(tibble::tibble())
    }
    
    req <- httr2::request("https://api.openalex.org/works") |>
      httr2::req_url_query(search = title, `per-page` = 3)
    
    resp <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
    
    if (is.null(resp)) {
      return(tibble::tibble())
    }
    
    dat <- tryCatch(
      jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE),
      error = function(e) NULL
    )
    
    if (is.null(dat) || is.null(dat$results) || length(dat$results) == 0) {
      return(tibble::tibble())
    }
    
    purrr::map_dfr(dat$results, function(res) {
      authors <- NA_character_
      if (!is.null(res$authorships) && length(res$authorships) > 0) {
        author_names <- purrr::map_chr(res$authorships, function(a) {
          if (!is.null(a$author) && !is.null(a$author$display_name)) {
            a$author$display_name
          } else {
            NA_character_
          }
        })
        author_names <- author_names[!is.na(author_names)]
        if (length(author_names) > 0) {
          authors <- paste(author_names, collapse = "; ")
        }
      }
      
      journal <- NA_character_
      publisher <- NA_character_
      if (!is.null(res$primary_location) && !is.null(res$primary_location$source)) {
        journal <- res$primary_location$source$display_name %||% NA_character_
        publisher <- res$primary_location$source$host_organization_name %||% NA_character_
      }
      
      abstract <- NA_character_
      if (!is.null(res$abstract_inverted_index)) {
        abstract <- build_openalex_abstract(res$abstract_inverted_index)
      }
      
      tibble::tibble(
        record_id = rec$record_id[[1]],
        source_api = "openalex",
        raw_id = res$id %||% NA_character_,
        title = res$display_name %||% NA_character_,
        authors = authors,
        year = res$publication_year %||% NA_integer_,
        journal = journal,
        volume = NA_character_,
        publisher = publisher,
        doi = res$doi %||% NA_character_,
        abstract = abstract,
        title_score = title_similarity(title, res$display_name %||% ""),
        id_score = 0,
        author_score = 0,
        year_score = 0,
        journal_score = 0
      )
    })
  })
}

#' Rebuild abstract from OpenAlex inverted index
#'
#' @param inverted_index OpenAlex abstract inverted index.
#'
#' @return Character scalar or NA.
#' @keywords internal
build_openalex_abstract <- function(inverted_index) {
  if (is.null(inverted_index) || length(inverted_index) == 0) {
    return(NA_character_)
  }
  
  pairs <- purrr::imap(inverted_index, function(pos, word) {
    tibble::tibble(pos = unlist(pos), word = word)
  }) |>
    dplyr::bind_rows()
  
  pairs |>
    dplyr::arrange(.data$pos) |>
    dplyr::pull(.data$word) |>
    paste(collapse = " ")
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}