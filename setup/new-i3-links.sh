if [ ! -f ~/.config/picom/picom.conf ]; then 
    mkdir -p ~/.config/picom
    ln -s ~/wd/dotfiles/picom/picom.conf ~/.config/picom/picom.conf
fi

if [ ! -f ~/.config/i3/config ]; then 
    ln -s ~/jamie-sync/dotfiles/i3/config ~/.config/i3/config
fi

