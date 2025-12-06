# Variables
IMMICH_DRIVE=""
NO_DECRYPTION=false
START=false
STOP_SERVER=false

# Colours for output
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
NC=$(tput sgr0) # No Colour

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --immich-drive DRIVE   The immich drive that needs decrypting (e.g., /dev/sda)
                           Decryption is only required once after boot.
                           If unset, skip the decryption step.
    --no-decryption        Suppress the warning when --immich-drive is not set
    --start                Start the immich server after drive decryption
    --stop                 Stop the immich server (cannot be combined with other flags)
    --help                 Show this help message

Examples:
    $0 --immich-drive /dev/sda --start
    $0 --immich-drive /dev/sda
    $0 --start --no-decryption
    $0 --stop

EOF
    exit 0
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --immich-drive)
            if [ -z "$2" ] || [ "${2#--}" != "$2" ]; then
                printf "%sError: --immich-drive requires a drive path argument%s\n" "$RED" "$NC" >&2
                exit 1
            fi
            IMMICH_DRIVE="$2"
            shift 2
            ;;
        --no-decryption)
            NO_DECRYPTION=true
            shift
            ;;
        --start)
            START=true
            shift
            ;;
        --stop)
            STOP_SERVER=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            printf "%sError: Unknown option: %s%s\n" "$RED" "$1" "$NC" >&2
            printf "Use --help for usage information\n" >&2
            exit 1
            ;;
    esac
done

# Handle --stop flag
if [ "$STOP_SERVER" = true ]; then
    # Check if other flags are set
    if [ -n "$IMMICH_DRIVE" ] || [ "$NO_DECRYPTION" = true ] || [ "$START" = true ]; then
        printf "%sError: --stop cannot be combined with other flags%s\n" "$RED" "$NC" >&2
        exit 1
    fi
    
    printf "Stopping immich server...\n"
    sudo systemctl stop immich-machine-learning
    sudo systemctl stop immich-server
    sudo systemctl stop postgresql
    exit 0
fi

# Decryption step
if [ -n "$IMMICH_DRIVE" ]; then
    printf "Decrypting immich drive at %s\n" "$IMMICH_DRIVE"
    sudo cryptsetup open "$IMMICH_DRIVE" immich_drive
    printf "Mounting immich drive to /mnt/immich_drive\n"
    sudo mount /dev/mapper/immich_drive /mnt/immich_drive
else
    # Print warning if --no-decryption is not set
    if [ "$NO_DECRYPTION" = false ]; then
        printf "%sWarning: Skipping decryption of immich drive. If this is not intended, set the --immich-drive flag. See --help for more info.%s\n" "$YELLOW" "$NC"
    fi
fi

# Start immich server
if [ "$START" = true ]; then
    printf "Starting immich server...\n"
    sudo systemctl start postgresql
    sudo systemctl start immich-server
    sudo systemctl start immich-machine-learning
fi
