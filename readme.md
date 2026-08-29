
From a config with sway, etc.:

```
mv ~/.config/sway/config.common ~/dotfiles/sway/
mv ~/.config/sway/config.d ~/dotfiles/sway/
mv ~/.config/foot/foot.ini ~/dotfiles/foot/
mv ~/.config/mako/config ~/dotfiles/mako/
mv ~/.config/swappy/config ~/dotfiles/swappy/

ln -s ~/dotfiles/sway/config.common ~/.config/sway/config.common
ln -s ~/dotfiles/sway/config.d ~/.config/sway/config.d
ln -s ~/dotfiles/foot/foot.ini ~/.config/foot/foot.ini
ln -s ~/dotfiles/mako/config ~/.config/mako/config
ln -s ~/dotfiles/swappy/config ~/.config/swappy/config
```

On a new machine:

```
mkdir ~/wd
git clone git@github.com:jamiekurtz/dotfiles.git ~/wd/dotfiles
cd ~/wd/dotfiles
./setup/new-sway-links.sh
./setup/new-sway-packages.sh
```

