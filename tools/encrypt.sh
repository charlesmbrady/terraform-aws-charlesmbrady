#!/usr/bin/env sh

input=$1

echo "Encrypting:  ${input}"

printf "%s" "$input" | openssl pkeyutl -encrypt -pubin -inkey ./keys/rsa_encrypt*.pub | base64