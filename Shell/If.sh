#!/bin/bash

#If Yes; then; else continue

read -p "Is this a Developer Machine?  [y/N]" Input

if  [ "$Input" != "${Input#[Yy]}" ] ;then
    echo "Building Dir"
    mkdir /tmp/dir 
    cd /tmp/dir
    pwd
else
    echo "Nope"
fi  