#!/bin/bash

# Colors for better readability
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# Function to display colored messages
print_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${ENDCOLOR}"
}

# Function to detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PACKAGER_INSTALL="sudo apt-get install -y"
    elif command -v dnf &> /dev/null; then
        PACKAGER_INSTALL="sudo dnf install -y"
    elif command -v pacman &> /dev/null; then
        PACKAGER_INSTALL="sudo pacman -S --noconfirm"
    else
        whiptail --title "Error" --msgbox "Error: Unsupported package manager. Please install packages manually." 8 78
        exit 1
    fi
}

# Function to check and install Git
check_and_install_git() {
    if ! command -v git &> /dev/null; then
        print_message "Git is not installed. Installing Git..." "$YELLOW"
        $PACKAGER_INSTALL git
        if command -v git &> /dev/null; then
            print_message "Git has been successfully installed." "$GREEN"
        else
            whiptail --title "Error" --msgbox "Failed to install Git. Please install it manually and run this script again." 8 78
            exit 1
        fi
    else
        print_message "Git is already installed." "$GREEN"
    fi
}

# Function to setup linuxtoolbox
setup_linuxtoolbox() {
    check_and_install_git

    LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

    if [ ! -d "$LINUXTOOLBOXDIR" ]; then
        print_message "Creating linuxtoolbox directory: $LINUXTOOLBOXDIR" "$YELLOW"
        mkdir -p "$LINUXTOOLBOXDIR"
        print_message "linuxtoolbox directory created: $LINUXTOOLBOXDIR" "$GREEN"
    fi

    if [ ! -d "$LINUXTOOLBOXDIR/linux-toolbox" ]; then
        print_message "Cloning linux-toolbox repository into: $LINUXTOOLBOXDIR/linux-toolbox" "$YELLOW"
        if git clone https://github.com/odiak0/linux-toolbox "$LINUXTOOLBOXDIR/linux-toolbox"; then
            print_message "Successfully cloned linux-toolbox repository" "$GREEN"
        else
            whiptail --title "Error" --msgbox "Failed to clone linux-toolbox repository" 8 78
            exit 1
        fi
    fi

    cd "$LINUXTOOLBOXDIR/linux-toolbox/grub-themes" || exit
}

# Directory where GRUB themes are stored
if [ -d "/boot/grub2" ]; then
    THEME_DIR="/boot/grub2/themes"
else
    THEME_DIR="/boot/grub/themes"
fi

# Function to let user select a theme
select_theme() {
    THEME_NAME=$(whiptail --title "Select Theme" --menu "Choose theme:" 15 45 5 \
        "Cyberpunk" "" \
        "BIOS" "" \
        "CyberRe" "" \
        "Minecraft-Theme" "" 3>&1 1>&2 2>&3)
    if [ -z "$THEME_NAME" ]; then
        print_message "User cancelled theme selection. Exiting..." "$YELLOW"
        exit 0
    fi

    print_message "Installing $THEME_NAME" "$GREEN"
}

# Function to backup current GRUB configuration
backup() {
    sudo cp -a /etc/default/grub "$LINUXTOOLBOXDIR/linux-toolbox/grub-themes"
    whiptail --title "Backup" --msgbox "GRUB configuration has been backed up to:\n$LINUXTOOLBOXDIR/linux-toolbox/grub-themes/grub" 10 78
}

# Function to install the selected theme
install_theme() {
    if [[ ! -d "${THEME_DIR}/${THEME_NAME}" ]]; then
        print_message "Installing ${THEME_NAME}" "$GREEN"
        if sudo mkdir -p "${THEME_DIR}/${THEME_NAME}"; then
            if sudo cp -r "$LINUXTOOLBOXDIR/linux-toolbox/grub-themes/themes/${THEME_NAME}"/* "${THEME_DIR}/${THEME_NAME}/"; then
                # Set correct ownership
                sudo chown -R root:root "${THEME_DIR}/${THEME_NAME}"
                print_message "Theme ${THEME_NAME} installed successfully" "$GREEN"
            else
                whiptail --title "Error" --msgbox "Failed to copy theme files. Please check permissions and try again." 8 78
                exit 1
            fi
        else
            whiptail --title "Error" --msgbox "Failed to create theme directory. Please check permissions and try again." 8 78
            exit 1
        fi
    else
        print_message "Theme ${THEME_NAME} is already installed" "$YELLOW"
    fi
}

# Function to configure GRUB settings
config_grub() {
    print_message "Enabling GRUB menu" "$GREEN"
    sudo sed -i '/GRUB_TIMEOUT_STYLE=/d' /etc/default/grub
    echo 'GRUB_TIMEOUT_STYLE=menu' | sudo tee -a /etc/default/grub > /dev/null

    #--------------------------------------------------

    print_message "Setting GRUB timeout to 30 seconds" "$GREEN"
    sudo sed -i '/GRUB_TIMEOUT=/d' /etc/default/grub
    echo 'GRUB_TIMEOUT=30' | sudo tee -a /etc/default/grub > /dev/null

    #--------------------------------------------------

    print_message "Setting ${THEME_NAME} as default theme" "$GREEN"
    sudo sed -i '/GRUB_THEME=/d' /etc/default/grub
    echo GRUB_THEME=${THEME_DIR}/"${THEME_NAME}"/theme.txt | sudo tee -a /etc/default/grub > /dev/null
    
    #--------------------------------------------------

    print_message "Setting GRUB graphics mode" "$GREEN"
    RESOLUTION=$(whiptail --title "GRUB Graphics Mode" --menu "Choose a resolution:" 15 60 4 \
        "auto" "Automatically detect best resolution" \
        "1920x1080" "Full HD" \
        "1280x720" "HD" \
        "1024x768" "XGA" 3>&1 1>&2 2>&3)
    
    if [ -z "$RESOLUTION" ]; then
        print_message "User cancelled resolution selection. Using 'auto'." "$YELLOW"
        RESOLUTION="auto"
    fi
    
    sudo sed -i '/GRUB_GFXMODE=/d' /etc/default/grub
    echo "GRUB_GFXMODE=$RESOLUTION" | sudo tee -a /etc/default/grub > /dev/null
    print_message "GRUB graphics mode set to $RESOLUTION" "$GREEN"
}

# Function to update GRUB configuration
update_grub() {
    print_message "Updating GRUB config..." "$GREEN"

    if [[ -x "$(command -v grub-mkconfig)" ]]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    elif [[ -x "$(command -v grub2-mkconfig)" ]]; then
        if command -v dnf &> /dev/null; then
            sudo sed -i '/GRUB_TERMINAL_OUTPUT="console"/d' /etc/default/grub
            sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
        else
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
    else
        whiptail --title "Error" --msgbox "Unable to update GRUB config. Please update it manually." 8 78
    fi
}

# Main function
main() {
    detect_package_manager
    setup_linuxtoolbox
    select_theme
    backup
    install_theme
    config_grub
    update_grub

    whiptail --title "Success" --msgbox "GRUB Theme Update Successful!" 8 78
}

# Execute the main function
main