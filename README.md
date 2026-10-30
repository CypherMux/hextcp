# hextcp

A 100% native Bash script designed to parse `/proc/net/tcp` and decode Little-Endian hexadecimal IPs and ports into human readable format.

## Why I Made This Tool

During Linux privilege escalation, specifically in restricted shell environments such as the one in TryHackMe's *Red Stone One Carat* room, standard tools such as `netstat`, `ss`, and `lsof` are often blocked or not installed meaning I had to decode the data via `/proc/net/tcp` to find the open ports locally on the system.

When you are forced to read `/proc/net/tcp` manually, the output is a wall of raw kernel data. In fact, the local addresses are written in **Little-Endian Hexadecimal**. *(e.g., `0100007F:7B3B`)*

I built this tool because manually doing the hex-to-decimal math and reversing byte orders during a CTF is tedious and prone to human error.

## Features In This Tool

*  **100% Native Bash:** No Python, Ruby, or external dependencies required. This tool runs purely on built-in Bash features such as parameter expansion and arithmetic expansion.

*  **IPv4 & IPv6 Support:** It can parse both `/proc/net/tcp` and `/proc/net/tcp6`.

*  **Process Mapping:** Cross references socket inodes with `/proc/` to find the exact running process name and PID running the socket. *(Requires `sudo`)*

*  **Heuristic Parsing:** The tool automatically filters for `0A` (LISTEN) and `01` (ESTABLISHED) states, and outright ignores dead connections in order to clean up the output and only show the important info.

*  **Visual Feedback:** It includes a custom terminal loading bar using `tput` and `printf` for that *hacker* aesthetic. 🤯

*  **File Output:** You can save your results directly to a file of your choice using the `-o` flag.

## How It Works & The Logic Behind It

The tool uses pure Bash to translate the kernel's data:

*  **1. Extracting Data:** It reads the TCP file line by line, skipping the header, and isolates the Local Address, State, and Inode columns.

*  **2.Port Conversion:** Bash natively converts hex to decimal using arithmetic expansion: `$((16#$port_hex))`.

*  **3. IPv4 Conversion:** It uses Bash substring extraction (`${ip_hex:6:2}`) to grab the hex string two bytes at a time, convert them to decimal format, and reverse the byte order.

*  **4. IPv6 Conversion:** It chunks the 32-character hex string into 4-byte blocks,reverses the byte order, and formats it with colons.

*  **5. Process Mapping (`-p`):** It takes the socket's Inode number and uses the command `find /proc/*/fd -lname "socket:\[$inode\]"` to locate which process file descriptor is holding that specified socket.

## Installation & Usage

### Option 1: Run Locally (Without Installing)

*  **1. Clone the repo:**

```git clone https://github.com/CypherMux/hextcp.git && cd hextcp```

*  **2. Make the script executable:**

```chmod +x hextcp.sh```

*  **3. Run the script:**

```./hextcp.sh```

### Option 2: Install The Tool Globally (Recommended)

If you want to run `hextcp` from any directory without using `./`, you can install it to your system's binary path:

*  **1.Make the script executable:**

```chmod +x hextcp.sh```

*  **2. Move it to `/usr/local/bin` and rename it:**

```sudo mv hextcp.sh /usr/local/bin/hextcp```

*  **3. Run it from anywhere via:**

```hextcp```

## Command Line Options

* `-o <filename>`: Save the decoded output to a specified text file.

* `-a`: Show **ALL** states *(TIME_WAIT, CLOSE_WAIT, SYN_SENT, etc.)* instead of just LISTEN and ESTABLISHED.

* `-6`: Parse the IPv6 table *(/proc/net/tcp6)* instead of IPv4.

* `-p`: Show Process/PID. Maps the socket to the application running it. *(Requires `sudo`)*

* `-c`: Count only. Outputs the total number of matching sockets instead of the full table.

* `-h`: Display the help menu.

## Examples of Some Commands

*  **Prints only listening/established IPv4 ports *(default)*:

```hextcp```

*  **Replicate `netstat -tulpn` *(show all processes and ports)*:

```sudo hextcp -a -p```

*  **Save all IPv6 connections to a file:**

```hextcp -6 -a -o <file_name>```

* **Count the number of listening ports:**

```hextcp -c```

## Disclaimer

*This tool is intended for educational purposes, CTFs, and authorized penetration testing. Always ensure you have explicit permission to enumerate systems you do not own.*

