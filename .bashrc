export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

export NPM_PACKAGES=~/.npm_packages
export NODE_PATH=~/.npm_packages/lib/node_modules
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:~/.npm_packages/bin:~/.npm_packages/lib/node_modules:$PATH

# golang stuff
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/wdgo
export PATH=$PATH:$GOPATH/bin

export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64/jre"
export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.7.5.1/
export PATH=$PATH:$EC2_HOME/bin

bind -r '\C-s'; stty -ixon

# Custom bash prompt via kirsle.net/wizards/ps1.html
#export PS1="\[$(tput bold)\]\[$(tput setaf 2)\][\w] $ \[$(tput sgr0)\]"
PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '

#if [ -f $(brew --prefix)/etc/bash_completion ]; then
#    . $(brew --prefix)/etc/bash_completion
#fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

