apt_repository 'openvpn' do
    uri "http://build.openvpn.net/debian/openvpn/release/2.4"
    key "https://swupdate.openvpn.net/repos/repo-public.gpg"
    components ["main"]
end

package 'openvpn'

bash 'add client autostart to openvpn' do
    code <<-EOS 
      echo 'AUTOSTART="all"' >> /etc/default/openvpn 
    EOS
    not_if 'grep -q AUTOSTART="all" /etc/default/openvpn'
end

service 'openvpn' do
  action [:enable, :start, :reload]
end