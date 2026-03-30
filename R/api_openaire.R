#' Query OpenAIRE Graph API for candidate metadata
#'
#' @param records A tibble with at least record_id and title.
#'
#' @return A tibble of candidate matches.
#' @export
query_openaire <- function(records) {
  purrr::map_dfr(seq_len(nrow(records)), function(i) {
    rec <- records[i, , drop = FALSE]
    
    title <- rec$title[[1]]
    if (is.na(title) || title == "") {
      return(tibble::tibble())
    }
    
    req <- httr2::request("https://api.openaire.eu/graph/v2/researchProducts") |>
      httr2::req_url_query(
        search = title,
        type = "publication",
        page = 1,
        pageSize = 3,
        sortBy = "relevance DESC"
      ) |>
      httr2::req_headers(Accept = "application/json")
    
    resp <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
    
    if (is.null(resp)) {
      return(tibble::tibble())
    }
    
    dat <- tryCatch(
      jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE),
      error = function(e) NULL
    )
    
    if (is.null(dat)) {
      return(tibble::tibble())
    }
    
    items <- extract_openaire_results(dat)
    if (length(items) == 0) {
      return(tibble::tibble())
    }
    
    purrr::map_dfr(items, function(item) {
      cand_title <- extract_openaire_title(item)
      cand_authors <- extract_openaire_authors(item)
      cand_year <- extract_openaire_year(item)
      cand_journal <- extract_openaire_journal(item)
      cand_publisher <- extract_openaire_publisher(item)
      cand_doi <- extract_openaire_doi(item)
      cand_abstract <- extract_openaire_abstract(item)
      cand_id <- extract_openaire_id(item)
      
      tibble::tibble(
        record_id = rec$record_id[[1]],
        source_api = "openaire",
        raw_id = cand_id,
        title = cand_title,
        authors = cand_authors,
        year = cand_year,
        journal = cand_journal,
        volume = NA_character_,
        publisher = cand_publisher,
        doi = cand_doi,
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

#' Extract result list from OpenAIRE Graph API response
#'
#' @param dat Parsed JSON list.
#'
#' @return A list of result items.
#' @keywords internal
extract_openaire_results <- function(dat) {
  candidates <- list(
    dat$results,
    dat$items,
    dat$datasource,
    dat$researchProducts
  )
  
  for (x in candidates) {
    if (!is.null(x) && length(x) > 0) {
      return(x)
    }
  }
  
  list()
}

#' Extract a title from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_openaire_title <- function(item) {
  title_fields <- c("title", "mainTitle")
  
  for (fld in title_fields) {
    x <- item[[fld]]
    if (is.character(x) && length(x) > 0) {
      return(x[[1]])
    }
    if (is.list(x) && length(x) > 0) {
      vals <- unlist(x, recursive = TRUE, use.names = FALSE)
      vals <- vals[vals != ""]
      if (length(vals) > 0) {
        return(as.character(vals[[1]]))
      }
    }
  }
  
  NA_character_
}

#' Extract authors from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_openaire_authors <- function(item) {
  author_fields <- c("authors", "creators")
  
  for (fld in author_fields) {
    x <- item[[fld]]
    if (is.null(x) || length(x) == 0) {
      next
    }
    
    vals <- character(0)
    
    if (is.character(x)) {
      vals <- x
    } else if (is.list(x)) {
      vals <- purrr::map_chr(x, function(a) {
        if (is.character(a) && length(a) > 0) {
          return(a[[1]])
        }
        if (is.list(a)) {
          nm_fields <- c("fullName", "name", "fullname")
          for (nf in nm_fields) {
            if (!is.null(a[[nf]]) && length(a[[nf]]) > 0) {
              return(as.character(a[[nf]][[1]]))
            }
          }
        }
        NA_character_
      })
    }
    
    vals <- vals[!is.na(vals) & nzchar(vals)]
    if (length(vals) > 0) {
      return(paste(vals, collapse = "; "))
    }
  }
  
  NA_character_
}

#' Extract publication year from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Integer year or NA.
#' @keywords internal
extract_openaire_year <- function(item) {
  year_fields <- c("publicationDate", "dateOfAcceptance", "date")
  
  for (fld in year_fields) {
    x <- item[[fld]]
    if (is.null(x) || length(x) == 0) {
      next
    }
    
    if (is.character(x) && length(x) > 0) {
      m <- stringr::str_extract(x[[1]], "^[0-9]{4}")
      if (!is.na(m)) {
        return(as.integer(m))
      }
    }
    
    if (is.list(x)) {
      vals <- unlist(x, recursive = TRUE, use.names = FALSE)
      vals <- vals[!is.na(vals) & nzchar(vals)]
      if (length(vals) > 0) {
        m <- stringr::str_extract(vals[[1]], "^[0-9]{4}")
        if (!is.na(m)) {
          return(as.integer(m))
        }
      }
    }
  }
  
  NA_integer_
}

#' Extract journal title from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_openaire_journal <- function(item) {
  journal_fields <- c("journal", "containerTitle", "publisherName")
  
  for (fld in journal_fields) {
    x <- item[[fld]]
    if (is.character(x) && length(x) > 0) {
      return(x[[1]])
    }
    if (is.list(x) && length(x) > 0) {
      vals <- unlist(x, recursive = TRUE, use.names = FALSE)
      vals <- vals[vals != ""]
      if (length(vals) > 0) {
        return(as.character(vals[[1]]))
      }
    }
  }
  
  NA_character_
}

#' Extract publisher from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_openaire_publisher <- function(item) {
  publisher_fields <- c("publisher", "publisherName")
  
  for (fld in publisher_fields) {
    x <- item[[fld]]
    if (is.character(x) && length(x) > 0) {
      return(x[[1]])
    }
    if (is.list(x) && length(x) > 0) {
      vals <- unlist(x, recursive = TRUE, use.names = FALSE)
      vals <- vals[vals != ""]
      if (length(vals) > 0) {
        return(as.character(vals[[1]]))
      }
    }
  }
  
  NA_character_
}

#' Extract DOI from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_openaire_doi <- function(item) {
  doi_fields <- c("doi", "pid")
  
  for (fld in doi_fields) {
    x <- item[[fld]]
    if (is.character(x) && length(x) > 0) {
      vals <- x
    } else if (is.list(x) && length(x) > 0) {
      vals <- unlist(x, recursive = TRUE, use.names = FALSE)
    } else {
      next
    }
    
    vals <- vals[!is.na(vals) & nzchar(vals)]
    if (length(vals) == 0) {
      next
    }
    
    doi_match <- stringr::str_extract(vals, "10\\.[^[:space:]/]+/.+")
    doi_match <- doi_match[!is.na(doi_match)]
    if (length(doi_match) > 0) {
      return(doi_match[[1]])
    }
  }
  
  NA_character_
}

#' Extract abstract from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_openaire_abstract <- function(item) {
  abstract_fields <- c("description", "abstract")
  
  for (fld in abstract_fields) {
    x <- item[[fld]]
    if (is.character(x) && length(x) > 0) {
      return(stringr::str_squish(x[[1]]))
    }
    if (is.list(x) && length(x) > 0) {
      vals <- unlist(x, recursive = TRUE, use.names = FALSE)
      vals <- vals[!is.na(vals) & nzchar(vals)]
      if (length(vals) > 0) {
        return(stringr::str_squish(vals[[1]]))
      }
    }
  }
  
  NA_character_
}

#' Extract identifier from an OpenAIRE item
#'
#' @param item A single OpenAIRE item.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_openaire_id <- function(item) {
  id_fields <- c("id", "openaireId")
  
  for (fld in id_fields) {
    x <- item[[fld]]
    if (is.character(x) && length(x) > 0) {
      return(x[[1]])
    }
    if (is.list(x) && length(x) > 0) {
      vals <- unlist(x, recursive = TRUE, use.names = FALSE)
      vals <- vals[!is.na(vals) & nzchar(vals)]
      if (length(vals) > 0) {
        return(as.character(vals[[1]]))
      }
    }
  }
  
  NA_character_
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}