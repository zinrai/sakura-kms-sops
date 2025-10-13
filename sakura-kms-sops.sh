#!/bin/bash

set -e

usage() {
    cat >&2 <<EOF
Usage: sakura-kms-sops.sh [sops arguments...]

A bridge tool between sakura-kms and sops for age key management.

Environment Variables (required):
  SAKURACLOUD_KMS_KEY_FILE          Encrypted age key file path

Examples:
  sakura-kms-sops.sh edit secrets.yaml
  sakura-kms-sops.sh -d secrets.yaml
  sakura-kms-sops.sh -e plain.yaml > encrypted.yaml
EOF
    exit 1
}

# Show usage if no arguments or help flag
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

# Validation
if [[ -z "$SAKURACLOUD_KMS_KEY_FILE" ]]; then
    echo "Error: SAKURACLOUD_KMS_KEY_FILE environment variable is not set" >&2
    usage
fi

if [[ ! -f "$SAKURACLOUD_KMS_KEY_FILE" ]]; then
    echo "Error: Age key file not found: $SAKURACLOUD_KMS_KEY_FILE" >&2
    exit 1
fi

# Export SOPS_AGE_KEY_CMD
export SOPS_AGE_KEY_CMD="sh -c 'sakura-kms decrypt -output /dev/stdout < $SAKURACLOUD_KMS_KEY_FILE 2>/dev/null'"

# Execute sops with all arguments
exec sops "$@"
