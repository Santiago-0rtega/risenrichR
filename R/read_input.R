#' Read and normalize input references
#'
#' @param input File path, tibble, data.frame, or character vector.
#' @param input_type Input type.
#'
#' @return A tibble with standardized input columns.
#' @export
read_input_refs <- function(input, input_type = c("auto", "ris", "bib", "csv", "data.frame", "titles")) {
  input_type <- match.arg(input_type)
  
  if (input_type == "auto") {
    if (inherits(input, "data.frame")) {
      input_type <- "data.frame"
    } else if (is.character(input) && length(input) == 1) {
      ext <- tolower(tools::file_ext(input))
      input_type <- switch(
        ext,
        ris = "ris",
        bib = "bib",
        csv = "csv",
        "titles"
      )
    } else if (is.character(input)) {
      input_type <- "titles"
    }
  }
  
  if (input_type == "data.frame") {
    x <- tibble::as_tibble(input)
    
    if (!"record_id" %in% names(x)) {
      x$record_id <- seq_len(nrow(x))
    }
    
    if (!"title" %in% names(x)) {
      stop("Data frame input must contain a 'title' column.")
    }
    
    if (!"abstract" %in% names(x)) {
      x$abstract <- NA_character_
    }
    
    x$title_quality <- flag_title_quality(x$title)
    x$abstract_quality <- flag_abstract_quality(x$abstract)
    return(x)
  }
  
  if (input_type == "titles") {
    x <- tibble::tibble(
      record_id = seq_along(input),
      title = as.character(input),
      abstract = NA_character_
    )
    
    x$title_quality <- flag_title_quality(x$title)
    x$abstract_quality <- flag_abstract_quality(x$abstract)
    return(x)
  }
  
  if (input_type == "csv") {
    x <- read.csv(input, stringsAsFactors = FALSE)
    x <- tibble::as_tibble(x)
    
    if (!"record_id" %in% names(x)) {
      x$record_id <- seq_len(nrow(x))
    }
    
    if (!"title" %in% names(x)) {
      stop("CSV input must contain a 'title' column.")
    }
    
    if (!"abstract" %in% names(x)) {
      x$abstract <- NA_character_
    }
    
    x$title_quality <- flag_title_quality(x$title)
    x$abstract_quality <- flag_abstract_quality(x$abstract)
    return(x)
  }
  
  if (input_type == "ris") {
    entries <- parse_ris_python(input)
    
    out <- tibble::tibble(
      record_id = seq_along(entries),
      
      type_of_reference = vapply(
        entries,
        function(x) if (!is.null(x$type_of_reference)) x$type_of_reference else NA_character_,
        character(1)
      ),
      
      title = vapply(
        entries,
        function(x) {
          if (!is.null(x$title)) {
            x$title
          } else if (!is.null(x$primary_title)) {
            x$primary_title
          } else {
            NA_character_
          }
        },
        character(1)
      ),
      
      authors = vapply(
        entries,
        function(x) {
          vals <- x$authors %||% x$author %||% NULL
          if (is.null(vals) || length(vals) == 0) {
            return(NA_character_)
          }
          vals <- unlist(vals, recursive = TRUE, use.names = FALSE)
          vals <- vals[!is.na(vals) & nzchar(vals)]
          if (length(vals) == 0) NA_character_ else paste(vals, collapse = "; ")
        },
        character(1)
      ),
      
      abstract = vapply(
        entries,
        function(x) {
          if (!is.null(x$abstract)) x$abstract else NA_character_
        },
        character(1)
      ),
      
      year = vapply(
        entries,
        function(x) {
          val <- x$year %||% NULL
          if (is.null(val) || length(val) == 0 || is.na(val)) {
            return(NA_integer_)
          }
          suppressWarnings(as.integer(val[[1]]))
        },
        integer(1)
      ),
      
      date = vapply(
        entries,
        function(x) if (!is.null(x$date)) x$date else NA_character_,
        character(1)
      ),
      
      journal = vapply(
        entries,
        function(x) {
          vals <- x$journal_name %||% x$secondary_title %||% x$container_title %||% NULL
          if (is.null(vals) || length(vals) == 0) {
            return(NA_character_)
          }
          as.character(vals[[1]])
        },
        character(1)
      ),
      
      publisher = vapply(
        entries,
        function(x) if (!is.null(x$publisher)) x$publisher else NA_character_,
        character(1)
      ),
      
      doi = vapply(
        entries,
        function(x) {
          vals <- x$doi %||% NULL
          if (is.null(vals) || length(vals) == 0) {
            return(NA_character_)
          }
          as.character(vals[[1]])
        },
        character(1)
      ),
      
      language = vapply(
        entries,
        function(x) if (!is.null(x$language)) x$language else NA_character_,
        character(1)
      ),
      
      note = vapply(
        entries,
        function(x) if (!is.null(x$note)) x$note else NA_character_,
        character(1)
      ),
      
      urls = vapply(
        entries,
        function(x) {
          vals <- x$urls %||% x$url %||% NULL
          if (is.null(vals) || length(vals) == 0) {
            return(NA_character_)
          }
          vals <- unlist(vals, recursive = TRUE, use.names = FALSE)
          vals <- vals[!is.na(vals) & nzchar(vals)]
          if (length(vals) == 0) NA_character_ else paste(vals, collapse = "; ")
        },
        character(1)
      ),
      
      keywords = vapply(
        entries,
        function(x) {
          vals <- x$keywords %||% x$keyword %||% NULL
          if (is.null(vals) || length(vals) == 0) {
            return(NA_character_)
          }
          vals <- unlist(vals, recursive = TRUE, use.names = FALSE)
          vals <- vals[!is.na(vals) & nzchar(vals)]
          if (length(vals) == 0) NA_character_ else paste(vals, collapse = "; ")
        },
        character(1)
      ),
      
      raw_record = lapply(entries, identity)
    )
    
    out$title_quality <- flag_title_quality(out$title)
    out$abstract_quality <- flag_abstract_quality(out$abstract)
    
    return(out)
  }
  
  stop("Input type not implemented yet: ", input_type)
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}