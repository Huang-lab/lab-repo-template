# Contributing

Delete or rewrite this file to match how the repo actually works.

```sh
git config user.name "Your Name" && git config user.email "your-github-email@mssm.edu"

pip install -e '.[dev]' && pre-commit install    # Python
Rscript -e 'renv::restore()'                     # R
cargo build --workspace                          # Rust
```

## Loop

1. Branch `<initials>/<topic>`.
2. Write the test first where a function could return a plausible wrong number rather than an error.
3. Mutation-check it: break the code, confirm the test fails, restore.
4. Commit per module or stage, naming the observation that motivated the change.
5. Open a PR. A human merges.

## Before pushing

```sh
./scripts/check_hygiene.sh
pytest -q                                            # Python
Rscript -e 'testthat::test_dir("tests/testthat")'    # R
cargo test --workspace --all-targets                 # Rust (--lib skips integration tests)
```

[CONVENTIONS.md](./CONVENTIONS.md) | [AGENTS.md](./AGENTS.md)
