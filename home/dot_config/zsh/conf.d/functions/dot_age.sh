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
    
    # Check if the provided file exists
    if [ ! -d "$app_file_path" ]; then
      echo "Error: '$app_file_path' is not a valid directory."
      return 1
    fi

    # Define temporary compressed file
    local compressed_file="${output_file}.tar.gz"

    # Compress the file
    echo "Compressing the file..."
    # Check if the file already exists
    if [ -e "$compressed_file" ]; then
      read -p "$compressed_file already exists. Do you want to overwrite it? (y/n): " yn
      if [[ "$yn" =~ ^[Yy]$ ]]; then
        echo "Overwriting $compressed_file..."
        tar -czf "$compressed_file" -C "$(dirname "$app_file_path")" "$(basename "$app_file_path")"
      else
        echo "Skipping $compressed_file..."
        return 0
      fi
    else
      echo "Compressing $compressed_file..."
      tar -czf "$compressed_file" -C "$(dirname "$app_file_path")" "$(basename "$app_file_path")"
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to compress the file."
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

    echo "Successfully compressed and encrypted the file. Encrypted file: $output_file"
}

# Example usage: compress_and_encrypt_with_age "/path/to/your/app/file.app" "output_filename.age" "your-public-key"

#!/bin/bash

# Function to decrypt and extract a compressed file using age
function age_decrypt_extract {
    if [ $# -ne 2 ]; then
        echo "Usage: age_decrypt_extract <encrypted_file> <output_dir> ?<private_key>"
        return 1
    fi

    local encrypted_file="$1"
    local output_dir="$2"
    local private_key="${3:-$AGE_LOCAL_KEYS_FILE}"
    local tempd=$(mktemp -d)
    
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
    local decrypted_file="${tempd}/decrypted_file.tar.gz"

    # Decrypt the file using age
    echo "Decrypting the file with age..."
    age -d -i "$private_key" -o "$decrypted_file" "$encrypted_file"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to decrypt the file."
        return 1
    fi

    # Extract the decrypted .tar.gz file
    echo "Extracting the decrypted .tar.gz file..."
    tar -xzf "$decrypted_file" -C "$tempd"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to extract the .tar.gz file."
        return 1
    fi

    # Clean up the temporary decrypted file
    rm "$decrypted_file"

    # Verify target directory exists
    mkdir -p "$output_dir"
    
    # Check if the extracted file is already in the target directory
    # Iterate over all files in the source directory
    for src_file in "$tempd"/*; do
      # Get the file name (without path)
      file_name=$(basename "$src_file")
    
      # Check if the file exists in the target directory
      target_file="$output_dir/$file_name"
      if [ -e "$target_file" ]; then
        # Check if the script is running in an interactive shell
        if [ -t 0 ]; then
            # If interactive, prompt the user
            echo -n "$file_name already exists. Do you want to overwrite it? (y/n): "
            read yn
        else
            # Default to 'y' if non-interactive
            yn="y"
        fi
        if [[ "$yn" =~ ^[Yy]$ ]]; then
          echo "Copying $file_name to $output_dir..."
          sudo cp -rf "$tempd/$file_name" "$target_file"
        else
          echo "Skipping $file_name..."
          continue
        fi
      else
        echo "Copying $file_name to $output_dir..."
        sudo cp -rf "$tempd/$file_name" "$target_file"
      fi
    done
    
    echo "Successfully decrypted and extracted the file. Output directory: $output_dir"
}

# Example usage: decrypt_and_extract_with_age "encrypted_app_file.age" "/path/to/extract" "private_key.txt"
