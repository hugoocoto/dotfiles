#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

mkdir -p /tmp/Downloads
ln -sf /tmp/Downloads -t $HOME


if [[ "$PWD" == "$HOME" ]]; then
    todo -week -quiet
fi
