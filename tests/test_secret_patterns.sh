#!/usr/bin/env bash
# Regression test for the secret-detection patterns in scripts/.
#
# Exists because the rule that was supposed to catch a hardcoded password did
# not, and did not say so. `scan_history.sh` carried
#
#     'password\s*[=:]\s*["'"'"'][^"'"'"']'
#
# and it applies its patterns with `git grep -E`, which compiles POSIX ERE via
# the system regcomp - not PCRE. In POSIX ERE `\s` is not an escape, it is a
# literal `s`. So the pattern read "password", then zero or more `s`, then
# `[=:]`, and matched `password:"x"` while missing `password: "x"` and
# `password = "x"` - the two forms anyone actually writes. A real database
# credential survived a full-history scan of a public repo that way.
#
# Two things follow, and this file does both:
#
#  1. A detector with no test asserting it fires is indistinguishable from no
#     detector. Every pattern gets a positive case, and the noisy ones get a
#     negative too - a scanner people stop reading is also a scanner that misses
#     things.
#
#  2. The test has to apply the patterns through `git grep -E`, the way
#     production does. A first draft used the system `grep -E`, which supports
#     `\s` as a GNU/BSD extension, so it passed against the broken pattern and
#     proved nothing. Verified on a dev machine: `grep -E` matches
#     `password: "x"`, `git grep -E` does not.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PASS=0
FAIL=0

