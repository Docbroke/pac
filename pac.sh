#!/bin/sh

export FZF_DEFAULT_OPTS="
  --multi
  --reverse
  --height='80%'
  --border=rounded
  --border-label=' Available Packages '
  --preview-window='right:70%:border-rounded'
  --preview-label=' Package Info '
  --info=inline
  --prompt='> '
  --pointer='▶'
  --color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008,border:111,label:111'
  --bind '?:toggle-preview'
  --bind 'shift-up:preview-up'
  --bind 'shift-down:preview-down'
  --bind 'ctrl-a:select-all'
"

PAC_MANAGE() {
  title="$1"   action="$2"  marker="$3"
  color="$4"   preview="$5"
  shift 5

  if [ "$action" = "Remove" ]; then
    display_title="Pacman \e[31mRemove\e[0m Packages"
    display_action="\e[31mRemove\e[0m"
  else
    display_title="$title"
    display_action="$action"
  fi

  printf '\n'
  printf '\e[1;%sm╭──────────────────────────────────────────────────────────────╮\e[0m\n' "$color"
  printf "\e[1;%sm│\e[1;37m 󰣇 %b\e[1;%sm%s│\e[0m\n" "$color" "$display_title" "$color" "$(printf "%$((59 - ${#title}))s")"
  printf '\e[1;%sm├──────────────────────────────────────────────────────────────┤\e[0m\n' "$color"
  printf "\e[1;%sm│\e[0m ⇥ Select  ⏎ %b\e[1;%sm%s\e[0m? Preview  ⇧↑/↓ Scroll  ^A All       \e[1;%sm│\e[0m\n" "$color" "$display_action" "$color" "$(printf "%-$((12 - ${#action}))s")" "$color"
  printf '\e[1;%sm╰──────────────────────────────────────────────────────────────╯\e[0m\n\n' "$color"

  pacman -Qq | fzf --preview="$preview" --marker="$marker" | xargs -ro "$@"
}

PACS() {
  printf '\n'
  printf '\e[1;36m╭──────────────────────────────────────────────────────────────╮\e[0m\n'
  printf '\e[1;36m│\e[1;37m 󰣇 Pacman Package Installer                                   \e[1;36m│\e[0m\n'
  printf '\e[1;36m├──────────────────────────────────────────────────────────────┤\e[0m\n'
  printf '\e[1;36m│\e[0m ⇥ Select  ⏎ INSTALL  ? Preview  ⇧↑/↓ Scroll  ^A All          \e[1;36m│\e[0m\n'
  printf '\e[1;36m╰──────────────────────────────────────────────────────────────╯\e[0m\n\n'
  printf 'run 🔁 to avoid partial upgrade'

## Changed -Syu to -S to prevent forced full-upgrades on simple installs
  pacman -Ssq | fzf --preview='pacman -Si {1}' --marker='🔜' | xargs -ro doas pacman -S
}

ARG_CHOICE=$(echo "$1" | sed 's/^-//')
while true; do
  if [ -n "$ARG_CHOICE" ]; then
    PACK="$ARG_CHOICE"
    ARG_CHOICE="" # Clear it so the loop prompts normally next time
  else
    echo -e "
choose from s/q/l/o/r/h/a/u/ SPACE=refresh Ctrl-C=exit
    s) 📥 or 🔍 package/s
    q) 🔍 installed package/s
    l) 🧾 FILES in installed package
    o) 🔍 find OWNER of a file
    r) 🔥 package/s
    h) 📚 History
    a) 🧾 of FOREIGN/AUR packages
    u) 🔁"
    read -r -n 1 PACK
  fi

  case $PACK in
    s) PACS; clear ;;
    q) PAC_MANAGE "Get Package INFO" "VIEW" "🔍" "32" "pacman -Qi {1}" pacman -Qi; clear ;;
    l) PAC_MANAGE "List Package Files" "LIST" "🧾" "32" "pacman -Ql {1}" pacman -Qlkk; clear ;;
    r) PAC_MANAGE "Pacman Remove Packages" "Remove" "❌" "31" "pacman -Qi {1}" doas pacman -Rns; clear ;;
    h) grep -E 'reloaded|installed|removed|upgraded' /var/log/pacman.log | sort -r | sed -e 's/removed/\x1b[31mremoved\x1b[0m/g' -e 's/installed/\x1b[32minstalled\x1b[0m/g' -e 's/upgraded/\x1b[33mupgraded\x1b[0m/g' | less -R; clear ;;
    a) pacman -Qm | less; clear ;;
	o)
       pacman -Qlq | grep -v '/$' | \
       fzf --prompt="Find Owner > " \
           --preview="pacman -Qo /{} 2>&1" \
           --border-label=" Find File Owner " \
           --preview-window="right:60%:border-rounded" | \
       xargs -I {} -ro pacman -Qo /{}

       printf "\n\e[1;30mPress any key to return to menu...\e[0m"
       read -r -n 1
       clear
       ;;
    u)
       doas pacman --color=always -Sy archlinux-keyring --needed
       doas pacman --color=always -Su
	   ## for waybar module
       # doas checkupdates | wc -l > /tmp/pacup
       # sleep 1
       # pkill -SIGRTMIN+8 waybar
       clear
       ;;
    " ") clear ;;
    *) clear ;;
  esac
done
