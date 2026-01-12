set -e

CLIENT_NAME=""
CA_PATH="/var/lib/certs"
CA_CRT="ca-cert.pem"
CA_KEY="ca-key.pem"

# Colours for output
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
NC=$(tput sgr0) # No Colour

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --client-name NAME     The name of the client. This is used to name the client cert files.
    --ca-path              Set the path to the CA cert. DEFAULT: current working directory.
    --ca-crt               Set the CA certificate filename. DEFAULT: "ca-cert.pem".
    --ca-key               Set the CA key filename. DEFAULT: "ca-key.pem".
    --help                 Show this help message

Examples:
    $0 --client-name my-pc
    $0 --client-name my-phone --ca-path /var/lib/immich

EOF
    exit 0
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --client-name)
            if [ -z "$2" ] || [ "${2#--}" != "$2" ]; then
                printf "%sError: --client-name requires an argument%s\n" "$RED" "$NC" >&2
                exit 1
            fi
            CLIENT_NAME="$2"
            shift 2
            ;;
        --ca-path)
            if [ -z "$2" ] || [ "${2#--}" != "$2" ]; then
                printf "%sError: --ca-path requires the path to the CA certs%s\n" "$RED" "$NC" >&2
                exit 1
            fi
            CA_PATH="$2"
            shift 2
            ;;
        --ca-crt)
            if [ -z "$2" ] || [ "${2#--}" != "$2" ]; then
                printf "%sError: --ca-crt requires the CA cert filename%s\n" "$RED" "$NC" >&2
                exit 1
            fi
            CA_CRT="$2"
            shift 2
            ;;
        --ca-key)
            if [ -z "$2" ] || [ "${2#--}" != "$2" ]; then
                printf "%sError: --ca-crt requires the CA key filename%s\n" "$RED" "$NC" >&2
                exit 1
            fi
            CA_KEY="$2"
            shift 2
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

if [ "$CLIENT_NAME" = "" ]; then
    printf "%sError: --client-name flag is required%s\n" "$RED" "$NC" >&2
    exit 1
fi

# Very shitty way of setting this!
cat > client_ext.cnf << 'EOF'
extendedKeyUsage = clientAuth
EOF


CA_CRT="$CA_PATH/$CA_CRT"
CA_KEY="$CA_PATH/$CA_KEY"

echo "Generating client certificates with"
echo "CA crt: $CA_CRT"
echo "CA key: $CA_KEY"

# Generate client key and cert
openssl genrsa -out "$CLIENT_NAME.key" 4096
openssl req -new -key "$CLIENT_NAME.key" -out "$CLIENT_NAME.csr" \
  -subj "/CN=$CLIENT_NAME/O=MyOrg"
openssl x509 -req -in "$CLIENT_NAME.csr" \
  -CA $CA_CRT -CAkey $CA_KEY \
  -CAcreateserial -out "$CLIENT_NAME.crt" \
  -days 365 -sha256 \
  -extfile client_ext.cnf

# Create PKCS12 for phone
openssl pkcs12 -export \
  -out "$CLIENT_NAME.p12" \
  -inkey "$CLIENT_NAME.key" \
  -in "$CLIENT_NAME.crt" \
  -certfile $CA_CRT \
  -name "$CLIENT_NAME"

chmod 600 $CLIENT_NAME.crt $CLIENT_NAME.csr $CLIENT_NAME.key $CLIENT_NAME.p12
chown ${SUDO_USER}:users $CLIENT_NAME.crt $CLIENT_NAME.csr $CLIENT_NAME.key $CLIENT_NAME.p12

echo "Generated:"
echo "  - $CLIENT_NAME.crt (certificate)"
echo "  - $CLIENT_NAME.key (private key)"
echo "  - $CLIENT_NAME.p12 (for phone)"


