alias ll="ls -lhiGF"
alias clip="xclip -select clipboard"
alias bc="bc -l"
function psg() { ps ax | grep "$@"; }


#PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '
# http://ezprompt.net/
PS1="\[\e[01;32m\]\w\[\e[m\] \\$ "

bind -r '\C-s'; stty -ixon

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:~/.npm_packages/bin:~/.npm_packages/lib/node_modules:/usr/sbin

export PATH=~/bin:$PATH 
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
export PATH=~/.local/bin:/snap/bin:$PATH

export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_261

export GOPATH=$HOME/go

alias mongotools="docker run -it -v `pwd`:/wd --rm jakurtz/mongotools"

export DIAGNOTES_NGROK_SUBDOMAIN=dn-jamie

function gd() { f=`mktemp`.patch; git diff develop > $f; /opt/google/chrome/google-chrome $f; }

function dn() { ./dn.sh "$@" ; }
function git-clean-feature { git branch | grep "feature/" | xargs git branch -D - ; }
function cdgo() { cd ~/go/src/github.com/diagnotes; }

function jup-run() { docker run -p 8090:8888 -v "${PWD}":/home/jovyan/work jupyter/scipy-notebook:6b49f3337709 ; }
function browsy-run() { docker run --network=host -v "${PWD}":/home/jovyan/work alphatradeeng/browsy:latest ; }
function py-run() { docker run -v "${PWD}":/home/jovyan/work alphatradeeng/browsy:latest /bin/bash ; }
function prism-run() { docker run -p 8090:8888 -v "${PWD}":/home/jovyan/work diagnotes/prism-notebook:latest ; }
function ate-run() { docker run --network=host -v "${PWD}":/home/jovyan/work alphatradeeng/browsy:latest ; }
function qa-sql() { ssh diagnotes-qa-bastion -L 5432:qadb02.cwqgvymnjrtv.us-east-1.rds.amazonaws.com:5432 ; }
function prod-sql() { ssh diagnotes-prod-bastion -L 5432:pgrr.dnprod:5432 ; }
function prod-trunc() { ssh diagnotes-prod-bastion -L 5432:proddb01-2021-03-09-pre-truncate.cvhyo4oarleo.us-east-1.rds.amazonaws.com:5432 ; }
function run-monday() { docker run -it -v "${PWD}":/home/jovyan/work -w "/home/jovyan/work" alphatradeeng/browsy:latest python3 monday.py ; }
function run-train() { docker run -it -v "${PWD}":/home/jovyan/work -w "/home/jovyan/work" alphatradeeng/browsy:latest python3 train.py ; }
function run-latest() { docker run -it -v "${PWD}":/home/jovyan/work -w "/home/jovyan/work" alphatradeeng/browsy:latest python3 get-latest.py ; }
function prod-sql-primary() { ssh diagnotes-prod-bastion -L 5432:proddb01.cvhyo4oarleo.us-east-1.rds.amazonaws.com:5432 ; }

function prod-trunc() { ssh diagnotes-prod-bastion -L 5432:proddb01-2021-03-09-pre-truncate.cvhyo4oarleo.us-east-1.rds.amazonaws.com:5432 ; }
function prod-bl() { ssh diagnotes-prod-bastion -L 3306:backline-prode02-57.cqazk6iiwrwy.us-east-1.rds.amazonaws.com:3306 ; }
function whatsmyip() { curl -w "\n" ipinfo.io/ip ; }

function rc-run() { docker run --user 1000:1000 --rm -it --workdir /home/bob -v ~/.bash_aliases:/home/bob/.bash_aliases:ro -v ~/.ssh:/home/bob/.ssh:ro -v release-console-home:/home/bob diagnotes/release-console; }

