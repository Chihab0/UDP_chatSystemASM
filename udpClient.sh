#!/bin/bash

SERVER=127.0.0.1
PORT=1337

# Colors and styles using tput
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RESET=$(tput sgr0)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)

clear

# Welcome animation
echo -e "${MAGENTA}${BOLD}"
echo "┌────────────────────────────────────────────┐"
echo "│                                            │"
echo "│       🎈 Welcome to the UDP Chat 🎈        │"      
echo "│                                            │"
echo "└────────────────────────────────────────────┘"
echo -e "${RESET}"
sleep 0.5
echo -e "${YELLOW}💡 Type '${RED}quit${YELLOW}' to exit like a boss.${RESET}"
echo -e "${CYAN}📡 Connected to server at ${SERVER}:${PORT} ${CYAN}Using UDP Protocol ${RESET}"
echo

# Emoji reaction pool
REACTS=("👍" "✨" "💬" "🔥" "🚀" "🎉" "🧠" "😎")

# Main loop
while true; do
    # Random emoji
    EMOJI=${REACTS[$((RANDOM % ${#REACTS[@]}))]}

    echo -en "${BLUE}${BOLD}You${RESET}${NORMAL} ${EMOJI}: "
    read msg

    if [[ "$msg" == "quit" ]]; then
	echo -n "quit" | nc -u -w1 $SERVER $PORT > /dev/null 
        echo -e "${RED}👋 Leaving the chat. Bye bye!${RESET}"
        break
    fi

    # Send the message
    echo -n "$msg" | nc -u -w1 $SERVER $PORT > response.txt

    # Display server response with typing effect
    echo -ne "${GREEN}🖥️ Server says:${RESET} "
    while IFS= read -r -n1 char; do
        echo -n "$char"
        sleep 0.01
    done < response.txt
    echo
    echo -e "${CYAN}💭 Awaiting your next message...${RESET}"
    echo
done
