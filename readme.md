Initial repo setup: 

```
mkdir -p ~/dotfiles
cd ~/dotfiles
git init
mkdir -p sway foot mako swappy
```

Move files around and symlink:

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

For machine-specific config:

```
cp ~/.config/sway/config ~/dotfiles/sway/config-for-meerkat   # or config-for-p14
ln -sf ~/dotfiles/sway/config-for-meerkat ~/.config/sway/config
```

On a new machine:

```
git clone git@github.com:you/dotfiles.git ~/dotfiles
mkdir -p ~/.config/sway ~/.config/foot ~/.config/mako ~/.config/swappy

ln -s ~/dotfiles/sway/config.common ~/.config/sway/config.common
ln -s ~/dotfiles/sway/config.d ~/.config/sway/config.d
ln -s ~/dotfiles/foot/foot.ini ~/.config/foot/foot.ini
ln -s ~/dotfiles/mako/config ~/.config/mako/config
ln -s ~/dotfiles/swappy/config ~/.config/swappy/config

# pick ONE, matching this machine:
ln -s ~/dotfiles/sway/config-for-meerkat ~/.config/sway/config
ln -s ~/dotfiles/sway/config-for-p14 ~/.config/sway/config
```
