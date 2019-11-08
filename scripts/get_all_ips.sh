#!/bin/bash
TEAMS=$(terraform workspace list | sed 's:^..::')
> vuln_ips
for TEAM in $TEAMS; do 
    echo "[$TEAM]" >> vuln_ips
    TF_WORKSPACE=$TEAM terraform output midterm_vuln_ip >> vuln_ips
    echo >> vuln_ips
done
