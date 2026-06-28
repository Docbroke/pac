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

  if [ ! -t 0 ]; then
    SELECTION=$(fzf --preview="$preview" --marker="$marker")
  else
    SELECTION=$(pacman -Qq | fzf --preview="$preview" --marker="$marker")
  fi

  if [ -n "$SELECTION" ] && [ "$SELECTION" != "" ]; then
    ARGS=$(echo "$SELECTION" | tr '\n' ' ')

    case "$*" in
      *"/{}"*)
        echo "$SELECTION" | while read -r item; do
          if [ -n "$item" ]; then
            cmd_string=$(echo "$*" | sed "s|/{}|/$item|g")
            eval "$cmd_string" < /dev/tty
          fi
        done
        ;;
      *)
        $@ $ARGS < /dev/tty
        ;;
    esac

    printf "\n\e[1;32mPress any key to return to menu...\e[0m"
    read -r -n 1 < /dev/tty
  fi
}

ARG_CHOICE=$(echo "$1" | sed 's/^-//')
while true; do
  clear
  if [ -n "$ARG_CHOICE" ]; then
    PACK="$ARG_CHOICE"
    ARG_CHOICE=""
  else
    echo -e "
choose from s/q/l/r/h/a/o/u/ SPACE=refresh Ctrl-C=exit
    s) 📥 or 🔍 package/s
    q) 🔍 installed package/s
    l) 🧾 FILES in installed package
    r) 🔥 package/s
    h) 📚 History
    a) 🧾 of FOREIGN/AUR packages
    o) 🔍 find OWNER of a file
    u) 🔁"
    read -r -n 1 PACK
  fi

  case $PACK in
    s) printf "\e[1;33mTip: Remember to run a system upgrade ('u') if your databases are out of date!\e[0m\n"
       pacman -Ssq | PAC_MANAGE "Pacman Package Installer" "INSTALL" "🔜" "36" "pacman -Si {1}" doas pacman -S ;;
    q) PAC_MANAGE "Get Package INFO" "VIEW" "🔍" "32" "pacman -Qi {1}" pacman -Qi ;;
    l) PAC_MANAGE "List Package Files" "LIST" "🧾" "32" "pacman -Ql {1}" pacman -Qlkk ;;
    r) PAC_MANAGE "Pacman Remove Packages" "Remove" "❌" "31" "pacman -Qi {1}" doas pacman -Rns ;;
    o) pacman -Qlq | grep -v '/$' | PAC_MANAGE "Find File Owner" "OWNER" "🔍" "35" "pacman -Qo /{} 2>&1" pacman -Qo /{} ;;
    h) grep -E 'reloaded|installed|removed|upgraded' /var/log/pacman.log | sort -r | sed -e 's/removed/\x1b[31mremoved\x1b[0m/g' -e 's/installed/\x1b[32minstalled\x1b[0m/g' -e 's/upgraded/\x1b[33mupgraded\x1b[0m/g' | less -R ;;
    a) pacman -Qm | less ;;
    u)
       doas pacman --color=always -Sy archlinux-keyring --needed
       doas pacman --color=always -Su
	   ## for waybar
 #      doas checkupdates | wc -l > /tmp/pacup
  #     sleep 1
   #    pkill -SIGRTMIN+8 waybar
       ;;
    *) ;;
  esac
done
