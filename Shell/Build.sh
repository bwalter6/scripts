#!/bin/bash
#
#Created By:  Brett Walter
#This script will initiate the build process for Macbooks using
#SCCM and the Parallels Management Agent
#
#
#
#Check for Root
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
    echo "... Initializing ..."
    echo "*****************************************"
fi

#Build Process has been placed into a function 
#to keep certain variables local
Build()	{ 
    #Get The HostName
    echo
    echo
    echo "Please Enter the Name of this Device"
    echo "Site Code + OS + Last 6 of S/N"
    echo "example: USCHAMNHSABC123"
    echo "*****************************************"
    system_profiler SPSoftwareDataType | grep "System Version"
    system_profiler SPHardwareDataType | grep Serial
    echo
    echo
    echo -n "HostName: "
    read -r HOSTNAME

    # #Set the HostName
    scutil --set LocalHostName "$HOSTNAME"
    scutil --set HostName "$HOSTNAME"
    scutil --set ComputerName "$HOSTNAME"

    
    #URL Encoding Special characters function shamelessly stolen from someone else
    url_encode() {
    local LANG=C i c e=''

    for ((i=0;i<${#1};i++)); do
        c=${1:$i:1}
        [[ "$c" =~ [a-zA-Z0-9\.\~_-] ]] || printf -v c '%%%02X' "'$c"
        e+="$c"
    done

    echo "$e"
    }

    # Prompt for the user zID
    echo
	echo -n "Enter DS_ ID: "
    read -r zID

    #[ -n "$zID" ] || username=$USER
    # local COUNTER
    # COUNTER=0

    #Prompt for and Encode password     
    echo -n "Password: "
    read -rs zPass

    local Encoded_Password
    Encoded_Password=$(url_encode "$zPass")
    #echo $encoded_password
    #echo "//"$zID":"$encoded_password"@dfw1mspif017.nao.global.gmacfs.com/public/mac/Build"

    # echo "Is this a Developer Machine?  y/n"
    # read -r CLT

    #Starting build
    echo
	echo
	echo "... Starting the Build Process..."
    echo "*****************************************"
	
	# #Join to NAO Domain
    echo "Joining NAO domain"
    dsconfigad -add NAO.GLOBAL.GMACFS.COM -computer "$HOSTNAME" -mobile enable -mobileconfirm disable -username "$zID" -password "$zPass" -ou "ou=osx,ou=technology,ou=windows 7,ou=united states,dc=nao,dc=global,dc=gmacfs,dc=com" -useuncpath disable groups "LG-OSX-Local-Admin" -force
    echo

    #Download and install SSH Key
    local Build_URL
    Build_URL="dfw1mspif017.nao.global.gmacfs.com/public/mac/Build"

    mkdir /tmp/build
    mount -t smbfs -o nobrowse //"$zID":"$Encoded_Password"@"$Build_URL" /tmp/build
    cd /tmp/build/
    ./NetworkSSHKey.sh

    # #Install CMD Tools
    # if [[$CLT="y"]]; then
    #     cd /tmp/build
    #     hdiutil attach cmdtools10_14.dmg
    #     installer -package /Volumes/cmdtools10_14/"Command Line Tools (...0.14).pkg" -target /
    #     hdiutil detach /Volumes/cmdtools
    # else
    #     echo "...This is not Developer Laptop..."
    # fi

    #Install PMA
    #
    #PMA Agent installer image download URL
    PMA_AGENT_DMG_DOWNLOAD_URL="http://dfw1mspif017.nao.global.gmacfs.com:8761/files/pma_agent.dmg"

    # Dedicated PMA Agent registration user credentials
    # to authenticate with Active Directory
    export PMA_AGENT_REGISTRATION_USERNAME="$zID"
    export PMA_AGENT_REGISTRATION_PASSWORD="$zPass"
    export PMA_AGENT_REGISTRATION_DOMAIN="nao.global.gmacfs.com"

    ################################################################

    PMA_AGENT_DMG_LOCAL_FILENAME=/tmp/pma_agent.$RANDOM.dmg
    PRODUCT_NAME="Parallels Mac Management for Microsoft SCCM"

	MAGT_INSTALL_DIR="/Library/Parallels"
    MAGT_PLIST_ID="com.parallels.pma.agent"
    MAGT_LAUNCHDAEMON_PLISTFILE="/Library/LaunchDaemons/com.parallels.pma.agent.launchdaemon.plist"
    MAGT_LAUNCHAGENT_PLISTFILE="/Library/LaunchAgents/com.parallels.pma.agent.launchagent.plist"
    MAGT_LAUNCH_APPINDEX_DAEMON_PLISTFILE="/Library/LaunchDaemons/com.parallels.pma.agent.launch.appindex.daemon.plist"
    MAGT_LAUNCH_CEP_DAEMON_PLISTFILE="/Library/LaunchDaemons/com.parallels.pma.agent.launchcep.plist"
    MAGT_UNATTENDED_INSTALLATION_FLAG_FILE="/tmp/pma_agent.installing.unattended"

    if [ $PARALLELS_INTERNAL ]; then
        ALLOW_UNTRUSTED_FLAG="-allowUntrusted"
    fi

    function cleanup {
        hdiutil detach "/Volumes/$PRODUCT_NAME"
        rm -f $PMA_AGENT_DMG_LOCAL_FILENAME
        rm -f $MAGT_UNATTENDED_INSTALLATION_FLAG_FILE
    }
    trap cleanup EXIT
    trap "exit 1" SIGHUP SIGINT SIGTERM SIGQUIT


    function launchctl_load {
        local plistPath=$1
        local lastExitCode=

        local jobLabel=$(defaults read "$plistPath" Label)
        lastExitCode=$?
        if [ $lastExitCode -ne 0 ]; then
            echo "Job plist has invalid format - $plistPath"
            return $lastExitCode
        fi

        launchctl list | grep "$jobLabel" > /dev/null
        if [ $? -eq 0 ]; then
            echo "Job $jobLabel is already launched"
            return 0
        fi

        launchctl load -w "$plistPath"
        lastExitCode=$?
        if [ $lastExitCode -eq 0 ]; then
            echo "Job $jobLabel loaded successfully"
        else
            echo "Unable to load job $jobLabel"
            return $lastExitCode
        fi
    }


    function launchctl_unload {
        local plistPath=$1
        local lastExitCode=

        local jobLabel=$(defaults read "$plistPath" Label)
        lastExitCode=$?
        if [ $lastExitCode -ne 0 ]; then
            echo "Job plist has invalid format - $plistPath"
            return $lastExitCode
        fi

        launchctl list | grep "$jobLabel" > /dev/null
        if [ $? -ne 0 ]; then
            echo "Job $jobLabel not launched"
            return 0
        fi

        launchctl unload -w "$plistPath"
        lastExitCode=$?
        if [ $lastExitCode -eq 0 ]; then
            echo "Job $jobLabel unloaded successfully"
        else
            echo "Unable to unload job $jobLabel"
            return $lastExitCode
        fi
    }


    function launchctl_for_users {
        cmd=$1
        skip_if_not_listed=$2
        users=$(ps aux | grep -E "loginwindow.app" | grep -v grep | tr -s ' ' | cut -d ' ' -f 1)
        for user in $users
        do
            pid=$(ps aux | grep -E "loginwindow.app" | grep -v grep | grep $user | tr -s ' ' | cut -d ' ' -f 2)
            if [ $skip_if_not_listed ]; then
                launchctl bsexec $pid sudo -u $user launchctl list | grep "${MAGT_PLIST_ID}" > /dev/null
                if [ $? -ne 0 ]; then
                    continue
                fi
            fi
            launchctl bsexec $pid sudo -u $user launchctl $cmd "${MAGT_LAUNCHAGENT_PLISTFILE}"
            if [ $? -eq 0 ]; then
                echo "\"launchctl ${cmd}\" Mac Client UI succeeded for user ${user}"
            else
                echo "\"launchctl ${cmd}\" Mac Client UI FAILED for user ${user}"
            fi
        done
    }

    function stop_agents {
        launchctl_for_users "unload -w" true
    }

    function start_agents {
        launchctl_for_users "load -w"
    }

    echo $PMA_AGENT_DMG_LOCAL_FILENAME > $MAGT_UNATTENDED_INSTALLATION_FLAG_FILE
    if [ $? -ne 0 ]; then
        echo "Error: can't create flag file \"${MAGT_UNATTENDED_INSTALLATION_FLAG_FILE}\""
        exit 1
    fi

    echo "Downloading Mac Client installation image to ${PMA_AGENT_DMG_LOCAL_FILENAME}..."
    curl -# -o $PMA_AGENT_DMG_LOCAL_FILENAME $PMA_AGENT_DMG_DOWNLOAD_URL || exit 1

    echo "Installing Mac Client..."
    hdiutil attach $PMA_AGENT_DMG_LOCAL_FILENAME || exit 1
    installer -verbose -pkg "/Volumes/$PRODUCT_NAME/$PRODUCT_NAME.pkg" -target / ${ALLOW_UNTRUSTED_FLAG} || exit 1

    echo "Waiting for postinstall script completion..."
    while [ -n "$(ps aux | grep "$PRODUCT_NAME" | grep postinstall | grep -v grep)" ]; do sleep 0.1; done

    echo "Stop components..."
    stop_agents
    launchctl_unload "$MAGT_LAUNCH_APPINDEX_DAEMON_PLISTFILE"
    launchctl_unload "$MAGT_LAUNCH_CEP_DAEMON_PLISTFILE"
    launchctl_unload "$MAGT_LAUNCHDAEMON_PLISTFILE" || exit 1

    echo "Register Mac Client..."
    ${MAGT_INSTALL_DIR}/pma_agent.app/Contents/MacOS/pma_agent_registrator || exit 1

    echo "Start components..."
    launchctl_load "$MAGT_LAUNCHDAEMON_PLISTFILE" || exit 1
    launchctl_load "$MAGT_LAUNCH_CEP_DAEMON_PLISTFILE"
    launchctl_load "$MAGT_LAUNCH_APPINDEX_DAEMON_PLISTFILE"
    start_agents
}
# # #
# # #
# # # cp -R PMA\ Beta.pkg /tmp/pma/
# # # installer -pkg /tmp/pma/PMA\ Beta.pkg -target /
# # # #
# # # echo
# # # echo "Please Wait..."
# # # echo
# # sleep 5s
# #
# #Connect to Parallels Servers
# #
# # echo "***********************************************************"
# # echo "Enter Domain, ZID and Password for Parallels when prompted"
# # echo "Domain = NAO.GLOBAL.GMACFS.COM"
# # echo "***********************************************************"
# # echo

#Function to pull policies from server  
GetPolicies()  {
    #Load Plist
    launchctl load -w /Library/LaunchAgents/com.parallels.pma.agent.launchagent.plist

    #Get Policies from PMA/SCCM
    echo
    echo
    echo "...Please Wait, Checking for Policy Updates..."
    sleep 120s; /Library/Parallels/pma_agent.app/Contents/MacOS/pmmctl get-policies &>/dev/null
    sleep 120s; /Library/Parallels/pma_agent.app/Contents/MacOS/pmmctl get-policies &>/dev/null
    sleep 120s; /Library/Parallels/pma_agent.app/Contents/MacOS/pmmctl get-policies &>/dev/null
    echo
}	
 
# #Function to restart with timer 
Restart()	{ 
	echo
    echo "...Setup Complete, Your Machine Will Now Reboot..."  
    echo
    read -p "   Please Press Enter to Continue"
    echo
    echo "5"; sleep 1s
    echo
    echo "4"; sleep 1s
    echo
    echo "3"; sleep 1s
    echo
    echo "2"; sleep 1s
    echo
    echo "1"; sleep 1s
    echo
    echo "Rebooting..."
	reboot
}

#Run Build
Build
#Gather policies & reboot
GetPolicies
#Restart
Restart

#Done