ok()  { printf '\033[32mok\033[0m   %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '\033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

# Load the real array and let the shell unquote it, so the patterns arrive
# exactly as scan_history.sh sees them. Parsing the block with sed instead
# mangles every pattern that uses the '"'"'-inside-single-quotes idiom.
eval "$(sed -n '/^PATTERNS=(/,/^)/p' "$ROOT/scripts/scan_history.sh")"
[ "${#PATTERNS[@]}" -gt 0 ] || { echo "could not read PATTERNS from scan_history.sh" >&2; exit 1; }

# The All of Us identifier regex and the notebook-output function live in BOTH
# scripts (a script copied into another repo must stand alone). Read each copy
# and fail if they ever differ, so one cannot be fixed and the other forgotten.
ID_RE=""; eval "$(grep '^ID_RE=' "$ROOT/scripts/scan_history.sh")"; SCAN_ID_RE=$ID_RE
ID_RE=""; eval "$(grep '^ID_RE=' "$ROOT/scripts/check_hygiene.sh")"; HYG_ID_RE=$ID_RE
if [ -n "$SCAN_ID_RE" ] && [ "$SCAN_ID_RE" = "$HYG_ID_RE" ]; then
    ok "identifier regex present and identical in scan_history.sh and check_hygiene.sh"
else
    bad "identifier regex (ID_RE) missing from, or different between, scan_history.sh and check_hygiene.sh"
fi
nbfn() { sed -n '/^nb_output_names_person_id() {/,/^}/p' "$1"; }
if [ -n "$(nbfn "$ROOT/scripts/scan_history.sh")" ] && [ "$(nbfn "$ROOT/scripts/scan_history.sh")" = "$(nbfn "$ROOT/scripts/check_hygiene.sh")" ]; then
    ok "nb_output_names_person_id present and identical in both scripts"
else
    bad "nb_output_names_person_id missing from, or different between, the two scripts"
fi
# The scan applies .scanignore, so the file made of the scanner's own fixtures has to be listed in it.
# A repository that copies this test must carry the line too, or its own scan reports these fixtures.
if grep -qxF 'tests/test_secret_patterns.sh' "$ROOT/.scanignore" 2>/dev/null; then
    ok "this file is listed in .scanignore (its fixtures are what the scanner looks for)"
else
    bad "tests/test_secret_patterns.sh is not listed in .scanignore: scan_history.sh would report its own fixtures"
fi

# Samples, one per line, in order. No tag prefix: several patterns are anchored
# with `^`, and a prefix would silently defeat the anchor.
DESCS=(); SAMPLES=(); EXPECT=()
want()   { DESCS+=("$1"); SAMPLES+=("$2"); EXPECT+=(yes); }
unwant() { DESCS+=("$1"); SAMPLES+=("$2"); EXPECT+=(no); }

# The three formattings of a hardcoded password. Only the second was caught
# before this fix, and it is the least common of the three.
want   "password, colon and a space"  '    password: "hunter2",'
want   "password, colon no space"     '    password:"hunter2",'
want   "password, equals and spaces"  '  password = "hunter2"'
want   "single-quoted value"          "  password = 'hunter2'"
want   "PASSWORD in a .env line"      'DB_PASSWORD=hunter2'
want   "api key, snake case"          '  api_key: "livekey-abcdefghijklmnop"'
want   "api key, kebab case"          '  api-key: "abcdefghijklmnop"'
want   "secret"                       '  secret: "abcdefghijklmnop"'
want   "access token"                 '  access_token = "abcdefghijklmnop"'
want   "credentials in a URL"         'DATABASE_URL=postgres://appuser:hunter2@localhost:5432/app'
want   "AWS access key"               'AKIAIOSFODNN7EXAMPLE'
want   "GitHub PAT"                   'ghp_abcdefghijklmnopqrstuvwxyz0123'
want   "PEM private key header"       '-----BEGIN OPENSSH PRIVATE KEY-----'
want   "Minerva project path"         'ref=/sc/arion/projects/lab/ref.fa'
want   "macOS home path"              "path = '/Users/someone/data'"

unwant "empty value in a .example"    'password='
unwant "quoted empty value"           'password: ""'
unwant "env indirection"              'PASSWORD=${DB_PASSWORD}'
unwant "command substitution"         'PASSWORD=$(vault read db/password)'
unwant "read from the environment"    '  password: process.env.password,'
unwant "a plain URL"                  'url = "https://ftp.ensembl.org/pub/release-115/"'
unwant "a bare word"                  'passwords are stored hashed'

# All of Us Researcher Workbench identifiers. Invented values, shaped like the
# real ones (a workspace project, a namespace as it appears in a workspace URL,
# a workspace bucket); none of them is real. This file is listed in .scanignore
# and .hygieneignore because it must contain them.
want   "workspace project, in code"            'PROJECT = "wb-synthetic-marker-0000"'
want   "workspace project, in a notebook cell" '    "project = \"wb-synthetic-marker-0000\"\n",'
want   "workspace project, three words"        'wb-synthetic-marker-extra-0000'
want   "workspace project, as a dataset prefix" 'SELECT * FROM `wb-synthetic-marker-0000.C2025Q4R6.person`'
want   "workspace project, at the end of a line" 'PROJECT = wb-synthetic-marker-0000'
want   "workspace project, a letter right after the digits" 'wb-synthetic-marker-0000x'
want   "workspace namespace in a URL"          'https://workbench.researchallofus.org/workspaces/aou-rw-c0ffee00/example/data'
want   "controlled-tier workspace bucket"      'gs://fc-secure-00000000-0000-4000-8000-000000000000/notebooks'
want   "registered-tier workspace bucket"      'gs://fc-00000000-0000-4000-8000-000000000000/data'
unwant "placeholder project"                   'project = "wb-xxxx-xxxx-xxxx"'
unwant "placeholder namespace"                 'workspaces/aou-rw-xxxxxxxx/name'
unwant "placeholder bucket"                    'gs://fc-secure-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
unwant "shared dataset bucket, public docs"    'gs://fc-aou-datasets-controlled/pgen_bed/'
unwant "shared CDR dataset, public docs"       'WORKSPACE_CDR = "fc-aou-cdr-prod-ct.C2024Q3R5"'
unwant "wb- inside a longer word"              'swb-alpha-beta-1234'
unwant "wb- name without a number"             'wb-cli-tool-docs'
unwant "wb- name ending in a five-digit number" 'wb-synthetic-marker-12345'
unwant "ordinary name ending in a long number"  'image: registry.example/wb-api-server-123456'

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- 1. the patterns, applied the way scan_history.sh applies them -----------
echo "== scan_history.sh PATTERNS via git grep -E (${#PATTERNS[@]} patterns) =="
mkdir -p "$TMP/pat" && cd "$TMP/pat"
git init -q .
: > samples.txt
for s in "${SAMPLES[@]}"; do printf '%s\n' "$s" >> samples.txt; done
git add samples.txt >/dev/null
git -c user.email=t@example.invalid -c user.name=t commit -qm samples

MATCHED=" "
# The identifier regex is applied here the way the history scan applies it. If
# it is missing, the check above has already failed; an empty pattern would
# match every line and bury that under noise.
ALL_PATTERNS=("${PATTERNS[@]}")
[ -n "$SCAN_ID_RE" ] && ALL_PATTERNS+=("$SCAN_ID_RE")
for p in "${ALL_PATTERNS[@]}"; do
    lines=$(git grep -nIE "$p" HEAD -- samples.txt 2>/dev/null | cut -d: -f3 | tr '\n' ' ' || true)
    MATCHED="$MATCHED$lines "
done

i=0
while [ "$i" -lt "${#SAMPLES[@]}" ]; do
    n=$((i+1))
    hit=no
    case "$MATCHED" in *" $n "*) hit=yes ;; esac
    if [ "$hit" = "${EXPECT[$i]}" ]; then
        if [ "$hit" = yes ]; then ok "detected: ${DESCS[$i]}"; else ok "ignored:  ${DESCS[$i]}"; fi
    elif [ "${EXPECT[$i]}" = yes ]; then
        bad "MISSED: ${DESCS[$i]}  <<${SAMPLES[$i]}>>"
    else
        bad "false positive: ${DESCS[$i]}  <<${SAMPLES[$i]}>>"
    fi
    i=$((i+1))
