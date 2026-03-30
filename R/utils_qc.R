#' Flag suspicious title strings
#'
#' @param x Character vector of titles.
#'
#' @return Character vector of quality labels.
#' @keywords internal
flag_title_quality <- function(x) {
  vapply(x, function(tt) {
    if (is.na(tt) || !nzchar(tt)) {
      return("missing")
    }
    
    tt2 <- stringr::str_squish(tt)
    words <- stringr::str_split(tt2, "\\s+", simplify = FALSE)[[1]]
    n_words <- length(words)
    
    tt_lower <- stringr::str_to_lower(tt2)
    
    has_title_punct <- stringr::str_detect(tt2, "[:\\-–—]")
    has_stopwords <- stringr::str_detect(
      tt_lower,
      "\\b(de|da|do|das|dos|e|em|para|por|the|of|and|in|na|no|nas|nos|um|uma|o|a|os|as)\\b"
    )
    
    # Unicode-aware: letters plus apostrophe/hyphen only
    all_words_alpha <- all(stringr::str_detect(words, "^[\\p{L}'-]+$"))
    lower_prop <- mean(words == stringr::str_to_lower(words))
    
    # Likely malformed author-name string rather than a title
    if (n_words >= 3 &&
        n_words <= 6 &&
        all_words_alpha &&
        lower_prop >= 0.8 &&
        !has_title_punct &&
        !has_stopwords) {
      return("suspect_non_title")
    }
    
    # Short titles are not necessarily wrong, only harder to match
    if (nchar(tt2) < 15) {
      return("short_title")
    }
    
    "ok"
  }, character(1))
}