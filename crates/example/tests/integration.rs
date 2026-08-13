//! Integration tests live in `tests/`, which means they are compiled as separate
//! crates and only run when the test target is built.
//!
//! `cargo test --workspace --lib` does NOT run this file. fastVEP shipped that CI
//! command while a bare `tests/` in `.gitignore` was separately hiding four test
//! files from every fresh clone - two invisible failures compounding. This file
//! exists partly so that `--all-targets` has something to prove.

use example::parse_locus;

#[test]
fn round_trips_a_realistic_locus_list() {
    let input = ["chr1:1", "chrX:155270000", "chr22:17000000"];
    let parsed: Vec<_> = input.iter().filter_map(|s| parse_locus(s)).collect();
    assert_eq!(parsed.len(), 3, "every well-formed locus should parse");
    assert_eq!(parsed[1].0, "chrX");
    assert_eq!(parsed[2].1, 17_000_000);
}

#[test]
fn malformed_input_is_dropped_not_defaulted() {
    let input = ["chr1:1", "garbage", "chr2:", ":5"];
    let parsed: Vec<_> = input.iter().filter_map(|s| parse_locus(s)).collect();
    assert_eq!(parsed.len(), 1);
}
