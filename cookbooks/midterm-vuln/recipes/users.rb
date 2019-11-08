#
# Cookbook:: midterm-vuln
# Recipe:: users
#
def keys_from_url(url)
  host = url.split('/')[0..2].join('/')
  path = url.split('/')[3..-1].join('/')
  begin
    response = Chef::HTTP.new(host).get(path)
    response.split("\n")
  rescue Net::HTTPServerException => e
    p "request: #{host}#{path}, error: #{e}"
  end
end


uid = 1111

node[:users].each do |u, attributes|
  
  home_dir = "/home/#{attributes[:username]}"
  gid = uid
  
  group attributes[:username] do
    gid gid
  end
  
  user attributes[:username] do
    manage_home true
    password attributes[:password_hash]
    uid uid
    gid gid
    home home_dir
    shell '/bin/bash'
  end
  
  # Add public key, if present in attributes
  # Lifted from https://github.com/chef-cookbooks/users
  if attributes[:ssh_keys]
  
    ssh_keys = []
    Array(attributes[:ssh_keys]).each do |key|
      if key.start_with?('https')
        ssh_keys += keys_from_url(key)
      else
        ssh_keys << key
      end
    end
  
    directory "#{home_dir}/.ssh" do
      recursive true
      owner uid
      group gid
      mode '0700'
    end
      
    # use the keyfile defined in the attributes or fallback to the standard file in the home dir
    key_file = attributes[:authorized_keys_file] || "#{home_dir}/.ssh/authorized_keys"
    
    template key_file do # ~FC022
      source 'authorized_keys.erb'
      owner uid
      group uid
      mode '0600'
      sensitive true
      # ssh_keys should be a combination of u['ssh_keys'] and any keys
      # returned from a specified URL
      variables ssh_keys: ssh_keys
    end
  end
  
  
  uid += 1
end

administrator_members = node[:users].keys.find_all { |user| node[:users][user][:admin] == true }

group 'sudo' do
  action :modify
  members administrator_members.map { |u| node[:users][u][:username] }
  append true
end


