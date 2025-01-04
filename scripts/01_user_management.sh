#!/bin/bash

add_user()
{
    echo -n "username: "
    read USERNAME
    adduser ${USERNAME}
}


echo "Checking Access Previlages...."
if [ "${UID}" != 0 ]; then
    echo "You need to be root to execute this script"
    echo "[Permission Denied]"
    exit 2
fi
echo "You are root! and good to go"

HARDEN_MODE=false
while [[ "$#" -gt 0 ]]; do
  case "$1" in 
	--harden| -d)
	  HARDEN_MODE=true
		;;
    *)
	  echo "usage : $0 [options]"
	  echo "A script to view and harden USER Management settings."
	  echo "The available options are: "
	  echo -e "\t-d,\t--harden \tmake required changes to harden user management"
	  echo -e "\t-h,\t--help \tShow this help message and exit."
	  exit 0
	  ;;
  esac
  shift
done

echo "listing users...."
IFS=$',' read -a USERS_LIST <<< $( awk -F: '$3>=1000 && $3<=60000 {print $1 }' /etc/passwd | paste -sd, )
for USER in ${USERS_LIST[@]}; do
    echo "- $USER"
done
NO_OF_SUDOERS=0
SSH_USER=""

if [ ${#USERS_LIST[@]} -ne 0 ]; then
    echo "checking user privilages...."
    for USER in ${USERS_LIST[@]}; do
        if sudo -lU ${USER} | grep -q "not allowed"; then   
            echo "- $USER is doesn't have sudo privilages"
        else 
            echo "- $USER have sudo privilages"
            NO_OF_SUDOERS=$(( $NO_OF_SUDOERS + 1))
        fi
    done
else 
    echo "no users found!"
    if ${HARDEN_MODE}; then
        echo "please add a user for remote management"
        add_user
    fi
fi

if [ ${NO_OF_SUDOERS} -eq 0 ]; then
    echo "No sudoers found!"
    if ${HARDEN_MODE}; then
        echo "please provide sudo privivlages for a user for remote management"
        MAX_INDEX=0
        for i in ${!USERS_LIST[@]}; do 
            echo "${i}. ${USERS_LIST[$i]}"
            MAX_INDEX=${i}
        done
        echo -n "Select the user to elevate sudo privilages[0-${MAX_INDEX}]: "
        read INDEX
        SSH_USER=${USERS_LIST[$INDEX]}
        if [ ${INDEX} -lt 0 ] || [ ${INDEX} -ge ${MAX_INDEX} ]; then
            echo "Invalid index selected!"
            exit 3
        fi
        usermod -aG sudo ${SSH_USER}
        newgrp sudo
    fi

fi

#Add ssh key for the ssh user
if ${HARDEN_MODE}; then
    echo "Configuring ssh keys for the sudo user"
    echo "Paste the public key: "
    read SSH_KEY
    if [ -z ${SSH_KEY} ]; then
        echo "No ssh key provided"
        exit 4
    fi
    echo "${SSH_KEY}" >> /home/${SSH_USER}/.ssh/authorized_keys
fi

#modify permissions for ssh files
if ${HARDEN_MODE}; then
    chmod 700 /home/${SSH_USER}/.ssh
    chmod 600 /home/${SSH_USER}/.ssh/authorized_keys
fi