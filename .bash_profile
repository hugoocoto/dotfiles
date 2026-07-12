#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

mkdir -p /tmp/Downloads
ln -sf /tmp/Downloads -t $HOME


if [ "$(tty)" = "/dev/tty1" ]; then
    exec uwsm start -e -D Hyprland hyprland.desktop
fi

[[ "$PWD" == "$HOME" ]] && command -v "todo" &>/dev/null && todo -week -quiet

