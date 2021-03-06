#
# Cookbook Name:: swift-private-cloud
# Recipe:: common
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "swift-private-cloud::attr-remap"
include_recipe "swift-private-cloud::packages"
include_recipe "swift-lite::ntp"
include_recipe "swift-private-cloud::logging"
include_recipe "swift-private-cloud::mail"
include_recipe "swift-private-cloud::snmp"
include_recipe "swift-private-cloud::sysctl"
include_recipe "swift-lite::common"
include_recipe "git"


# /etc/cron.d
service "swift-storage-cron" do
  service_name "crond"
  action :nothing
end

# /etc/cron.d
service "swift-common-cron" do
  service_name "crond"
  action :nothing
end

template "/etc/cron.d/swift_ring_check" do
  source "common/etc/cron.d/swift_ring_check.erb"
  notifies :reload, "service[swift-common-cron]", :delayed
end

# /etc/default
template "/etc/default/irqbalance" do
  source "common/etc/default/irqbalance.erb"
  only_if { platform_family?("debian") }
end

template "/etc/default/megaclisas-statusd" do
  source "common/etc/default/megaclisas-statusd.erb"
  only_if { platform_family?("debian") }
end

# /etc/exim4
if not node["swift-private-cloud"]["mailing"]["smarthost"]
    nodelist = get_nodes_by_recipe("swift-private-cloud::admin-server")
    if nodelist.length == 0
      raise "Must specify swift-private-cloud/mailing/smarthost"
    end

    node.default["swift-private-cloud"]["mailing"]["smarthost"] = get_ip_for_net("swift-management", nodelist[0])
end

template "/etc/exim4/update-exim4.conf.conf" do
  source "common/etc/exim4/update-exim4.conf.conf.erb"
  variables(
    :outdomain => node["swift-private-cloud"]["mailing"]["outgoing_domain"],
    :smarthost => node["swift-private-cloud"]["mailing"]["smarthost"]
  )
  notifies :run, "execute[update-exim-config]", :delayed
  only_if { platform_family?("debian") }
end

template "/etc/exim/exim.conf" do
  source "common/etc/exim4/exim.conf.erb"
  variables(
    :outdomain => node["swift-private-cloud"]["mailing"]["outgoing_domain"],
    :smarthost => node["swift-private-cloud"]["mailing"]["smarthost"]
  )
  notifies :restart, "service[#{node['exim']['platform']['service']}]", :delayed
  only_if { platform_family?("rhel") }
end

# /etc/logrotate.d
template "/etc/logrotate.d/swift" do
  source "common/etc/logrotate.d/swift.erb"
end

# /etc/snmp
template "/etc/snmp/snmp.conf" do
  source "common/etc/snmp/snmp.conf.erb"
  notifies :restart, "service[#{node['snmp']['platform']['service']}]", :delayed
end

template "/etc/snmp/snmpd.conf" do
  source "common/etc/snmp/snmpd.conf.erb"
  notifies :restart, "service[#{node['snmp']['platform']['service']}]", :delayed
end

# /etc/swift
template "/etc/swift/internal-proxy-server.conf" do
  source "common/etc/swift/internal-proxy-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/log-processor.conf" do
  source "common/etc/swift/log-processor.conf.erb"
  owner "swift"
  group "swift"
  variables(
    :processing_account => "swift"
  )
end

template "/etc/swift/mime.types" do
  source "common/etc/swift/mime.types.erb"
  owner "swift"
  group "swift"
end

# /etc/syslog-ng
template "/etc/syslog-ng/conf.d/swift-ng.conf" do
  source "common/etc/syslog-ng/conf.d/swift-ng.conf.erb"
  variables(
    :remote_syslog_ip => node["swift-private-cloud"]["swift_common"]["syslog_ip"]
  )
  notifies :reload, "service[syslog-ng]", :delayed
end

# /etc
template "/etc/aliases" do
  source "common/etc/aliases.erb"
  variables(
    :email_addr => node["swift-private-cloud"]["mailing"]["email_addr"],
    :pager_addr => node["swift-private-cloud"]["mailing"]["pager_addr"]
  )
end

resources("template[/etc/ntp.conf]") do
  cookbook "swift-private-cloud"
  source "common/etc/ntp.conf"
end

template "/etc/rc.local" do
  source "common/etc/rc.local.erb"
end

# /usr/local/bin


# if the pull-ring sufficies, we'll use that
#

# template "/usr/local/bin/retrievering.sh" do
#   source "common/usr/local/bin/retrievering.sh.erb"
#   user "root"
#   mode "0700"
# end

# template "/usr/local/bin/ringverify.sh" do
#   source "common/usr/local/bin/ringverify.sh.erb"
#   user "root"
#   mode "0700"
# end

template "/usr/local/bin/pull-rings.sh" do
  source "common/usr/local/bin/pull-rings.sh.erb"
  user "swift"
  group "swift"
  mode "0700"
  variables( :repo => node["swift-private-cloud"]["versioning"]["repository_name"],
             :builder_ip => node["swift-private-cloud"]["versioning"]["repository_host"],
             :service_prefix => platform_family?("debian") ? "" : "openstack-" )
  only_if "/usr/bin/id swift"
end
