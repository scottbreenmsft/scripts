#!/bin/bash
echo "Downloading Teams CDN" | tee -a /var/log/install.log
curl -L -o /tmp/teams.pkg 'https://go.microsoft.com/fwlink/p/?linkid=869428' | tee -a /var/log/install.log

echo "Installing Teams" | tee -a /var/log/install.log
installer -pkg /tmp/teams.pkg -target / | tee -a /var/log/install.log

echo "Removing tmp files" | tee -a /var/log/install.log

rm -rf /tmp/teams.pkg | tee -a /var/log/install.log
