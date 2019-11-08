execute 'set vim default editor' do
    command 'update-alternatives --set editor /usr/bin/vim.basic'
end

cookbook_file '/etc/sshguard/whitelist' do
    source 'sshguard/whitelist'
    mode '644'
end

service 'sshguard' do
    action [:restart]
end