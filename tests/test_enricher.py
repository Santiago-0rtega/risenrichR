import pytest
from ris_enrich.enricher import clean_html_tags, verify_title_match, normalize_text

def test_clean_html_tags():
    raw = "This is <jats:p>an abstract</jats:p> with tags."
    assert clean_html_tags(raw) == "This is an abstract with tags."

def test_normalize_text():
    # The code should PRESERVE the accent now, just lowercasing it.
    assert normalize_text("Seleção Sexual") == "seleção sexual"
    
    # It should still fix full-width characters (Japanese/Chinese standard)
    assert normalize_text("Full-width Ａ") == "fullwidth a"

def test_verify_title_match():
    # Should pass (minor punctuation difference)
    assert verify_title_match("A study on birds", "A study on birds.") == True
    # Should fail (completely different)
    assert verify_title_match("Mate-choice copying", "Foraging behavior in bees") == False