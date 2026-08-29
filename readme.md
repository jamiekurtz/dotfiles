
On a new machine:

```
mkdir ~/wd
git clone https://github.com/jamiekurtz/dotfiles.git ~/wd/dotfiles
cd ~/wd/dotfiles
./setup/new-sway-packages.sh
./setup/new-sway-links.sh
. ~/.profile
```

Before launching sway, verify the config:

```
# root config
sway -C -c ~/.config/sway/config

# individual files
sway -C -c ~/.config/sway/config.common
sway -C -c ~/.config/sway/config.d/p14.conf
sway -C -c ~/.config/sway/config.d/meerkat.conf
```

Note, you may see the following harmless error: `gpu: amdgpu_cs_ctx_create2 failed`

To launch sway manually from VT:

```
sway
```

To temporarily disable auto-launch of sway in this profile:

```
touch ~/.no-sway
```

The code in `.profile` will see this marker file and skip the launch of sway. Just remove
that file to return to the auto-launch configuration.



