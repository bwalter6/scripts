#!/bin/bash
#
#Created By:  Brett Walter
#This script will initiate the build process for Macbooks using
#SCCM and the Parallels Management Agent
#
#
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
    echo "Starting Build Process ..."
    echo "*****************************************"
fi
echo
echo
sleep 2s
#
#Get The HostName
#
echo
echo "*****************************************"
echo "Please Enter the Name of this Device"
echo "Site Code + OS + Last 6 of S/N"
echo "example: USCHAMNHSABC123"
echo "*****************************************"
system_profiler SPSoftwareDataType | grep "System Version"
system_profiler SPHardwareDataType | grep Serial
echo
echo
echo "HostName:" 
read HOSTNAME
# 
# #Set the HostName
#
scutil --set LocalHostName $HOSTNAME
scutil --set HostName $HOSTNAME
scutil --set ComputerName $HOSTNAME
#
#copy build files
#
echo
echo "Enter Z iD:";
read ZID;
echo 
#
mkdir /tmp/build
mkdir /tmp/pma
mount -t smbfs -o nobrowse //$ZID@dfw1mspif017.nao.global.gmacfs.com/public/mac/Build /tmp/build
echo
cd /tmp/build/
./NetworkSSHKey.sh
cp -R PMA\ Beta.pkg /tmp/pma/
installer -pkg /tmp/pma/PMA\ Beta.pkg -target /
#
echo
echo "Please Wait..."
echo
sleep 5s
#
#Connect to Parallels Servers
#
echo "***********************************************************"
echo "Enter Domain, ZID and Password for Parallels when prompted"
echo "Domain = NAO.GLOBAL.GMACFS.COM"
echo
sleep 45s
/Library/Parallels/pma_agent.app/Contents/MacOS/pmmctl get-policies
echo
read -p "Press Enter to Continue..."
echo
/Library/Parallels/pma_agent.app/Contents/MacOS/pmmctl get-policies
echo
sleep 5s
exit
#
