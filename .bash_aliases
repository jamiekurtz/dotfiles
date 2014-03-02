alias ll="ls -alch"
alias bdown="xrandr --output eDP1 --brightness 0.6"
alias bup="xrandr --output eDP1 --brightness 1.0"
alias clip="xclip -select clipboard"
alias cdr="cd ~/wd/rividea"

alias d2on="xrandr --output HDMI1 --right-of eDP1 --auto"
alias d2off="xrandar --output HDMI1 --off"

alias d3on="xrandr --output VGA1 --right-of eDP1 --auto"
alias d3off="xrandr --output VGA1 --off"


export PATH="/home/jkurtz/MyApps/adt-bundle-linux-x86_64-20130917/sdk/platform-tools:$PATH"

bind -r '\C-s'
stty -ixon


### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
