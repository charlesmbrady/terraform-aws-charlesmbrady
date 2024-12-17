#!/usr/bin/env sh

input=$1

echo "Encrypting:  ${input}"

printf "%s" "$input" | base64 -d | openssl pkeyutl -decrypt -inkey ./keys/rsa_decrypt*.key