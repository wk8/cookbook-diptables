Description
===========

Chef! cookbook with LWRPs for managing iptables rules and policies.

Largely inspired by Dan Crosta's `simple-iptables` cookbook (https://github.com/dcrosta/cookbook-simple-iptables), but with a slightly different approach: we rebuild the whole iptables config file from scratch every time this cookbook is run. That allows to automatically remove obsolete rules (rather than manually with Dan's cookbook).

Also, it makes it possible to make rules that apply to the result of a Chef! search query, which allows for rules such as "allow all my servers tagged Apache to access the current server on that port and that protocol".

Requirements
============

None, other than a system that supports iptables.

Platforms
=========

The following platforms are supported and known to work:

* Debian (6.0 and later)
* RedHat (5.8 and later)
* CentOS (5.8 and later)

Other platforms that support `iptables` and the `iptables-restore` script
are likely to work as well; if you use one, please let me know so that I can
update the supported platforms list.

Installation
============

Usual stuff:
`knife cookbook site install diptables`

Attributes
==========

This cookbook uses two attributes, both of which are optional:

* `['diptables']['rules_path']` defines the path to which we should save the current iptables rules set. It defaults to sensible locations depending on your distribution.
* `['diptables']['dry_run']` set that attribute to `true` to generate the new iptables rules set, but without actually loading it. This allows you to easily test your rules, and check what iptables configuration they would result in, without actually applying them yet. (Obviously defaults to `false`).

Usage
=====

This cookbook defines three LWRPS: `diptables_rule`, `diptables_tcp_udp_rule` and `diptables_policy`, that you can use in your recipes, after telling Chef! that your cookbook depends on this one (just put `depends 'diptables'` in your `metadata.rb` file).

Please note that you need to include the `recipe[diptables]` in your run list *AFTER* the recipe(s) using these resources to actually commit your changes (you'll get an error-level log at the end of the run otherwise, and your rules won't get enforced).

`diptables_rule` Resource
-------------------------

In its simpler form, that resource defines a single iptables rule, composed of a rule string (passed as-is to iptables), a table name, a chain name, and a jump target. All the attributes are optional, and respectively to '' (empty string), 'filter', 'INPUT', and 'ACCEPT'. For instance:

    # Allow SSH
    diptables_rule 'ssh' do
      rule '--proto tcp --dport 22'
    end

For convenience, you may also specify an array of rule strings in a single LWRP invocation:

    # Allow HTTP, HTTPS
    diptables_rule 'http' do
      rule [ '--proto tcp --dport 80',
             '--proto tcp --dport 443' ]
    end

The same resource allows you to apply a given rule to every server matching a given Chef! search query. For instance, that rule would allow all your servers with the `backend-server` role to access the current server on the port 3306 (typical for a MySQL server):

    # Allow backend servers to connect to MySQL
    diptables_rule 'mysql' do
      rule '-s %<remote_ip>s --proto tcp --dport 3306'
      query 'roles:backend-server'
      placeholders({:remote_ip => 'ipaddress'})
    end

This example will run the `roles:backend-server` query in the Chef! search, then create one rule per matching node on the current server, replacing the `%<remote_ip>s` placeholder by whatever is returned by the `ipaddress` method on the matching nodes. So if you have two servers with the `backend-server` role in your system, with IP addresses 1.2.3.4 and 1.2.3.5, the resource above will result in two rules in your iptables config file:

    -A INPUT -s 1.2.3.4 --proto tcp --dport --jump ACCEPT
    -A INPUT -s 1.2.3.5 --proto tcp --dport --jump ACCEPT

And the best thing is, if you add a third server with the same role, it will automatically add the relevant line to your iptables config.

Together with the `query` attribute, you can set the `same_environment` to `true` to retrieve only the nodes with the same Chef! environment as the current server.

Please note that the syntax for the placeholders is the same as for Ruby's `sprintf` function (see http://www.ruby-doc.org/core-2.0.0/Kernel.html#method-i-format).

Finally, a word on the `comment` attribute. Its default value, `true`, will simply use the name of the rule to comment it in the resulting rules file. Set it to `false` to not output any comment for the current rule, or simply set it to whatever `String` you want to be displayed as comment.

`diptables_tcp_udp_rule` Resource
---------------------------------

That resource is essentially an alias for `diptables_rule` resources to create rules for TCP or UDP connections. It defines the following self-explanatory attributes:


* table (default: 'filter')
* chain (default: 'INPUT')
* proto (default: 'tcp')
* jump (default: 'ACCEPT')
* comment (default: true)
* interface
* dport (which can be either a Fixnum - e.g. 80 - a String - e.g '9300:9400' - or an Array of Strings and Fixnums - e.g. [80, 443, '9200:9400' - in which case it uses the `multiport` iptables module])
* source (which can be either a string or an array of strings)

For instance, the following is equivalent to the 'ssh' example above:

    # Allow SSH
    diptables_tcp_udp_rule 'ssh' do
      dport 22
    end

It also supports the same querying system as the `diptables_rule` resources: just give a query in the `source_query` attribute. Optionally, you can specify what method to call on the resulting nodes to get their IP address (by default `ipaddress`) in the `source_method` attribute. Finally, the `same_environment` attribute works the same as for `diptables_rule` resources.
The example below shows a fairly complex rule:

    # Enable Elasticsearch servers to speak to each other
    diptables_tcp_udp_rule 'es_internal' do
        interface 'eth1'
        source_query 'roles:es-server'
        source_method 'internal_ipaddress'
        same_environment true
        dport [9200, '9300:9400']
    end

`diptables_policy` Resource
---------------------------

That resource is very much the same as the `simple_iptables_policy` one from Dan Crosta's `simple-iptables` cookbook.

It defines a default action for a given iptables chain. This is usually used to switch from a default-accept policy to a default-reject policy. For instance:

    # Reject packets other than those explicitly allowed
    diptables_policy 'drop_by_default' do
      policy 'DROP'
    end

Same as the `diptables_rules` resource, it defaults to the 'filter' table and the 'INPUT' chain, but you can redefine the `table` and `chain` attributes to whatever you want.

Example recipe
==============

You can have a look at the `diptables::example` recipe for examples on how to use the LWRPs.

You can also test my cookbook with Vagrant (see the 'Vagrant' section below).

Vagrant
=======

You can test this cookbook locally, provided you have a bunch of free software installed, namely [Vagrant](https://www.vagrantup.com/downloads), [Berkshelf](http://berkshelf.com/), [VirtualBox](https://www.virtualbox.org/), and a couple of Vagrant plugins: [Vagrant-Berkshelf](https://github.com/berkshelf/vagrant-berkshelf) and [Vagrant-Omnibus](https://github.com/schisamo/vagrant-omnibus).

Then playing with this cookbook should be as easy as running `bundle install && vagrant up`!

Chef-Solo
=========

As of version 0.1.5, you can use this cookbook's LWRPs with the `query` attribute as long as you have the [`chef-solo-search` cookbook (by edelight)](https://github.com/edelight/chef-solo-search) installed.

Contributing & Feedback
=======================

As always, I appreciate bug reports, suggestions, pull requests, feedback...
Feel free to reach me at <wk8.github@gmail.com>

Changes
=======

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
