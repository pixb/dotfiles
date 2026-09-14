#!/bin/env bash
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

if grep -e "github.com" /etc/hosts &>/dev/null ; then 
	echo -e "${COLOR_GREEN}github host exists.${COLOR_NC}"
else
	echo -e "${COLOR_YELLOW}github host don't exists.${COLOR_NC}"
	echo "140.82.123.3	github.com" >> /etc/hosts
fi

