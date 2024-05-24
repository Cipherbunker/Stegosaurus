#!/bin/bash

# Directory for temporary files in the current working directory
temp_root="$(pwd)/tarcry_temp"
mkdir -p "$temp_root"

# Function to create a tar archive
create_tar() {
    echo "Enter file paths separated by spaces (e.g., /path/to/file1 /path/to/file2):"
    read -e -a files

    if [ "${#files[@]}" -eq 0 ]; then
        echo "No files provided."
        return 1
    fi

    temp_dir=$(mktemp -d -p "$temp_root")
    tar cf "$temp_dir/files.tar" "${files[@]}"
    echo "Tar archive created: $temp_dir/files.tar"
    return 0
}

# Function to encrypt a tar file
encrypt_tar() {
    echo "Drag and drop the tar file onto this terminal window, then press Enter."
    read -e tar_file

    if [ -z "$tar_file" ]; then
        echo "No tar file provided."
        return 1
    fi

    if [ ! -f "$tar_file" ]; then
        echo "File does not exist: $tar_file"
        return 1
    fi

    echo -n "Enter the passphrase for encryption: "
    read -s passphrase
    echo

    read -p "Do you want to encrypt the tar file? (y/n): " encrypt

    if [ "$encrypt" == "y" ]; then
        temp_dir=$(mktemp -d -p "$temp_root")
        echo "$passphrase" | gpg --batch --passphrase-fd 0 -c -o "$temp_dir/files.tar.gpg" "$tar_file"
        echo "The tar file has been encrypted and saved as $temp_dir/files.tar.gpg."
    else
        echo "The tar file has not been encrypted."
    fi
    return 0
}

# Function to decrypt a tar file
decrypt_tar() {
    echo "Drag and drop the encrypted tar file onto this terminal window, then press Enter."
    read -e tar_file

    if [ -z "$tar_file" ]; then
        echo "No tar file provided."
        return 1
    fi

    if [ ! -f "$tar_file" ]; then
        echo "File does not exist: $tar_file"
        return 1
    fi

    echo -n "Enter the passphrase for decryption: "
    read -s passphrase
    echo

    temp_dir=$(mktemp -d -p "$temp_root")
    echo "$passphrase" | gpg --batch --passphrase-fd 0 -o "$temp_dir/decrypted.tar" -d "$tar_file"
    echo "The tar file has been decrypted and saved as $temp_dir/decrypted.tar."
    return 0
}

# Function for steganography
steganography() {
    source .venv/bin/activate  # Linux/macOS

    echo -e "\n\n"
    cat dedsec
    echo -e "\n\n"

    read_file_input() {
        local prompt="$1"
        local file_var="$2"
        local red='\033[0;31m'
        local nc='\033[0m'

        echo -e "${prompt} ${red}Then press Enter:${nc}"
        read -rp "" file_path
        eval "$file_var='$file_path'"
    }

    read_file_input "Drag and drop image file." cover_image
    read_file_input "Drag and drop secret file." secret_file
    read -rp "Enter the output file name: " output_image

    ./lsb_image_stego.py -H -c "$cover_image" -s "$secret_file" -o "$output_image"

    if [[ $? -eq 0 ]]; then
      echo "Secret hidden in image saved as $output_image"
    else
      echo "An error occurred during the process."
    fi
    return 0
}

# Function to recover secret from steganographic image
recover_secret() {
    temp_dir=$(mktemp -d -p "$temp_root")

    read -rp "Enter the path to the steganographic image file: " steganographic_image

    ./lsb_image_stego.py -R -c "$steganographic_image" -o "$temp_dir/output_file"

    if [[ $? -eq 0 ]]; then
      echo "Recovered secret saved as $temp_dir/output_file"
    else
      echo "An error occurred during the process."
      echo "Temporary directory: $temp_dir"
    fi
    return 0
}

# Function to purge all temporary directories
purge_temp_files() {
    read -p "Are you sure you want to delete all temporary directories? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -rf "$temp_root"
        mkdir -p "$temp_root"
        echo "All temporary directories have been purged."
    else
        echo "Purge cancelled."
    fi
    return 0
}

# Main menu loop
while true
do
    echo "Welcome! Choose your option:"
    echo "1. Create Tar Archive"
    echo "2. Encrypt"
    echo "3. Decrypt"
    echo "4. Steganography"
    echo "5. Recover Secret from Steganographic Image"
    echo "6. Purge Temporary Files"
    echo "7. Exit"
    read -p "Enter your choice (1, 2, 3, 4, 5, 6, or 7): " option

    case $option in
        1) create_tar ;;
        2) encrypt_tar ;;
        3) decrypt_tar ;;
        4) steganography ;;
        5) recover_secret ;;
        6) purge_temp_files ;;
        7) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please choose either 1, 2, 3, 4, 5, 6, or 7";;
    esac
done
