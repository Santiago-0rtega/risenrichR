"""
RIS Abstract Enricher (Multilingual & Stable Version)

This script processes a .ris file (often exported from Google Scholar or 
other databases with truncated snippets) and attempts to retrieve the full, 
complete abstract for each record. 

It safely handles international characters (Cyrillic, Kanji, Diacritics) 
and queries four major open academic databases in a cascading sequence:
1. Semantic Scholar
2. OpenAlex
3. Europe PMC
4. Crossref

To prevent false positives, the script enforces a strict text similarity 
threshold (default 80%) between the requested title and the title returned 
by the API.

Usage:
    python enrich_abstracts.py input_file.ris -o output_file.ris -l log.txt
"""

import rispy
import requests
import time
import os
import argparse
import logging
import re
import unicodedata
from rapidfuzz import fuzz
from unidecode import unidecode

# =========================
# Configuration & Setup
# =========================

# The minimum similarity ratio (0 to 100) required between the search title
# and the API result title to accept the abstract. Protects against false positives.
SIMILARITY_THRESHOLD = 80

def get_crossref_email(email_arg=None):
    """
    Determines the email to use for Crossref API.
    Prioritizes argument, then environment variable.
    """
    if email_arg:
        return email_arg
    return os.environ.get("RIS_ENRICH_EMAIL")

