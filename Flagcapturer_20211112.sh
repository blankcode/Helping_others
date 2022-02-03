#!/bin/bash

# Created from:
# https://www.reddit.com/r/bash/comments/qsdu4x/resolving_thousands_of_domains_faster_way_to_do/
#
# Title: Resolving thousands of domains: faster way to do it? (code attached)
# Post: Hi there,
#
# I routinely need to do a lookup on thousands of domains and record the IP attached
# to those domains. I've created a bash script to do this, but it takes a long time.
# I think this mainly has to do with the time it takes to do the resolving with the
# DNS itself, but not sure. Do you guys have any tips on how to do this more
# effectively? E.g. use parallel or insert xargs -P 4 -L 1 to get more concurrent
# look-ups? Maybe add multiple DNS resolvers in the script (no idea how to though).
#
# Here's an excerpt from my code. The domains are stored in the hosts file and the
# output is written to the IP's file.
#
# while IFS= read -r host
# do
#     if [[ -n "$host" ]]
#     then
#         ips=$(dig @8.8.8.8 +short "$host" | grep '^[[:digit:].]*$' | xargs )
#         printf "%s\t%s\n" "$host" "$ips"
#     fi
# done <hosts >ips

# Response:
# If you are going to accellarate the queries, you'll probably need to spread them out also.
# 1. Cloudflare:         1.1.1.1 1.0.0.1
# 2. Google Public DNS:  8.8.8.8 8.8.4.4
# 3. Norton ConnectSafe: 199.85.126.10 199.85.127.10
# 4. Comodo Secure DNS:  8.26.56.26 8.20.247.20
# 5. Quad9:              9.9.9.9 149.112.112.112
#
# The key here is going to be parallel processing.
# However, I'm not going to assume you can install new software on the client you a using.
# I would take your "hosts" file and split them up each time the program is run,
# so you still only have to look after a single file.
# Depending on how many you have you'll probably want to work off of two numbers,
# CPU Cores to use and the number of DNS providers you're working with.

## GetOpt Arguments
OPTS=$(getopt -o hc::d:: --long "helps,cores::,domains::" -- "$@")
eval set -- "$OPTS"
while true; do
  case "$1" in
  -h | --helps)
    helps
    shift
    ;;
  -c | --cores)
    NUM_CORES=$2 # Cores to use
    shift 2
    ;;
  -d | --domains)
    HOSTS=$2 # Original Hosts file from the CLI argument
    shift 2
    ;;
  --)
    shift
    break
    ;;
  esac
done

# Gee I wonder what thisbit does...
helps() {
  echo "
  Usage:
    $0 -c 4 -d hosts.txt
  -h | --help       This message.
  -c | --cores      Cores to use.
  -d | --domains    Original Hosts file from the CLI argument.
  "
}

NSI=0 # NS Index Start Number
# Nameserver Array
NSIPS[0]="1.1.1.1"
NSIPS[1]="8.8.8.8"
NSIPS[2]="199.85.126.10"
NSIPS[3]="8.26.56.26"
NSIPS[4]="9.9.9.9"

# Figuring out how to split your hosts list.
NUM_LINES=$(wc -l "$HOSTS" | cut -d\  -f1)             # Lines in the Hosts list
NUM_LINES_FILES=$((("$NUM_LINES" / "$NUM_CORES") + 1)) # Total Lines in Hosts / Cores +1 for padding
split --lines="$NUM_LINES_FILES" "$HOSTS" /tmp/host.   # Split the Hosts list into equal parts
FILES=$(ls /tmp/host.*)                                # Build a list of the files

for FILE in $FILES; do        # Loop for each file
  while IFS= read -r host; do # Loop for each host of that file
    if [[ -n "$host" ]]; then
      ips=$(dig @"${NSIPS[$NSI]}" +short "$host" | grep '^[[:digit:].]*$') # DNS lookup
      ips=$(echo "$ips" | tr "\n" " ")                                     # format IPs into one line
      printf "%s\t%s\n" "$host" "$ips" >>ips                               # Output data to a file.
    fi
    ((++NSI))                               # Iterate the Nameserver Index
    [[ "$NSI" == "${#NSIPS[@]}" ]] && NSI=0 # Check if the Nameserver Index needs reset
    # In-take file and background loop
  done <"$FILE" &
  rm "$FILE" # Remove the tmp file
done
