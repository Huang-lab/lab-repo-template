# Data

**Raw data never enters git.** `/data/` is gitignored except this file.
Git keeps every version forever, and `.gitignore` does not remove what's already committed.

## Where the data lives

Fill this in - the most useful paragraph in the repo for the next person.
Paths go here, not hardcoded in scripts (`check_hygiene.sh` rejects `/Users/...` in code).

| What | Where | Access | Contact |
|---|---|---|---|
| Raw extract | `/sc/arion/projects/<project>/raw/` | Minerva group `<group>` | |
| Derived | `/sc/arion/projects/<project>/derived/` | | |
| Reference | `/sc/arion/projects/<project>/ref/` | | |

Symlink rather than copy: `ln -s /sc/arion/projects/<project>/raw data/raw`

## Governance

- Participant-level data is IRB-scoped. Know the protocol; don't move data outside the systems it names.
- `--inspect`-style commands report **schema only**. An extract with no header row hands `csv.DictReader` the first data row as fieldnames - a "column names only" report then prints a real participant ID. That bug reached a lab repo.
- De-identification isn't one-time: free text, dates near an index event, and rare-value combinations re-identify.
- **Exception:** small synthetic fixtures under `tests/fixtures/` are how tests stay runnable. Synthesize them; don't sample real participants.
