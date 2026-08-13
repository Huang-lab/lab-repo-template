//! Binary half of the crate. Keep it thin: parse arguments, install a logger,
//! call into the library.

use std::process::ExitCode;

use example::parse_locus;

fn main() -> ExitCode {
    // Install a logger FIRST, before anything can warn. fastVEP silently dropped
    // every IUPAC-allele variant because `log::warn!` fired into a logger that was
    // never installed. With log + env_logger:
    //     env_logger::Builder::from_env(
    //         env_logger::Env::default().default_filter_or("info")).init();
    eprintln!("example: diagnostics on stderr; add env_logger and init it here");

    let mut args = std::env::args().skip(1);
    let Some(locus) = args.next() else {
        eprintln!("usage: example <chr:pos>");
        return ExitCode::from(2);
    };

    match parse_locus(&locus) {
        Some((chrom, pos)) => {
            println!("{chrom}\t{pos}");
            ExitCode::SUCCESS
        }
        None => {
            eprintln!("error: could not parse locus {locus:?}");
            ExitCode::FAILURE
        }
    }
}
