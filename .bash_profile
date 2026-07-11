#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

mkdir -p /tmp/Downloads
ln -sf /tmp/Downloads -t $HOME


if [[ "$PWD" == "$HOME" ]]; then
    /home/hugo/code/hemp/bin/todo -week -quiet
fi

if [ "$(tty)" = "/dev/tty1" ]; then
    exec uwsm start -e -D Hyprland hyprland.desktop
fi
