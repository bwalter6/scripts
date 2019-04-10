#!/bin/bash
#
#sudo -s
#
#Get The HostName
# echo "Please Enter the Name of this Device"
# echo "Site Code + OS + Last 6 of S/N"
# echo "example: USCHAMNHSABC123"
# echo
# echo
# echo "HostName:" 
# read HOSTNAME
#
#Set the HostName
# scutil --set LocalHostName $HOSTNAME
# scutil --set HostName $HOSTNAME
# scutil --set ComputerName $HOSTNAME
#
#copy build files
echo
echo "Enter Z iD:";
read ZID;
echo "Enter Password:";
stty -echo
read PASSWD;
stty echo
#
# mkdir /tmp/build
# mount -t smbfs -o nobrowse smb://$ZID:$PASSWD@dfw1mspif017.nao.global.gmacfs.com/shared/mac/Build
# cd /tmp/build/
# ./NetworkSSHkey.sh
# cp -R PMA_Beta.pkg /Users/macadmin/Desktop/


#
