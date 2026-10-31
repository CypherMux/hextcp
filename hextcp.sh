#!/bin/bash

# Default Variables
OUTPUT_FILE=""
TCP_FILE="/proc/net/tcp"
SHOW_ALL=false
SHOW_PROC=false
COUNT_ONLY=false

# Help menu functionality
show_help() {
  echo "Usage: hextcp [options]"
  echo ""
  echo "Options:"
  echo " -o <file>    Save decoded output to a specified file"
  echo " -a           Show ALL connection states (not just LISTEN/ESTABLISHED)"
  echo " -6           Parse IPv6 table (/proc/net/tcp6) instead of IPv4"
  echo " -p           Show Process/PID (requires root/sudo for all processes)"
  echo " -c           Count the number of matching sockets only"
  echo " -h           Show this help message"
    exit 0
    }

# Parse command-line flags
