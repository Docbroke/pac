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

CLEAN() {
  clear
  echo -e "
choose from c/o SPACE=back \e[1;31mCtrl-C=exit\e[0m

    c) 🧹 cache
    o) 🔥 orphans
    "
  read -r -n 1 ops
  echo

  case $ops in
    o)
      if [ -n "$(pacman -Qdt)" ]; then
        printf "\n\e[1;31mThe following orphan packages will be removed:\e[0m\n"
        pacman -Qdt
        printf "\nProceed with removing orphans? [y/N] "
        read -r confirm
        case "$confirm" in
          [yY][eE][sS]|[yY]) doas pacman -Rns $(pacman -Qdtq) ;;
          *) echo "Aborted." ;;
        esac
      else
        echo "No orphans to remove."
      fi
      printf "\n\e[1;32mPress any key to return...\e[0m"
      read -r -n 1 < /dev/tty
      ;;
    c)
      printf "\n\e[1;33mAre you sure you want to clean your package cache?\e[0m [y/N] "
      read -r confirm
      case "$confirm" in
        [yY][eE][sS]|[yY])
          echo -e "\nRemoving all uninstalled packages from cache..."
          doas paccache -ruk0
          echo "Removing older cached versions of all packages except latest 2..."
          doas paccache -rk2
          ;;
        *)
          echo "Aborted."
          ;;
      esac
      printf "\n\e[1;32mPress any key to return...\e[0m"
      read -r -n 1 < /dev/tty
      ;;
    *) ;;
  esac
}

ARG_CHOICE=$(echo "$1" | sed 's/^-//')
while true; do
  clear

  if [ -f /var/log/pacman.log ]; then
    LAST_UPGRADE_TIME=$(grep "synchronizing package lists" /var/log/pacman.log | tail -n 1 | cut -d'[' -f2 | cut -d']' -f1)

    if [ -n "$LAST_UPGRADE_TIME" ]; then
      last_mod=$(date -d "$LAST_UPGRADE_TIME" +%s 2>/dev/null)
      now=$(date +%s)
      diff=$((now - last_mod))

      days=$((diff / 86400))
      diff=$((diff % 86400))
      hrs=$((diff / 3600))
      diff=$((diff % 3600))
      min=$((diff / 60))
      sec=$((diff % 60))

      AGE_STR=$(printf "%dd %02dh %02dm %02ds ago" $days $hrs $min $sec)
    else
      last_mod=$(date -r /var/log/pacman.log +%s)
      now=$(date +%s)
      diff=$((now - last_mod))
      days=$((diff / 86400))
      hrs=$(( (diff % 86400) / 3600 ))
      min=$(( (diff % 3600) / 60 ))
      AGE_STR=$(printf "~ %dd %02dh %02dm ago (last log touch)" $days $hrs $min)
    fi
  else
    AGE_STR="Log not found"
  fi

  if [ -n "$ARG_CHOICE" ]; then
    PACK="$ARG_CHOICE"
    ARG_CHOICE=""
  else
    echo -e "
Last Database Sync(-Sy): $AGE_STR
\e[1;33mchoose from s/q/l/L/r/h/a/A/o/u/y/f/c\e[0m SPACE=refresh \e[1;31mCtrl-C=exit\e[0m

    \e[1;32ms) 📥 or 🔍 package/s\e[0m
    q) 🔍 installed package/s INFO
    l) 🧾 FILES in installed package
    L) 🧾 FILES in all packages (Uses -F database)
    \e[1;31mr) 🔥 package/s\e[0m
    h) 📚 History
    a) 🧾 of FOREIGN/AUR packages
    A) 🔍 or 🔥 FOREIGN/AUR packages
    o) 🔍 find OWNER of a file
    \e[1;32mu) 🔁 Update & Upgrade\e[0m
    y) 🔁 Update Only
    f) 🔁 Update Database (-F)
    c) 🧹cleanup🧹
    "
    read -r -n 1 PACK
  fi

  case $PACK in
    s)
	   printf '\n'
	   printf "\e[1;33mTip: Run a system upgrade ('u: 🔁') to avoid partial upgrade!\e[0m\n";
	   read -r -n 1 < /dev/tty;
       pacman -Ssq |\
       PAC_MANAGE "Pacman Package Installer" "INSTALL" "🔜" "36" "pacman -Si {1}" doas pacman -S
       ;;
    q) PAC_MANAGE "Get Package INFO" "VIEW" "🔍" "32" "pacman -Qi {1}" pacman -Qi ;;
    l) PAC_MANAGE "List Package Files" "LIST" "🧾" "32" "pacman -Ql {1}" pacman -Qlkk ;;
    r) PAC_MANAGE "Pacman Remove Packages" "Remove" "❌" "31" "pacman -Qi {1}" doas pacman -Rns ;;
    o)
       pacman -Qlq |\
       grep -v '/$' |\
       PAC_MANAGE "Find File Owner" "OWNER" "🔍" "35" "pacman -Qo /{} 2>&1" pacman -Qo /{}
       ;;
    L)
	   printf '\n'
       printf "\e[1;33mTip: Run a database update('f: 🔁') if out-of-date!\e[0m\n";
       read -r -n 1 < /dev/tty;
       pacman -Ssq |\
       PAC_MANAGE "Pacman Package Installer" "INSTALL" "🔜" "36" "pacman -Fl {1}" doas pacman -Fl
       ;;
    h)
       grep -E 'reloaded|installed|removed|upgraded' /var/log/pacman.log |\
       sort -r |\
       sed -e 's/removed/\x1b[31mremoved\x1b[0m/g;
       	s/installed/\x1b[32minstalled\x1b[0m/g;
       	s/upgraded/\x1b[33mupgraded\x1b[0m/g' |\
       less -R
       ;;
    a) pacman -Qm | less ;;
    A)
       pacman -Qmq |\
       PAC_MANAGE "Installed AUR Packages" "Remove" "🔜" "36" "pacman -Qi {1}" doas pacman -Rns
       ;;
    u)
       doas pacman --color=always -Sy archlinux-keyring --needed
       doas pacman --color=always -Su
       ## Below is for updating waybar module
       # doas checkupdates | wc -l > /tmp/pacup
       # sleep 1
       # pkill -SIGRTMIN+8 waybar
       ;;
    y)
       doas pacman --color=always -Sy
       ## Below is for updating waybar module
       # doas checkupdates | wc -l > /tmp/pacup
       # sleep 1
       # pkill -SIGRTMIN+8 waybar
       ;;
    f) doas pacman -Fy ;;
    c) CLEAN ;;
    *) ;;
  esac
done
