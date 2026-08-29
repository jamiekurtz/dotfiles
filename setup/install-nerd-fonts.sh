#!/bin/bash

mkdir -p ~/.local/share/fonts/JetBrainsMonoNF
cd ~/.local/share/fonts/JetBrainsMonoNF
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip
rm JetBrainsMono.zip
fc-cache -fv

fc-match "JetBrainsMono Nerd Font Mono"
