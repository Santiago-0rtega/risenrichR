# ris-enrich

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**ris-enrich** is an automated tool designed to enrich RIS bibliography files with full abstracts via academic APIs. It is particularly useful for researchers conducting systematic reviews and meta-analyses who need complete abstracts for screening.

## Features

-   **Automated Enrichment**: Parses `.ris` files and retrieves missing abstracts.
-   **Multi-Source Fallback**: Queries Semantic Scholar, OpenAlex, Europe PMC, and Crossref in a cascading sequence.
-   **High Fidelity**: Uses strict title similarity checks (levenshtein distance) to prevent false positives.
-   **Unicode Support**: Handles international characters (Cyrillic, Kanji, Diacritics) correctly.

## Installation

You can install `ris-enrich` directly from the source:

```bash
pip install .
```

## Usage

After installation, you can use the `ris-enrich` command line tool:

```bash
ris-enrich input_file.ris -o output_file.ris
```

### Arguments

-   `input_file`: Path to the original `.ris` file (Required).
-   `-o`, `--output`: Path to save the enriched `.ris` file. Defaults to `*_Enriched.ris`.
-   `-l`, `--log`: Path to save the execution log. Defaults to `enrichment_log.txt`.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
