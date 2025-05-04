"""
Author: Pugemon
Translate matching tags between two localization files and produce an updated output file.

This script:
  1. Reads an “original” key=value file (e.g. English tags and text).
  2. Reads a “translation” key=value file (e.g. Russian tags and translated text).
  3. Builds a mapping of tags→original text and tags→translation.
  4. For each tag present in both files:
       - Replaces the original text with the translation.
       - Logs each replacement to the console.
  5. Writes out a new key=value file where every tag maps to its (possibly updated) value.

Usage:
    python replace_tags.py <originalfile> <translationfile> <outputfile>

Example:
    python replace_tags.py enLocalization.txt.eng enLocalization.txt.rus enLocalization.txt
"""
import struct
from pathlib import Path
from typing import Dict


def replace_tags(
    originalfile_path: str,
    translationfile_path: str,
    output_file_path: str
) -> None:
    """
    Read two key=value files, replace matched values, and write the merged result.

    Args:
        originalfile_path (str): Path to the base localization file (e.g. English).
        translationfile_path (str): Path to the translation file (e.g. Russian).
        output_file_path (str): Path where the merged file will be written.

    Behavior:
      1. Opens and reads all lines from the original and translation files.
      2. Parses each line containing “=” into tag and value:
           - original_tags[tag]   = original value
           - translations[tag]    = translated value
      3. For each tag in translations that also exists in original_tags:
           - Overwrite original_tags[tag] with the translated text.
           - Print a message: “Found matching tag: {tag} – wrote value: {translation}”
      4. Writes all tags and their final values (one per line) to the output file.

    Notes:
      - Lines without an “=” character are ignored.
      - Original tags with no matching translation remain unchanged.
      - The output file preserves the tag order based on the original file’s keys.
    """
    # Read original localization
    with open(originalfile_path, 'r', encoding='utf-8') as file1:
        en_content = file1.readlines()

    # Read translation localization
    with open(translationfile_path, 'r', encoding='utf-8') as file2:
        ru_content = file2.readlines()

    original_tags: Dict[str, str] = {}
    translations:   Dict[str, str] = {}

    # Parse original file into tag→value
    for line in en_content:
        if '=' in line:
            tag, text = line.split('=', 1)
            original_tags[tag.strip()] = text.strip()

    # Parse translation file into tag→value
    for line in ru_content:
        if '=' in line:
            tag, text = line.split('=', 1)
            translations[tag.strip()] = text.strip()

    # Replace matching tags
    for tag, trans in translations.items():
        if tag in original_tags:
            original_tags[tag] = trans
            print(f"Found matching tag: {tag} – wrote value: {trans}")

    # Write merged output
    with open(output_file_path, 'w', encoding='utf-8') as out_file:
        for tag, text in original_tags.items():
            out_file.write(f"{tag}={text}\n")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Merge translations into an original localization file."
    )
    parser.add_argument('originalfile',     help="Base key=value file (e.g. English)")
    parser.add_argument('translationfile',  help="Key=value translation file (e.g. Russian)")
    parser.add_argument('outputfile',       help="Output path for the merged localization")
    args = parser.parse_args()

    replace_tags(args.originalfile, args.translationfile, args.outputfile)
