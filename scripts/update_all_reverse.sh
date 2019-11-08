#!/bin/bash
TEAMS=$(terraform workspace list | sed 's:^..::' | tac | awk 'NF')
for TEAM in $TEAMS; do 
    WORKSPACE="$TEAM"
    TF_WORKSPACE=$WORKSPACE terraform apply -auto-approve
done
