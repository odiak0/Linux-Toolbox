#!/bin/bash

GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

print_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${ENDCOLOR}"
}

setup_linuxtoolbox() {
    LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

    if [ ! -d "$LINUXTOOLBOXDIR" ]; then
        print_message "Creating linuxtoolbox directory: $LINUXTOOLBOXDIR" "$YELLOW"
        mkdir -p "$LINUXTOOLBOXDIR"
        print_message "linuxtoolbox directory created: $LINUXTOOLBOXDIR" "$GREEN"
    fi

    cd "$LINUXTOOLBOXDIR" || exit
}

toolbox_menu() {
    while true; do
        menu_options=(
            "1" "System Update"
            "2" "Bspwm desktop setup"
            "3" "Hyprland desktop setup (Arch Linux only)"
            "4" "Grub themes setup"
            "5" "Bash setup"
            "6" "Reboot"
            "7" "Purge linuxtoolbox directory"
            "8" "Exit"
        )
        choice=$(whiptail --title "Linux Toolbox" --menu "Choose an option:" 16 60 8 "${menu_options[@]}" 3>&1 1>&2 2>&3)

        case $choice in
            1)
                if command -v apt-get &> /dev/null; then
                    PACKAGER="apt-get"
                elif command -v dnf &> /dev/null; then
                    PACKAGER="dnf"
                elif command -v yum &> /dev/null; then
                    PACKAGER="yum"
                elif command -v pacman &> /dev/null; then
                    PACKAGER="pacman"
                elif command -v zypper &> /dev/null; then
                    PACKAGER="zypper"
                else
                    PACKAGER="unknown"
                fi

                case $PACKAGER in
                    apt-get)
                        sudo apt-get update && sudo apt-get upgrade -y
                        ;;
                    dnf)
                        sudo dnf upgrade -y
                        ;;
                    yum)
                        sudo yum update -y
                        ;;
                    pacman)
                        sudo pacman -Syu --noconfirm
                        ;;
                    zypper)
                        sudo zypper update -y
                        ;;
                    *)
                        whiptail --title "Error" --msgbox "Unable to detect a supported package manager. System update failed." 8 60
                        ;;
                esac

                if [ "$PACKAGER" != "unknown" ]; then
                    whiptail --title "Linux Toolbox" --msgbox "System update completed." 8 60
                fi
                ;;
            2)
                bash <(curl -fsSL https://github.com/odiak0/bspwm-config/raw/main/install.sh)
                ;;
            3)
                bash <(curl -fsSL https://github.com/odiak0/hyprland-config/raw/main/install.sh)
                ;;
            4)
                bash <(curl -fsSL https://github.com/odiak0/linux-toolbox/raw/main/grub-themes/install.sh)
                ;;
            5)
                bash <(curl -fsSL https://github.com/odiak0/mybash/raw/main/install.sh)
                ;;
            6)
                sudo reboot
                ;;
            7)
                rm -rf "$LINUXTOOLBOXDIR"
                print_message "linuxtoolbox directory has been purged." "$GREEN"
                exit 0
                ;;
            8)
                exit 0
                ;;
            *)
                whiptail --title "Linux Toolbox" --msgbox "Invalid selection. Please try again." 8 60
                ;;
        esac
    done
}

check_and_install_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        print_message "whiptail is not installed. Attempting to install..." "$YELLOW"
        
        if command -v apt-get &> /dev/null; then
            PACKAGER="apt-get"
        elif command -v dnf &> /dev/null; then
            PACKAGER="dnf"
        elif command -v yum &> /dev/null; then
            PACKAGER="yum"
        elif command -v pacman &> /dev/null; then
            PACKAGER="pacman"
        elif command -v zypper &> /dev/null; then
            PACKAGER="zypper"
        else
            whiptail --title "Error" --msgbox "Unable to detect a supported package manager. Please install whiptail manually." 8 60
            exit 1
        fi

        case $PACKAGER in
            apt-get)
                sudo apt-get update && sudo apt-get install -y whiptail
                ;;
            dnf)
                sudo $PACKAGER install -y newt
                ;;
            yum)
                sudo $PACKAGER install -y newt
                ;;
            pacman)
                sudo pacman -S --noconfirm libnewt
                ;;
            zypper)
                sudo zypper install -y newt
                ;;
        esac
        
        if command -v whiptail &> /dev/null; then
            print_message "whiptail has been successfully installed." "$GREEN"
        else
            whiptail --title "Error" --msgbox "whiptail installation failed. Please install it manually." 8 60
            exit 1
        fi
    fi
}

setup_linuxtoolbox
check_and_install_whiptail
toolbox_menu