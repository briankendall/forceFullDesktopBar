#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Deactivate old launchctl if it's running

prevPID=$(pgrep forceFullDesktopBar)

if [ ! -z "$prevPID" ]; then
    launchctlInfo=`launchctl list | grep net.briankendall.forceFullDesktopBar`
    
    if [ -z "$launchctlInfo" ]; then
        killall -QUIT forceFullDesktopBar
    else
        echo Removing old launch daemon...
        launchctl remove net.briankendall.forceFullDesktopBar
    fi
    
    echo "Waiting for previous forceFullDesktopBar to terminate..."
    while s=`ps -p $prevPID -o stat=` && [[ "$s" && "$s" != 'Z' ]]; do
        sleep 0.1
    done
    
    echo "Restarting Dock..."
    interactiveUID=`scutil <<< "show State:/Users/ConsoleUser" | awk '/UID :/ { print $3 }'`
    # The safe way to restart the Dock:
    launchctl asuser $interactiveUID launchctl stop com.apple.Dock.agent
    launchctl asuser $interactiveUID launchctl start com.apple.Dock.agent
fi

mkdir -p /usr/local/forceFullDesktopBar
if [ "$?" -ne 0 ]; then echo "Failed to create /usr/local/forceFullDesktopBar"; exit 1; fi

# Remove previous files if they exist
# Apparently it's important to delete the existing files first, otherwise the
# new dylibs may not be properly injected after loading the launch daemon.

if [ -f "/usr/local/forceFullDesktopBar/bootstrap.dylib" ]; then
    rm /usr/local/forceFullDesktopBar/bootstrap.dylib
fi

if [ -f "/usr/local/forceFullDesktopBar/dockInjection.dylib" ]; then
    rm /usr/local/forceFullDesktopBar/dockInjection.dylib
fi

if [ -f "/usr/local/forceFullDesktopBar/forceFullDesktopBar" ]; then
    rm /usr/local/forceFullDesktopBar/forceFullDesktopBar
fi

if [ -f "/Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist" ]; then
    rm /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
fi

cp forceFullDesktopBar /usr/local/forceFullDesktopBar/forceFullDesktopBar
if [ "$?" -ne 0 ]; then echo "Could not copy forceFullDesktopBar. Make sure you're running this script in the directory that contains: forceFullDesktopBar, dockInjection.dylib, net.briankendall.forceFullDesktopBar.plist "; exit 1; fi

cp dockInjection.dylib /usr/local/forceFullDesktopBar/dockInjection.dylib
if [ "$?" -ne 0 ]; then echo "Could not copy dockInjection.dylib. Make sure you're running this script in the directory that contains: forceFullDesktopBar, dockInjection.dylib, net.briankendall.forceFullDesktopBar.plist "; exit 1; fi

# Copy and launch daemon using launchctl:
cp -f net.briankendall.forceFullDesktopBar.plist /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
if [ "$?" -ne 0 ]; then echo "Could not copy LaunchDaemon plist. Make sure you're running this script in the directory that contains: forceFullDesktopBar, dockInjection.dylib, net.briankendall.forceFullDesktopBar.plist "; exit 1; fi

chown root:wheel /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
chmod 644 /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
launchctl load /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist
if [ "$?" -ne 0 ]; then echo "Failed to load the LaunchDaemon"; exit 1; fi

echo "Finished"
