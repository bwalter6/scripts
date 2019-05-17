#!/bin/bash
#
######################################
#Created By:  Brett Walter
#THis Tool will Remove Symantec DLP on machines running macOS Mojave
######################################
#
#Check for Root
#
if [[ $EUID -ne 0 ]]; then
    echo
    echo "*****************************************"
    echo "You must run this script as Root"
    echo "You can do this with the sudo -s command"
    echo "*****************************************"
    echo
    exit 10
else
    echo 
    echo "... Removing DLP ..."
    echo "*****************************************"
fi
echo
launchctl unload /Library/LaunchDaemons/com.symantec.manufacturer.agent.plist;
rm -rf /Library/Manufacturer;
rm -f /Library/LaunchDaemons/com.symantec.dlp.edpa.plist;
rm -f /Library/LaunchDaemons/com.symantec.manufacturer.agent.plist;
rm -f /Library/Receipts/com.symantec.dlp.edpa.plist;
rm -f /Library/Receipts/com.symantec.dlp.bom;  
pkgutil --forget com.symantec.dlp.edpa;
exit