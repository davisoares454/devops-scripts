#!/bin/bash

Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: aws-assume-default.sh -r <role-arn> -s <session-name> -p <profile-name> -d <destination-profile>"
   echo 
   echo "Options:"
   echo " -r     Role ARN to be assumed."
   echo " -s     Session name to the assume."
   echo " -p     Profile name to use to assume the role."
   echo " -d     Destination profile (better option: default)."
   echo
}

commands=(aws jq)
cmdexit=0
for i in ${commands[@]}; do
   if ! command -v $i &> /dev/null
   then
      invalidcommands+=("$i")
      ((cmdexit=cmdexit+1))
   fi
done
if [ $cmdexit -ge 1 ]
then
   echo "${invalidcommands[@]} command could not be found"
   exit
fi

#Get the options
while getopts hr:s:p:d: option; do
   case $option in
      h) Help
         exit;;
      r) Role=$OPTARG
      ;;
      s) Session=$OPTARG
      ;;
      p) Profile=$OPTARG
      ;;
      d) Destination=$OPTARG
      ;;
      \?) # Invalid option
         echo "Error: Invalid option"
	      Help
         exit;;
   esac
  case $OPTARG in
    -*) echo "Option -$option needs a valid argument"
    exit 1
    ;;
  esac
done

role_arn=$Role
role_session_name=$Session
profile_source=$Profile
profile_destination=$Destination

temp_role=$(aws sts assume-role \
     --role-arn $role_arn \
     --role-session-name $role_session_name --profile $profile_source)

export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $profile_destination
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $profile_destination
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile $profile_destination

echo "Assumed role and configured it in profile $profile_destination"