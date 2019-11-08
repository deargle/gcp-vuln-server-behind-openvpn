#!/bin/bash
TEAMS=$(terraform workspace list | sed 's:^..::')
for TEAM in $TEAMS ; do
  TF_WORKSPACE=$TEAM terraform destroy -auto-approve
#TF_WORKSPACE=$WORKSPACE terraform workspace delete
done
