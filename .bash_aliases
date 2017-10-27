alias ll="ls -lhiGF"
alias clip="xclip -select clipboard"
#alias clip="pbcopy"
alias bc="bc -l"
function psg() { ps ax | grep "$@"; }

function de() { ssh diaglocal "cd /vagrant && $@"; }

# sudo apt-get install openvpn easy-rsa xsel
# might need to set --verb 4 for below commands
function vpnd() { sudo openvpn --config ~/jamie-sync/diagnotes/openvpn/linux/mac-dev.ovpn;  }
function vpns() { sudo openvpn --config ~/jamie-sync/diagnotes/openvpn/linux/mac-staging.ovpn; }
function vpnp() { sudo openvpn --config ~/jamie-sync/diagnotes/openvpn/linux/linux-prod.ovpn ; }

#PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '
# http://ezprompt.net/
PS1="\[\e[01;32m\]\w\[\e[m\] \\$ "

bind -r '\C-s'; stty -ixon

export NPM_PACKAGES=~/.npm_packages
export NODE_PATH=~/.npm_packages/lib/node_modules
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:~/.npm_packages/bin:~/.npm_packages/lib/node_modules:/usr/sbin

export PATH=~/bin:$PATH 
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin

export GOPATH=$HOME/go

alias mongotools="docker run -it -v `pwd`:/wd --rm jakurtz/mongotools"

export DIAGNOTES_NGROK_SUBDOMAIN=dn-jamie

function gd() { f=`mktemp`.patch; git diff develop > $f; /opt/google/chrome/google-chrome $f; }

function dn() { ./dn.sh "$@" ; }
function git-clean-feature { git branch | grep "feature/" | xargs git branch -D - ; }

