#!/bin/bash

# Default Variables
OUTPUT_FILE=""
TCP_FILE="/proc/net/tcp"
SHOW_ALL=false
SHOW_PROC=false
COUNT_ONLY=false
SOCKET_MODE="tcp"
JSON_OUT=false
WATCHLIST_FILE=""
CHECK_EVIL=false
RESOLVE_DNS=false

# Colors for the Watchlist
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # <--- No Color

# Help menu functionality
show_help() {
  echo "Usage: hextcp [options]"
  echo ""
  echo "Options:"
  echo " -o <file>    Save decoded output to a specified file"
  echo " -a           Show ALL connection states (not just LISTEN/ESTABLISHED)"
  echo " -6           Parse IPv6 table (/proc/net/tcp6) instead of IPv4"
  echo " -u           Parse Unix sockets (/proc/net/unix)"
  echo " -p           Show Process/PID (requires root/sudo for all processes)"
  echo " -c           Count the number of matching sockets only"
  echo " -j           Output results in JSON format"
  echo " -w <file>    Check against a watchlist of malicious IPs"
  echo " -e           Highlight processes from suspicious paths such as /tmp, /dev/shm, or deleted binaries"
  echo " -r           Resolve remote IPs to hostnames"
  echo " -h           Show this help message"
    exit 0
    }

# Parse command-line flags
while getopts "o:6apcuhjw:er" opt; do
  case ${opt} in
  o ) OUTPUT_FILE=$OPTARG ;;
  6 ) TCP_FILE="/proc/net/tcp6" ;;
  a ) SHOW_ALL=true ;;
  p ) SHOW_PROC=true ;;
  c ) COUNT_ONLY=true ;;
  h ) show_help ;;
  u ) SOCKET_MODE="unix" ;;
  j ) JSON_OUT=true ;;
  w ) WATCHLIST_FILE=$OPTARG ;;
  e ) CHECK_EVIL=true ;;
  r ) RESOLVE_DNS=true ;;
  \? ) echo "Invalid Option." 1>&2; show_help ;;
  esac
done

if [ "$SOCKET_MODE" == "unix" ]; then
  TCP_FILE="/proc/net/unix"
fi

if [ ! -f "$TCP_FILE" ]; then
  echo "Error: $TCP_FILE not found.Are you on Linux or is IPv6 disabled?"
  exit 1
fi

# Loading Bar Functionality (Skip if -c is used)
if [ "$COUNT_ONLY" = false ] &&
[ "$JSON_OUT" = false ]; then

  echo "hextcp - A tool by Stlwtrs"
  echo ""
  
  tput civis
  for ((i = 0; i <= 100; i += 2)); do
    filled=$((i * 40 / 100))
    empty=$((40 - filled))
    
    printf "\rParsing $TCP_FILE ["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d%%" "$i"
    sleep 0.01
  done
  printf "\n"
  tput cnorm

  echo ""
fi

  # ONLY PRINTS TCP HEADERS IF WE ARE NOT IN UNIX MODE
if [ "$SOCKET_MODE" == "tcp" ] &&
  [ "$JSON_OUT" = false ]; then
    if [ "$RESOLVE_DNS" = true ]; then
      if [ "$SHOW_PROC" = true ]; then
        printf "%-12s  %-22s  %-20s  %-12s  %s\n"  "STATE"  "LOCAL IP"  "REMOTE HOST"  "PORT"  "PROCESS"
      else
        printf "%-12s  %-22s  %-20s  %s\n"  "STATE"  "LOCAL IP"  "REMOTE HOST"  "PORT"
      fi
    else
      if [ "$SHOW_PROC" = true ]; then
        printf "%-12s  %-22s  %-12s  %s\n"  "STATE"  "LOCAL IP"  "LOCAL PORT"  "PROCESS"
        echo "-------------------------------------------------------------------------"
      else
        printf "%-12s  %-22s  %s\n"  "STATE"  "LOCAL IP"  "LOCAL PORT"
        echo "-------------------------------------------------------------------------"
      fi
    fi
  fi
    
     

  # Clearing the output if specified
  if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
  fi


