#!/bin/bash
ln -s ~/.config/zsh/themes/powerlevel9k ~/.oh-my-zsh/custom/themes/powerlevel9k ;
#offlineimap
#vdirsyncer discover
#vdirsyncer sync
ln -s ~/.config/oh-my-zsh-modules/autoupdate ~/.oh-my-zsh/plugins/autoupdate
ln -s ~/.config/oh-my-zsh-modules/you-should-use ~/.oh-my-zsh/plugins/you-should-use
nvim +PluginInstall +qall ;
nvim +UpdateRemotePlugins ;
