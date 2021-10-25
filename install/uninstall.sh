#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if test -f "/usr/local/forceFullDesktopBar/bootstrap.dylib"; then
    rm /usr/local/forceFullDesktopBar/bootstrap.dylib
fi

rm /usr/local/forceFullDesktopBar/forceFullDesktopBar
rm /usr/local/forceFullDesktopBar/dockInjection.dylib
rmdir /usr/local/forceFullDesktopBar
rm /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
launchctl remove net.briankendall.forceFullDesktopBar

# Give app a moment to fully quit:
sleep 0.5
killall Dock

echo "Uninstalled"
