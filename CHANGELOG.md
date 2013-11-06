# CHANGELOG for diptables

This file is used to list changes made in each version of iptables.

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

* Initial release of iptables
