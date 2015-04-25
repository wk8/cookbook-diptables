#!/bin/bash

# This script simply checks that the configuration defined in
# diptables_tests::full_example was indeed successfully applied
# It serves as an end-to-end test, and also tests some features
# that could not (without major hacks) be tested with chefspec
# (most notably that the handler will indeed apply the config
# if no apply resource is ever set)

EXPECTED_IPTABLES_SAVE="-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -s 10.2.3.4/32 -i eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
-A INPUT -s 10.5.6.7/32 -i eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -p igmp -j ACCEPT
-A INPUT -m limit --limit 1/sec --limit-burst 1000 -j LOG --log-prefix \"REJECT \"
-A INPUT -j REJECT --reject-with icmp-port-unreachable"

# RHEL systems add trailing spaces...
[ -f /etc/redhat-release ] && EXPECTED_IPTABLES_SAVE=$(echo "$EXPECTED_IPTABLES_SAVE" | sed 's/$/ /')

ACTUAL_IPTABLES_SAVE=$(iptables-save | grep -E '^-A INPUT')

[[ "$ACTUAL_IPTABLES_SAVE" == "$EXPECTED_IPTABLES_SAVE" ]] \
    || eval "echo -e 'Expected:\n$EXPECTED_IPTABLES_SAVE\nGot:\n$ACTUAL_IPTABLES_SAVE\n' && exit 1"
