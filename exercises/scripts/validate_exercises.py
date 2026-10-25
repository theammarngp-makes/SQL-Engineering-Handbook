#!/usr/bin/env python3
"""
Exercise validator for the SQL Engineering Handbook.

What it checks (static, no DB needed):
  * front matter present, required fields, valid difficulty/level/category, id format,
    id <-> filename <-> folder consistency, module folder exists, dataset + tables exist
  * duplicate exercise IDs / titles / identical solution SQL
  * required sections present and non-empty, exactly 3 hints, all 9 solution-policy labels
  * exactly one solution block; PostgreSQL-only syntax is not present in MySQL-labelled SQL
  * relative Markdown links resolve

What it checks (with a MySQL 8.x server):
  * dataset loads (schema.sql + seed.sql)
  * every `sql setup` block and the `sql` solution execute without error
  * the solution's result equals the documented Expected-output table (cell-for-cell)
  * every `sql wrong` block executes AND returns a DIFFERENT result from the solution
    (so "common wrong answer" claims are demonstrated, not asserted)

Usage:
  python3 scripts/validate_exercises.py                 # static + DB checks
  python3 scripts/validate_exercises.py --no-db         # static checks only
  python3 scripts/validate_exercises.py --update        # rewrite Expected-output tables from real results
  python3 scripts/validate_exercises.py EX-03-002       # a single exercise

Works in a full repository checkout (module-folder and relative-link checks resolve against the
real curriculum folders, 01_Fundamentals/ through 16_QUERY_OPTIMIZATION/) and in a standalone copy
of just datasets/ + exercises/ + scripts/. When NO curriculum folder (a top-level directory named
NN_*) exists next to this script, those two checks are skipped and a notice is printed, so a partial
checkout does not produce false failures. If at least one curriculum folder exists, all checks run.

Connection (env): MYSQL_HOST, MYSQL_PORT, MYSQL_USER (default root), MYSQL_PWD.
With no MYSQL_HOST the local socket is used.
"""
import os, re, subprocess, sys, glob

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
EX_DIR = os.path.join(ROOT, "exercises")

DIFFICULTY_LEVEL = {"BEGINNER": "L1", "EASY": "L2", "INTERMEDIATE": "L3", "ADVANCED": "L4", "EXPERT": "L5"}
CATEGORIES = {"FOUNDATIONS", "FILTERING", "AGGREGATION", "JOINS", "SUBQUERIES", "CTES", "WINDOW_FUNCTIONS",
              "DATE_ANALYTICS", "STRING_ANALYTICS", "NULL_LOGIC", "DATA_CLEANING", "BUSINESS_ANALYTICS",
              "PERFORMANCE", "DATABASE_ENGINEERING", "PRODUCTION_DEBUGGING", "SET_OPERATORS"}
REQUIRED_FIELDS = ["id", "title", "module", "category", "difficulty", "level", "estimated_time_min",
                   "business_domain", "dataset", "tables", "mysql_version", "related_interview"]
REQUIRED_SECTIONS = ["Learning objectives", "Business context", "Scenario", "Input assumptions", "Task",
                     "Constraints", "Expected output", "Hints", "Solution", "Explanation", "Common mistakes",
                     "Edge cases", "Performance notes", "Optional challenge", "Related"]
EXPLANATION_LABELS = ["Grain", "Rows that survive", "Filtering", "Join cardinality", "Aggregation",
                      "NULL behavior", "Why it is correct", "What could make it slow", "How to validate"]
PG_ONLY = [r"::\s*\w", r"\bDATE_TRUNC\b", r"\bRANDOM\s*\(\s*\)", r"EXTRACT\s*\(\s*EPOCH", r"\bILIKE\b",
           r"\bRETURNING\b", r"\bGENERATE_SERIES\b", r"\bSERIAL\b", r"INTERVAL\s+'"]

CURRICULUM_PRESENT = any(re.fullmatch(r"\d{2}_.+", d) and os.path.isdir(os.path.join(ROOT, d))
                         for d in os.listdir(ROOT))

errors, warnings = [], []
def err(ex, msg): errors.append(f"{ex}: {msg}")
def warn(ex, msg): warnings.append(f"{ex}: {msg}")

# ------------------------------------------------------------------ parsing
def parse_front_matter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m: return None, text
    fm = {}
    for line in m.group(1).splitlines():
        if not line.strip() or line.startswith("#"): continue
        k, _, v = line.partition(":")
        v = v.strip()
        if v.startswith("[") and v.endswith("]"):
            v = [x.strip().strip("'\"") for x in v[1:-1].split(",") if x.strip()]
        else:
            v = v.strip("'\"")
        fm[k.strip()] = v
    return fm, text[m.end():]

def split_sections(body):
    parts = re.split(r"^## (.+?)\s*$", body, flags=re.M)
    return {parts[i].strip(): parts[i + 1] for i in range(1, len(parts) - 1, 2)}

FENCE = re.compile(r"```sql([^\n]*)\n(.*?)```", re.S)
def sql_blocks(section_text):
    out = []
    for m in FENCE.finditer(section_text):
        out.append((m.group(1).strip(), m.group(2).strip()))
    return out