done

# --- 2. check_hygiene.sh end to end -----------------------------------------
# This is the gate that runs in CI and as a pre-commit hook, so drive the real
# script over a throwaway repo rather than testing its patterns in isolation.
echo
echo "== check_hygiene.sh end-to-end =="
mkdir -p "$TMP/hyg/scripts" && cd "$TMP/hyg"
git init -q .
cp "$ROOT/scripts/check_hygiene.sh" scripts/
printf 'x\n' > .gitignore

run_hygiene() { OUT="$(bash scripts/check_hygiene.sh 2>&1)"; }

cat > knexfile.js <<'JS'
export default {
  connection: {
    database: "app",
    user: "app-user",
    password: "hunter2",
  },
};
JS
git add -A >/dev/null
if run_hygiene; then
    bad "passed a file with a hardcoded password"
else
    if printf '%s' "$OUT" | grep -q 'hunter2'; then
        bad "echoed the secret value into its own output"
    else
        ok "hardcoded password rejected, value withheld from the report"
    fi
    if printf '%s' "$OUT" | grep -q 'knexfile.js:5'; then
        ok "reported the offending file and line"
    else
        bad "did not report knexfile.js:5; got:
$OUT"
    fi
fi

cat > knexfile.js <<'JS'
export default {
  connection: {
    database: process.env.database,
    user: process.env.username,
    password: process.env.password,
  },
};
JS
cat > .env.example <<'ENV'
username=app-user
password=
database=app
ENV
git add -A >/dev/null
if run_hygiene; then
    ok "env-var config plus .env.example passes"
else
    bad "rejected a clean env-var config:
$OUT"
fi

# --- 3. All of Us identifiers and participant columns, through check_hygiene.sh ----
# Same throwaway repo. Each case plants files under case/, runs the real script,
# and checks the verdict, that the report names the file and line, and that the
# planted value is never echoed.
echo
echo "== check_hygiene.sh: Workbench identifiers and notebook output =="

# A notebook written the way Jupyter writes it (indent 1): one code cell, with a
# stored stream output when a third argument is given.
nb_json() {
    printf '{\n "cells": [\n  {\n   "cell_type": "code",\n   "execution_count": 1,\n   "metadata": {},\n'
    if [ -n "${3:-}" ]; then
        printf '   "outputs": [\n    {\n     "name": "stdout",\n     "output_type": "stream",\n     "text": [\n      "%s\\n"\n     ]\n    }\n   ],\n' "$3"
    else
        printf '   "outputs": [],\n'
    fi
    printf '   "source": [\n    "%s"\n   ]\n  }\n ],\n "metadata": {},\n "nbformat": 4,\n "nbformat_minor": 5\n}\n' "$2"
}
# The same, with the output as a rendered HTML table, as pandas displays one.
nb_html_json() {
    printf '{\n "cells": [\n  {\n   "cell_type": "code",\n   "execution_count": 1,\n   "metadata": {},\n'
    printf '   "outputs": [\n    {\n     "data": {\n      "text/html": [\n       "<table><tr><th>%s</th></tr></table>"\n      ]\n     },\n     "execution_count": 1,\n     "metadata": {},\n     "output_type": "execute_result"\n    }\n   ],\n' "$3"
    printf '   "source": [\n    "%s"\n   ]\n  }\n ],\n "metadata": {},\n "nbformat": 4,\n "nbformat_minor": 5\n}\n' "$2"
}

nb()      { nb_json "$@" >"$1"; }
nb_html() { nb_html_json "$@" >"$1"; }

