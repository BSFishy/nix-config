set -e

CWD=$(pwd)

if [[ ! -d "$HOME/shells" ]]; then
  echo "$HOME/shells does not exist. Please create it to be able to use $0"
  exit 1
fi

if [[ -z "$1" ]]; then
  echo "Usage: $0 <project-name>"
  echo "  project-name: required"
  exit 1
fi

PROJECT="$1"

if [[ ! -d "$HOME/shells/$PROJECT" ]]; then
  echo "$HOME/shells/$PROJECT does not exist. Please make a project to be able to start a shell"
  exit 1
fi

if [[ -f "$HOME/shells/$PROJECT/flake.nix" ]]; then
  nix-your-shell zsh nix develop "$HOME/shells/$PROJECT"
elif [[ -f "$HOME/shells/$PROJECT/shell.nix" ]]; then
  pushd "$HOME/shells/$PROJECT"
  nix-your-shell zsh nix-shell --command "cd $CWD; return"
  popd
else
  echo "No nix shell defined in $PROJECT"
  exit 1
fi
