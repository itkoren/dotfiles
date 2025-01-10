#!/bin/bash

# Platform specific customizations
if [ -f "${DOTDIR:-$HOME}"/age/.public ]; then
  source "${DOTDIR:-$HOME}"/age/.public
fi
 
# Function to compress and encrypt a file using age
function age_compress_encrypt {
    if [ $# -ne 2 ]; then
        echo "Usage: age_compress_encrypt <app_file_path> <output_file> ?<public_key>"
        return 1
    fi

    local app_file_path="$1"
    local output_file="$2"
    local public_key="${3:-$AGE_LOCAL_PUBLIC_KEY}"

    if [ -z "$public_key" ]; then
      echo "Error: '$public_key' is not a valid public key."
      return 1
    fi
    
    # Check if the provided .app file exists
    if [ ! -d "$app_file_path" ]; then
      echo "Error: '$app_file_path' is not a valid .app directory."
      return 1
    fi

    # Define temporary compressed file
    local compressed_file="${output_file}.tar.gz"

    # Compress the .app file
    echo "Compressing the .app file..."
    tar -czf "$compressed_file" -C "$(dirname "$app_file_path")" "$(basename "$app_file_path")"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to compress the .app file."
        return 1
    fi

    # Encrypt the compressed file with age
    echo "Encrypting the compressed file with age..."
    age -r "$public_key" -o "$output_file" "$compressed_file"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to encrypt the compressed file."
        return 1
    fi

    # Clean up the temporary compressed file
    rm "$compressed_file"

    echo "Successfully compressed and encrypted the .app file. Encrypted file: $output_file"
}

# Example usage: compress_and_encrypt_with_age "/path/to/your/app/file.app" "output_filename.age" "your-public-key"

#!/bin/bash

# Function to decrypt and extract a compressed file using age
function age_decrypt_extract {
    if [ $# -ne 2 ]; then
        echo "Usage: decrypt_and_extract_with_age <encrypted_file> <output_dir> ?<private_key>"
        return 1
    fi

    local encrypted_file="$1"
    local output_dir="$2"
    local private_key="${3:-$AGE_LOCAL_KEYS_FILE}"

    # Check if the encrypted file exists
    if [ ! -f "$encrypted_file" ]; then
        echo "Error: '$encrypted_file' is not a valid encrypted file."
        return 1
    fi

    # Check if the private key exists
    if [ ! -f "$private_key" ]; then
        echo "Error: '$private_key' is not a valid private key."
        return 1
    fi

    # Define the temporary decrypted compressed file
    local decrypted_file="${output_dir}/decrypted_file.tar.gz"

    # Decrypt the file using age
    echo "Decrypting the file with age..."
    age -d -i "$private_key" -o "$decrypted_file" "$encrypted_file"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to decrypt the file."
        return 1
    fi

    # Extract the decrypted .tar.gz file
    echo "Extracting the decrypted .tar.gz file..."
    mkdir -p "$output_dir"
    tar -xzf "$decrypted_file" -C "$output_dir"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to extract the .tar.gz file."
        return 1
    fi

    # Clean up the temporary decrypted file
    rm "$decrypted_file"

    echo "Successfully decrypted and extracted the .app file. Output directory: $output_dir"
}

# Example usage: decrypt_and_extract_with_age "encrypted_app_file.age" "/path/to/extract" "private_key.txt"
