#!/bin/bash

# HakPak Desktop Launcher
# Handles privilege escalation for desktop environment integration

# Colors for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to detect available GUI sudo program
detect_gui_sudo() {
    # Check for available GUI sudo programs in order of preference
    local gui_sudo_programs=("pkexec" "gksudo" "kdesudo" "gksu")
    
    for program in "${gui_sudo_programs[@]}"; do
        if command -v "$program" &> /dev/null; then
            echo "$program"
            return 0
        fi
    done
    
    # If no GUI sudo found, check if we're in a terminal
    if [ -t 0 ]; then
        echo "sudo"
        return 0
    fi
    
    return 1
}

# Function to show error dialog if available
show_error() {
    local message="$1"
    
    if command -v zenity &> /dev/null; then
        zenity --error --text="$message" --title="HakPak Error" 2>/dev/null
    elif command -v kdialog &> /dev/null; then
        kdialog --error "$message" --title "HakPak Error" 2>/dev/null
    elif command -v notify-send &> /dev/null; then
        notify-send "HakPak Error" "$message" --icon=error 2>/dev/null
    else
        echo -e "${RED}[✗]${NC} $message" >&2
    fi
}

# Function to show success notification if available
show_success() {
    local message="$1"
    
    if command -v notify-send &> /dev/null; then
        notify-send "HakPak" "$message" --icon=hakpak 2>/dev/null
    fi
}

# Main launcher function
main() {
    local hakpak_path="/usr/local/bin/hakpak"
    local hakpak_local="./hakpak.sh"
    
    # Determine HakPak location
    if [[ -x "$hakpak_path" ]]; then
        HAKPAK_EXEC="$hakpak_path"
    elif [[ -x "$hakpak_local" ]]; then
        HAKPAK_EXEC="$hakpak_local"
    else
        show_error "HakPak executable not found. Please ensure HakPak is properly installed."
        exit 1
    fi
    
    # Detect GUI sudo program
    local gui_sudo
    gui_sudo=$(detect_gui_sudo)
    
    if [[ $? -ne 0 ]]; then
        show_error "No suitable privilege escalation program found.\nPlease install pkexec, gksudo, or run HakPak from terminal with sudo."
        exit 1
    fi
    
    # Handle command line arguments
    local args="$*"
    [[ -z "$args" ]] && args="--interactive"
    
    # Launch HakPak with appropriate privilege escalation
    case "$gui_sudo" in
        "pkexec")
            # PolicyKit - most modern approach
            # For interactive mode, open in terminal for better user experience
            if [[ "$args" == "--interactive" ]] || [[ -z "$args" ]]; then
                # Open in terminal for interactive mode
                if command -v gnome-terminal &> /dev/null; then
                    gnome-terminal -- bash -c "echo 'Launching HakPak...'; sudo '$HAKPAK_EXEC' $args; echo; echo 'Press Enter to close...'; read"
                elif command -v konsole &> /dev/null; then
                    konsole -e bash -c "echo 'Launching HakPak...'; sudo '$HAKPAK_EXEC' $args; echo; echo 'Press Enter to close...'; read"
                elif command -v xfce4-terminal &> /dev/null; then
                    xfce4-terminal -e "bash -c \"echo 'Launching HakPak...'; sudo '$HAKPAK_EXEC' $args; echo; echo 'Press Enter to close...'; read\""
                elif command -v x-terminal-emulator &> /dev/null; then
                    x-terminal-emulator -e bash -c "echo 'Launching HakPak...'; sudo '$HAKPAK_EXEC' $args; echo; echo 'Press Enter to close...'; read"
                else
                    # Fallback to pkexec
                    if ! pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" "$HAKPAK_EXEC" $args; then
                        show_error "Failed to launch HakPak. Authentication may have been cancelled."
                        exit 1
                    fi
                fi
            else
                # For non-interactive commands, use pkexec directly
                if ! pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" "$HAKPAK_EXEC" $args; then
                    show_error "Failed to launch HakPak. Authentication may have been cancelled."
                    exit 1
                fi
            fi
            ;;
        "gksudo"|"kdesudo"|"gksu")
            # Legacy GUI sudo programs
            if ! "$gui_sudo" "$HAKPAK_EXEC $args"; then
                show_error "Failed to launch HakPak. Authentication may have been cancelled."
                exit 1
            fi
            ;;
        "sudo")
            # Terminal sudo - ensure we're in a terminal
            if [ -t 0 ]; then
                echo -e "${BLUE}[i]${NC} Launching HakPak..."
                echo -e "${YELLOW}[!]${NC} Administrator privileges required"
                exec sudo "$HAKPAK_EXEC" $args
            else
                show_error "Terminal required for sudo authentication. Please run from terminal or install pkexec."
                exit 1
            fi
            ;;
    esac
    
    show_success "HakPak launched successfully"
}

# Run main function with all arguments
main "$@"
