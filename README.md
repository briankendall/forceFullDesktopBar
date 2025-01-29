# Force Full Desktop Bar

This is a utility for macOS 10.11 and macOS 10.13 and later (including macOS 14 and 15) that changes the behavior of Mission Control so that the desktop bar is always full size and showing previews of the desktops, just like it was in macOS 10.10 and earlier. It's for users like myself who really hate that particular change Apple made in El Capitan and find that it constantly interrupts their workflow and causes much frustration.

This is accomplished by injecting code in the Dock process and modifying its behavior. Unfortunately I didn't find any hidden preference for doing this, which would of course be a lot better. Maybe we'll get lucky and Apple will decide to add a proper setting or hidden preference for bringing back the old Mission Control behavior. However we're three major macOS releases in and they still haven't done it, so that probably won't ever happen.

**Note:** if you don't want to disable System Integrity Protection or are otherwise uncomfortable with an app injecting code into the Dock, then you can try [missionControlFullDesktopBar](https://github.com/briankendall/missionControlFullDesktopBar), a standalone app that triggers Mission Control with the full desktop bar without modifying the Dock. It's clunkier and a little harder to set up, but gets the job done.

### Installation (easy / automatic)

1. First, since this utility injects code into the Dock, you must first disable System Integrity Protection. In macOS 11 Big Sur it is necessary to completely disable it as just disabling debugging protections no longer works. In macOS 10.15 and earlier you can just disable the parts that prevent you from injecting code into Apple processes (though you can also disable it completely if you prefer). It's not possible to do this when macOS is running normally; you'll have to reboot your computer into the Recovery Mode and disable it from there. Here's how to do it:

    1. Boot into Recovery Mode using the instructions in this Apple support document: [About macOS Recovery](https://support.apple.com/guide/mac-help/about-macos-recovery-mchl46d531d6/mac)
    2. Once the main Recovery Mode window appears (it will read "macOS Utilities" or "OS X Utilities"), open the Utilities menu and pick Terminal
    3. If you're running macOS 11 (Big Sur), type the following into a terminal window and press return:    
       `csrutil disable`    
       If you're running macOS 10.14 or 10.15, type the following into the terminal window and press return:    
       `csrutil enable --without debug --without fs`    
       If you're running macOS 10.13 or earlier, type the following into the terminal window and press return:    
       `csrutil enable --without debug`
    4. Reboot your system:    
       `reboot`
    5. If your mac has an Apple Silicon chip, after your computer boots up normally, open Terminal and execute the following, entering your admin password when prompted:    
       `sudo nvram boot-args=-arm64e_preview_abi `   
       ...and then reboot one more time. (Phew! They don't make this easy.)
2. Back in normal macOS, open Terminal
3. Navigate to where you downloaded the release of forceFullDesktopBar.
  * `cd /path/to/forceFullDesktopBar`    
  <sub>(Note: this will not work if you cloned the repo instead of downloading a release! In that case you must first open the Xcode project and build the "Copy to install folder" target.)</sub>
4. Execute install.sh as root
  * `sudo ./install.sh`
  * Type in your administrator password when prompted.

That should install the daemon and modify the Dock process. Mission Control is now back to the way you want it. Furthermore, if the Dock should crash or any new users log in, the daemon will automatically modify the Dock process again.

### Installation (manual)

1. Follow the step 1 in the above "Installation (Easy)" instructions to disable the necessary restrictions of System Integrity Protection, and if you have an Apple Silicon mac, enable running of arm64e applications.
2. Create the following directory:
  * /usr/local/forceFullDesktopBar
3. Copy dockInjection.dylib and forceFullDesktopBar into /usr/local/forceFullDesktopBar
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

forceFullDesktopBar requires dockInjection.dylib in order to work. It will first look for this file in the current directory, and if it doesn't find it, it will look for it in /usr/local/forceFullDesktopBar/

### Building

As of version 1.2, forceFullDesktopBar uses Frida to do its code injection and function swapping, as its the only library I've found that can do so on Apple Silicon systems. However, Frida is a very heavy-weight library and isn't intended just for simple cases of code injection and function swapping. Consequently Frida's static libraries are too large to include in a GitHub repository, especially when combined together into a fat library, as required by Xcode.

So to build forceFullDesktopBar, first run the bash script named `setup.sh` with the current directory at the root of the project. It will automatically fetch the needed archives from Frida's releases on GitHub, extract the needed static libraries, combine them into fat x86_64 / arm64e libraries, and move them into the right places in the project hierarchy. The script is currently set to download Frida 16.6.6 as that is the latest release as of the time of this writing, but newer releases will probably work too.

Afterwards, open the Xcode project and build the ""Copy to install folder" target. You should now be set up to follow the above installation instructions.

### And what of macOS 10.12?

Unfortunately I was never able to find a suitable method of accomplishing this in macOS 10.12's version of the Dock. Starting in 10.13, having the cursor be at the top of the screen would cause Mission Control to open with the full desktop bar, which provided a new means of hacking it. But in 10.12 it would probably require manually overriding a function by its address, which is fairly unstable and dangerous. I'd rather not do that. Fortunately not many people are running 10.12 any longer so I don't think it's _too_ big of a deal that it's not supported.

### Is this safe???

You might be thinking that injecting code into the Dock process sounds pretty fishy, and are suspicious of this software. You also might not like the idea of disabling System Integrity Protection. These are all valid worries and if you feel strongly that they're worrisome enough to prevent you from using this tool, then you probably shouldn't.

That said, I'm not too worried about disabling System Integrity Protection. For one, the only part that has to be disabled is the part that restricts debugging and injecting code into Apple processes (and filesystem protections in 10.14). That's a new security measure starting with 10.11, and for all previous versions of macOS I never had a problem with any software, malicious or otherwise, injecting code into Apple processes and causing problems. Never. I haven't even once had a piece of malware get onto one of my macs, and what malware I have encountered on other people's systems generally doesn't *need* to inject any code into Apple processes. It can wreck havoc on your computer, steal your data, or cause annoying ads to pop up uninhibited with SIP running, provided someone made the unfortunate mistake of giving it root access by typing in their admin password when they shouldn't have.

As for injecting code into the Dock process, in macOS 10.11, the particular way forceFullDesktopBar modifies the Dock is quite safe. You can look at the source code yourself — dockInjection.m in particular — if you want to, but the only thing it's doing is dynamically swizzling the _missionControlSetupSpacesStripControllerForDisplay:showFullBar: method of the WVExpose class. The new method its replacing it with just calls the old method, except it passes in true for the showFullBar parameter. It's hard for there to be a more clean and safer way to change an app's behavior through injection than something like that — there's no question what the 'showFullBar' parameter is for!

In macOS 10.13 and later it's a _little_ bit more hacky, but still relatively safe. Methods are still being replaced by name or by a visible symbol in the binary, and the way the behavior of the Dock is modified is unlikely to cause any serious issues as it's tricking the Dock into thinking that the mouse cursor is at the top of the screen for the moment that Mission Control is activated. This only happens when entering into Mission Control, and the Dock's behavior shouldn't change in any other circumstance.

Anyway, if something does go wrong as a result of using this software, which I admit is always a possibility especially with shady stuff like code injections, all you have to do is terminate the process and restart the Dock process to get back to normal. Or if things get really screwed up, just delete the forceFullDesktopBar binary and/or LaunchDaemon plist and reboot.

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

This project makes extensive use of [Frida](https://frida.re) for code injection and function swapping, specifically its core and gum devkits.