# ------------------------------------------------------------------ MySQL
def mysql_cmd(db=None):
    cmd = ["mysql", "-B", "--default-character-set=utf8mb4", f"-u{os.environ.get('MYSQL_USER', 'root')}"]
    if os.environ.get("MYSQL_HOST"):
        cmd += ["-h", os.environ["MYSQL_HOST"], "-P", os.environ.get("MYSQL_PORT", "3306")]
    if db: cmd.append(db)
    return cmd

def run_sql(sql, db=None):
    p = subprocess.run(mysql_cmd(db), input=sql, capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr

def load_dataset(name):
    d = os.path.join(ROOT, "datasets", name)
    for f in ("schema.sql", "seed.sql"):
        rc, _, e = run_sql(open(os.path.join(d, f), encoding="utf8").read())
        if rc != 0: return f"loading {name}/{f} failed: {e.strip()}"
    return None

def db_name(dataset): return f"handbook_{dataset}"

def result_table(tsv):
    lines = tsv.rstrip("\n").split("\n") if tsv.strip() else []
    return [l.split("\t") for l in lines]

def to_markdown(rows):
    if not rows: return "_(no rows)_"
    esc = lambda c: c.replace("|", "\\|")
    head = "| " + " | ".join(esc(c) for c in rows[0]) + " |"
    sep = "|" + "|".join("---" for _ in rows[0]) + "|"
    body = ["| " + " | ".join(esc(c) for c in r) + " |" for r in rows[1:]]
    return "\n".join([head, sep] + body) + f"\n\n_{len(rows) - 1} row(s)_"

EXP = re.compile(r"(<!-- expected:start -->\n)(.*?)(\n<!-- expected:end -->)", re.S)

# ------------------------------------------------------------------ main checks
def load_exercises(only):
    files = sorted(glob.glob(os.path.join(EX_DIR, "*", "EX-*.md")))
    return [f for f in files if not only or any(o in os.path.basename(f) for o in only)]

def check_file(path, seen, do_db, update, loaded):
    rel = os.path.relpath(path, ROOT)
    text = open(path, encoding="utf8").read()
    fm, body = parse_front_matter(text)
    ex = os.path.basename(path).split("_")[0]
    if fm is None: err(ex, f"{rel}: missing front matter"); return
    for f in REQUIRED_FIELDS:
        if f not in fm or (fm[f] in ("", []) and f != "related_interview"):
            err(ex, f"missing front-matter field '{f}'")
    if any(f not in fm for f in REQUIRED_FIELDS): return
    eid = fm["id"]
    if not re.fullmatch(r"EX-\d{2}-\d{3}", eid): err(ex, f"bad id format '{eid}'")
    if not os.path.basename(path).startswith(eid + "_"): err(ex, f"filename does not start with id '{eid}_'")
    if eid in seen["ids"]: err(ex, f"duplicate id (also in {seen['ids'][eid]})")
    seen["ids"][eid] = rel
    if fm["title"].lower() in seen["titles"]: err(ex, f"duplicate title (also {seen['titles'][fm['title'].lower()]})")
    seen["titles"][fm["title"].lower()] = eid
    if fm["difficulty"] not in DIFFICULTY_LEVEL: err(ex, f"invalid difficulty '{fm['difficulty']}'")
    elif DIFFICULTY_LEVEL[fm["difficulty"]] != fm["level"]: err(ex, f"level {fm['level']} does not match difficulty {fm['difficulty']}")
    if fm["category"] not in CATEGORIES: err(ex, f"invalid category '{fm['category']}'")
    if not fm["estimated_time_min"].isdigit(): err(ex, "estimated_time_min must be an integer")
    mod_no = eid.split("-")[1]
    if not os.path.basename(os.path.dirname(path)).startswith(mod_no + "_"): err(ex, f"folder does not match module number {mod_no}")
    if not fm["module"].startswith(mod_no + "_"): err(ex, f"module '{fm['module']}' does not match id module {mod_no}")
    elif CURRICULUM_PRESENT and not os.path.isdir(os.path.join(ROOT, fm["module"])): err(ex, f"module folder '{fm['module']}' does not exist")
    ds_dir = os.path.join(ROOT, "datasets", fm["dataset"])
    schema_tables = set()
    if not os.path.isfile(os.path.join(ds_dir, "schema.sql")): err(ex, f"dataset '{fm['dataset']}' has no schema.sql")
    else:
        schema_tables = set(re.findall(r"CREATE TABLE\s+(\w+)", open(os.path.join(ds_dir, "schema.sql"), encoding="utf8").read()))
        for t in fm["tables"]:
            if t not in schema_tables: err(ex, f"table '{t}' not in dataset schema")
    if not str(fm["mysql_version"]).startswith("8"): warn(ex, "mysql_version should be 8.x")

    secs = split_sections(body)
    for s in REQUIRED_SECTIONS:
        if s not in secs: err(ex, f"missing section '## {s}'")
        elif not secs[s].strip(): err(ex, f"empty section '## {s}'")
    if any(s not in secs for s in REQUIRED_SECTIONS): return

    if len(re.findall(r"<summary>\s*Hint [123]\b", secs["Hints"])) != 3: err(ex, "Hints must contain exactly Hint 1, Hint 2, Hint 3 as <summary> blocks")
    for lab in EXPLANATION_LABELS:
        if f"**{lab}.**" not in secs["Explanation"]: err(ex, f"Explanation missing label **{lab}.**")
    # dialect is already enforced via the required front-matter field 'mysql_version' (checked above)

    sol_blocks = sql_blocks(secs["Solution"])
    setup = [b for tag, b in sol_blocks if tag == "setup"]
    sols = [b for tag, b in sol_blocks if tag == ""]
    if len(sols) != 1: err(ex, f"Solution must have exactly one plain ```sql block (found {len(sols)})"); return
    solution = sols[0]
    norm = re.sub(r"\s+", " ", solution.strip().rstrip(";")).lower()
    if norm in seen["sql"]: err(ex, f"solution SQL identical to {seen['sql'][norm]}")
    seen["sql"][norm] = eid
    wrongs = [b for tag, b in sql_blocks(secs["Common mistakes"]) if tag == "wrong"]
    for tag, b in sql_blocks(text):
        if tag in ("", "setup", "wrong"):
            for pat in PG_ONLY:
                if re.search(pat, b, re.I): err(ex, f"PostgreSQL-only syntax /{pat}/ in MySQL-labelled SQL block (label it ```sql postgresql)")
    for m in re.finditer(r"\[[^\]]*\]\(([^)]+)\)", text):
        link = m.group(1).split("#")[0].strip()
        if not link or re.match(r"^(https?:|mailto:)", link): continue
        if not CURRICULUM_PRESENT and re.match(r"^(\.\./)+\d{2}_", link): continue
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(path), link))): err(ex, f"broken relative link: {link}")
    if not EXP.search(secs["Expected output"]): err(ex, "Expected output needs <!-- expected:start --> / <!-- expected:end --> markers")

    if not do_db: return
    try:
        run_db_checks(path, ex, eid, fm, text, setup, solution, wrongs, update, loaded)
    finally:
        if fm.get("mutates", "false") == "true": loaded["ds"] = None

