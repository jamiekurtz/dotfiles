alias ll="ls -lhiGF"
#alias clip="xclip -select clipboard"
alias clip="pbcopy"
alias bc="bc -l"
alias pgstop="launchctl stop ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
alias pgstart="launchctl start ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
alias pgload="launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"
alias pgunload="launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist"

function psg() { ps ax | grep "$@"; }

alias mongotools="docker run -it -v `pwd`:/wd --rm jakurtz/mongotools"

