---
title: 'ris-enrich: An automated tool for enriching bibliographic RIS files with full abstracts'
tags:
  - Python
  - systematic reviews
  - meta-analysis
  - bibliometrics
  - open scholarship
authors:
  - name: Eduardo Santos
    orcid: 0000-0000-0000-0000 # Replace with your ORCID
    affiliation: 1
affiliations:
 - name: University of Alberta, Canada
   index: 1
date: 26 February 2026
bibliography: paper.bib
---

# Summary

Systematic reviews and meta-analyses require rigorous literature screening, a process highly dependent on the availability of accurate paper abstracts. However, researchers often encounter a significant bottleneck during the discovery phase: major academic search engines, such as Google Scholar, routinely truncate abstracts in their bulk `.ris` bibliographic exports. `ris-enrich` is an open-source Python package designed to resolve this data loss. It parses `.ris` files and cascades searches across four major open academic databases (Semantic Scholar, OpenAlex, Europe PMC, and Crossref) to retrieve and append the full-text abstracts, utilizing strict NFKC Unicode normalization and fuzzy string matching to prevent false-positive data contamination.

# Statement of need

The preparation of a preregistration protocol and the subsequent screening workload in systematic reviews (e.g., in fields like ecology, evolution, and psychology) are heavily reliant on the integrity of the initial bibliographic dataset. While tools exist to optimize search string generation [@Grames2019] or facilitate manual screening (e.g., Rayyan), there is a distinct lack of lightweight tools focused strictly on bibliographic data enrichment post-export. 

When researchers export search results, they are frequently left with snippets rather than full abstracts, rendering title-and-abstract screening virtually impossible without manual intervention. `ris-enrich` automates the recovery of this missing metadata. By prioritizing a sequential API fallback architecture and enforcing an 80% title-similarity threshold using the `difflib` and `unicodedata` libraries, the software ensures high-fidelity data retrieval even across international, diacritic-heavy, and logographic languages. 

`ris-enrich` was developed to directly support the screening workflows of university research centres, seamlessly preparing robust `.ris` datasets for assignment among primary and secondary screeners. 

# Acknowledgements

We acknowledge contributions from [Name any co-authors, e.g., Losia or team members, or funding sources for the centre].

# References