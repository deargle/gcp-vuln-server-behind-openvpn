#
# Cookbook:: metasploitable
# Recipe:: clear_cache
#
# Copyright:: 2017, Rapid7, All Rights Reserved.

directory '/var/chef' do
  action :delete
  recursive true
end

directory '/vagrant' do
  action :delete
  recursive true
end
