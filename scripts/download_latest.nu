# Helper: Find next available filename (Chrome-style incrementing)
def get-unique-filename [filename: string] {
    if not ($filename | path exists) {
        return $filename
    }

    let ext = ($filename | path parse | get extension)
    let stem = ($filename | path parse | get stem)

    mut counter = 1
    mut new_name = $"($stem)_($counter).($ext)"

    while ($new_name | path exists) {
        $counter = $counter + 1
        $new_name = $"($stem)_($counter).($ext)"
    }

    $new_name
}

# Download the latest task file for a given session
def download-latest [session_id: string] {
    if ($env.NAMING_PREFIX? | is-empty) {
        error make {msg: "$env.NAMING_PREFIX not set"}
    }

    print $"  Session passed: ($session_id)"

    # Get userId from AuthSession
    let user_id = (mongosh $env.NAMING_PREFIX --quiet --eval $"JSON.stringify\(db.AuthSession.findOne\({_id: '($session_id)'}\)\)"
        | from json
        | get user)

    print $"  userId: ($user_id)"

    # Get the most recent task for this user
    let task_id = (mongosh $env.NAMING_PREFIX --quiet --eval $"JSON.stringify\(db.Task.find\({userId: ObjectId\('($user_id)'\)}\).toArray\(\)\)"
        | from json
        | sort-by createDate
        | last
        | get _id)

    print $"  taskId: ($task_id)"

    # Download to temp file and capture headers to get the filename
    let timestamp = (date now | format date "%s%f")
    let temp_file = $"/tmp/download_latest_($timestamp)"
    let headers_file = $"/tmp/download_latest_headers_($timestamp)"

    curl --no-remote-name -o $temp_file -D $headers_file -H 'sec-ch-ua: "Not:A-Brand";v="99", "Google Chrome";v="145", "Chromium";v="145"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "macOS"' -H 'upgrade-insecure-requests: 1' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'sec-fetch-dest: document' -H 'referer: https://seedbrand.awt.loc/envoy/downloads' -H 'accept-language: en-US,en;q=0.9' -H $"cookie: envoy_cookie-consent=true; ENVOY_IS_MAIN_NAV_ACTIVE=true; envoy_language=en-US; ENVOY_PRODUCT_VIEW_MODE=GRID; ENVOY_LAST_SELECTED_LIST=69a1b93de0341c5496d07452; envoy_SESSION=($session_id)" $"http://seedbrand.awt.loc/api/downloads/($task_id)"

    # Extract filename from Content-Disposition header
    let filename = (open $headers_file
        | lines
        | where {|line| $line | str contains "Content-Disposition" }
        | first
        | parse --regex 'filename="?([^";\r\n]+)"?'
        | get capture0.0
        | str trim)

    # Get unique filename (increment if exists)
    let final_filename = (get-unique-filename $filename)

    # Move temp file to final location
    mv $temp_file $final_filename

    # Clean up headers file
    rm $headers_file

    print $"  Downloaded: ($final_filename)"
}
