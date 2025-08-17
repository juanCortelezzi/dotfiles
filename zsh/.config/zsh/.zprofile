export PATH="$HOME/.local/bin:$PATH"

if [[ "$(tty)" = "/dev/tty1" ]]; then
  if uwsm check may-start 1; then
      exec systemd-cat -t uwsm_start uwsm start hyprland-uwsm.desktop
  fi
fi
