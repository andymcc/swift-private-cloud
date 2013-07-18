#
# Cookbook Name:: swift-private-cloud
# Recipe:: management-server
#
# Copyright 2013, Rackspace US, Inc.
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
include_recipe "swift-lite::management-server"

contrib_files = ["drivescout_wrapper.sh", "setup_drives.sh",
                 "setup_local_swiftops.sh", "setup_remote_swiftops.exp",
                 "udev_drive_rules.sh"]

contrib_files.each do |file|
  cookbook_file "/usr/local/bin/#{file}" do
    source "management/usr/local/bin/#{file}"
    user "root"
    mode "0755"
  end
end