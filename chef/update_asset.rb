#
# Cookbook:: security-center
# Recipe:: update_asset
#
# Author: mpb10
#
# Description: This recipe moves the update_asset.sh script file to the
# Security Center box and creates a cron entry for it. This script gets a
# list of running hosts and uploads that list to an asset via REST API calls.

# Create the directory that stores the script if it's not there.
directory '/opt/sc/scripts' do
  mode '0750'
  owner 'root'
  group 'root'
end

# Move the script file into that directory if it's not there.
cookbook_file '/opt/sc/scripts/update_asset.sh' do
  source 'update_asset.sh'
  mode '0500'
  owner 'root'
  group 'root'
end

# Create a cron job for the script.
cron 'create-cron-job' do
  minute '59'
  command '/opt/sc/scripts/update_asset.sh'
end
