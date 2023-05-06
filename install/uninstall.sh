#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

interactiveUID=`scutil <<< "show State:/Users/ConsoleUser" | awk '/UID :/ { print $3 }'`

if test -f "/usr/local/forceFullDesktopBar/bootstrap.dylib"; then
    rm /usr/local/forceFullDesktopBar/bootstrap.dylib
fi

rm /usr/local/forceFullDesktopBar/forceFullDesktopBar
rm /usr/local/forceFullDesktopBar/dockInjection.dylib
rmdir /usr/local/forceFullDesktopBar
rm /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
launchctl remove net.briankendall.forceFullDesktopBar

# Wait for app to fully quit:

prevPID=$(pgrep forceFullDesktopBar)
if [ ! -z "$prevPID" ]; then
    echo "Waiting for forceFullDesktopBar to terminate..."
    while s=`ps -p $prevPID -o stat=` && [[ "$s" && "$s" != 'Z' ]]; do
        sleep 0.1
    done
fi

echo "Restarting Dock..."
# The safe way to restart the Dock:
launchctl asuser $interactiveUID launchctl stop com.apple.Dock.agent
launchctl asuser $interactiveUID launchctl start com.apple.Dock.agent

echo "Uninstalled"
