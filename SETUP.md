# New repo checklist

Delete this file when done.

**1. Cut first.** Keep what fits your project, delete the rest. CI detects languages by file presence, so deleting a scaffold removes its job too.

```sh
rm -rf R DESCRIPTION tests/testthat crates Cargo.toml          # not R or Rust
rm -rf src steps tests/test_*.py pyproject.toml                # not Python
rm -rf docs config .pre-commit-config.yaml .github/dependabot.yml   # if unused
rm CONVENTIONS.md CONTRIBUTING.md                              # if you won't follow them
```

Keep `.gitignore`, `LICENSE`, and - if the repo will ever go public - `scripts/`.

**2. Replace the README.** `mv docs/README_SKELETON.md README.md && rm SETUP.md`

**3. Set your git identity here.** The one step everyone should do - it prevents agents committing as themselves and humans committing under an email GitHub can't link.

```sh
git config user.name "Your Name" && git config user.email "your-github-email@mssm.edu"
git config --get user.email   # ends in .local or a hostname? fix it
```

**4. License.** MIT ships by default; swap in [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0.txt) for a tool meant for wide adoption.

**5. Optional extras.**

```sh
pip install pre-commit && pre-commit install     # hooks
gh api -X PUT repos/Huang-lab/<repo>/branches/main/protection \
  --input .github/branch-protection.json         # branch protection
```

Also worth it: fill in `CITATION.cff`, and note where data lives in `data/README.md`.

**6. Before going public or submitting:** `./scripts/scan_history.sh --full`
`.gitignore` doesn't remove what's already committed, and the fix (`git filter-repo` + force push) only works cleanly before external forks exist.
