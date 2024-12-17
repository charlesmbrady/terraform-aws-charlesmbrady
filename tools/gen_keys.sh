#!/usr/bin/env sh

# Generate a new key pair for an environment

# Fail on error
set -e

if [ -z "$1" ]; then
  echo "Please provide an environment name as the first argument"
  exit 1
fi

environment="$1"

rsa_decrypt_key_path="./keys/rsa_decrypt_$environment.key"
rsa_encrypt_key_path="./keys/rsa_encrypt_$environment.pub"

mkdir -p ./keys

# Generate a new key pair
if [ -f "$rsa_decrypt_key_path" ]; then
  echo "Key pair already exists for environment $environment.  Refusing to overwrite."
else
  echo "Writing Private Key for decryption"
  openssl genrsa 4096 > "$rsa_decrypt_key_path"
fi

if [ -f "$rsa_encrypt_key_path" ]; then
  echo "Public key already exists for environment $environment.  Refusing to overwrite."
else
  echo "Writing Public Key for encryption"
    # export public key
  openssl rsa -in "$rsa_decrypt_key_path" -outform pem -pubout -out "$rsa_encrypt_key_path"
fi