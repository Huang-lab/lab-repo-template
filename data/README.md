# Data

**Raw data never enters git.** `/data/` is gitignored except this file. Git keeps every version forever, and `.gitignore` doesn't remove what's already committed.

## Where the data lives

Fill in what applies - this is the most useful paragraph in the repo for the next person. Paths go here, not hardcoded in scripts.

| What | Where | Access | Contact |
|---|---|---|---|
| Raw extract | `/sc/arion/projects/<project>/raw/` | Minerva group `<group>` | |

Symlink rather than copy: `ln -s /sc/arion/projects/<project>/raw data/raw`

## If the data is participant-level

- Know which IRB protocol covers it; don't move it outside the systems that protocol names.
- `--inspect`-style commands report **schema only**. An extract with no header row hands `csv.DictReader` the first data row as fieldnames, so a "column names only" report prints a real participant ID. That bug reached a lab repo.
- De-identification isn't one-time: free text, dates near an index event, and rare-value combinations re-identify.
- **Exception:** small *synthetic* fixtures under `tests/fixtures/` keep tests runnable. Don't sample real participants.
