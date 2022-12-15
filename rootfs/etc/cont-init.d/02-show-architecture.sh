#!/usr/bin/env bash

white="\e[0;97m"
reset="\e[0m"

echo -e "${white}"
echo "Hardware information:"
echo "Machine:   $(uname -m)"
echo "Processor: $(uname -p)"
echo "Platform:  $(uname -i)"
echo -e "${reset}"
