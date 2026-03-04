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
-   `-e`, `--email`: **(optional)** Your email address, which will be included in the User-Agent header when querying the Crossref API. Providing an email helps Crossref identify polite usage and may increase rate limits. You can also set this value by exporting `RIS_ENRICH_EMAIL` in your environment before running the tool:

    ```bash
    export RIS_ENRICH_EMAIL=you@example.com
    ris-enrich input_file.ris -o output_file.ris
    ```
    or pass it directly on the command line:

    ```bash
    ris-enrich input_file.ris -o output_file.ris --email you@example.com
    ```

## Usage Example

To test the tool with the included sample data, run:

```bash
ris-enrich data/GoogleScholarPortugueseMateChoiceExample.ris
```
## Future Roadmap
- [ ] Investigate direct integration with regional non-English databases (e.g., SciELO and LA Referencia for Latin America, J-STAGE for Japan) to catch records not yet indexed by major aggregators.
- [ ] Add support for custom API keys for power users.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
