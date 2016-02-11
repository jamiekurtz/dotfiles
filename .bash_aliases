alias ll="ls -lh"
alias clip="xclip -select clipboard"
alias bc="bc -l"

function psg() { ps ax | grep "$@"; }


PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

bind -r '\C-s'; stty -ixon

export NPM_PACKAGES=~/.npm_packages
export NODE_PATH=~/.npm_packages/lib/node_modules
export PATH=/home/jkurtz/MyApps/android-sdk-linux/tools:/home/jkurtz/MyApps/android-sdk-linux/platform-tools:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:~/.npm_packages/bin:~/.npm_packages/lib/node_modules

export PATH=~/bin:$PATH 
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/wdgo
export PATH=$PATH:$GOPATH/bin

export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64/jre"
export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.7.5.1/
export PATH=$PATH:$EC2_HOME/bin

alias mongotools="docker run -it -v `pwd`:/wd --rm jakurtz/mongotools"

