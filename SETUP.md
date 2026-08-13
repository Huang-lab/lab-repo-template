# New repo checklist

Delete this file when you reach the bottom.

1. **Name it.** Kebab-case unless it's a published tool ([why](./CONVENTIONS.md#repository-names)).

2. **Replace the README.**
   ```sh
   mv docs/README_SKELETON.md README.md && rm SETUP.md
   ```

3. **License.** MIT ships by default. For a tool meant for wide adoption, swap in Apache-2.0 (patent grant) from <https://www.apache.org/licenses/LICENSE-2.0.txt>.

4. **Delete unused scaffolds** - CI detects languages by file presence, so this removes their jobs too.
   ```sh
   rm -rf R DESCRIPTION tests/testthat crates Cargo.toml   # Python only
   rm -rf src steps tests/test_*.py pyproject.toml crates Cargo.toml   # R only
   rm -rf src steps R DESCRIPTION tests pyproject.toml     # Rust only
   ```

5. **Set your git identity in this checkout.** Prevents the lab's two attribution failures: agents committing as themselves, humans committing under a machine-local email GitHub can't link.
   ```sh
   git config user.name  "Your Name"
   git config user.email "the-address-on-your-github-account@example.org"
   git config --get user.email   # if this ends in .local or a hostname, fix it
   ```

6. **Hooks.** `pip install pre-commit && pre-commit install`

7. **Fill in `CITATION.cff`.**

8. **Branch protection** (any repo backing a manuscript or going public):
   ```sh
   gh api -X PUT repos/Huang-lab/<repo>/branches/main/protection \
     --input .github/branch-protection.json
   ```

9. **Write down where data lives** in [data/README.md](./data/README.md). Paths go there, not in scripts.

10. **Before going public or submitting:** `./scripts/scan_history.sh --full`
    `.gitignore` does not remove what's already committed, and the fix (`git filter-repo` + force push) only works cleanly before external forks exist.
