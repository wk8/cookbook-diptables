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


Attributes
==========

This cookbook uses only one attribute: `diptables_rules_path`, which is the path to which we should save the current iptables rules set.

That attribute is optional. It defaults to sensible locations depending on your distribution.


Usage
=====

This cookbook defines two LWRPS: `diptables_rule` and `diptables_policy`, that you can use in your recipes, after telling Chef! that your cookbook depends on this one (just put `depends 'diptables'` in your `metadata.rb` file).

Please note that you need to include the `recipe[diptables]` in your run list *AFTER* the recipe(s) using these resources to actually commit your changes (will crash anyway otherwise).

`diptables_rule` Resource
-------------------------

In its simpler form, that resource defines a single iptables rule, composed of a rule string (passed as-is to iptables), a table name, a chain name, and a jump target. Only the rule is mandatory, the other three default respectively to 'filter', 'INPUT', and 'ACCEPT'. For instance:

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

`diptables_policy` Resource
---------------------------

That resource is very much the same as the `simple_iptables_policy` one from Dan Crosta's `simple-iptables` cookbook.

It defines a default action for a given iptables chain. This is usually used to switch from a default-accept policy to a default-reject policy. For instance:

    # Reject packets other than those explicitly allowed
    diptables_policy 'drop_by_default' do
      policy 'DROP'
    end

Same as the `diptables_rules` resource, it defaults to the 'filter' table and the 'INPUT' chain, but you can redefine the `table` and `chain` attributes to whatever you want.


Changes
=======

* 0.1.0 (Sep 11, 2013)
    * Initial release