fresh() { rm -rf case .hygieneignore; mkdir case; }
# hyg_case <fail|pass> <description> [text the report must contain] [text it must not contain]
hyg_case() {
    git add -A >/dev/null
    if run_hygiene; then verdict=pass; else verdict=fail; fi
    if [ "$verdict" != "$1" ]; then bad "$2 (expected $1, got $verdict):
$OUT"; return; fi
    if [ -n "${3:-}" ] && ! printf '%s' "$OUT" | grep -qF -- "$3"; then bad "$2: report lacks '$3':
$OUT"; return; fi
    if [ -n "${4:-}" ] && printf '%s' "$OUT" | grep -qF -- "$4"; then bad "$2: report echoed '$4'"; return; fi
    ok "$2"
}

fresh; printf 'PROJECT = "wb-synthetic-marker-0000"\n' >case/p.py
hyg_case fail "workspace project in code rejected, file:line named, value withheld" "case/p.py:1" "synthetic-marker"

fresh; printf 'The project is wb-synthetic-marker-0000 in this example.\n' >case/r.md
hyg_case fail "workspace project in a .md file rejected too (docs are public)" "case/r.md:1" "synthetic-marker"

fresh; nb case/n.ipynb 'ns = \"aou-rw-c0ffee00\"'
hyg_case fail "workspace namespace in a notebook source cell rejected" "case/n.ipynb:" "c0ffee00"

fresh; printf 'bucket: gs://fc-secure-00000000-0000-4000-8000-000000000000/x\n' >case/c.yml
hyg_case fail "controlled-tier bucket in a yaml file rejected" "case/c.yml:1" "4000-8000"

fresh; printf 'PROJECT = "wb-synthetic-marker-0000"\n' >case/p.py; printf 'case/p.py\n' >.hygieneignore
hyg_case pass "an identifier in a file listed in .hygieneignore is allowed"

fresh; printf 'project = "wb-xxxx-xxxx-xxxx"\nns = aou-rw-xxxxxxxx\ncdr = fc-aou-cdr-prod-ct.C2024Q3R5\nsrc = gs://fc-aou-datasets-controlled/x\n' >case/doc.md
hyg_case pass "placeholders and the shared public dataset names pass"

fresh; printf 'PROJECT=wb-synthetic-marker-0000\n' >case/e.txt
hyg_case fail "workspace project at the very end of a line rejected" "case/e.txt:1" "synthetic-marker"

fresh; printf 'image: registry.example/wb-api-server-123456\nbuild = wb-synthetic-marker-12345\n' >case/o.txt
hyg_case pass "hyphenated names ending in five or more digits are not read as a project"

fresh; nb case/o.ipynb 'df.head()' '   person_id  birth_datetime'
hyg_case fail "notebook output with a person_id column fails (it used to warn)" "case/o.ipynb" "birth_datetime"

fresh; nb_html case/h.ipynb 'df.head()' 'person_id'
hyg_case fail "notebook output with a person_id column as an HTML table fails" "case/h.ipynb"

fresh; printf '{"cells":[{"cell_type":"code","execution_count":1,"metadata":{},"outputs":[{"name":"stdout","output_type":"stream","text":["   person_id  x\\n"]}],"source":["df.head()"]}],"metadata":{},"nbformat":4,"nbformat_minor":5}\n' >case/m.ipynb
hyg_case fail "a minified notebook (no line to anchor on) with person_id in its output fails" "case/m.ipynb"

fresh; nb case/s.ipynb 'SELECT person_id FROM t'
hyg_case pass "person_id in a source cell of a notebook without output passes" "" "WARN"

fresh; nb case/w.ipynb 'SELECT person_id FROM t' '3 rows returned'
hyg_case pass "person_id only in the source, other output: passes with the old warning" "WARN: notebooks with stored output" "FAIL"
# the function must read past the first output's own "text": [ ... ] array, and the name in any case,
# and it reads a name as a whole word: a column that merely contains it is a different column
fresh; printf '{\n "cells": [\n  {\n   "cell_type": "code",\n   "execution_count": 1,\n   "metadata": {},\n   "outputs": [\n    {\n     "name": "stdout",\n     "output_type": "stream",\n     "text": [\n      "3 rows returned\\n"\n     ]\n    },\n    {\n     "name": "stdout",\n     "output_type": "stream",\n     "text": [\n      "   person_id  x\\n"\n     ]\n    }\n   ],\n   "source": [\n    "df.head()"\n   ]\n  }\n ],\n "metadata": {},\n "nbformat": 4,\n "nbformat_minor": 5\n}\n' >case/t.ipynb
hyg_case fail "person_id in a second output, after another output's text array, fails" "case/t.ipynb"
fresh; nb case/u.ipynb 'df.head()' '   PERSON_ID  x'
hyg_case fail "the column name in capitals fails too" "case/u.ipynb"
fresh; nb case/b.ipynb 'df.head()' '   person_identifier  ext_person_id'
hyg_case pass "names that only contain person_id (person_identifier, ext_person_id) are other columns: warns, does not fail" "WARN: notebooks with stored output" "FAIL"
fresh
git add -A >/dev/null

