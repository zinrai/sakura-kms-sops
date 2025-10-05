#!/bin/bash

set -e

usage() {
    cat >&2 <<EOF
Usage: sakura-kms-sops --resource-id ID --age-key FILE -- sops [args...]

A bridge tool between sakura-kms and sops for age key management.

Options:
  --resource-id  KMS key resource ID (required)
  --age-key      Encrypted age key file path (required)

Examples:
  sakura-kms-sops --resource-id 110000000000 --age-key key.kms.enc -- sops edit secrets.yaml
  sakura-kms-sops --resource-id 110000000000 --age-key key.kms.enc -- sops -d secrets.yaml
EOF
    exit 1
}

# Parse arguments
RESOURCE_ID=""
AGE_KEY_FILE=""
SOPS_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --resource-id)
            RESOURCE_ID="$2"
            shift 2
            ;;
        --age-key)
            AGE_KEY_FILE="$2"
            shift 2
            ;;
        --)
            shift
            SOPS_ARGS=("$@")
            break
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage
            ;;
    esac
done

# Validation
if [[ -z "$RESOURCE_ID" ]]; then
    echo "Error: --resource-id is required" >&2
    usage
fi

if [[ -z "$AGE_KEY_FILE" ]]; then
    echo "Error: --age-key is required" >&2
    usage
fi

if [[ ${#SOPS_ARGS[@]} -eq 0 ]]; then
    echo "Error: no sops command specified after --" >&2
    usage
fi

# Export SOPS_AGE_KEY_CMD
export SOPS_AGE_KEY_CMD="sh -c 'sakura-kms decrypt -output /dev/stdout -resource-id $RESOURCE_ID < $AGE_KEY_FILE 2>/dev/null'"

# Execute sops
exec "${SOPS_ARGS[@]}"
