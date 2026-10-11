#!/bin/bash

# Colors for terminal styling
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_VERSION="v2.1.0 (Stable)"

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Android Helper Script (${SCRIPT_VERSION})  ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check essential core tools
if ! command -v adb &> /dev/null || ! command -v fastboot &> /dev/null; then
    echo -e "${RED}[!] Error: adb or fastboot is missing from your PATH.${NC}"
    exit 1
fi

clean_path() {
    local path="$1"
    path="${path%\'}"
    path="${path#\'}"
    path="${path%\"}"
    path="${path#\"}"
    echo "$path"
}

show_menu() {
    echo -e "\n${YELLOW}Please select an option:${NC}"
    echo "1) ADB Sideload (Flash ZIP / Update / ROM)"
    echo "2) Flash TWRP Recovery (Standard Fastboot)"
    echo "3) Unbrick Device (Standard Fastboot Firmware)"
    echo "4) Samsung Unbrick / Flash (Odin4 Native Engine)"
    echo "5) Exit"
    echo "6) Version"
    echo "7) Detect Devices"
    echo -n "Enter choice [1-7]: "
}

while true; do
    show_menu
    read -r choice
    case $choice in
        1)
            echo -e "\n${BLUE}--- ADB Sideload ---${NC}"
            echo -e "Put your device into ${YELLOW}Recovery Mode -> Apply Update from ADB${NC}."
            echo -e "Drag and drop your ${GREEN}.zip${NC} file here and press Enter:"
            read -r -p "> " zip_file
            zip_file=$(clean_path "$zip_file")

            if [ -f "$zip_file" ]; then
                echo -e "${GREEN}Starting sideload...${NC}"
                adb sideload "$zip_file"
            else
                echo -e "${RED}[!] File not found.${NC}"
            fi
            ;;
        2)
            echo -e "\n${BLUE}--- Flash TWRP Recovery ---${NC}"
            echo -e "Put your device into ${YELLOW}Fastboot Mode${NC} (Bootloader)."
            echo -e "Drag and drop your TWRP ${GREEN}.img${NC} file here and press Enter:"
            read -r -p "> " twrp_file
            twrp_file=$(clean_path "$twrp_file")

            if [ -f "$twrp_file" ]; then
                echo -e "${GREEN}Flashing recovery...${NC}"
                fastboot flash recovery "$twrp_file"
                echo -e "${GREEN}Flashing complete!${NC}"
            else
                echo -e "${RED}[!] File not found.${NC}"
            fi
            ;;
        3)
            echo -e "\n${BLUE}--- Unbrick Device (Fastboot) ---${NC}"
            echo -e "Put your device in ${YELLOW}Fastboot Mode${NC}."
            echo -e "Drag and drop the ${GREEN}folder containing your firmware files${NC} and press Enter:"
            read -r -p "> " fw_dir
            fw_dir=$(clean_path "$fw_dir")

            if [ -d "$fw_dir" ]; then
                echo -n "Are you sure you want to flash partitions from this folder? (y/n): "
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    if [ -f "$fw_dir/flash-all.sh" ]; then
                        cd "$fw_dir" && ./flash-all.sh
                    else
                        [ -f "$fw_dir/boot.img" ] && fastboot flash boot "$fw_dir/boot.img"
                        [ -f "$fw_dir/recovery.img" ] && fastboot flash recovery "$fw_dir/recovery.img"
                        [ -f "$fw_dir/system.img" ] && fastboot flash system "$fw_dir/system.img"
                        [ -f "$fw_dir/vendor.img" ] && fastboot flash vendor "$fw_dir/vendor.img"
                        [ -f "$fw_dir/vbmeta.img" ] && fastboot flash vbmeta "$fw_dir/vbmeta.img"
                        echo -e "${GREEN}Flashing sequence finished.${NC}"
                    fi
                fi
            else
                echo -e "${RED}[!] Directory not found.${NC}"
            fi
            ;;
        4)
            echo -e "\n${BLUE}--- Samsung Stable Firmware Flashing (Odin4) ---${NC}"
            if ! command -v odin4 &> /dev/null; then
                echo -e "${RED}[!] 'odin4' executable not found in PATH.${NC}"
                echo -e "${YELLOW}Please download Odin4 for Linux and place it in /usr/local/bin/${NC}"
                continue
            fi

            echo -e "Put your Samsung device into ${YELLOW}Download Mode${NC} and connect via USB."
            echo -e "Choose mode:"
            echo "1) Single Image / TWRP / Custom Recovery (.tar / .tar.md5)"
            echo "2) Full Stock Unbrick (4-File / 5-File Samsung Directory)"
            echo -n "Select option [1-2]: "
            read -r sam_choice

            # Resolve kernel USB interface lock before running Odin
            sudo modprobe -r cdc_acm 2>/dev/null

            if [ "$sam_choice" == "1" ]; then
                echo -e "Drag and drop your ${GREEN}.tar or .tar.md5 file${NC}:"
                read -r -p "> " sam_tar
                sam_tar=$(clean_path "$sam_tar")

                if [ -f "$sam_tar" ]; then
                    echo -e "${GREEN}Flashing with Odin4...${NC}"
                    sudo odin4 -a "$sam_tar"
                else
                    echo -e "${RED}[!] File not found.${NC}"
                fi

            elif [ "$sam_choice" == "2" ]; then
                echo -e "Drag and drop the ${GREEN}directory containing BL, AP, CP, CSC tar.md5 files${NC}:"
                read -r -p "> " sam_dir
                sam_dir=$(clean_path "$sam_dir")

                if [ -d "$sam_dir" ]; then
                    bl_file=$(ls "$sam_dir"/BL_*.tar* 2>/dev/null | head -n 1)
                    ap_file=$(ls "$sam_dir"/AP_*.tar* 2>/dev/null | head -n 1)
                    cp_file=$(ls "$sam_dir"/CP_*.tar* 2>/dev/null | head -n 1)
                    csc_file=$(ls "$sam_dir"/CSC_*.tar* 2>/dev/null | head -n 1)
                    home_csc_file=$(ls "$sam_dir"/HOME_CSC_*.tar* 2>/dev/null | head -n 1)

                    echo -e "\nSelect Wipe Type:"
                    echo "1) Full Wipe (Factory Reset / Recommended for Unbrick - uses CSC)"
                    echo "2) Keep User Data (Update / Upgrade - uses HOME_CSC)"
                    echo -n "Choice [1-2]: "
                    read -r wipe_choice

                    target_csc="$csc_file"
                    if [ "$wipe_choice" == "2" ] && [ -n "$home_csc_file" ]; then
                        target_csc="$home_csc_file"
                    fi

                    ODIN_CMD="sudo odin4"
                    [ -n "$bl_file" ] && ODIN_CMD="$ODIN_CMD -b $bl_file"
                    [ -n "$ap_file" ] && ODIN_CMD="$ODIN_CMD -a $ap_file"
                    [ -n "$cp_file" ] && ODIN_CMD="$ODIN_CMD -c $cp_file"
                    [ -n "$target_csc" ] && ODIN_CMD="$ODIN_CMD -s $target_csc"

                    echo -e "${GREEN}Executing Odin4 Flash Sequence...${NC}"
                    eval "$ODIN_CMD"
                else
                    echo -e "${RED}[!] Directory not found.${NC}"
                fi
            fi
            ;;
        5)
            echo -e "${GREEN}Exiting. Goodbye!${NC}"
            exit 0
            ;;
        6)
            echo -e "\n${BLUE}--- Version & Environment Info ---${NC}"
            echo -e "Android Helper Version: ${GREEN}${SCRIPT_VERSION}${NC}"
            echo -n "ADB Version: "
            adb version | head -n 1
            echo -n "Fastboot Installed: "
            command -v fastboot &> /dev/null && echo -e "${GREEN}Yes${NC}" || echo -e "${RED}No${NC}"
            echo -n "Odin4 (Samsung Engine): "
            command -v odin4 &> /dev/null && echo -e "${GREEN}Installed${NC}" || echo -e "${YELLOW}Not Found${NC}"
            ;;
        7)
            echo -e "\n${BLUE}--- Connected Android Devices ---${NC}"
            echo -e "${YELLOW}[1] ADB Devices (Normal / Recovery / Sideload):${NC}"
            adb devices
            
            echo -e "\n${YELLOW}[2] Fastboot Devices (Bootloader Mode):${NC}"
            fastboot devices
            
            echo -e "\n${YELLOW}[3] Samsung Devices (Download Mode via Odin4):${NC}"
            if command -v odin4 &> /dev/null; then
                sudo odin4 -l
            else
                echo -e "${YELLOW}Odin4 not found, scanning general USB list (lsusb):${NC}"
                lsusb | grep -i "samsung" || echo -e "${RED}No Samsung USB devices detected.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}[!] Invalid option. Choose between 1-7.${NC}"
            ;;
    esac
done