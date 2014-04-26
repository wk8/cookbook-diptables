# This recipe simply aims to give a few example rules as to how to use
# the LWRPs

# For example, here we set up a pretty simple web server listening specifically
# on the eth0 interface to a set of white-listed IP addresses

# we allow everything on the loopback interface
diptables_rule 'loopback_interface' do
    rule '-i lo'
end

# anyone is welcome to SSH
diptables_tcp_udp_rule 'ssh_int' do
    dport 22
end

# we allow ports 80 & 443 for the web server
diptables_tcp_udp_rule 'http_https_web_server' do
    dport [80, 443]
    source ['1.2.3.4', '5.6.7.8']
    interface 'eth0'
end

# we allow all icpm and igmp traffic
diptables_rule 'icpm' do
    rule '-p icmp'
end
diptables_rule 'igmp' do
    rule '-p igmp'
end

# keep established connections
diptables_rule 'established_connections' do
    rule '-m state --state RELATED,ESTABLISHED'
end

# log DDOS attacks
diptables_rule 'ddos_log' do
    rule '-m limit --limit 1/sec --limit-burst 1000 -j LOG --log-prefix "REJECT "'
    jump false
end

# reject all the rest
diptables_rule 'reject_rest' do
    rule '-j REJECT --reject-with icmp-port-unreachable'
    jump false
end
