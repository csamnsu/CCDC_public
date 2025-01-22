#!/bin/bash

# Define variables
SPLUNK_DIR="/opt/splunk"
BACKUP_DIR="/backups/splunk"
SPLUNK_PORT=8000
SPLUNK_USER="splunk"

# 1. Update Splunk to the latest version
wget -O splunk-latest.rpm https://download.splunk.com/path-to-latest.rpm
rpm -Uvh splunk-latest.rpm
splunk apply shcluster-bundle

# 2. Enforce strong password policies
splunk edit auth ldap -minPwdLength 12 -mustChangePassword true
splunk enable auth-mfa

# 3. Fix permissions issues
chown -R $SPLUNK_USER:$SPLUNK_USER $SPLUNK_DIR/var/log/splunk
chmod -R 755 $SPLUNK_DIR/var/log/splunk
chattr -i $SPLUNK_DIR/var/log/splunk/*

# 4. Check and disable SELinux temporarily
setenforce 0

# 5. Implement adaptive monitoring
splunk search "index=_audit action=login" | awk '{print $3}' | sort | uniq -c | sort -nr | head -10
splunk search "index=_internal sourcetype=splunkd_access" | grep -i failed

# 6. Protect log integrity
mkdir -p $BACKUP_DIR
splunk backup data -location $BACKUP_DIR

# 7. Ensure service availability
systemctl enable splunk
chattr +i $SPLUNK_DIR/etc/system/local/*
(crontab -l ; echo "* * * * * $SPLUNK_DIR/bin/splunk restart") | crontab -

# 8. Secure forwarder connections dynamically
splunk search "index=_internal sourcetype=splunkd" | awk '{print $4}' | sort | uniq -c | sort -nr | head -10

# 9. Monitor installed apps
splunk display app list
find $SPLUNK_DIR/etc/apps -type f -mtime -1
splunk edit user admin -role limited_access

# 10. Disable malicious scheduled searches
splunk search "index=_internal sourcetype=scheduler"
splunk disable savedsearch -name malicious_search

# 11. Close unused ports dynamically
netstat -tuln | grep LISTEN
iptables -A INPUT -p tcp --match multiport --dports 22,9997,8089 -j ACCEPT

# 12. Enable encryption
splunk edit server -sslEnable 1

# 13. Restart Splunk with correct user
sudo -u $SPLUNK_USER $SPLUNK_DIR/bin/splunk start

# 14. Kill any conflicting processes
pkill -f splunk

echo "Splunk defense script executed successfully."
