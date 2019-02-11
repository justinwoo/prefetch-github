-- | A simple program for preparing fetchFromGitHub expressions for nix
-- | Ported from go. See history for original.

module Main where

import qualified Data.List as List
import qualified Data.Text as Text
import qualified System.Environment as Env
import qualified System.Process as Proc

main :: IO ()
main = do
  args <- Env.getArgs
  case args of
    [] -> help
    ["help"] -> help
    ["-help"] -> help
    _ -> main' args

main' :: [String] -> IO ()
main' args = do
  owner <- parseOwner args
  repo <- parseRepo args

  let cmd = mkNixPrefetchGitCmd owner repo revArg
  let cp = Proc.shell cmd
  out <- Proc.readCreateProcess cp ""

  (url, rev, sha@(Sha sha')) <- parseNixPrefetchGitResult out

  case (hashOnly, fetchGit) of
    (True, _) -> putStrLn sha'
    (_, False) -> putStrLn $ mkGithubTemplate owner repo rev sha
    (_, True) -> putStrLn $ mkGitTemplate url rev sha

  where
    fetchGit = parseFetchGit args
    asBranch = parseAsBranch args
    hashOnly = parseHashOnly args
    revArg = case (parseRev args, asBranch) of
      (Just (Rev r), True) -> refsPrefix <> r
      (Just (Rev r), False) -> r
      (Nothing, _) -> ""

-- | Required arg for Owner of a repo (user or org)
newtype Owner = Owner String

-- | Required arg for repo (e.g. 'readme' in justinwoo/readme)
newtype Repo = Repo String

-- | Revision (git)
newtype Rev = Rev String

newtype Url = Url String
newtype Sha = Sha String

help :: IO ()
help = putStrLn helpMessage

parseOwner :: [String] -> IO Owner
parseOwner ("-owner" : owner : _) = pure $ Owner owner
parseOwner (_ : xs) = parseOwner xs
parseOwner [] = fail "owner must be specified in args. see help."

parseRepo :: [String] -> IO Repo
parseRepo ("-repo" : repo : _) = pure $ Repo repo
parseRepo (_ : xs) = parseRepo xs
parseRepo [] = fail "repo must be specified in args. see help."

parseRev :: [String] -> Maybe Rev
parseRev ("-rev" : rev : _) = Just $ Rev rev
parseRev (_ : xs) = parseRev xs
parseRev [] = Nothing

-- | Print the output in the fetchGit format. Default: fromFromGitHub"
parseFetchGit :: [String] -> Bool
parseFetchGit = List.elem "-fetchgit"

-- | Treat the rev as a branch, where the commit reference should be used
parseAsBranch :: [String] -> Bool
parseAsBranch = List.elem "-branch"

-- | Print only the hash
parseHashOnly :: [String] -> Bool
parseHashOnly = List.elem "-hash-only"

-- | Parse out the result of running nix-prefetch-git
-- {
--   "url": "https://github.com/justinwoo/easy-purescript-nix",
--   "rev": "54266e45aeaebc78dd51a40da36e9840a8a300dd",
--   "date": "2019-02-08T01:59:41+02:00",
--   "sha256": "1swjii6975cpys49w5rgnhw5x6ms2cc9fs8ijjpk04pz3zp2vpzn",
--   "fetchSubmodules": false
-- }
parseNixPrefetchGitResult :: String -> IO (Url, Rev, Sha)
parseNixPrefetchGitResult out = do
  case handleResult <$> mUrl <*> mRev <*> mSha of
    Just x -> x
    Nothing -> fail $ "failed to parse nix-prefetch-git output: " <> out
  where
    texts = Text.lines $ Text.pack out
    takeProp key
        = Text.filter (\c -> c /= '"' && c /= ',')
        . (\xs -> xs !! 1)
        . Text.words
      <$> List.find (Text.isInfixOf . Text.pack $ "\"" <> key <> "\"") texts
    mUrl = takeProp "url"
    mRev = takeProp "rev"
    mSha = takeProp "sha256"
    mkString ctr txt = ctr $ Text.unpack txt
    handleResult url rev sha =
      if Text.pack failedPrefetchRev `Text.isInfixOf` rev
        then fail $ "nix-prefetch-url could not find the repo:\n" <> out
        else pure $ (mkString Url url, mkString Rev rev, mkString Sha sha)

-- | prefix used to refer to a branch instead of tag
refsPrefix :: String
refsPrefix = "refs/heads/"

-- | we live in hell, so we must deal with this:
-- | the prefix given when nix-prefetch-git --quiet fails to find a legitimate revision
-- | the properties in the result will be as follows:
-- |   "rev": "refs/heads/fetchgit",
-- |   "date": "",
-- |   "sha256": "0sjjj9z1dhilhpc8pq4154czrb79z9cm044jvn75kxcjv6v5l2m5",
-- |   "fetchSubmodules": false
-- | the sha is computed likely from an empty checkout, as this sha is consistent across empty revisions
failedPrefetchRev :: String
failedPrefetchRev = "refs/heads/fetchgit"

mkNixPrefetchGitCmd :: Owner -> Repo -> String -> String
mkNixPrefetchGitCmd (Owner owner) (Repo repo) revArg = cmd
  where
    url = "https://github.com/" <> owner <> "/" <> repo <> ".git/"
    cmd = "GIT_TERMINAL_PROMPT=0 nix-prefetch-git " <> url <> " --quiet --rev " <> revArg

mkGithubTemplate :: Owner -> Repo -> Rev -> Sha -> String
mkGithubTemplate (Owner owner) (Repo repo) (Rev rev) (Sha sha) = "{\n\
\  owner = \"" <> owner <> "\";\n\
\  repo = \"" <> repo <> "\";\n\
\  rev = \"" <> rev <> "\";\n\
\  sha256 = \"" <> sha <> "\";\n\
\}"

mkGitTemplate :: Url -> Rev -> Sha -> String
mkGitTemplate (Url url) (Rev rev) (Sha sha) = "{\n\
\  url =\"" <> url <> "\";\n\
\  rev =\"" <> rev <> "\";\n\
\  sha256 =\"" <> sha <> "\";\n\
\}"

helpMessage :: String
helpMessage = "Usage of prefetch-github:\n\
\  -branch\n\
\    Treat the rev as a branch, where the commit reference should be used.\n\
\  -fetchgit\n\
\    Print the output in the fetchGit format. Default: fromFromGitHub\n\
\  -hash-only\n\
\    Print only the hash.\n\
\  -owner string\n\
\    The owner of the repository. e.g. justinwoo\n\
\  -repo string\n\
\    The repository name. e.g. easy-purescript-nix\n\
\  -rev string\n\
\    Optionally specify which revision should be fetched."
