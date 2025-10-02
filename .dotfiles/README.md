# dotfiles

Each project that exists in the Automa project should do the following:
1. Add this REPO as a git-submodule & ensure to keep it up-to-date `git submodule add https://github.com/GetAutomaApp/dotfiles .dotfiles`
2. In the `install:all` `package.json` script add the following:
```json
"config": "./.dotfiles/config.sh"
"install:all": "previous commands... npm run config"
```

> [!NOTE]
> Any repo you clone that already has the dotfiles included clone via this command: `git clone <repo> --recursive` 

Add the following command to your package.json in order to update all the sub-modules in the repo.
This command automatically runs `npm run config` if there where any changes in the `.dotfiles` folder
```json
{
  "scripts": {
    "update:submodules": "git submodule foreach --recursive 'branch=$(git remote show origin | awk \"/HEAD branch/ {print \\$NF}\"); git checkout $branch && git pull origin $branch' && CHANGED=$(git status --porcelain | grep '^ M \\.dotfiles' || true) && if [ -n \"$CHANGED\" ]; then npm run config; fi && git add -A && git commit -m \"chore: update submodules\" || echo 'No changes to commit'",
    "lint": "swiftlint . --config=.swiftlint.yml",
    "format": "./.dotfiles/format.sh"
  }
}
```
> [!NOTE]
> If you're adding this to an existing repo where others have this cloned locally. Please ask them to run this command: `git submodule update --init --recursive`
