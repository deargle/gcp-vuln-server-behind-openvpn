#!/bin/bash
NUM_TEAMS=20
START_FROM=1
for i in $(seq $START_FROM $(( $START_FROM + $NUM_TEAMS )) ); do 
    WORKSPACE="team-${i}"

    # Select/Create Terraform Workspace
    terraform workspace select "${WORKSPACE}"
    IS_WORKSPACE_PRESENT=$?
    if [ "${IS_WORKSPACE_PRESENT}" -ne "0" ]
    then
        terraform workspace new "${WORKSPACE}"
    fi
    TF_WORKSPACE=$WORKSPACE terraform apply -auto-approve
done
