alias ll="ls -alh"
alias clip="xclip -select clipboard"
alias bc="bc -l"

function psg() { ps ax | grep "$@"; }


PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

bind -r '\C-s'; stty -ixon

export NPM_PACKAGES=~/.npm_packages
export NODE_PATH=~/.npm_packages/lib/node_modules
export PATH=/home/jkurtz/MyApps/android-sdk-linux/tools:/home/jkurtz/MyApps/android-sdk-linux/platform-tools:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:~/.npm_packages/bin:~/.npm_packages/lib/node_modules


