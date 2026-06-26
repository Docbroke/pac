#!/bin/sh

## FZF config
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

## $1=Title, $2=Action, $3=Marker, $4=Color, $5=PreviewCmd, $6+=ExecCmd
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

# FIXED: Switched back to frame color for spaces, then dropped back to standard text color (\e[0m) before "? Preview"
  printf "\e[1;%sm│\e[0m ⇥ Select  ⏎ %b\e[1;%sm%s\e[0m? Preview  ⇧↑/↓ Scroll  ^A All       \e[1;%sm│\e[0m\n" "$color" "$display_action" "$color" "$(printf "%-$((12 - ${#action}))s")" "$color"
  # printf "\e[1;%sm│\e[0m ⇥ Select  ⏎ %b\e[1;%sm%s? Preview  ⇧↑/↓ Scroll  ^A All       \e[1;%sm│\e[0m\n" "$color" "$display_action" "$color" "$(printf "%-$((12 - ${#action}))s")" "$color"

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

  pacman -Ssq | fzf --preview='pacman -Si {1}' --marker='🔜' | xargs -ro doas pacman -Syu
}

clear
echo -e "
choose from s/q/l/r/h/a/u
    s) 📥 or 🔍 package/s
    q) 🔍 installed package/s
    l) 🧾 FILES in installed package
    r) 🔥 package/s
    h) 📚 History
    a) 🧾 of FOREIGN/AUR packages
    u) 🔁"
read -r -n 1 PACK

case $PACK in
    s) PACS; clear; exec $0 ;;
## Clean Title | Clean Action | Marker Emoji | Color | FZF Preview Mode | Execution Command
    q) PAC_MANAGE "Get Package INFO" "VIEW" "🔍" "32" "pacman -Qi {1}" pacman -Qi; exec $0 ;;
    l) PAC_MANAGE "List Package Files" "LIST" "🧾" "32" "pacman -Ql {1}" pacman -Qlkk; exec $0 ;;
    r) PAC_MANAGE "Pacman Remove Packages" "Remove" "❌" "31" "pacman -Qi {1}" doas pacman -Rns; clear; exec $0 ;;
    h) expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort -r | less; clear; exec $0 ;;
    a) pacman -Qm | less; clear; exec $0 ;;
    u) doas pacman --color=always -Sy archlinux-keyring --needed; doas pacman --color=always -Su; clear; exec $0 ;;
	*) clear; exec $0 ;;
esac
