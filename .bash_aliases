alias ll="ls -lh"
alias clip="xclip -select clipboard"
alias bc="bc -l"

function psg() { ps ax | grep "$@"; }

function de() { ssh diaglocal "cd /vagrant && $@"; }

function vpnd() { sudo openvpn --config ~/jamie-sync/diagnotes/mac-dev.ovpn --auth-user-pass ~/jamie-sync/diagnotes/mac-dev-vpn-credentials; }
function vpns() { sudo openvpn --config ~/jamie-sync/diagnotes/mac-staging.ovpn --auth-user-pass ~/jamie-sync/diagnotes/mac-staging-vpn-credentials; }

PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

bind -r '\C-s'; stty -ixon

export NPM_PACKAGES=~/.npm_packages
export NODE_PATH=~/.npm_packages/lib/node_modules
export PATH=/home/jkurtz/MyApps/android-sdk-linux/tools:/home/jkurtz/MyApps/android-sdk-linux/platform-tools:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:~/.npm_packages/bin:~/.npm_packages/lib/node_modules:/usr/sbin

export PATH=~/bin:$PATH 
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/wdgo
export PATH=$PATH:$GOPATH/bin


