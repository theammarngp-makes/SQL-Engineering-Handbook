#!/usr/bin/env python3
"""
validate_questions.py

Validates the Module 18 question bank for structural integrity:
- Duplicate question IDs across all QUESTION_BANK.md files
- Questions missing required fields (Difficulty, Category, Type)
- Broken relative markdown links: within the module (always), and into
  other handbook modules (only when those sibling folders are present;
  in a standalone copy they are reported as 'not verifiable', not as broken)

LIMITATIONS:
- Does NOT execute or validate SQL correctness against a real database
  engine. SQL correctness is verified manually per the module's build
  process (see TAXONOMY_AND_FORMAT.md); this script catches structural
  regressions, not logic errors in a query's SQL.
- The link checker is fence-naive: a relative link written inside a
  ```markdown ... ``` illustrative code example will be checked as if it
  were a real link from that file's location, which can produce a false
  positive for deliberately-illustrative example links. Review flagged
  links accordingly.
- Level 8 (Interviewer/Hiring) questions omit a Difficulty field by
  design (meta-questions aren't candidate-difficulty-rated) — this is
  expected and not flagged as an error by the required-fields check
  below, which only requires Category and Type for those.

Usage:
    python3 validate_questions.py [module_root]

Exit code 0 = no issues found. Exit code 1 = issues found (see output).
"""

import re
import sys
from pathlib import Path

QUESTION_HEADER_RE = re.compile(r"^## (Q\d{3}) — (.+)$", re.MULTILINE)
MD_LINK_RE = re.compile(r"\]\(([^)]+)\)")


def find_question_bank_files(root: Path):
    return sorted(root.glob("*/QUESTION_BANK.md"))


def parse_questions(path: Path):
    text = path.read_text(encoding="utf-8")
    matches = list(QUESTION_HEADER_RE.finditer(text))
    questions = []
    for i, m in enumerate(matches):
        qid, title = m.group(1), m.group(2)
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        questions.append((qid, title, path, text[start:end]))
    return questions


def check_duplicate_ids(all_questions):
    seen = {}
    duplicates = []
    for qid, title, path, block in all_questions:
        if qid in seen:
            duplicates.append((qid, seen[qid], path))
        else:
            seen[qid] = path
    return duplicates


def check_required_fields(all_questions):
    missing = []
    for qid, title, path, block in all_questions:
        # Level 8 (09_INTERVIEWER_QUESTIONS) uses a deliberately different
        # format per TAXONOMY_AND_FORMAT.md's "Level 8 Format Exception":
        # "What it tests" / "Expected competency" / "Good answer" / etc.,
        # with no Difficulty/Category/Type fields at all -- these are
        # meta-questions for interviewers, not candidate-facing difficulty-
        # rated questions. Skip the standard field check for this level.
        if "09_INTERVIEWER_QUESTIONS" in str(path):
            if "What it tests" not in block:
                missing.append((qid, "What it tests: (Level 8 format)"))
            continue
        for field in ["Difficulty:", "Category:", "Type:"]:
            if field not in block:
                missing.append((qid, field))
    return missing


def is_standalone(root: Path) -> bool:
    """True when no sibling handbook modules exist next to this module
    (e.g. this folder was extracted from a standalone ZIP)."""
    siblings = [p for p in root.resolve().parent.iterdir()
                if p.is_dir() and p != root.resolve() and re.match(r"^\d{2}_", p.name)]
    return not siblings


def check_links(root: Path):
    """Returns (broken_internal, broken_external, skipped_external).
    Internal = target inside this module (always checked).
    External = target in another handbook module; checked only when the
    sibling modules are present, otherwise reported as skipped (unverifiable)."""
    broken, broken_external, skipped = [], [], []
    standalone = is_standalone(root)
    root_resolved = root.resolve()
    for md_file in root.rglob("*.md"):
        text = md_file.read_text(encoding="utf-8", errors="ignore")
        for link in MD_LINK_RE.findall(text):
            if link.startswith("http") or link.startswith("#"):
                continue
            link_path = link.split("#")[0]
            if not link_path:
                continue
            resolved = (md_file.parent / link_path).resolve()
            if resolved.exists():
                continue
            entry = (str(md_file.relative_to(root)), link)
            try:
                resolved.relative_to(root_resolved)
                broken.append(entry)
            except ValueError:
                (skipped if standalone else broken_external).append(entry)
    return broken, broken_external, skipped


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
    bank_files = find_question_bank_files(root)

    if not bank_files:
        print(f"No QUESTION_BANK.md files found under {root}")
        sys.exit(1)

    all_questions = []
    for path in bank_files:
        all_questions.extend(parse_questions(path))

    issues_found = False
    print(f"Scanned {len(bank_files)} question bank files, {len(all_questions)} questions total.\n")

    dupes = check_duplicate_ids(all_questions)
    if dupes:
        issues_found = True
        print("DUPLICATE IDS:")
        for qid, first_path, second_path in dupes:
            print(f"  {qid} appears in both {first_path} and {second_path}")
    else:
        print("No duplicate IDs found.")

    missing = check_required_fields(all_questions)
    if missing:
        issues_found = True
        print("\nMISSING REQUIRED FIELDS:")
        for qid, field in missing:
            print(f"  {qid} is missing '{field}'")
    else:
        print("All questions have required metadata fields.")

    broken_links, broken_external, skipped = check_links(root)
    if broken_links:
        issues_found = True
        print("\nBROKEN LINKS WITHIN THIS MODULE:")
        for file, link in broken_links:
            print(f"  {file} -> {link}")
    else:
        print("No broken links within this module.")
    if broken_external:
        issues_found = True
        print("\nBROKEN CROSS-MODULE LINKS (sibling modules present, target missing):")
        for file, link in broken_external:
            print(f"  {file} -> {link}")
    elif skipped:
        print(f"\nNOTE: {len(skipped)} cross-module link(s) could not be verified because "
              "sibling handbook modules are not present (standalone copy).\n"
              "      Run this script from inside the full handbook repository to verify them.")
    else:
        print("All cross-module links resolve.")

    print("\n" + ("ISSUES FOUND — see above." if issues_found else "All checks passed."))
    sys.exit(1 if issues_found else 0)


if __name__ == "__main__":
    main()
