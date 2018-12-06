package main

import "flag"
import "fmt"
import "os"
import "os/exec"
import "encoding/json"

type PrefetchResult struct {
	Url string
	Rev string
	Sha256 string
}

// prefix used to refer to a branch instead of tag
const refsPrefix = "refs/heads/"

// we live in hell, so we must deal with this:
// the prefix given when nix-prefetch-git --quiet fails to find a legitimate revision
// the properties in the result will be as follows:
//   "rev": "refs/heads/fetchgit",
//   "date": "",
//   "sha256": "0sjjj9z1dhilhpc8pq4154czrb79z9cm044jvn75kxcjv6v5l2m5",
//   "fetchSubmodules": false
// the sha is computed likely from an empty checkout, as this sha is consistent across empty revisions
const failedPrefetchRev string = "refs/heads/fetchgit"

const githubTemplate = `{
  owner = "%s";
  repo = "%s";
  rev = "%s";
  sha256 = "%s";
}`

const gitTemplate = `{
  url = "%s";
  rev = "%s";
  sha256 = "%s";
}`

func main() {
	var owner string
	var repo string
	var rev string
	var asFetchGit bool
	var asBranch bool
	var hashOnly bool

	flag.StringVar(&owner, "o", "", "Alias for -owner")
	flag.StringVar(&owner, "owner", "", "The owner of the repository. e.g. justinwoo")
	flag.StringVar(&repo, "r", "", "Alias for -repo")
	flag.StringVar(&repo, "repo", "", "The repository name. e.g. easy-purescript-nix")
	flag.StringVar(&rev, "v", "", "Alias for -rev")
	flag.StringVar(&rev, "rev", "", "Optionally specify which revision should be fetched.")
	flag.BoolVar(&asFetchGit, "fetchgit", false, "Print the output in the fetchGit format. Default: fromFromGitHub")
	flag.BoolVar(&asBranch, "branch", false, "Treat the rev as a branch, where the commit reference should be used.")
	flag.BoolVar(&hashOnly, "hash-only", false, "Print only the hash.")
	flag.Parse()

	if (owner == "" || repo == "") {
		fmt.Println("You must specify the owner and repository to work from")
		fmt.Println("See prefetch-github --help")
		os.Exit(1)
	}

	revArg := ""
	if rev != "" {
		if asBranch {
			revArg = refsPrefix + rev
		} else {
			revArg = rev
		}
	}

	url := fmt.Sprintf("https://github.com/%s/%s.git/", owner, repo)
	cmd := exec.Command(
		"nix-prefetch-git",
		url,
		"--quiet",
		"--rev",
		revArg,
	)

	output, execErr := cmd.CombinedOutput()

	if execErr != nil {
		fmt.Println("Failed to run nix-prefetch-git")
		panic(execErr)
	}

	jsonStr := string(output)

	var result PrefetchResult

	decodeErr := json.Unmarshal([]byte(jsonStr), &result)

	if decodeErr != nil {
		fmt.Println("Failure to decode string:")
		fmt.Println(jsonStr)
		panic(decodeErr)
	}

	if result.Rev == failedPrefetchRev {
		fmt.Println("result revision matched fetch failure revision:")
		fmt.Println(jsonStr)
		os.Exit(1)
	}

	if hashOnly {
		fmt.Println(result.Sha256)
		os.Exit(0)
	}

	var outputRev string
	if rev == "" || asBranch {
		outputRev = result.Rev
	} else {
		outputRev = rev
	}

	if asFetchGit {
		templated := fmt.Sprintf(
			gitTemplate,
			url,
			outputRev,
			result.Sha256,
		)
		fmt.Println(templated)
		os.Exit(0)
	}

	templated := fmt.Sprintf(
		githubTemplate,
		owner,
		repo,
		outputRev,
		result.Sha256,
	)
	fmt.Println(templated)
	os.Exit(0)
}
