#!/bin/bash

CONFIG_FILE=/etc/ssh/sshd_config
CONFIG_FILE_DIR=/etc/ssh/sshd_config.d/
CUSTOM_CONFIG_FILE=${CONFIG_FILE_DIR}/00_harden_sshd.conf

#check root access privilages
echo "Checking access privilages"
if [ "$UID" != 0 ]; then
  echo "You need to be root user to run this program"
  echo "[Permission denied]"
  exit 2
fi

#load the contents of sshd_config
if [ -f ${CONFIG_FILE} ]; then
  CONFIG=$(sshd -T)
  echo "creating backup of the config file"
  cp ${CONFIG_FILE} ${CONFIG_FILE}.backup
  if [ $(grep -E "^Include ${CONFIG_FILE_DIR}\*.conf" ${CONFIG_FILE} | wc -l) -eq 0 ]; then
	echo "Include not included"
	INCLUDE_PATH=$(echo ${CONFIG_FILE_DIR} | sed 's/\//\\\//g')
	sed "1s/^/Include\ ${INCLUDE_PATH}*.conf\n/g" -i ${CONFIG_FILE} 
  fi
else
  echo "${CONFIG_FILE} file not found"
  exit 1
fi

HARDEN_MODE=false
while [[ "$#" -gt 0 ]]; do
  case "$1" in 
	--harden| -d)
	  HARDEN_MODE=true
		;;
	*)
	  echo "usage : $0 [options]"
	  echo "A script to view and harden SSH configuration settings."
	  echo "The available options are: "
	  echo -e "\t-d,\t--harden \tApply security hardening to the SSH configuration."
	  echo -e "\t-h,\t--help \tShow this help message and exit."
	  exit 0
	  ;;
  esac
  shift
done
#load default values into respective variables
PORT=$( echo "$CONFIG" | grep -iE "^[#]?Port " | cut -d " " -f2)
PERMIT_ROOT_LOGIN=$(echo "$CONFIG" | grep -iE  "^[\#]?PermitRootLogin" | cut -d " " -f2)
PASSWORD_AUTHENTICATION=$(echo "$CONFIG" | grep -iE  "^[\#]?PasswordAuthentication" | cut -d " " -f2)
MAX_AUTH_TRIES=$(echo "$CONFIG" | grep -iE  "^[\#]?MaxAuthTries " | cut -d " " -f2)

#print default values
print_defaults(){
	echo "The default configs are....."
	echo "Port : "${PORT}
	echo "PermitRootLogin : ${PERMIT_ROOT_LOGIN}"
	echo "PasswordAuthentication : ${PASSWORD_AUTHENTICATION}"
	echo "MaxAuthTries : ${MAX_AUTH_TRIES}"
}
print_defaults

echo "Hardening sshd config"
if $HARDEN_MODE; then
    if [[ ! -f ${CUSTOM_CONFIG_FILE} ]]; then
	  	touch ${CUSTOM_CONFIG_FILE} 
	fi
	
	#change default Port 
  	if [[ ! "$PORT" =~ "(^|[[:space:]])22([[:space:]]|$)" ]]; then
	  echo "Changing default PORT from :22 to :2222"
	  if $( grep -q "Port " ${CUSTOM_CONFIG_FILE} ); then
		sed 's/^Port 22*/Port 2222/' -i ${CUSTOM_CONFIG_FILE}
	  else
		echo "Port 2222" >> ${CUSTOM_CONFIG_FILE}
	  fi
	fi
	#Disable root login
	if $( grep -q "PermitRootLogin " ${CUSTOM_CONFIG_FILE} ); then
		sed 's/^PermitRootLogin yes/PermitRootLogin no/' -i ${CUSTOM_CONFIG_FILE}
	else
		echo "PermitRootLogin no" >> ${CUSTOM_CONFIG_FILE}
	fi

	#Disable Passowrd based Authentication
	if $( grep -q "PasswordAuthentication " ${CUSTOM_CONFIG_FILE} ); then
		sed 's/^PasswordAuthentication yes/PasswordAuthentication no/' -i ${CUSTOM_CONFIG_FILE}
	else
		echo "PasswordAuthentication no" >> ${CUSTOM_CONFIG_FILE}
	fi

	#Set Max Authentication tries to 6
	if $( grep -q "MaxAuthTries " ${CUSTOM_CONFIG_FILE} ); then
		sed 's/^MaxAuthTries [0-9]*/MaxAuthTries 6/' -i ${CUSTOM_CONFIG_FILE}
	else
		echo "MaxAuthTries 6" >> ${CUSTOM_CONFIG_FILE}
	fi
	#restart sshd deamon
	systemctl restart sshd.service
fi
