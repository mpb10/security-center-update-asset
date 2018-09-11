#!/bin/bash
# Author: mpb10 07/24/18
# This script uses AWS CLI to get a list of all running instances' IP addresses. This list is then sent
# to Security Center via a REST API call to update a certain asset list. A new token is generated every
# time the script is ran and then deleted after the asset is updated.
#
# Options:
# -c    Cookie file for Security Center login.
# -i    Security Center asset id.
# -I    Security Center asset name.
# -k    Don't have curl verify the certificate (NOT RECOMMENDED).
# -l    Security Center address.
# -p    Security Center password.
# -P    Credential file to have KMS decrypt instead of specifying a password.
# -u    Security Center username.

logger -p syslog.info "$0 - Script starting."

export PATH=$PATH:/usr/local/bin
export HOME=/root

# Default settings for variables.
USERNAME=""
PASSWORD=""
CREDFILE=""
ASSETNUM=""
ASSETNAME=""
COOKIEFILE="./cookiefile"
SSLVERIFY=""
SECURITYCENTERURI=""
CERTPATH=""
CERTFILE=""

while [ ! -z "$1" ]; do
    case $1 in
        -u | --username )   shift
                            USERNAME=$1
                            ;;
        -p | --password )   shift
                            PASSWORD=$1
                            ;;
        -P | --kms-file )   shift
                            CREDFILE=$1
                            ;;
        -i | --asset-id )   shift
                            ASSETNUM=$1
                            ;;
        -I | --asset-name ) shift
                            ASSETNAME=$1
                            ;;
        -c | --cookie-file ) shift
                            COOKIEFILE=$1
                            ;;
        -l | --sc-address ) shift
                            SECURITYCENTERURI=$1
                            ;;
        -k | --no-sslverify )
                            SSLVERIFY="-k"
    esac
    shift
done

# Check if an asset id or name was provided.
if [ -z "$ASSETNUM" ] && [ -z "$ASSETNAME" ]; then
    logger -s -p syslog.err "$0 - No asset ID or name provided."
    exit 1
fi

# Using KMS to decrypt the Security Center credentials file if provided.
if [ ! -z "$CREDFILE" ]; then
    PASSWORD=$(aws kms decrypt --ciphertext-blob fileb://<(cat $CREDFILE | base64 -d) --output text --query Plaintext | base64 -d)
fi

# POST request to generate new token for provided user.
TOKEN=$(curl $CERTPATH $CERTFILE $SSLVERIFY -H "Content-Type: application/json" -c $COOKIEFILE -X POST "https://${SECURITYCENTERURI}/rest/token" -d '{"username" : "'"$USERNAME"'","password" : "'"$PASSWORD"'","releaseSession" : "false"}' | tr ',' '\n' | grep -i "token" | sed 's/"token"://')

# Check if token was successfully generated.
if [ -z "$TOKEN" ]; then
    logger -s -p syslog.err "$0 - Failed to generate Security Center token."
    exit 1
fi

# Lookup asset ID from asset name if provided.
if [ ! -z "$ASSETNAME" ]; then
    ASSETNUM=$(curl $CERTPATH $CERTFILE $SSLVERIFY -H "Content-Type: application/json" -H "X-SecurityCenter: $TOKEN" -b "$COOKIEFILE" -X GET "https://${SECURITYCENTERURI}/rest/asset?filter=usable&fields=id,name" | tr '{' '\n' | grep -i "name\":\"${ASSETNAME}\"" | tr ',' '\n' | tr -d '"' | grep -i "id:" | sed 's/id://')

    # Check if the asset ID could be found.
    if [ -z "$ASSETNUM" ]; then
        curl $CERTPATH $CERTFILE $SSLVERIFY -H "Content-Type: application/json" -H "X-SecurityCenter: $TOKEN" -b "$COOKIEFILE" -X DELETE "https://${SECURITYCENTERURI}/rest/token"
        logger -s -p syslog.err "$0 - Failed to find asset ID. Invalid asset name provided."
        exit 1
    fi
fi

# AWS CLI command to get list of running instances' IP addresses.
HOSTLIST=$(aws ec2 describe-instances --filter 'Name=instance-state-code,Values=16' --query "Reservations[].Instances[].[PrivateIpAddress]" --output text | sort | uniq | tr '\n' ',')

# Check if AWS CLI command successfully ran.
if [ -z "$HOSTLIST" ]; then
    curl $CERTPATH $CERTFILE $SSLVERIFY -H "Content-Type: application/json" -H "X-SecurityCenter: $TOKEN" -b "$COOKIEFILE" -X DELETE "https://${SECURITYCENTERURI}/rest/token"
    logger -s -p syslog.err "$0 - Failed to get AWS host list."
    exit 1
fi

# PATCH request to update an asset's IP list.
curl $CERTPATH $CERTFILE $SSLVERIFY -H "Content-Type: application/json" -H "X-SecurityCenter: $TOKEN" -b "$COOKIEFILE" -X PATCH "https://${SECURITYCENTERURI}/rest/asset/$ASSETNUM" -d '{"definedIPs": "'"$HOSTLIST"'"}'

# DELETE request to delete the token after it's been used.
curl $CERTPATH $CERTFILE $SSLVERIFY -H "Content-Type: application/json" -H "X-SecurityCenter: $TOKEN" -b "$COOKIEFILE" -X DELETE "https://${SECURITYCENTERURI}/rest/token"

logger -p syslog.info "$0 - Script completed."

exit 0

