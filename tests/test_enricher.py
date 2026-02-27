import pytest
from unittest.mock import patch, MagicMock
from ris_enrich.enricher import (
    clean_html_tags,
    verify_title_match,
    normalize_text,
    fetch_semantic,
    enrich_ris_file,
    get_crossref_email
)
import os

def test_clean_html_tags():
    raw = "This is <jats:p>an abstract</jats:p> with tags."
    assert clean_html_tags(raw) == "This is an abstract with tags."

def test_normalize_text():
    # The code should remove accents (transliterate)
    assert normalize_text("Seleção Sexual") == "selecao sexual"
    
    # It should still fix full-width characters (Japanese/Chinese standard)
    assert normalize_text("Full-width Ａ") == "fullwidth a"

def test_verify_title_match():
    # Should pass (minor punctuation difference)
    assert verify_title_match("A study on birds", "A study on birds.") == True
    # Should fail (completely different)
    assert verify_title_match("Mate-choice copying", "Foraging behavior in bees") == False

@patch('ris_enrich.enricher.requests.get')
def test_fetch_semantic_success(mock_get):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        'data': [{'title': 'A study on birds', 'abstract': 'This is the abstract.'}]
    }
    mock_get.return_value = mock_response

    abstract = fetch_semantic(title="A study on birds")
    assert abstract == "This is the abstract."

@patch('ris_enrich.enricher.rispy.load')
@patch('ris_enrich.enricher.rispy.dump')
@patch('ris_enrich.enricher.fetch_semantic')
def test_enrich_ris_file(mock_fetch_semantic, mock_dump, mock_load, tmp_path):
    # Setup mock data
    mock_entries = [
        {'title': 'Paper 1', 'abstract': ''},
        {'title': 'Paper 2', 'abstract': 'Existing abstract'}
    ]
    mock_load.return_value = mock_entries
    mock_fetch_semantic.return_value = "New Abstract"

    input_file = tmp_path / "test.ris"
    input_file.touch()
    output_file = tmp_path / "output.ris"

    enrich_ris_file(str(input_file), str(output_file))

    # Verify fetch called only for missing abstract
    # It is called twice because the first paper has no abstract and triggers the search,
    # and the second paper has a short abstract (implied by test logic) or logic was misinterpreted.
    # Looking at the code:
    # entry 1: abstract="", so checks len("") > 300 -> False. Enters if. Calls fetch.
    # entry 2: abstract="Existing abstract", len < 300. Enters if. Calls fetch.

    # The code says:
    # if current_abstract and len(str(current_abstract)) > 300: continue

    # So "Existing abstract" is short, so it fetches again.
    assert mock_fetch_semantic.call_count == 2

    # Verify dump called with updated entries
    assert mock_entries[0]['abstract'] == "New Abstract"
    # The second entry should also be updated because its original abstract was short
    assert mock_entries[1]['abstract'] == "New Abstract"
    mock_dump.assert_called_once()

def test_get_crossref_email(monkeypatch):
    # Test default (None now)
    assert get_crossref_email() is None

    # Test arg
    assert get_crossref_email("arg@example.com") == "arg@example.com"

    # Test env var
    monkeypatch.setenv("RIS_ENRICH_EMAIL", "env@example.com")
    assert get_crossref_email() == "env@example.com"

    # Arg overrides env var
    assert get_crossref_email("arg@example.com") == "arg@example.com"
