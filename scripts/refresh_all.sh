#!/bin/bash
TEAMS=$(terraform workspace list | sed 's:^..::')
for TEAM in $TEAMS; do 
    TF_WORKSPACE=$TEAM terraform refresh
done
