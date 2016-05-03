Diptables cookbook
==================

A Chef cookbook with to manage iptables rules and policies.

*_WARNING_: Chef 11 is no longer supported by this cookbook. Please use version
1.0.1 if you still use Chef 11, or better yet, upgrade your Chef client!*

Usage
=====

This cookbook rebuilds the entire set of rules at every Chef-client run, thus
making it trivial to keep the iptables configuration up-to-date.

It also makes it easy to create iptables rules using Chef search queries. For
example, you can very simply create a rule telling your database server to let
all your backend servers connect to it.

You simply need to create all the rules and policies using the resources
provided by this cookbook (see below), and then apply them using with a
`diptables_apply` resource or alternatively by including `diptables::default`.
Note that if you do not do either of these things, this cookbook defines a
handler that will apply the rules for you at the end of the run (but that's not
recommended, as you won't benefit from your reporting handlers if there's an
error applying rules that way).

Requirements
============

This cookbook is fully tested on Ubuntu 12.04, 14.04, CentOS 6.5, and Chef 12.

It should work on any platform that supports `iptables` though.

Resources
=========

***diptables_rule***

The most generic resource to define rules. If you want to apply TCP or UDP
rules, you might want to have a look at `diptables_tcp_udp_rule` below that
brings so syntactic sugar on top of this `diptables_rule`.

Actions:

| Action | Description |
|--------|-------------|
| `:append` | (_default_) Appends the rule after the other rules already   defined in its chain |
| `:prepend` | Prepends the rule the front of its chain |
| `:insert` | Inserts the rule in its chain at the position given by the `index` attribute (see below) |
| `:add` | (_deprecated_) An alis for `:append` |

Attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `table` | `String` | `'filter'` | The rule's table |
| `chain` | `String` | `'INPUT` | The rule's chain |
| `rule` | `String | Array` | `''` | The rule itself; if it's an array, it will create one `iptables` rule for each item in the array |
| `jump` | `String | FalseClass` | `ACCEPT` | What to do with the matching packets; can be `false` to omit that part from the generated rule |
| `comment` | `String | TrueClass | FalseClass` | `true` | A comment for that rule (will appear in the files containing the generated rules); `false` disables this feature, `true` takes the resource's name as comment |
| `query` | `String | FalseClass` | `false` | A query to fetch `Chef::Node` objects used to generate the rule (see `placeholders` below) |
| `placeholders` | `Hash` | `{}` | When using the `query` attribute, this defines how to replace placeholders from the `rule`; it should map each placeholder's name to a method name or an attribute path (given as arrrays) used to retrieve the corresponding values from the `Chef::Node` objects returned by the query |
| `same_environment` | `TrueClass | FalseClass` | `false` | Restricts the `query` to return only nodes from the same Chef environment |
| `index` | `Fixnum` | `-1` | The rule's index in its chain (only makes sense with the `:insert` action) |

A few examples (note that all these would be simpler with `diptables_tcp_udp_rule` resources instead):

    # Disallow SSH
    diptables_rule 'ssh' do
      rule '--proto tcp --dport 22'
      jump 'REJECT'
    end

    # Allow HTTP, HTTPS
    diptables_rule 'http' do
      rule [ '--proto tcp --dport 80',
             '--proto tcp --dport 443' ]
    end

    # Allow backend servers to connect to MySQL (using a node method)
    diptables_rule 'mysql with node method' do
      rule '-s %<remote_ip>s --proto tcp --dport 3306'
      query 'roles:backend-server'
      placeholders({:remote_ip => 'ipaddress'})
    end

