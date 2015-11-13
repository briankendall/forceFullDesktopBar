#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Copy files:
mkdir -p /usr/local/forceFullDesktopBar
if [ "$?" -ne 0 ]; then echo "Failed to create /usr/local/forceFullDesktopBar"; exit 1; fi

cp forceFullDesktopBar /usr/local/forceFullDesktopBar/
if [ "$?" -ne 0 ]; then echo "Could not copy forceFullDesktopBar. Make sure you're running this script for the directory that contains: forceFullDesktopBar, bootstrap.dylib, dockInjection.dylib, net.briankendall.forceFullDesktopBar.plist "; exit 1; fi

cp bootstrap.dylib /usr/local/forceFullDesktopBar/
if [ "$?" -ne 0 ]; then echo "Could not copy bootstrap.dylib. Make sure you're running this script for the directory that contains: forceFullDesktopBar, bootstrap.dylib, dockInjection.dylib, net.briankendall.forceFullDesktopBar.plist "; exit 1; fi

cp dockInjection.dylib /usr/local/forceFullDesktopBar/
if [ "$?" -ne 0 ]; then echo "Could not copy dockInjection.dylib. Make sure you're running this script for the directory that contains: forceFullDesktopBar, bootstrap.dylib, dockInjection.dylib, net.briankendall.forceFullDesktopBar.plist "; exit 1; fi

# Copy and launch daemon using launchctl:
cp net.briankendall.forceFullDesktopBar.plist /Library/LaunchDaemons/
if [ "$?" -ne 0 ]; then echo "Could not copy LaunchDaemon plist. Make sure you're running this script for the directory that contains: forceFullDesktopBar, bootstrap.dylib, dockInjection.dylib, net.briankendall.forceFullDesktopBar.plist "; exit 1; fi

chown root:wheel /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
chmod 644 /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
launchctl load /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
if [ "$?" -ne 0 ]; then echo "Failed to load the LaunchDaemon"; exit 1; fi

echo "Finished"
