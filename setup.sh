CUR_DIR=$(pwd)

echo "making links to the config files"

CONFIG_ITEM=(.config .ghci.conf .gitconfig .gitignore .hammerspoon .inputrc .ipython .mpv .qutebrowser .tmux.conf .zsh .zshrc)

for config in "${CONFIG_ITEM[@]}"; do
  ln -s $CUR_DIR/$config ~/$config
  #rm -rf ~/$config
done

echo "setting the shell to zsh"
chsh -s /bin/zsh

echo 'add fonts to homebrew'
brew tap homebrew/cask-fonts

echo "installing homebrew packages"
for package in $(cat brew-packages); do brew install $package; done