def setup_logging(log_file):
    """
    Configures the logging system to output to both the console and a file.
    
    Args:
        log_file (str): The file path where the log will be saved.
    """
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Clear existing handlers to prevent duplicate logs if run interactively
    if logger.hasHandlers():
        logger.handlers.clear()
        
    formatter = logging.Formatter('%(asctime)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    
    # File handler records everything for auditing
    fh = logging.FileHandler(log_file, encoding='utf-8')
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    
    # Console handler keeps terminal output clean and readable
    ch = logging.StreamHandler()
    ch.setFormatter(logging.Formatter('%(message)s'))
    logger.addHandler(ch)

# =========================
# Cleaning & Verification
# =========================

def clean_html_tags(text):
    """
    Removes HTML/XML tags from a string. Often necessary for Crossref 
    and Europe PMC abstracts which may contain tags like <jats:p>.
    
    Args:
        text (str): The raw abstract text.
        
    Returns:
        str: The cleaned abstract text with tags removed and spacing normalized.
    """
    if not text:
        return text
    clean = re.sub(r'<[^>]+>', ' ', text)
    return re.sub(r'\s+', ' ', clean).strip()

def normalize_text(text):
    """
    Standardizes text by using NFKC normalization (handling international characters)
    and removing punctuation, but PRESERVING accents.
    """
    if not text:
        return ""
    # NFKC normalizes characters (e.g., full-width to half-width) but keeps accents composed
    norm = unicodedata.normalize('NFKC', text).lower()
    # Strip punctuation (\w natively supports international word characters like 'ç', 'ã', 'ñ')
    return re.sub(r'[^\w\s]', '', norm)

def verify_title_match(query_title, result_title, threshold=SIMILARITY_THRESHOLD):
    """
    Compares two titles to verify if the API returned the correct paper.
    """
    if not query_title or not result_title:
        return False
        
    # Use the helper function we just created
    clean_q = normalize_text(query_title)
    clean_r = normalize_text(result_title)
    
    similarity = fuzz.ratio(clean_q, clean_r)
    return similarity >= threshold

def build_openalex_abstract(inverted_index):
    """
    Reconstructs a readable abstract string from OpenAlex's inverted index format.
    
    Args:
        inverted_index (dict): A dictionary mapping words to their position indices.
        
    Returns:
        str: The reconstructed, readable abstract paragraph.
    """
    if not inverted_index:
        return None
    word_index = []
    for word, positions in inverted_index.items():
        for pos in positions:
            word_index.append((pos, word))
            
    # Sort the words by their positional index to rebuild the sentence structure
    word_index.sort(key=lambda x: x[0])
    return " ".join([word for pos, word in word_index])

# =========================
# API Fetchers
# =========================

def fetch_semantic(title=None, doi=None):
    """Queries the Semantic Scholar API for an abstract."""
    base_url = "https://api.semanticscholar.org/graph/v1/paper"
    if doi:
        try:
            response = requests.get(f"{base_url}/DOI:{doi}?fields=title,abstract", timeout=10)
            if response.status_code == 200:
                return response.json().get('abstract')
        except requests.RequestException: pass
        
    if title:
        try:
            response = requests.get(f"{base_url}/search", params={'query': title, 'limit': 1, 'fields': 'title,abstract'}, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get('data') and verify_title_match(title, data['data'][0].get('title', '')):
                    return data['data'][0].get('abstract')
        except requests.RequestException: pass
    return None

def fetch_openalex(title=None, doi=None):
    """Queries the OpenAlex API for an abstract and decodes the inverted index."""
    base_url = "https://api.openalex.org/works"
    if doi:
        try:
            response = requests.get(f"{base_url}/https://doi.org/{doi}", timeout=10)
            if response.status_code == 200:
                return build_openalex_abstract(response.json().get('abstract_inverted_index'))
        except requests.RequestException: pass
        
    if title:
        try:
            response = requests.get(f"{base_url}?search={title}&per-page=1", timeout=10)
            if response.status_code == 200:
                results = response.json().get('results', [])
                if results and verify_title_match(title, results[0].get('title', '')):
                    return build_openalex_abstract(results[0].get('abstract_inverted_index'))
        except requests.RequestException: pass
    return None

def fetch_europepmc(title=None, doi=None):
    """Queries the Europe PMC API, enforcing exact phrase matching for titles."""
    base_url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search"
    query = f'DOI:"{doi}"' if doi else f'TITLE:"{title}"' if title else None
    
    if not query: return None
    try:
        response = requests.get(base_url, params={'query': query, 'format': 'json', 'resultType': 'core'}, timeout=10)
        if response.status_code == 200:
            results = response.json().get('resultList', {}).get('result', [])
            if results and (doi or verify_title_match(title, results[0].get('title', ''))):
                return clean_html_tags(results[0].get('abstractText'))
    except requests.RequestException: pass
    return None

def fetch_crossref(title=None, doi=None, email=None):
    """Queries the Crossref API, safely encoding international titles."""
    base_url = "https://api.crossref.org/works"

    headers = {}
    if email:
        headers['User-Agent'] = f'AbstractEnricher/1.0 (mailto:{email})'
    
    if doi:
        try:
            response = requests.get(f"{base_url}/{doi}", headers=headers, timeout=10)
            if response.status_code == 200:
                return clean_html_tags(response.json().get('message', {}).get('abstract'))
        except requests.RequestException: pass
        
    if title:
        try:
            # Passed securely through the params dictionary for safe URL encoding
            params = {
                'query.title': title,
                'select': 'title,abstract',
                'rows': 1
            }
            response = requests.get(base_url, params=params, headers=headers, timeout=10)
            if response.status_code == 200:
                items = response.json().get('message', {}).get('items', [])
                if items and verify_title_match(title, items[0].get('title', [''])[0]):
                    return clean_html_tags(items[0].get('abstract'))
        except requests.RequestException: pass
    return None

# =========================
# Main Execution
# =========================

def enrich_ris_file(input_path, output_path, email=None):
    """
    Reads a .ris file, iterates through records to find missing abstracts, 
    queries databases in sequence, and saves the enriched data to a new file.
    
    Args:
        input_path (str): Filepath of the original .ris file.
        output_path (str): Filepath where the updated .ris file will be saved.
        email (str): Email for Crossref API.
    """
    logging.info(f"Reading '{input_path}'...")
    
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            entries = rispy.load(f)
    except Exception as e:
        logging.error(f"Failed to read RIS file: {e}")
        return

    logging.info(f"Found {len(entries)} references. Starting enrichment...\n")
    updated_count = 0
    
    crossref_contact = get_crossref_email(email)
    if not crossref_contact:
        logging.warning("No email provided for Crossref API. Rate limits may be lower. Use --email or set RIS_ENRICH_EMAIL.")

    for i, entry in enumerate(entries):
        title = entry.get('title') or entry.get('primary_title')
        doi = entry.get('doi')
        current_abstract = entry.get('abstract', '')
        
        # Skip if we already have a reasonably long abstract (> 300 chars)
        if current_abstract and len(str(current_abstract)) > 300:
            continue
            
        if title or doi:
            display_name = doi if doi else f"{title[:50]}..."
            logging.info(f"[{i+1}/{len(entries)}] Searching: {display_name}")
            
            new_abstract = None
            source = ""
            
            # Cascade logic: Attempt APIs sequentially until an abstract is found
            if not new_abstract:
                new_abstract, source = fetch_semantic(title, doi), "Semantic Scholar"
            if not new_abstract:
                new_abstract, source = fetch_openalex(title, doi), "OpenAlex"
            if not new_abstract:
                new_abstract, source = fetch_europepmc(title, doi), "Europe PMC"
            if not new_abstract:
                new_abstract, source = fetch_crossref(title, doi, email=crossref_contact), "Crossref"
            
            if new_abstract:
                entry['abstract'] = new_abstract
                updated_count += 1
                logging.info(f"   -> Found abstract via {source} ({len(new_abstract)} chars)")
            else:
                logging.info("   -> No exact matching abstract found.")
            
            # Polite delay to prevent free-tier API rate limiting (HTTP 429 errors)
            time.sleep(1.5) 
            
    # Save the updated references back to disk
    with open(output_path, 'w', encoding='utf-8') as f:
        rispy.dump(entries, f)
        
    logging.info(f"\nDone! Safely updated {updated_count} abstracts.")

def main():
    # Setup command line argument parsing
    parser = argparse.ArgumentParser(description="Enrich RIS files with full abstracts via academic APIs.")
    parser.add_argument("input_file", help="Path to the original .ris file")
    parser.add_argument("-o", "--output", help="Path to save the enriched .ris file", default=None)
    parser.add_argument("-l", "--log", help="Path to save the execution log", default="enrichment_log.txt")
    parser.add_argument("-e", "--email", help="Email for Crossref API (Polite Pool)", default=None)

    args = parser.parse_args()
    
    # Auto-generate the output filename if one is not explicitly provided
    if not args.output:
        base, ext = os.path.splitext(args.input_file)
        args.output = f"{base}_Enriched{ext}"
        
    setup_logging(args.log)
    
    # Execute the main pipeline
    if os.path.exists(args.input_file):
        enrich_ris_file(args.input_file, args.output, email=args.email)
    else:
        logging.error("Fatal Error: Input file not found.")

if __name__ == "__main__":
    main()