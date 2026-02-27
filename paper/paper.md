---
title: 'ris-enrich: An automated tool for enriching bibliographic RIS files with full abstracts'
tags:
  - Python
  - systematic reviews
  - meta-analysis
  - bibliometrics
  - open scholarship
authors:
  - name: Eduardo S. A. Santos
    orcid: 0000-0002-0434-3655
    affiliation: 1
affiliations:
 - name: Collaboration for Open Science and Synthesis in Ecology and Evolution, Department of Biological Sciences, University of Alberta, Edmonton, AB, T6G 2E9, Canada
   index: 1
date: 26 February 2026
bibliography: paper.bib
link-citations: true
---

# Summary

Systematic reviews and meta-analyses require rigorous literature screening, a process highly dependent on the availability of accurate abstracts for each bibliographic record. However, researchers often encounter a  bottleneck during the discovery phase: some academic search engines, such as Google Scholar, routinely truncate abstracts in their bibliographic records. `ris-enrich` is an open-source Python package designed to resolve this data loss. It parses `.ris` files and cascades searches across four major open academic databases (Semantic Scholar, OpenAlex, Europe PMC, and Crossref) to retrieve and append the full-text abstracts, utilizing strict NFKC Unicode normalization and fuzzy string matching to prevent false-positive data contamination.

# Statement of need

The preparation of a preregistration protocol and the subsequent screening workload in evidence synthesis studies (e.g., in fields like ecology, evolution, and psychology) are reliant on the integrity of the initial bibliographic dataset. While tools exist to optimize search string generation [@gramesAutomatedApproachIdentifying2019] or facilitate the literature screening process, for example, Rayyan or SysRev [@ouzzaniRayyanWebMobile2016; @bozadaSysrevFAIRPlatform2021], there is a distinct lack of lightweight tools focused strictly on bibliographic data enrichment post-export. 

When researchers export search results, they are frequently left with snippets rather than full abstracts, rendering title-and-abstract screening virtually impossible without manual intervention. This is especially common from search records exported from Google Scholar that truncates abstracts. Google Scholar is one of the few search engines that retrieves academic records in non-English languages, thus being an important search engine in attempts to minimize bias in data collection for evidence synthesis studies.  `ris-enrich` automates the recovery of this missing metadata. By prioritizing a sequential API fallback architecture and enforcing an 80% title-similarity threshold using the `difflib` and `unicodedata` libraries, the software ensures high-fidelity data retrieval even across international, diacritic-heavy, and logographic languages. 

`ris-enrich` was developed to directly support the screening workflows of university research centres, seamlessly preparing robust `.ris` datasets for assignment among primary and secondary screeners. 

# Acknowledgements

ESAS, as well as this research work, are supported by the Canada Excellence Research Chairs (CERC) program (grant number CERC-2022-00074).


# AI usage disclosure
- **Tool use:** For this paper, I used Google Gemini 3.1 Pro to write the main code of this open-source Python package, and to prepare the initial versions of the documents of the github repository.

- **The nature and scope of assistance:** Assistance was used for code generation, refactoring, and test scaffolding.

# References