# UNIX SOCKET PARSING
if [ "$SOCKET_MODE" == "unix" ]; then
  if [ "$COUNT_ONLY" = false ] &&
    [ "$JSON_OUT" = false ]; then
    echo ""
    if [ "$SHOW_PROC" = true ]; then
      printf "%-12s  %-22s  %s\n"  "STATE"  "PROCESS"  "PATH"
        echo "-----------------------------------------------------------"
          else
            printf "%-12s  %s\n"  "STATE"  "PATH"
              echo "---------------------------------------------------------"
                fi
              fi
              if [ -n "$OUTPUT_FILE" ]; then
                echo "STATE          PROCESS PATH" > "$OUTPUT_FILE"
                
              fi

              
      # Read /proc/net/unix
      tail -n +2 "$TCP_FILE" | while read -r line; do

      # Extract Columns Safely Using awk

      state=$(echo "$line" | awk '{print $6}')
      inode=$(echo "$line" | awk '{print $7}')
      path=$(echo "$line" | awk '{print $8}')

      # If path is empty, it is an unnamed socket
      if [ -z "$path" ]; then
        path="(unnamed)"
      fi

      
      # Process Mapping 
      proc_name="-"

      # Use lsof to map the unix socket path to a PID
     pid=""
     if [ -n "$path" ] && [ "$path" != "(unnamed)" ]; then
       pid=$(lsof -U 2>/dev/null | grep "$path" | awk '{print $2}' | head -n 1)
         else
           pid=$(find /proc/*/fd -lname "socket:\[$inode\]" 2>/dev/null | head -n 1 | cut -d/ -f3)
             fi

             if [ -n "$pid" ]; then
               p_name=$(cat /proc/$pid/comm 2>/dev/null)
                 proc_name="$p_name $pid"
                fi

      # Output Formatiing
      if [ "$COUNT_ONLY" = false ]; then
        if [ "$JSON_OUT" == "true" ]; then
            if [ "$SHOW_PROC" == "true" ]; then
      
              output_line="{\"type\":\"unix\",\"state\":\"$state\",\"process\":\"$proc_name\":,\"path\":\"$path\"}"
                else
                  output_line="{\"type\":\"unix\",\"state\":\"$state\",\"path\":\"$path\"}"
                fi
              else
                if [ "$SHOW_PROC" = true ]; then
         
                  output_line=$(printf "%-12s  %-22s  %s"  "$state"  "$proc_name"  "$path")
                    else
                      output_line=$(printf "%-12s  %s"  "$state"  "$path")
                    fi
                  fi

                  echo "$output_line"

                  if [ -n "$OUTPUT_FILE" ]; then
                    echo "$output_line" >> "$OUTPUT_FILE"
                  fi
                fi
              done

                  exit 0
              fi

  # TCP LOOP (Only will run if not UNIX)
  if [ "$SOCKET_MODE" != "unix" ]; then

    COUNT=0

    tail -n +2 "$TCP_FILE" | while read -r line; do

  # Read columns and turn into variables
  local_address=$(echo "$line" | awk '{print $2}')
  state=$(echo "$line" | awk '{print $4}')
  inode=$(echo "$line" | awk '{print $10}')

  # Parse State
  if [ "$state" == "0A" ]; then
    state_str="LISTEN"
  elif [ "$state" == "01" ]; then
    state_str="ESTABLISHED"
  elif [ "$SHOW_ALL" = true ]; then
    state_str="OTHER $state"
  else
    continue
  fi

  # Separate the IP and Port's Hexadecimal
  ip_hex="${local_address%:*}"
  port_hex="${local_address#*:}"

  # Convert the Port's Hexadecimal to Decimal Format
  port_dec=$((16#$port_hex))

  # Parse the IP address
  if [ "$TCP_FILE" == "/proc/net/tcp" ]; then

  # IPv4 Parsing (or reversing the Little-Endian)
    b1=$((16#${ip_hex:6:2}))
    b2=$((16#${ip_hex:4:2}))
    b3=$((16#${ip_hex:2:2}))
    b4=$((16#${ip_hex:0:2}))
    ip_dec="$b1.$b2.$b3.$b4"
  else

  # IPv6 Parsing
    ip_dec=""
    for ((i=0; i<32; i+=8)); do
      block="${ip_hex:$i:8}"
      rev="$((16#${block:6:2}))$((16#${block:4:2}))$((16#${block:2:2}))$((16#${block:0:2}))"
        ip_dec+="${rev:0:4}:${rev:4:4}:"
          done
          ip_dec="${ip_dec%:}"
        fi

        
          # Grab the remote address from the 3rd column
          rem_address=$(echo "$line" | awk '{print $3}')
          rem_ip_hex="${rem_address%:*}"

          # Convert the remote hex to a decimal
          rb1=$((16#${rem_ip_hex:6:2}))
          rb2=$((16#${rem_ip_hex:4:2}))
          rb3=$((16#${rem_ip_hex:2:2}))
          rb4=$((16#${rem_ip_hex:0:2}))
          rem_ip_dec="$rb1.$rb2.$rb3.$rb4"


        # Watchlist Check
          is_suspicious=false
          if [ -n "$WATCHLIST_FILE" ] && [ -f "$WATCHLIST_FILE" ]; then
            if grep -q "^$rem_ip_dec$"  "$WATCHLIST_FILE" 2>/dev/null; then
              is_suspicious=true
            fi
          fi

          # Reverse DNS Resolution
          rem_host=""
          if [ "$RESOLVE_DNS" = true ]; then

          # Check if it is a local or VPN IP
          if [[ "$rem_ip_dec" == 10.* || "$rem_ip_dec" == 192.168.* || "$rem_ip_dec" == 127.* ]]; then
            rem_host="[local/VPN]"
          elif [ "$rem_ip_dec" == "0.0.0.0" ]; then
            rem_host="[listening]"
          else

          # Use getent to resolve the host
          rem_host=$(getent hosts "$rem_ip_dec" | awk '{print $2}' | head -n 1)
            if [ -z "$rem_host" ]; then
              rem_host="[no DNS]"
            fi
          fi
        fi

          
          # Use grep to check the watchlist
          if grep -q "^$rem_ip_dec$" "$WATCHLIST_FILE" 2>/dev/null; then
            is_suspicious=true
          fi
        fi
      fi

  
        
         

        # Process Mapping (or finding the PID via the Inode)
        proc_name=""
        is_evil_path=false
        if [ "$SHOW_PROC" = true ]; then
          pid=$(find /proc/*/fd -lname "socket:\[$inode\]" 2>/dev/null | head -n 1 | cut -d/ -f3)

            if [ -n "$pid" ]; then
              p_name=$(cat /proc/$pid/comm 2>/dev/null)
                proc_name="$p_name $pid"
                
            # Evil Path Check
            if [ "$CHECK_EVIL" = true ]; then
              exe_path=$(readlink /proc/$pid/exe 2>/dev/null)
                if [[ "$exe_path" == *"/tmp/"* || "$exe_path" == *"/dev/shm/"* || "$exe_path" == *"(deleted)"* ]]; then
                  is_evil_path=true
                fi
              fi

            # End Evil Path Block

            else
              proc_name="-"
            fi
          fi

            # Formatting and printing the output
            if [ "$COUNT_ONLY" = false ]; then
              if [ "$JSON_OUT" == "true" ]; then
                if [ "$SHOW_PROC" == "true" ];
              then

                  output_line="{\"type\":\"tcp\",\"state\":\"$state_str\",\"local_ip\":\"$ip_dec\",\"local_port\":$port_dec,\"process\":\"$proc_name\"}"
                    else
                      output_line="{\"type\":\"tcp\",\"state\":\"$state_str\",\"local_ip\":\"$ip_dec\",\"local_port\":$port_dec}"
                      fi

              # Warning for suspicious traffic
              if [ "$is_suspicious" = true ]; then
                output_line="${output_line},\"warning\":\"Malicious Remote IP ($rem_ip_dec)\"}"
              else
                output_line="${output_line}}"
            fi
            else

            # Continue Normal Table Output
                      if [ "$RESOLVE_DNS" = true ]; then
                        if [ "$SHOW_PROC" = true ]; then
                          output_line=$(printf "%-12s  %-22s  %-20s  %-12s  %s"  "$state_str"  "$ip_dec"  "$rem_host"  "$port_dec"  "$proc_name")
                            else
                              output_line=$(printf "%-12s  %-22s  %-20s  %s"  "$state_str"  "$ip_dec"  "$rem_host"  "$port_dec")
                            fi
                          else
                            if [ "$SHOW_PROC" = true ]; then
                              output_line=$(printf "%-12s  %-22s  %s"  "$state_str"  "$ip_dec"  "$port_dec"  "$proc_name")
                            else
                              output_line=$(printf "%-12s  %-22s  %s"  "$state_str"  "$ip_dec"  "$port_dec")
                            fi
                          fi
                    # Highlight in RED if suspicious
                    if [ "$is_suspicious" = true ]; then
                      output_line="${RED}${output_line} [!] MALICIOUS IP${NC}"
                    fi

                    # Highlight in YELLOW if evil path
                    if [ "$is_evil_path" = true ]; then
                      output_line="${YELLOW}  ${output_line}  [!] SUSPICIOUS PATH${NC}"
                    fi
                  fi

                   

                  echo -e "$output_line"

                  # Appending to a file if requested by the user
                  if [ -n "$OUTPUT_FILE" ]; then
                    echo "$output_line" >> "$OUTPUT_FILE"
                    fi
                  fi
              

                    # Write to a temporary file for counting
                  
                
                  
                  
                  done

                  # Final count calculations

          

                  if [ "$COUNT_ONLY" = true ]; then
                    REAL_COUNT=$(tail -n +2 "$TCP_FILE" | wc --lines)
                    echo "Total matching sockets:$REAL_COUNT"
                  else
                    if [ -n "$OUTPUT_FILE" ] ; then
                      echo ""
                      echo "Success! Decoded results are saved to: $OUTPUT_FILE"
                        fi
                    fi
                fi
                  
                  
                  