# --- 4. the history scan, end to end ------------------------------------------------
# scan_history.sh used to exit 0 whatever it found, read .scanignore and never
# applied it, and had no Workbench identifier or participant column in it.
echo
echo "== scan_history.sh end-to-end =="
mkdir -p "$TMP/scan/scripts" && cd "$TMP/scan"
git init -q .
cp "$ROOT/scripts/scan_history.sh" scripts/
gc() { git add -A >/dev/null; git -c user.email=t@example.invalid -c user.name=t -c commit.gpgsign=false commit -qm "$1" >/dev/null; }
run_scan() { bash scripts/scan_history.sh --full >"$TMP/scan.out" 2>&1; RC=$?; OUT="$(cat "$TMP/scan.out")"; }
run_tree() { bash scripts/scan_history.sh >"$TMP/scan.out" 2>&1; RC=$?; OUT="$(cat "$TMP/scan.out")"; }
scan_has() { printf '%s' "$OUT" | grep -qE -- "$1"; }
# The report also lists every file name ever committed (sections 1 and 5), so a bare grep for a
# path would pass whether or not the detector fired. scan_in <heading> <regex> looks only at the
# lines under the heading(s) that start with it, up to the next blank line.
scan_in() { printf '%s\n' "$OUT" | awk -v h="$1" 'index($0, h) { on = 1; next } /^$/ { on = 0 } on' | grep -qE -- "$2"; }

printf 'x = 1\n' >a.py; gc clean
run_scan
if [ "$RC" -eq 0 ]; then ok "scan: a clean repository exits 0"; else bad "scan: a clean repository exited $RC:
$OUT"; fi

mkdir case
printf 'PROJECT = "wb-synthetic-marker-0000"\n' >case/p.py; gc "identifier in the tree"
run_scan
if [ "$RC" -eq 1 ]; then ok "scan: an identifier in the tree exits 1"; else bad "scan: identifier in the tree, exit $RC (wanted 1)"; fi
if scan_has 'case/p\.py:1'; then ok "scan: reports the file and line of the identifier"; else bad "scan: did not report case/p.py:1:
$OUT"; fi
if scan_has 'synthetic-marker'; then bad "scan: echoed the identifier"; else ok "scan: the identifier is withheld from the report"; fi
# Without --full only the tree is read: the history section of the report cannot be what finds it.
run_tree
if [ "$RC" -eq 1 ] && scan_in 'Workbench identifier' 'case/p\.py:1'; then ok "scan (tree only): an identifier in the tree is reported and fails the run"; else bad "scan (tree only): identifier in the tree, exit $RC:
$OUT"; fi
printf 'case/p.py\n' >.scanignore
run_tree
if [ "$RC" -eq 0 ]; then ok "scan (tree only): a path listed in .scanignore is not reported (identifier)"; else bad "scan (tree only): .scanignore did not exempt case/p.py (exit $RC):
$OUT"; fi
rm -f .scanignore

git rm -q case/p.py; gc "identifier removed from the tree, still in history"
run_scan
if [ "$RC" -eq 1 ] && scan_has 'case/p\.py:1'; then ok "scan --full: an identifier that is only in history exits 1 and is reported"; else bad "scan --full: history-only identifier, exit $RC:
$OUT"; fi

