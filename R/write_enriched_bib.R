#' Write enriched references to a BibTeX file
#'
#' @param x An `enriched_refs` object.
#' @param path Output `.bib` file path.
#'
#' @return Invisibly returns `path`.
#' @export
write_enriched_bib <- function(x, path) {
  stopifnot(inherits(x, "enriched_refs"))
  
  records <- build_bib_records(x)
  write_bib_python(records, path)
  
  invisible(path)
}

#' Build BibTeX-like records from an enriched_refs object
#'
#' @param x An `enriched_refs` object.
#'
#' @return A list of records ready for Python BibTeX writing.
#' @keywords internal
build_bib_records <- function(x) {
  resolved <- x$resolved
  
  if (nrow(resolved) == 0) {
    return(list())
  }
  
  lapply(seq_len(nrow(resolved)), function(i) {
    row <- resolved[i, , drop = FALSE]
    
    title_val <- first_non_missing(
      row$title_resolved,
      row$title
    )
    
    author_val <- first_non_missing(
      row$authors_resolved,
      row$authors
    )
    
    year_val <- first_non_missing(
      row$year_resolved,
      row$year
    )
    
    journal_val <- first_non_missing(
      row$journal_resolved,
      row$journal
    )
    
    publisher_val <- first_non_missing(
      row$publisher_resolved,
      row$publisher
    )
    
    volume_val <- first_non_missing(
      row$volume_resolved
    )
    
    abstract_val <- first_non_missing(
      choose_abstract_value(row),
      row$abstract
    )
    
    doi_val <- first_non_missing(
      row$doi_resolved,
      row$doi
    )
    
    url_val <- first_non_missing(
      row$urls,
      extract_url_from_raw(row$raw_record[[1]])
    )
    
    keywords_val <- first_non_missing(
      row$keywords,
      extract_keywords_from_raw(row$raw_record[[1]])
    )
    
    note_val <- first_non_missing(
      row$note,
      extract_note_from_raw(row$raw_record[[1]])
    )
    
    entry_type <- map_ris_type_to_bib(row$type_of_reference)
    entry_key <- make_bib_key(
      author = author_val,
      year = year_val,
      title = title_val,
      record_id = row$record_id[[1]]
    )
    
    rec <- list(
      entry_type = entry_type,
      entry_key = entry_key,
      title = null_if_missing(title_val),
      author = null_if_missing(author_val),
      year = null_if_missing(year_val),
      journal = null_if_missing(journal_val),
      publisher = null_if_missing(publisher_val),
      volume = null_if_missing(volume_val),
      doi = null_if_missing(doi_val),
      url = null_if_missing(url_val),
      abstract = null_if_missing(abstract_val),
      keywords = null_if_missing(keywords_val),
      note = null_if_missing(note_val)
    )
    
    rec
  })
}

#' Choose the preferred abstract value for export
#'
#' @param row One-row tibble.
#'
#' @return Character scalar or NA.
#' @keywords internal
choose_abstract_value <- function(row) {
  original <- row$abstract[[1]]
  enriched <- row$abstract_resolved[[1]]
  
  oq <- if ("abstract_quality" %in% names(row)) row$abstract_quality[[1]] else NA_character_
  
  if (is_missing_value(original) && !is_missing_value(enriched)) {
    return(enriched)
  }
  
  if (!is_missing_value(original) && oq %in% c("very_short", "likely_truncated", "short")) {
    if (!is_missing_value(enriched) && nchar(enriched) > nchar(original)) {
      return(enriched)
    }
  }
  
  if (!is_missing_value(original)) {
    return(original)
  }
  
  enriched
}

#' Return first non-missing value from arguments
#'
#' @param ... Candidate values.
#'
#' @return First non-missing value, or NA.
#' @keywords internal
first_non_missing <- function(...) {
  vals <- list(...)
  
  for (v in vals) {
    if (length(v) == 0) {
      next
    }
    
    val <- v[[1]]
    
    if (!is_missing_value(val)) {
      return(val)
    }
  }
  
  NA
}

#' Check whether a value should be treated as missing
#'
#' @param x Any scalar.
#'
#' @return Logical scalar.
#' @keywords internal
is_missing_value <- function(x) {
  is.null(x) || length(x) == 0 || is.na(x) || !nzchar(as.character(x))
}

