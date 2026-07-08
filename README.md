<img width="2006" height="1260" alt="image1" src="https://github.com/user-attachments/assets/3a4ff78e-531d-4900-8c61-6629bcd89cce" />
<img width="2560" height="1464" alt="image2" src="https://github.com/user-attachments/assets/5aabb79b-20e7-4043-aeca-72b174bfd941" />


pac.sh is a TUI wrapper for arch linux package manager pacman, using FZF.

Depends ON:
- pacman
- fzf
- pacman-contrib (for some features)
- doas or sudo (selected by editing pac.sh)

# waybar module (entirely optional)
paccheck is a small script which runs checkupdates and stores number of updated packages

paccheck.service and paccheck.timer are --user systemd services to run paccheck periodically

waybar module is partial waybar config, to display number of updated packages available.
