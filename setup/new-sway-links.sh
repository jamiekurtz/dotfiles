#!/bin/bash
set -e
DOTFILES=~/wd/dotfiles
mkdir -p ~/.config/sway ~/.config/foot ~/.config/mako ~/.config/swappy

ln -sf $DOTFILES/.gitconfig ~/.gitconfig
ln -sf $DOTFILES/.bash_aliases ~/.bash_aliases
ln -sf $DOTFILES/.profile ~/.profile
ln -sf $DOTFILES/.tmux.conf ~/.tmux.conf

ln -sf $DOTFILES/sway/config.common ~/.config/sway/config.common
ln -sf $DOTFILES/sway/config.d ~/.config/sway/config.d
ln -sf $DOTFILES/foot/foot.ini ~/.config/foot/foot.ini
ln -sf $DOTFILES/mako/config ~/.config/mako/config
ln -sf $DOTFILES/swappy/config ~/.config/swappy/config

case "$(hostname)" in
shadowws) ln -sf $DOTFILES/sway/config-for-meerkat ~/.config/sway/config ;;
shadowlt) ln -sf $DOTFILES/sway/config-for-p14 ~/.config/sway/config ;;
*) echo "unknown host, symlink sway config manually" ;;
esac
