#![warn(rust_2018_idioms, clippy::all)]

use std::env;
use std::process::exit;
use std::process::Command;

fn main() {
    let mut args: Vec<String> = env::args().collect();
    args.remove(0);

    let mut help: bool = false;
    let mut branch: bool = false;
    let mut fetchgit: bool = false;
    let mut hash_only: bool = false;
    let mut opt_owner: Option<&str> = None;
    let mut opt_repo: Option<&str> = None;
    let mut opt_rev: Option<&str> = None;

    let required_param = |tag: &str, i: usize| {
        let result: Option<&str>;
        match args.get(i + 1) {
            Some(x) => result = Some(x),
            None => {
                println!("Error: Expected argument for flag '{}'", tag);
                exit(1)
            }
        };
        result
    };

    for (i, x) in args.clone().iter().enumerate() {
        let word: &str = x;
        match word {
            "-owner" => opt_owner = required_param("-owner", i),
            "-repo" => opt_repo = required_param("-repo", i),
            "-rev" => opt_rev = required_param("-rev", i),

            "-branch" => branch = true,
            "-fetchgit" => fetchgit = true,
            "-hash-only" => hash_only = true,

            "help" => help = true,
            "-h" => help = true,
            "-help" => help = true,
            "--help" => help = true,
            _ => {}
        };
    }

    if help || args.is_empty() {
        println!("{}", HELP_MESSAGE);
        exit(0);
    }

    if opt_owner.is_none() {
        println!("You must specify an owner via '-owner OWNER'. See help.");
        exit(1);
    }

    if opt_repo.is_none() {
        println!("You must specify a repo via '-repo REPO'. See help.");
        exit(1);
    }

    let owner = opt_owner.unwrap();
    let repo = opt_repo.unwrap();

    let results: NixPrefetchGitResults = get_nix_prefetch_git_results(owner, repo, opt_rev, branch);

    if hash_only {
        println!("{}", results.sha);
        exit(0);
    }

    if fetchgit {
        println!(
            r#"{{
  url = "{}";
  rev = "{}";
  sha256 = "{}";
}}"#,
            results.url, results.rev, results.sha
        );
        exit(0);
    } else {
        println!(
            r#"{{
  owner = "{}";
  repo = "{}";
  rev = "{}";
  sha256 = "{}";
}}"#,
            owner, repo, results.rev, results.sha
        );
        exit(0);
    }
}

struct NixPrefetchGitResults {
    url: String,
    rev: String,
    sha: String,
}

fn get_nix_prefetch_git_results(
    owner_arg: &str,
    repo_arg: &str,
    opt_rev_arg: Option<&str>,
    as_branch: bool,
) -> NixPrefetchGitResults {
    let rev_arg = match (opt_rev_arg, as_branch) {
        (Some(r), true) => {
            let formatted = format!("{}{}", REFS_PREFIX, r);
            formatted
        }
        (Some(r), false) => r.to_owned(),
        (None, _) => "".to_owned(),
    };

    let prefetch_result = Command::new("nix-prefetch-git")
        .arg("--quiet")
        .arg(format!("https://github.com/{}/{}.git/", owner_arg, repo_arg))
        .arg("--rev")
        .arg(rev_arg)
        .env("GIT_TERMINAL_PROMPT", "0")
        .output()
        .expect("Failed to run nix-prefetch-git in bash")
        .stdout;

    let result: String = String::from_utf8(prefetch_result).unwrap();

    // Parse out the result of running nix-prefetch-git
    // {
    //   "url": "https://github.com/justinwoo/easy-purescript-nix",
    //   "rev": "54266e45aeaebc78dd51a40da36e9840a8a300dd",
    //   "date": "2019-02-08T01:59:41+02:00",
    //   "sha256": "1swjii6975cpys49w5rgnhw5x6ms2cc9fs8ijjpk04pz3zp2vpzn",
    //   "fetchSubmodules": false
    // }

    let mut url: Option<String> = None;
    let mut rev: Option<String> = None;
    let mut sha: Option<String> = None;

    for line_ in result.lines() {
        let line = line_.replace(",", "").replace("\"", "");
        let split = line.split_whitespace().collect::<Vec<&str>>();
        if line.contains("url") {
            url = Some(split[1].to_string());
        }
        if line.contains("rev") {
            rev = Some(split[1].to_string());
        }
        if line.contains("sha256") {
            sha = Some(split[1].to_string());
        }
    }

    let prefetch_results = NixPrefetchGitResults {
        url: url
            .unwrap_or_else(|| panic!("Could not parse url result"))
            .to_owned(),
        rev: rev
            .unwrap_or_else(|| panic!("Could not parse revision result"))
            .to_owned(),
        sha: sha
            .unwrap_or_else(|| panic!("Could not parse sha256 result"))
            .to_owned(),
    };

    if prefetch_results.rev == FAILED_PREFETCH_REV {
        println!("nix-prefetch-git could not fetch the repo with the given params.");
        exit(1);
    } else {
        prefetch_results
    }
}

// prefix used to refer to a branch instead of tag
const REFS_PREFIX: &str = "refs/heads/";

// we live in hell, so we must deal with this:
// the prefix given when nix-prefetch-git --quiet fails to find a legitimate revision
// the properties in the result will be as follows:
//   "rev": "refs/heads/fetchgit",
//   "date": "",
//   "sha256": "0sjjj9z1dhilhpc8pq4154czrb79z9cm044jvn75kxcjv6v5l2m5",
//   "fetchSubmodules": false
// the sha is computed likely from an empty checkout, as this sha is consistent across empty revisions
const FAILED_PREFETCH_REV: &str = "refs/heads/fetchgit";

const HELP_MESSAGE: &str = "Usage of prefetch-github:
   -branch
     Treat the rev as a branch, where the commit reference should be used.
   -fetchgit
     Print the output in the fetchGit format. Default: fromFromGitHub
   -hash-only
     Print only the hash.
   -owner string
     The owner of the repository. e.g. justinwoo
   -repo string
     The repository name. e.g. easy-purescript-nix
   -rev string
     Optionally specify which revision should be fetched.";
