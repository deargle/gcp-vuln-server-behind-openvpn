tar czvf chef-solo.tar.gz ./cookbooks ./berks-cookbooks
ansible-playbook -i vuln_ips -l team-999 --private-key=tyler-midterm-vuln playbook-chef-solo.yml -f 10
rm chef-solo.tar.gz
