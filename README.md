# Force Full Desktop Bar

This is a utility for OS X 10.11 El Capitan that changes the behavior of Mission Control so that the desktop bar is always full size and showing previews of the desktops, just like it was in Yosemite and earlier. It's for users like myself who really hate that particular change Apple made in El Capitan and find that it constantly interrupts their workflow and causes much frustration.

This is accomplished by injecting code in the Dock process. Granted I'm not all that good with tinkering around in binaries and looking at disassembled / decompiled code, but unfortunately I didn't find any hidden preference for doing this. Obviously that would be a much better way of doing this, and I sincerely hope someone finds one that I missed. If there isn't, however, maybe we'll get lucky and Apple will decide to add a proper setting or hidden preference for bringing back the old Mission Control behavior. But I'm not feeling too optimistic about that.

### Installation (easy / automatic)

1. First, since this utility injects code into the Dock, you must first disable System Integrity Protection. However, it's not necessary to disable it completely — just the parts that prevent you from injecting code into Apple processes. It's not possible to do this when OS X is running normally; you'll have to reboot your computer into the Recovery Mode and disable it from there. Here's how to do it:

  1. Boot into Recovery Mode: restart your Mac and hold Command+Option+R
  2. Once the main Recovery Mode window appears (i.e. OS X Utilities), open the Utilities menu and pick Terminal
  3. Type the following into the terminal window and press return:
    * `csrutil enable --without debug`
  4. Reboot your system:
    * `reboot`
2. Back in normal OS X, open Terminal.app
3. Navigate to where you downloaded the release of forceFullDesktopBar
  * `cd /path/to/forceFullDesktopBar`
  * or, if you cloned the repo, navigate to forceFullDesktopBar/install
4. Execute install.sh as root
  * `sudo ./install.sh`
  * Type in your administrator password when prompted.

That should install the daemon and modify the Dock process. Mission Control is now back to the way you want it. Furthermore, if the Dock should crash or any new users log in, the daemon will automatically modify the Dock process again.

### Installation (manual)

1. Follow the step 1 in the above "Installation (Easy)" instructions to disable the debugging restrictions of System Integrity Protection.
2. Create the following directory:
  * /usr/local/forceFullDesktopBar
3. Copy bootstrap.dylib, dockInjection.dylib, and forceFullDesktopBar into /usr/local/forceFullDesktopBar
4. Copy net.briankendall.forceFullDesktopBar.plist to /Library/LaunchDaemons
5. Change the owner/group of net.briankendall.forceFullDesktopBar.plist to root:wheel:
  * `sudo chown root:wheel /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist`
6. Change the permissions of net.briankendall.forceFullDesktopBar.plist to 644:
  * `sudo chmod 644 /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist`
7. Execute the following as root:
  * `sudo launchctl load /Library/LaunchDaemons/net.briankendall.forceFullDesktopBar.plist`

### Uninstallation

Either run the provided uninstallation script (uninstall.sh) as root, or delete all the files listed in the manual installation instructions yourself and then execute the following as root:
`launchctl remove net.briankendall.forceFullDesktopBar`

### Advanced use

forceFullDesktopBar can be executed on its own, and has two command line arguments:

`-u <uid>`

* Only modifies the Dock process for the user with the given UID.

`-d`

* Runs the app as a daemon, constantly monitoring Dock processes and modifying new ones.

When forceFullDesktopBar is not run as a daemon, it will try to inject its payload into all the current Dock processes (or just the ones for one user if -u is used) and then exit. The launchd property file (net.briankendall.forceFullDesktopBar.plist) will launch the process as a daemon when the system starts up and ensure it keeps running.

forceFullDesktopBar requires both bootstrap.dylib and dockInjection.dylib in order to work. It will first look for both files in the current directory, and if it doesn't find them, it will look for them in /usr/local/forceFullDesktopBar/

### Is this safe???

You might be thinking that injecting code into the Dock process sounds pretty fishy, and are suspicious of this software. You also might not like the idea of disabling System Integrity Protection. These are all valid worries and if you feel strongly that they're worrisome enough to prevent you from using this tool, then you probably shouldn't.

That said, I'm not too worried about disabling System Integrity Protection. For one, the only part that has to be disabled is the part that restricts debugging and injecting code into Apple processes. That's a new security measure starting with OS X 10.11, and for all previous versions of OS X I have **never** had a problem with any software, malicious or otherwise, injecting code into Apple processes and causing problems. Never. Hell, I haven't even once had a piece of malware get onto one of my OS X systems, and what malware I have encountered on other people's systems generally doesn't *need* to inject any code into Apple processes. It can wreck havoc on your computer, steal your data, or cause annoying ads to pop up uninhibited with SIP running, provided someone made the unfortunate mistake of giving it root access by typing in their admin password when they shouldn't have.

As for injecting code into the Dock process, the particular way forceFullDesktopBar modifies the Dock is quite safe. You can look at the source code yourself — dockInjection.m in particular — if you want to, but the only thing it's doing is dynamically swizzling the _missionControlSetupSpacesStripControllerForDisplay:showFullBar: method of the WVExpose class. The new method its replacing it with just calls the old method, except it passes in true for the showFullBar parameter. It's hard for there to be a more clean and safer way to change an app's behavior through injection than something like that — there's no question what the 'showFullBar' parameter is for!

Anyway, if something does go wrong as a result of using this software, which I admit is always a possibility, especially with shady stuff like code injections, all you have to do is terminate the process and restart the Dock process to get back to normal. Or if things get really screwed up, just delete the forceFullDesktopBar binary and/or LaunchDaemon plist and reboot.

### Why go through all of this trouble?

When I first started using El Capitan, I immediately knew I was going to have a hard time with the new Mission Control UI. My muscle memory is pretty hard-wired to move the cursor to specific spots on the screen to change desktops. Furthermore, the new way of interacting with it is very problematic. Let me break it down.

Negative effects of the new Mission Control UI:
- Makes the clickable area for changing desktops smaller
- No longer provides a preview of the various desktops
- Accidentally mousing over the wrong desktop button causes all of the desktop buttons to shift as the bar expands to full size, causing the user to have to examine it and decide where to move the mouse in order to click the right one
- Reduces clarity about what the different desktops actually are and why someone would use them
- Causes the UI and its context to change when clicking and dragging a window

And just to be fair, I can identify a few marginally positive effects of this change:
- Slightly increases vertical real estate for the windows below the desktop bar, allowing them to be just a little bit bigger
- Makes the Mission Control UI at least initially appear a little bit simpler looking

So frankly this is a pretty bad user experience degradation. There's almost no benefit to this change — increasing the vertical area for the windows solves nothing and is completely unnecessary — and it causes a lot of problems. The biggest one, at least for me, is absolutely that it changes the act of switching Desktops via Mission Control from a simple point-and-click operation to something that easily could require me to focus on what the UI is doing. That might seem subtle and nit-picky, but the best UI is the kind that barely requires any thought when using it, or what thought you are engaged in is just thinking about what you're trying to do, e.g. switch windows or desktops. Problematic UIs require you to focus on the actual UI and figure out how to accomplish whatever it is you're doing, and this change to Mission Control moves it from the former to the latter.

### Other info

This project uses code from James Robson's OS X injection tutorial located here: http://soundly.me/osx-injection-override-tutorial-hello-world/

It also uses mach_inject by Jonathan Rentzsch, also used by the OS X injection tutorial.