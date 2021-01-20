#!/bin/bash

# this is
# ex) filename.sh <calleer-profile-name> <switch-profile-name>

# check exist command aws.
if ! type "aws" > /dev/null 2>&1; then
    echo "aws command not installed."
    return;
fi
# check exist command jq.
if ! type "jq" > /dev/null 2>&1; then
    echo "jq command not installed."
    return;
fi
if [ $# != 2 ]; then
    echo "invalid argument count. ex)  aws-mfa-switch-session <calleer_profile> <switch_profile>"
    return;
fi
caller_profile=$1
switch_profile=$2
#code=$2

read -sp "Input MFA Code: " code

echo -e ""

# get taget profile device(mfa_serial).
device=$(aws configure get mfa_serial --profile $switch_profile)
echo -e "switch from: ${device}"

# get target profile role
role=$(aws configure get role_arn --profile $switch_profile)
echo -e "switch to:   ${role}"

# execute get aws sts tokens. assume-role
sts=$(
  aws sts assume-role \
  --role-arn "$role" \
  --role-session-name `date +%s`-session \
  --serial-number "$device" \
  --token-code "$code" \
  --profile "$caller_profile" \
  --duration-second 14400 \
  --output json
)

# set enviroment temporary aws access tokens
export AWS_ACCESS_KEY_ID=$(echo $sts | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $sts | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $sts | jq -r .Credentials.SessionToken)
echo -e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"

