# NetSuite API integration
# Requires env vars: NETSUITE_DOMAIN, NETSUITE_ACCOUNT, NETSUITE_API_KEY, NETSUITE_API_SECRET

def netsuite_get_token [] {
    let response = (
        http post $"($env.NETSUITE_DOMAIN)/api/integrations/netsuite/getToken"
            --content-type application/json
            --headers [nsaccount $env.NETSUITE_ACCOUNT connectorversion "1"]
            { apiKey: $env.NETSUITE_API_KEY, apiSecret: $env.NETSUITE_API_SECRET }
    )

    let token = $response.token
    print $"Token: ($token)"
    $token
}
