#' Query Crossref for candidate metadata
#'
#' @param records A tibble with at least record_id and title.
#'
#' @return A tibble of candidate matches.
#' @export
query_crossref <- function(records) {
  purrr::map_dfr(seq_len(nrow(records)), function(i) {
    rec <- records[i, , drop = FALSE]
    
    title <- rec$title[[1]]
    if (is.na(title) || title == "") {
      return(tibble::tibble())
    }
    
    req <- httr2::request("https://api.crossref.org/works") |>
      httr2::req_url_query(
        `query.title` = title,
        rows = 3,
        select = "DOI,title,author,issued,container-title,publisher,abstract,volume"
      )
    
    resp <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
    
    if (is.null(resp)) {
      return(tibble::tibble())
    }
    
    dat <- tryCatch(
      jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE),
      error = function(e) NULL
    )
    
    if (is.null(dat) ||
        is.null(dat$message) ||
        is.null(dat$message$items) ||
        length(dat$message$items) == 0) {
      return(tibble::tibble())
    }
    
    purrr::map_dfr(dat$message$items, function(item) {
      cand_title <- NA_character_
      if (!is.null(item$title) && length(item$title) > 0) {
        cand_title <- item$title[[1]]
      }
      
      cand_authors <- NA_character_
      if (!is.null(item$author) && length(item$author) > 0) {
        author_names <- purrr::map_chr(item$author, function(a) {
          given <- a$given %||% ""
          family <- a$family %||% ""
          nm <- stringr::str_squish(paste(given, family))
          if (nm == "") NA_character_ else nm
        })
        author_names <- author_names[!is.na(author_names)]
        if (length(author_names) > 0) {
          cand_authors <- paste(author_names, collapse = "; ")
        }
      }
      
      cand_year <- extract_crossref_year(item)
      
      cand_journal <- NA_character_
      if (!is.null(item$`container-title`) && length(item$`container-title`) > 0) {
        cand_journal <- item$`container-title`[[1]]
      }
      
      cand_abstract <- NA_character_
      if (!is.null(item$abstract)) {
        cand_abstract <- clean_html_tags(item$abstract)
      }
      
      tibble::tibble(
        record_id = rec$record_id[[1]],
        source_api = "crossref",
        raw_id = item$DOI %||% NA_character_,
        title = cand_title,
        authors = cand_authors,
        year = cand_year,
        journal = cand_journal,
        volume = item$volume %||% NA_character_,
        publisher = item$publisher %||% NA_character_,
        doi = item$DOI %||% NA_character_,
        abstract = cand_abstract,
        title_score = title_similarity(title, cand_title %||% ""),
        id_score = 0,
        author_score = 0,
        year_score = 0,
        journal_score = 0
      )
    })
  })
}

#' Extract publication year from a Crossref item
#'
#' @param item A single Crossref item as a list.
#'
#' @return Integer year or NA_integer_.
#' @keywords internal
extract_crossref_year <- function(item) {
  date_fields <- c("issued", "published-print", "published-online", "created")
  
  for (fld in date_fields) {
    x <- item[[fld]]
    if (is.null(x) || is.null(x$`date-parts`) || length(x$`date-parts`) == 0) {
      next
    }
    
    first_part <- x$`date-parts`[[1]]
    
    if (is.list(first_part)) {
      first_part <- unlist(first_part, recursive = TRUE, use.names = FALSE)
    }
    
    if (length(first_part) > 0) {
      yr <- suppressWarnings(as.integer(first_part[[1]]))
      if (!is.na(yr)) {
        return(yr)
      }
    }
  }
  
  NA_integer_
}

#' Remove simple HTML/XML tags from text
#'
#' @param text Character scalar.
#'
#' @return Cleaned character scalar.
#' @keywords internal
clean_html_tags <- function(text) {
  if (is.null(text) || is.na(text) || !nzchar(text)) {
    return(NA_character_)
  }
  
  text |>
    stringr::str_replace_all("<[^>]+>", " ") |>
    stringr::str_squish()
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}