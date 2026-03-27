alias e = cd ~/appropos/envoy-web
alias van = ~/bin/my-emacs.sh

alias cod = git checkout develop
alias pd = git pull origin develop
alias ns = cd ~/appropos/envoy-web/server/bin/run-dev-server
alias o = ~/dotfiles/scripts/next_rebase_file.sh
alias fd = ~/dotfiles/scripts/next_git_diff_file.sh
alias fa = ~/dotfiles/scripts/next_git_add_file.sh
alias fr = ~/dotfiles/scripts/next_git_checkout_file.sh
alias fo = ~/dotfiles/scripts/next_git_ours_file.sh
alias ft = ~/dotfiles/scripts/next_git_theirs_file.sh
alias cf = ~/dotfiles/scripts/next_vs_code_file.sh
alias ef = ~/dotfiles/scripts/next_emacs_file.sh

alias nr = npm run
alias nt = npm run test:concurrent
alias nrt = npm run test-one
alias nrs = npm run test:server
alias nru = npm run test:utilities
alias nrc = npm run test:client

alias gits = git status
alias co = git checkout
alias cob = git checkout -b
alias gitc = git commit -m
alias gitb = git branch
alias gitd = git diff
def gita [] {
      git add -A .
      git status
}
alias gitl = git log
def gpull [] {
    git pull origin (git symbolic-ref --short HEAD) --rebase
}
def gpush [] {
    git push origin (git symbolic-ref --short HEAD)
}
alias cof = bash ~/dotfiles/scripts/checkout_feature.sh
# alias stash='git add -A .; git stash; git status'
# alias pop='git stash pop; git reset HEAD .; git status'
alias rmautodump = rm auto_dump_*.tar.gz; rm -rf auto_dump_*
# alias fcode='fzf | cut -d ":" -f 1 | xargs code'

alias onering = /Users/michaelschneider/code/tools-and-infrastructure/scripts/developer/one-ring/onering.sh

# Select environment - sources .sh export files via fzf
def --env se [] {
    let env_dir = "~/code/tools-and-infrastructure/scripts/developer/environments" | path expand
    let filename = (ls $env_dir | get name | each { path basename } | to text | fzf | str trim)
    load-sh-exports ($env_dir | path join $filename)
}
