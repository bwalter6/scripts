# !/bin/bash

echo -n "Please enter Sitecode & OS: "
read -r SC

SN()    {
    ioreg -k IOPlatformSerialNumber | sed -En 's/^.*"IOPlatformSerialNumber".*(.{6})"$/\1/p'
}

serial=$(SN)
# echo $serial

SC+="$serial"

echo $SC



