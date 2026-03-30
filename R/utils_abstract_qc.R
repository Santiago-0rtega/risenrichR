#' Flag abstract quality
#'
#' @param x Character vector of abstracts.
#'
#' @return Character vector of abstract-quality labels.
#' @keywords internal
flag_abstract_quality <- function(x) {
  vapply(x, function(ab) {
    if (is.null(ab) || is.na(ab) || !nzchar(ab)) {
      return("missing")
    }
    
    ab2 <- stringr::str_squish(ab)
    n <- nchar(ab2)
    
    if (n < 80) {
      return("very_short")
    }
    
    if (grepl("…$", ab2) || grepl("\\.\\.\\.$", ab2)) {
      return("likely_truncated")
    }
    
    if (n < 250) {
      return("short")
    }
    
    "good"
  }, character(1))
}