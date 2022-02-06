#!/bin/bash
# HP ILO4 Server wake up script - small script to trigger PoweredOn state of an HP ProLiant server through ILO4 Inferface
# https://hewlettpackard.github.io/ilo-rest-api-docs/ilo4/?shell#performing-actions

usage() {
	echo ""
	echo "   usage: $0 \"ILO-interface\" \"username\" \"password\""
	echo ""
	exit 1
}

error_creds() {
	echo "Error : check credentials"
}

ILO=${1}
USERNAME=${2:-admin}
PASSWORD=${3:-admin}
JQ=$(command -v jq || exit 1)

[[ $# -lt 1 ]] && usage

# Reset types: ON, ForceOff, ForceRestart, Nmi, PushPowerButton
# curl -X GET https://${ILO}/redfish/v1/Systems/1/ -u ${USERNAME}:${PASSWORD} --insecure
DESIRED_POWER_STATE=PushPowerButton
ONLY_WHEN=off

POWERSTATE=$(curl -s -X GET https://"${ILO}"/redfish/v1/Systems/1/ -u "${USERNAME}:${PASSWORD}" --insecure | "$JQ" '.PowerState' | sed 's#"##g' | tr '[:upper:]' '[:lower:]')
if [ "$POWERSTATE" == "null" ]; then
	error_creds
elif [ "$POWERSTATE" == "$ONLY_WHEN" ]; then
	echo "... trigger wake up script on host $ILO"
	curl -H "Content-Type: application/json" -X POST \
		https://"${ILO}"/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/ \
		-u "${USERNAME}:${PASSWORD}" --insecure \
		-d "{\"ResetType\": \"$DESIRED_POWER_STATE\"}"

else
	echo "... host $ILO state condition mismatch ($POWERSTATE != $ONLY_WHEN)"
	exit 1
fi
