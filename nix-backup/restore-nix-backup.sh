#!/bin/bash

# Read the backup file and install each package
while IFS= read -r line; do
    # Remove the version number using regex
    package=$(echo $line | sed 's/-[0-9]\+\(\.[0-9]\+\)*$//')
    nix-env -iA nixpkgs.$package
done < nix-backup