# .scanignore must do what the file says it does, for identifiers and for the older patterns.
printf 'case/p.py\n' >.scanignore
run_scan
if [ "$RC" -eq 0 ]; then ok "scan: a path listed in .scanignore is not reported (identifier, history)"; else bad "scan: .scanignore did not exempt case/p.py (exit $RC):
$OUT"; fi
rm -f .scanignore
mkdir -p docs; printf 'Example key from the AWS docs: AKIAIOSFODNN7EXAMPLE\n' >docs/aws.md; gc "aws example key in docs"
run_scan
if [ "$RC" -eq 1 ] && scan_has 'docs/aws\.md:1'; then ok "scan: an older pattern is reported and fails the run"; else bad "scan: AWS example key, exit $RC:
$OUT"; fi
printf 'case/p.py\ndocs/aws.md\n' >.scanignore
run_scan
if [ "$RC" -eq 0 ]; then ok "scan: a path listed in .scanignore is not reported (older pattern, tree and history)"; else bad "scan: .scanignore did not exempt docs/aws.md (exit $RC):
$OUT"; fi

# all three identifier shapes, through the real script
mkdir -p case; printf 'a = wb-synthetic-marker-0000\nb = aou-rw-c0ffee00\nc = gs://fc-secure-00000000-0000-4000-8000-000000000000\n' >case/ids.txt; gc "three shapes"
run_scan
for n in 1 2 3; do
    if scan_has "case/ids\\.txt:$n"; then ok "scan: identifier shape $n of 3 reported (project, namespace, bucket)"; else bad "scan: shape $n of 3 not reported:
$OUT"; fi
done
rm -f .scanignore; git rm -q case/ids.txt docs/aws.md; gc "clean again"
printf 'image: registry.example/wb-api-server-123456\nbuild = wb-synthetic-marker-12345\n' >case/o.txt; gc "ordinary names ending in long numbers"
run_tree
if [ "$RC" -eq 0 ]; then ok "scan (tree only): hyphenated names ending in five or more digits are not reported"; else bad "scan (tree only): ordinary names ending in long numbers, exit $RC:
$OUT"; fi
git rm -q case/o.txt; gc "ordinary names removed"

# participant column in notebook output: repositories of their own, so that the exit status
# cannot come from the findings above, which stay in history
new_scan_repo() { rm -rf "$TMP/$1"; mkdir -p "$TMP/$1/scripts" "$TMP/$1/case"; cd "$TMP/$1" && git init -q . && cp "$ROOT/scripts/scan_history.sh" scripts/; }
new_scan_repo scan_nb
nb case/o.ipynb 'df.head()' '   person_id  birth_datetime'
nb case/s.ipynb 'SELECT person_id FROM t'; gc "notebooks"
run_scan
if [ "$RC" -eq 1 ] && scan_in 'Notebook output names a participant-level column' 'case/o\.ipynb'; then ok "scan: person_id in a notebook output is reported and fails the run"; else bad "scan: notebook output with person_id, exit $RC:
$OUT"; fi
if scan_in 'Notebook output names a participant-level column' 'case/s\.ipynb'; then bad "scan: flagged a notebook that names person_id only in a source cell"; else ok "scan: a notebook with person_id only in a source cell is left alone"; fi
if scan_has 'birth_datetime'; then bad "scan: echoed notebook output"; else ok "scan: notebook output is withheld from the report"; fi
run_tree
if [ "$RC" -eq 1 ] && scan_in 'Notebook output names a participant-level column' 'case/o\.ipynb'; then ok "scan (tree only): person_id in a notebook output is reported and fails the run"; else bad "scan (tree only): notebook output with person_id, exit $RC:
$OUT"; fi
printf 'case/o.ipynb\n' >.scanignore
run_tree
if [ "$RC" -eq 0 ]; then ok "scan (tree only): a notebook listed in .scanignore is not reported"; else bad "scan (tree only): .scanignore did not exempt the notebook (exit $RC):
$OUT"; fi
run_scan
if [ "$RC" -eq 0 ]; then ok "scan --full: a notebook listed in .scanignore is not reported, in the tree or in history"; else bad "scan --full: .scanignore did not exempt the notebook (exit $RC):
$OUT"; fi
rm -f .scanignore
git rm -q case/o.ipynb; gc "output removed from the tree, still in history"
run_scan
if [ "$RC" -eq 1 ] && scan_in 'Notebook output names a participant-level column' 'case/o\.ipynb'; then ok "scan --full: person_id in a notebook output that is only in history is reported"; else bad "scan --full: history-only notebook output, exit $RC:
$OUT"; fi
new_scan_repo scan_src
nb case/s.ipynb 'SELECT person_id FROM t'; gc "source only"
run_scan
if [ "$RC" -eq 0 ]; then ok "scan: person_id only in a notebook source cell exits 0"; else bad "scan: source-only notebook exited $RC:
$OUT"; fi

echo
printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
