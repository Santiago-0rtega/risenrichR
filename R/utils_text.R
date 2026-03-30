#' Normalize text for matching
#'
#' @param x Character vector.
#'
#' @return Character vector.
#' @keywords internal
normalize_text <- function(x) {
  x |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^[:alnum:][:space:]]", " ") |>
    stringr::str_squish()
}

#' Compute title similarity
#'
#' @param x First title.
#' @param y Second title.
#'
#' @return Numeric score between 0 and 1.
#' @keywords internal
title_similarity <- function(x, y) {
  x2 <- normalize_text(x)
  y2 <- normalize_text(y)
  
  if (is.na(x2) || is.na(y2) || x2 == "" || y2 == "") {
    return(0)
  }
  
  1 - stringdist::stringdist(x2, y2, method = "jw")
}