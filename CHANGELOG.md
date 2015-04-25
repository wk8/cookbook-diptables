# CHANGELOG for diptables

This file is used to list changes made in each version of diptables.

## 1.0.0:
* Added full support for CentOS 6.5
* Added `rspec` tests
* Added Test-Kitchen tests for all supported platforms and Chef versions
* Migrated the applying logic to the `diptables_apply` resource

## 0.2.0:
* Added the `diptables_bpf_rule` resource

## 0.1.6:

* Included Vagrant & Berkshelf for easier development

## 0.1.5:

* Enabling the use of the search queries with Chef-Solo if the `chef-solo-search` cookbook is installed
* Enforcing that the default recipe runs after LWRPs have been defined in a smoother way

## 0.1.4:

* Sorting the query's results to avoid reloading iptables unnecessarily

## 0.1.3:

* Forcing the flush of the test chain, fixing a possible bug when a previous Chef-client run has been killed half-way through

## 0.1.2:

* Forcing the iptables reload action when disabling the `dry_run` mode
* Fixing possible name collision

## 0.1.1:

* Added the `comment` attribute

## 0.1.0:

* Initial release of diptables