#' Convert missing values to NULL for Python export
#'
#' @param x Any scalar.
#'
#' @return NULL or scalar.
#' @keywords internal
null_if_missing <- function(x) {
  if (is_missing_value(x)) {
    return(NULL)
  }
  as.character(x)
}

#' Map RIS type to a BibTeX entry type
#'
#' @param x RIS type string.
#'
#' @return BibTeX entry type.
#' @keywords internal
map_ris_type_to_bib <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x)) {
    return("misc")
  }
  
  xx <- tolower(as.character(x[[1]]))
  
  if (xx %in% c("journal article", "article", "jfull", "ejour")) {
    return("article")
  }
  
  if (xx %in% c("book", "whole book")) {
    return("book")
  }
  
  if (xx %in% c("book chapter", "chapter")) {
    return("incollection")
  }
  
  if (xx %in% c("conference paper", "conference proceeding", "conference proceedings")) {
    return("inproceedings")
  }
  
  if (xx %in% c("thesis", "doctoral dissertation", "dissertation", "master's thesis")) {
    return("phdthesis")
  }
  
  "misc"
}

#' Make a BibTeX key
#'
#' @param author Author string.
#' @param year Year string/integer.
#' @param title Title string.
#' @param record_id Integer record id.
#'
#' @return Character scalar.
#' @keywords internal
make_bib_key <- function(author, year, title, record_id) {
  surname <- "ref"
  
  if (!is_missing_value(author)) {
    first_author <- strsplit(as.character(author), ";", fixed = TRUE)[[1]][1]
    first_author <- stringr::str_squish(first_author)
    parts <- strsplit(first_author, "\\s+")[[1]]
    if (length(parts) > 0) {
      surname <- tolower(parts[length(parts)])
      surname <- stringr::str_replace_all(surname, "[^[:alnum:]]", "")
      if (!nzchar(surname)) {
        surname <- "ref"
      }
    }
  }
  
  yy <- if (!is_missing_value(year)) as.character(year) else "nd"
  
  title_word <- "item"
  if (!is_missing_value(title)) {
    words <- strsplit(as.character(title), "\\s+")[[1]]
    words <- words[nzchar(words)]
    if (length(words) > 0) {
      title_word <- tolower(words[1])
      title_word <- stringr::str_replace_all(title_word, "[^[:alnum:]]", "")
      if (!nzchar(title_word)) {
        title_word <- "item"
      }
    }
  }
  
  paste0(surname, yy, title_word, "_", record_id)
}

#' Extract URL from raw parsed RIS record
#'
#' @param raw One raw record.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_url_from_raw <- function(raw) {
  if (is.null(raw)) {
    return(NA_character_)
  }
  
  vals <- raw$urls %||% raw$url %||% NULL
  if (is.null(vals) || length(vals) == 0) {
    return(NA_character_)
  }
  
  vals <- unlist(vals, recursive = TRUE, use.names = FALSE)
  vals <- vals[!is.na(vals) & nzchar(vals)]
  if (length(vals) == 0) {
    return(NA_character_)
  }
  
  paste(vals, collapse = "; ")
}

#' Extract keywords from raw parsed RIS record
#'
#' @param raw One raw record.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_keywords_from_raw <- function(raw) {
  if (is.null(raw)) {
    return(NA_character_)
  }
  
  vals <- raw$keywords %||% raw$keyword %||% NULL
  if (is.null(vals) || length(vals) == 0) {
    return(NA_character_)
  }
  
  vals <- unlist(vals, recursive = TRUE, use.names = FALSE)
  vals <- vals[!is.na(vals) & nzchar(vals)]
  if (length(vals) == 0) {
    return(NA_character_)
  }
  
  paste(vals, collapse = "; ")
}

#' Extract note from raw parsed RIS record
#'
#' @param raw One raw record.
#'
#' @return Character scalar or NA.
#' @keywords internal
extract_note_from_raw <- function(raw) {
  if (is.null(raw)) {
    return(NA_character_)
  }
  
  vals <- raw$note %||% NULL
  if (is.null(vals) || length(vals) == 0) {
    return(NA_character_)
  }
  
  as.character(vals[[1]])
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}