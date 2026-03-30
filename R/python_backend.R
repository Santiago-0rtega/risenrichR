#' Ensure required Python packages are available
#'
#' @param packages Character vector of Python package names.
#'
#' @return Invisibly TRUE.
#' @keywords internal
ensure_python_packages <- function(packages) {
  reticulate::py_require(packages)
  invisible(TRUE)
}

#' Ensure rispy is available in the active Python environment
#'
#' @return Invisibly TRUE.
#' @keywords internal
ensure_python_rispy <- function() {
  ensure_python_packages("rispy")
  invisible(TRUE)
}

#' Define Python helpers for RIS parsing
#'
#' @return Invisibly TRUE.
#' @keywords internal
define_python_ris_helpers <- function() {
  ensure_python_rispy()
  
  reticulate::py_run_string("
import rispy

def load_ris_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return rispy.load(f)
")
  
  invisible(TRUE)
}

#' Parse a RIS file with the Python backend
#'
#' @param path Path to a RIS file.
#'
#' @return A Python-derived list of records.
#' @keywords internal
parse_ris_python <- function(path) {
  if (!file.exists(path)) {
    stop('RIS file not found: ', path)
  }
  
  define_python_ris_helpers()
  reticulate::py$load_ris_file(path)
}

#' Define Python helpers for BibTeX writing
#'
#' @return Invisibly TRUE.
#' @keywords internal
define_python_bib_helpers <- function() {
  reticulate::py_run_string("
def _bib_escape(value):
    if value is None:
        return ''
    s = str(value)
    s = s.replace('\\\\', '\\\\\\\\')
    s = s.replace('{', '\\\\{')
    s = s.replace('}', '\\\\}')
    return s

def write_bib_file(records, path):
    with open(path, 'w', encoding='utf-8') as f:
        for rec in records:
            entry_type = rec.get('entry_type', 'misc') or 'misc'
            entry_key = rec.get('entry_key', 'ref') or 'ref'

            f.write(f'@{entry_type}{{{entry_key},\\n')

            field_order = [
                'title', 'author', 'year', 'journal', 'booktitle',
                'publisher', 'volume', 'number', 'pages',
                'doi', 'url', 'abstract', 'keywords', 'note'
            ]

            for fld in field_order:
                val = rec.get(fld, None)
                if val is None:
                    continue
                sval = str(val).strip()
                if sval == '' or sval == 'NA':
                    continue
                sval = _bib_escape(sval)
                f.write(f'  {fld} = {{{sval}}},\\n')

            f.write('}\\n\\n')
")
  
  invisible(TRUE)
}

#' Write BibTeX records with the Python backend
#'
#' @param records A list of BibTeX-like record dictionaries.
#' @param path Output path.
#'
#' @return Invisibly TRUE.
#' @keywords internal
write_bib_python <- function(records, path) {
  define_python_bib_helpers()
  reticulate::py$write_bib_file(records, path)
  invisible(TRUE)
}