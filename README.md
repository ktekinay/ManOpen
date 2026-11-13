# ManOpen

ManOpen provides a graphical interface for viewing Unix man pages, which are the standard documentation format on macOS for command line programs, programmer libraries, and other system processes.

ManOpen also supports Apropos, which performs a keyword search on the man pages installed on the computer. All Apropos searches are performed locally on your computer; ManOpen will not connect to the Internet for any reason whatsoever.

ManOpen can be useful for opening a man page without using the command line, browsing and searching through man pages, or for printing them out. Customization options for power users are provided.

ManOpen 3.x is based on ManOpen 2.x by Carl Lindberg, and ManOpen 1.x by Harald Schlangmann. This version has been greatly enhanced, with a new UI for macOS 11 ("Big Sur"), support for Dark Mode, native support for Apple Silicon Macs, plus several internal refactors and rewrites so the app will run on modern macOS releases. ManOpen requires macOS 12 ("Monterey") or later.

ManOpen is free software, licensed under the 3-clause (modified) BSD license. This program is provided "as is" and without any warranty. Source code is available on [GitHub](https://github.com/nickzman/ManOpen).

### Installation

Simply copy ManOpen.app to your computer's Applications folder, or wherever you want to put it.

ManOpen adds three services to your computer:

- **Open File in ManOpen** will attempt to open the selected file(s) in ManOpen, or fail silently if any can't be opened.
- **Open man Page in ManOpen** will take the selected text, and attempt to open a man page for each selected word.
- **Search man Page Index in ManOpen** will take the selected text, and search for man pages for each selected word.

As of macOS 11.0, like other macOS services, you can enable and disable these services in System Preferences, in the Keyboard preference pane, under the Shortcuts tab, under the Services table item. You may need to log out and log back in again after installing the app before the services will appear. Also, do note that some third party apps, particularly antivirus apps, are known to interfere with services.

### Using ManOpen from Terminal

ManOpen includes a command-line tool, `openman`, inside the app at `ManOpen.app/Contents/Helpers/openman`, with its man page at `ManOpen.app/Contents/Resources/man/man1/openman.1`. It opens man pages in ManOpen instead of in Terminal. To use it, link it into a folder on your `PATH`, for example:

```sh
sudo ln -s /Applications/ManOpen.app/Contents/Helpers/openman /usr/local/bin/openman
sudo ln -s /Applications/ManOpen.app/Contents/Resources/man/man1/openman.1 /usr/local/share/man/man1/openman.1
```

Then, for example, `openman ls` opens `ls`, `openman 3 printf` opens `printf` from section 3, `openman -k printf` searches with Apropos, and `openman -f file.1` opens a man page file. See `man openman` for details.

### Searching for man Pages

By default, ManOpen will look for man pages in the following locations:

1. `/usr/share/man` (where built-in macOS command line tool man pages are stored)
2. `/usr/local/man` (where third-party macOS command line tool man pages are stored)
3. Several additional paths used by commonly used first- and third-party developer tools and package managers, if they are installed:
   1. `/opt/X11/share/man` (XQuartz)
   2. `/sw/share/man` and `/opt/sw/share/man` (Fink)
   3. `/opt/local/share/man` (MacPorts)
   4. `/opt/homebrew/share/man` (Homebrew)
   5. `/Applications/Xcode.app/Contents/Developer/usr/share/man` (Xcode, used for its developer tools)
   6. `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man` (Xcode, used for the standard C library, and other macOS APIs)
   7. `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man` (Xcode, used for its compilers)
   8. `/Applications/CMake.app/Contents/man` (CMake GUI)

You can add additional paths as necessary in the Preferences window, under the Advanced tab. You can add a path by clicking the + button. If the path is inside a hidden folder or an application bundle, you can navigate into them by pressing Shift-Command-G to navigate to any arbitrary path.

### Building

ManOpen builds with current versions of Xcode, and requires macOS 12 or later. Open `ManOpen.xcodeproj` in Xcode and build the **ManOpen (Aggregate)** scheme, or build from the command line:

```sh
xcodebuild -project ManOpen.xcodeproj -scheme "ManOpen (Aggregate)" \
    -configuration Release -destination 'generic/platform=macOS' build
```

Building for the generic "Any Mac" destination (as above, or with Product ▸ Archive) produces a universal build for Apple silicon and Intel Macs. Building for "My Mac" builds only for your Mac's architecture.

To run the unit tests, use the **ManOpen** scheme (Product ▸ Test in Xcode), or:

```sh
xcodebuild -project ManOpen.xcodeproj -scheme ManOpen test
```

Code-signing settings are in `Config/Base.xcconfig`. To sign with your own identity, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and uncomment one of the options in it. Git ignores `Local.xcconfig`. Don't change signing in Xcode's Signing & Capabilities pane, because that edits the shared project file.

### Version History

Version 3.1:

- ManOpen now requires macOS 12 ("Monterey") or later.
- The `openman` command-line tool now uses the hardened runtime too, so every executable in a release can be notarized.
- You can now build and sign ManOpen with your own developer identity without editing the project file. See "Building" above.
- Removed obsolete build phases and settings left over from older versions of Xcode.
- Fixed man pages, searches, and File ▸ List Pages coming up empty when ManOpen was opened from Terminal (directly, with `open`, or by `openman`) and the shell's `PAGER` or `MANPAGER` was set to an interactive pager.
- Fixed windows reopened at launch (with "Close windows when quitting an app" off, or "Save windows on quit" on) coming back blank, with no title and "No manual entry". Windows that can't be restored, such as a file that has since been deleted, are no longer reopened.
- Fixed C library pages (sections 2 and 3, such as `printf(3)`) not being found, and missing from Apropos results. On current macOS these pages are installed only with Xcode or the Command Line Tools; ManOpen now searches man's default locations after the folders listed in Preferences.
- Fixed File ▸ List Pages ▸ 1–9 finding nothing, and ▸ n listing pages from every section. List Pages windows are now titled after the menu item, for example "Section 3 - Library Calls".
- Apropos and List Pages windows: the Name column always comes first; drag the divider to resize it, and Description fills the rest of the window. Click a column header to sort by it. The Name width and sort are remembered and apply to all open Apropos windows at once. Double-click anywhere on a row to open the page. Resting the pointer on text that's cut off shows all of it.
- Apropos and List Pages windows open much faster, especially File ▸ List Pages ▸ All Pages.
- Printing an Apropos or List Pages window now prints wrapped, readable columns with the column headings and page numbers on every page, and is much faster.
- The `openman` command-line tool is now included in the app, in `Contents/Helpers`. See "Using ManOpen from Terminal" above.
- `openman` now works with the right copy of ManOpen: an already running ManOpen, the app it's inside, or the newest installed copy of ManOpen 3.0 or later, never an older 2.x copy. It reports errors and exits with a non-zero status when it can't reach ManOpen.
- Links now use the system link color by default, so they're readable in Dark Mode and with Increase Contrast. If your link color was still the old default blue, it switches to the new default automatically; colors you chose are kept. A new **Restore Default Colors** button in Preferences ▸ Appearance goes back to the system colors.
- Printing a man page in Dark Mode now prints dark text on white paper, the same as in Light Mode, and doesn't print the window's background color.
- Added unit tests. See "Building" above.

Version 3.0:

- ManOpen now runs natively on Apple Silicon Macs, and requires macOS 10.9 or later. Support for older Macs has been discontinued.
- The UI has been updated to look like a modern macOS app as of macOS 11 ("Big Sur").
- The app has been internally rewritten in places to use modern memory management, auto-layout, the hardened runtime, and new APIs.
- Searching man pages is now done through a search bar instead of a find panel.
- The app now supports auto-termination, so it will disappear from the Dock when all its windows have been closed, and it'll automatically quit if it hasn't been used in a while. You don't have to manually quit the app anymore.
- The services have been renamed to make their function more clear.
- Fixed a bug where the "Copy URL" menu item used the incorrect URL scheme.