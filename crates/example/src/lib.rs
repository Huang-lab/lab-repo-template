//! Library half of the crate. Logic lives here so integration tests and the
//! binary can both reach it, and so `cargo test` has something to test.

/// Parse a `chr:pos` locus, rejecting anything malformed rather than guessing.
///
/// Returns `None` for input this function cannot interpret. Callers decide
/// whether that is fatal - a parser that silently substitutes a default is how a
/// pipeline produces plausible wrong numbers instead of an error.
///
/// # Examples
///
/// ```
/// use example::parse_locus;
/// assert_eq!(parse_locus("chr22:17000000"), Some(("chr22".to_string(), 17_000_000)));
/// assert_eq!(parse_locus("chr22:-1"), None);
/// ```
pub fn parse_locus(input: &str) -> Option<(String, u64)> {
    let (chrom, pos) = input.split_once(':')?;
    if chrom.is_empty() {
        return None;
    }
    let pos: u64 = pos.parse().ok()?;
    Some((chrom.to_string(), pos))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_a_well_formed_locus() {
        assert_eq!(
            parse_locus("chr22:17000000"),
            Some(("chr22".to_string(), 17_000_000))
        );
    }

    #[test]
    fn rejects_negative_and_non_numeric_positions() {
        assert_eq!(parse_locus("chr22:-1"), None);
        assert_eq!(parse_locus("chr22:seventeen"), None);
    }

    #[test]
    fn rejects_missing_parts() {
        assert_eq!(parse_locus("chr22"), None);
        assert_eq!(parse_locus(":17000000"), None);
    }
}
