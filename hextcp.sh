#!/bin/bash

# Default Variables
OUTPUT_FILE=""
TCP_FILE="/proc/net/tcp"
SHOW_ALL=false
SHOW_PROC=false
COUNT_ONLY=false
SOCKET_MODE="tcp"

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
  echo " -h           Show this help message"
    exit 0
    }

# Parse command-line flags
while getopts "o:6apcuh" opt; do
  case ${opt} in
  o ) OUTPUT_FILE=$OPTARG ;;
  6 ) TCP_FILE="/proc/net/tcp6" ;;
  a ) SHOW_ALL=true ;;
  p ) SHOW_PROC=true ;;
  c ) COUNT_ONLY=true ;;
  h ) show_help ;;
  u ) SOCKET_MODE="unix" ;;
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
if [ "$COUNT_ONLY" = false ]; then
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
if [ "$SOCKET_MODE" == "tcp" ]; then
  if [ "$SHOW_PROC" = true ]; then
    printf "%-12s  %-22s  %-12s %s\n"  "STATE"  "LOCAL IP"  "LOCAL PORT" "PROCESS"
    echo "------------------------------------------------------------"
    else
      printf  "%-12s  %-22s  %s\n" "STATE"  "LOCAL IP"  "LOCAL PORT"
      echo "------------------------------------------------------------"
    fi
  fi

  # Clearing the output if specified
  if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
  fi


# UNIX SOCKET PARSING
if [ "$SOCKET_MODE" == "unix" ]; then
  if [ "$COUNT_ONLY" = false ]; then
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
                exit 0
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
      if [ "$SHOW_PROC" = true ]; then
    fi

      # Use lsof to map the unix socket path to a PID
     pid=""
     if [ -n "$path" ] && [ "$path" ! = "(unnamed)" ]; then
       pid=$(lsof -U 2>/dev/null | grep "$path" | awk '{print $2}' | head -n 1)
         else
           pid=$(find /proc/*/fd -lname "socket:\[$inode\]" 2>/dev/null | head -n 1 | cut -d\ -f3)
             fi

             if [ -n "$pid" ]; then
               p_name=$(cat /proc/$pid/comm 2>/dev/null)
                 proc_name="$p_name $pid"
                fi

      # Output Formatiing
      if [ "$SHOW_PROC" = true ]; then
        
        output_line=$(printf "%-12s  %-22s  %s" "$state"  "$proc_name"  "$path")
          else
            output_line=$(printf "%-12s  %s" "$state"  "$path")
              fi

              echo "$output_line"
              
              if [ -n "$OUTPUT_FILE" ]; then

                  echo "$output_line" >> "$OUTPUT_FILE";
            fi
        done < <(tail -n +2 "$TCP_FILE")

        # Close the UNIX block
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

        # Process Mapping (or finding the PID via the Inode)
        proc_name=""
        if [ "$SHOW_PROC" = true ]; then
          pid=$(find /proc/*/fd -lname "socket:\[$inode\]" 2>/dev/null | head -n 1 | cut -d/ -f3)

            if [ -n "$pid" ]; then
              p_name=$(cat /proc/$pid/comm 2>/dev/null)
                proc_name="$p_name $pid"
              else
                proc_name="-"
              fi
            fi

            # Formatting and printing the output
            if [ "$COUNT_ONLY" = false ]; then
              if [ "$SHOW_PROC" = true ]; then
                output_line=$(printf "%-12s  %-22s  %-12s  %s"  "$state_str"  "$ip_dec"  "$port_dec"  "$proc_name")
                  else 
                    output_line=$(printf "%-12s  %-22s  %s"  "$state_str"  "$ip_dec"  "$port_dec")
                      fi

                  echo "$output_line"

                  # Appending to a file if requested by the user
                  if [ -n "$OUTPUT_FILE" ]; then
                    echo "$output_line" >> "$OUTPUT_FILE"
                    fi
                  fi

                    # Write to a temporary file for counting
                  
                
                  
                  
                  done < <(tail -n +2 "$TCP_FILE")

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
                  
                  

                  