def run_db_checks(path, ex, eid, fm, text, setup, solution, wrongs, update, loaded):
    dbn = db_name(fm["dataset"])
    if fm.get("mutates", "false") == "true" or loaded.get("ds") != fm["dataset"]:
        e = load_dataset(fm["dataset"])
        if e: err(ex, e); return
        loaded["ds"] = fm["dataset"]
    for s in setup:
        rc, _, e = run_sql(s, dbn)
        if rc: err(ex, f"setup block failed: {e.strip()}"); return
    rc, out, e = run_sql(solution, dbn)
    if rc: err(ex, f"solution failed on MySQL: {e.strip()}"); return
    actual = result_table(out)
    md = to_markdown(actual)
    m = EXP.search(text)
    if not m: return
    if update:
        new = EXP.sub(lambda mm: mm.group(1) + md + mm.group(3), text, count=1)
        if new != text: open(path, "w", encoding="utf8").write(new); print(f"  updated expected output: {eid}")
    elif m.group(2).strip() != md.strip():
        err(ex, "Expected-output table does not match the real result of the solution (run with --update after reviewing)")
    for i, w in enumerate(wrongs, 1):
        rc, wout, e = run_sql(w, dbn)
        if rc: err(ex, f"wrong-answer block #{i} does not even execute: {e.strip()}"); continue
        if result_table(wout) == actual: err(ex, f"wrong-answer block #{i} returns the SAME result as the solution — it does not demonstrate a failure")

def main(argv):
    do_db = "--no-db" not in argv
    update = "--update" in argv
    only = [a for a in argv if a.startswith("EX-")]
    if not os.path.isfile(os.path.join(EX_DIR, "README.md")): err("exercises", "exercises/README.md missing")
    else:
        r = open(os.path.join(EX_DIR, "README.md"), encoding="utf8").read()
        for d in DIFFICULTY_LEVEL:
            if d not in r: err("exercises/README.md", f"difficulty '{d}' is not defined")
    if not CURRICULUM_PRESENT:
        print("NOTE: no curriculum folders (NN_*) found next to scripts/ — skipping module-folder and "
              "module-link checks (standalone checkout).")
    files = load_exercises(only)
    if not files: err("exercises", "no exercises found")
    if do_db:
        rc, v, e = run_sql("SELECT VERSION();")
        if rc: print("Cannot connect to MySQL:", e.strip(), "\n(use --no-db for static checks only)"); return 2
        ver = v.strip().split("\n")[-1]
        print(f"MySQL server: {ver}")
        if not ver.startswith("8"): print("WARNING: baseline is MySQL 8.x")
    seen = {"ids": {}, "titles": {}, "sql": {}}
    loaded = {}
    for f in files:
        before = len(errors)
        check_file(f, seen, do_db, update, loaded)
        print(("PASS " if len(errors) == before else "FAIL ") + os.path.relpath(f, ROOT))
    for w in warnings: print("WARN ", w)
    for e in errors: print("ERROR", e)
    print(f"\n{len(files)} exercise(s), {len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
