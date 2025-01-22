#!/bin/bash

# Define variables
SPLUNK_DIR="/opt/splunk"
BACKUP_DIR="/backups/splunk"
SPLUNK_PORT=8000

# 1. Update Splunk to the latest version
wget -O splunk-latest.rpm https://download.splunk.com/path-to-latest.rpm
rpm -Uvh splunk-latest.rpm
splunk apply shcluster-bundle

# 2. Enforce strong password policies
splunk edit auth ldap -minPwdLength 12 -mustChangePassword true
splunk enable auth-mfa

# 3. Implement rate limiting
splunk edit limits -rate_limit 500
iptables -A INPUT -p tcp --dport 9997 -m limit --limit 50/s --limit-burst 100 -j ACCEPT
splunk edit server -maxThreads 200

# 4. Protect log integrity
chattr +i $SPLUNK_DIR/var/log/splunk/*
mkdir -p $BACKUP_DIR
splunk backup data -location $BACKUP_DIR

# 5. Ensure service availability
systemctl enable splunk
chattr +i $SPLUNK_DIR/etc/system/local/*
(crontab -l ; echo "* * * * * $SPLUNK_DIR/bin/splunk restart") | crontab -

# 6. Secure forwarder connections
echo "sslPassword = securepass" >> $SPLUNK_DIR/etc/system/local/outputs.conf

# 7. Monitor installed apps
splunk display app list
find $SPLUNK_DIR/etc/apps -type f -mtime -1
splunk edit user admin -role limited_access

# 8. Disable malicious scheduled searches
splunk search "index=_internal sourcetype=scheduler"
splunk disable savedsearch -name malicious_search

# 9. Close unused ports
iptables -A INPUT -p tcp --dport 8089 -j DROP

# 10. Enable encryption
splunk edit server -sslEnable 1

echo "Splunk defense script executed successfully."