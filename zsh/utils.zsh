###############################################################################
# GIT
###############################################################################
# unalias ohmyzsh git plugin aliases
unalias gma
unalias gca
unalias gc
unalias gl

function gs() { git status $*; }
function gc() { git commit -m "$1"; }
function gca() { git commit --amend -C HEAD; }
function gl() { git dag --max-count=35 $*; }
function gma() { gcm && git pull $@; }
function gma() { gcm && git pull $@; }
alias gpl="git pull"


###############################################################################
# DOCKER
###############################################################################

function dk() { docker $*; }
function dkb() { docker build --rm -t $* .; }
function dps() { docker ps $*; }
function dsa() { docker stop $(docker ps -aq); }
function dstats() { docker stats $(docker ps -q); }
function dcsh() {
  containers=($(docker ps | awk '{if(NR>1) print $NF}'))
  select c in "${containers[@]}"; do
    docker exec -it $c bash
    break
  done;
}

function dco() { docker-compose $*; }
function dcup() { docker-compose -f $* up -d; }
function dcdw() { docker-compose -f $* down; }
function dce() { docker-compose exec -it $*; }


###############################################################################
# GENERAL
###############################################################################

function psgrep() { ps -ef |grep $1 |grep -v grep; }
function up() { Z=1 && [[ -n $1 ]] && Z=$1; for (( X=$Z; X>0; X-- )); do cd ..; done; }

alias reload=". ~/.zshrc"
alias sls=serverless
alias work="cd ~/workspace"
alias "?"=which


# pull() {
#   if [ $# -eq 2 ]; then
#     git pull --rebase -q $2 "$(git rev-parse --abbrev-ref HEAD)"
#   else
#     git pull --rebase -q origin "$(git rev-parse --abbrev-ref HEAD)"
#   fi
# }

# push() {
#   if [ $# -eq 2 ]; then
#     git push -q $2 "$(git rev-parse --abbrev-ref HEAD)"
#   else
#     git push -q origin "$(git rev-parse --abbrev-ref HEAD)"
#   fi
# }

# send() {
#   git add "$(git rev-parse --show-toplevel)"
#   if [ $# -eq 1 ]; then
#     git commit -a -m "$1"
#   else
#     git commit -a -m "I'm too lazy to write a commit message."
#   fi
#   pull
#   push
# }