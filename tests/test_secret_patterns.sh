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
for p in "${PATTERNS[@]}"; do
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

echo
printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