And the same as the above, but using node attributes instead (assuming
`node['my_company']['network']['internal_ip']` is defined):

    # Allow backend servers to connect to MySQL (using an attribute path)
    diptables_rule 'mysql with attribute path' do
      rule '-s %<remote_ip>s --proto tcp --dport 3306'
      query 'roles:backend-server'
      placeholders({:remote_ip => ['my_company', 'network', 'internal_ip]})
    end

***diptables_tcp_udp_rule***

Essentially a wrapper with some syntactic sugar on top of `diptables_rule`.

Same actions as `diptables_rule`.

Attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `table` | `String` | `'filter'` | The rule's table |
| `chain` | `String` | `'INPUT`   | The rule's chain |
| `jump` | `String | FalseClass` | `ACCEPT` | What to do with the matching packets; can be `false` to omit that part from the generated rule |
| `proto` | `'tcp' | 'udp'` | `'tcp'` | The protocol |
| `interface` | `String | FalseClass` | `false` | The interface |
| `dport` | `Fixnum | String | Array | FalseClass` | `false` | The destination port(s); can be a `String` to specify a range - e.g `'9300:9400'`, or an `Array` of `String`s and `Fixnum`s - e.g. `[80, 443, '9200:9400']` - in which case it uses the `multiport` iptables module |
| `source` | `String | Array | FalseClass` | `false` | One or more source IP(s) (cannot be used together with `source_query` below) |
| `source_query` | `String | FalseClass` | `false` | A query to fetch the source nodes for that rule |
| `source_method` | `String | Array` | `'ipaddress'` | A method or attribute path to retrieve the IP address of source nodes |
| `comment` | `String | TrueClass | FalseClass` | `true` | A comment for that rule (will appear in the files containing the generated rules); `false` disables this feature, `true` takes the resource's name as comment |
| `same_environment` | `TrueClass | FalseClass` | `false` | Restricts the `query` to return only nodes from the same Chef environment |
| `index` | `Fixnum` | `-1` | The rule's index in its chain (only makes sense with the `:insert` action) |

The same examples as above, re-written using `diptables_tcp_udp_rule`s:

    # Disallow SSH
    diptables_tcp_udp_rule 'ssh' do
      dport 22
      jump 'REJECT'
    end

    # Allow HTTP, HTTPS
    diptables_tcp_udp_rule 'http' do
      dport [80, 443]
    end

    # Allow backend servers to connect to MySQL (using a node method)
    diptables_tcp_udp_rule 'mysql with node method' do
      dport 3306
      source_query 'roles:backend-server'
    end

    # Allow backend servers to connect to MySQL (using an attribute path)
    diptables_tcp_udp_rule 'mysql with attribute path' do
      dport 3306
      query 'roles:backend-server'
      source_method ['my_company', 'network', 'internal_ip]
    end

***diptables_bpf_rule***

Another wrapper on top of `diptables_rule`; that one allows to create BPF ("Berkeley Packet Filter") rules
using the same syntax as for `tcpdump` filters.

This one is very specific, and you probably won't use it, so just a couple of
examples here:

    # drops all IPv6 traffic
    diptables_bpf_rule 'drop all IPv6 traffic' do
        tcpdump_rule 'ip6'
        jump 'DROP'
    end

A more sophisticated example, that accepts all IP packets where the source and
destination IP do not belong to the same `/16` network on `tun0`:

    diptables_bpf_rule 'accept only traffic on the same /16 network' do
        tcpdump_rule 'ip and ip[12:4] & 0xFFFF0000 = ip[16:4] & 0xFFFF0000'
        # WARNING: this interface is only used to generate the bytecode, not for the
        # actual iptables rule!
        interface 'tun0'
        additional_rule '-i tun0'
    end

Of course assumes you have the `bpf` iptables module installed. You also need
to have `tcpdump` around.

More docs and example at https://github.com/cloudflare/bpftools

***diptables_policy***

Defines a policy (default action) for a given iptables chain.

Actions:

| Action | Description |
|--------|-------------|
| `:add` | (_default_) Adds the policy |

Attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `table` | `String` | `'filter'` | The policy's table |
| `chain` | `String` | `'INPUT` | The policy's chain |
| `policy` | `'ACCEPT' | 'DROP'` | none (_required_) | The policy itself |

***diptables_apply***

| Action | Description |
|--------|-------------|
| `:apply` | (_default_) Applies the `iptables` configuration as defined so far |

Applies rules and policies defined so far. There *must* be *exactly one*
`diptables_apply` resource in your Chef-client run, and it *must* be converged
*after* all your rule and policy resources (if you have more than one, Chef
will output an explicit warning).

Note that the `diptables::default` recipe defines such a resource. As mentioned
above, if your Chef-client run ends with one or more rule or policy resources
that haven't been applied yet, our custom Chef handler will create and converge
a `diptables_apply` resource on the fly, but it is not recommended to rely on
this behaviour.

Contributing & Feedback
=======================

As always, I appreciate bug reports, suggestions, pull requests, feedback...
Feel free to reach me at <wk8.github@gmail.com>

Development & Testing
=====================

You can test this cookbook locally, provided you have a bunch of free software
installed, namely [Vagrant](https://www.vagrantup.com/downloads),
[Berkshelf](http://berkshelf.com/), [VirtualBox](https://www.virtualbox.org/),
and a couple of Vagrant plugins:
[Vagrant-Berkshelf](https://github.com/berkshelf/vagrant-berkshelf) and
[Vagrant-Omnibus](https://github.com/schisamo/vagrant-omnibus).

Then playing with this cookbook should be as easy as running `bundle install && vagrant up`!

To run the full test suite across all supported platforms and Chef versions,
you need to have [ChefDK](https://downloads.chef.io/chef-dk/) around, and run
`kitchen test`.

Chef-Solo
=========

As of version 0.1.5, you can use this cookbook's resources' query abilities as
long as you have the [`chef-solo-search` cookbook (by
edelight)](https://github.com/edelight/chef-solo-search) installed.

Please note though that the `chef-solo-search` cookbook is deprecated, and you
should really consider starting using `chef-zero` instead [as suggested by
`chef-solo-search`'s author
himself.](https://www.chef.io/blog/2014/06/24/from-solo-to-zero-migrating-to-che
f-client-local-mode/)

Changes
=======

* 1.1.0 (May 2nd, 2016):
    * Upgraded the syntax to Chef 12. Deprecated support for Chef 11
    * Upgraded the dev environment

* 1.0.1 (Sep 19, 2015)
    * Added the `['diptables']['force_reload']` attribute to explicitely
      reload rules even when the rules file has not been modified -
      not adding to the README as this is a smell in Chef use as far as I'm
      concerned

* 1.0.0 (Apr 24, 2015)
    * Added full support for CentOS 6.5
    * Added `rspec` tests
    * Added Test-Kitchen tests for all supported platforms and Chef versions
    * Migrated the applying logic to the `diptables_apply` resource

* 0.2.0 (Mar 1, 2015)
    * Added the `diptables_bpf_rule` resource

* 0.1.6 (May 6, 2014)
    * Included Vagrant & Berkshelf for easier development

* 0.1.5 (Apr 26, 2014)
    * Enabling the use of the search queries with Chef-Solo if the `chef-solo-search` cookbook is installed
    * Enforcing that the default recipe runs after LWRPs have been defined in a smoother way

* 0.1.4 (Nov 6, 2013)
    * Sorting the query's results to avoid reloading iptables unnecessarily

* 0.1.3 (Oct 8, 2013)
    * Forcing the flush of the test chain, fixing a possible bug when a previous Chef-client run has been killed half-way through

* 0.1.2 (Sep 23, 2013)
    * Forcing the iptables reload action when disabling the `dry_run` mode
    * Fixing possible name collision

* 0.1.1 (Sep 23, 2013)
    * Added the `comment` attribute

* 0.1.0 (Sep 11, 2013)
    * Initial release
