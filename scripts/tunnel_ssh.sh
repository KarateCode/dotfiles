#!/bin/zsh

# ssh_alias="envoy-stag-na-cf-integration"
ssh_alias=$(grep "Host " ~/.ssh/config | cut -d " " -f 2 | grep "integration" | fzf)
echo $selected_file
# exit 0

# Function to convert alias to display name
# e.g., "bauer-stag-na-cf-integration" -> "Bauer Stag Na Cf Integration"
alias_to_name() {
    echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# Generate display name
name=$(alias_to_name "$ssh_alias")
echo "  Name: $name"

# SSH into the box and get MONGO_CONNECTION_STRING
# Note: </dev/null prevents SSH from consuming stdin (which breaks the while loop)
echo "  SSHing to get MONGO_CONNECTION_STRING..."
MONGO_URI=$(ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$ssh_alias" 'echo $MONGO_CONNECTION_STRING' 2>/dev/null)
ssh_exit_code=$?

echo "  mon conn string: $MONGO_URI"

URI_FILE="$HOME/.config/.mongo-remote-uri"
# Save it
printf "%s\n" "$MONGO_URI" > "$URI_FILE"
chmod 600 "$URI_FILE"

LOCAL_PORT=27018
REMOTE_PORT=27017

# Extract host[:port] portion
hostport="${MONGO_URI#*@}"
hostport="${hostport%%/*}"

# Remove port if present
host="${hostport%%:*}"

TUNNEL_SPEC="${LOCAL_PORT}:${host}:${REMOTE_PORT}"

echo "  tunnel spec: $TUNNEL_SPEC"

# Start SSH tunnel in background
ssh -N -L $TUNNEL_SPEC $ssh_alias &
SSH_PID=$!

# Wait for tunnel to be established (check every 0.2 seconds)
echo -n "  Waiting for tunnel"
while ! lsof -i :$LOCAL_PORT > /dev/null 2>&1; do
    echo -n "."
    sleep 0.2
done
echo ""
echo "  Tunnel established (PID: $SSH_PID)"
