[[toc]]
----
----
=A micro HTTP applet server V0.99 - 2012/2/4=
* I appologize for writing with an inconsistent organization.  I wrote this over a long period of time and I priotize the addition of features over documentation editing.  Programming is more fun:)
* V0.99 because I am calling it feature complete and am planning no more feature addition.  Of course good ideas come along all the time so I might still add, just that I'm not planning a lot
==An introductory demo==
* [[/ls.pl?path=./docs_demo/index.txt|A guided tour of l00httpd features]]
* Doesn't belong here but it's a useful one to have handy: [[/edit.pl?path=./l00httpd.cfg|edit l00httpd.cfg]]
==Why should you be interested==
* If you are willing to put up with the hassle of installing SL4A, the Perl environment for Android, and copying some l00httpd script files, you can:
** Use a simple Wiki, with the usual Wiki benefits:
*** Renders regular texts as HTML pages
*** Links to other HTML pages using WikiWords (this one is an example and is a broken link)
*** Easily create new pages just by typing
** In addition, some Wiki enhancements allow you to:
*** Easily make a bookmark page with one URL per line that produce a high density page.  You can see 30 or more links on a single screen without scrolling.  Great for very quickly browse to your favorite destinations, or to your local Personal Digital Assistants stuff
*** Find in file with links and find files with line numbers
** Because they are simple text files and Perl, which is almost universally available, as long as you have your data backed up, you can be up and running with all your data on any desktop or netbook or tablet computers.  It is the ultimate data and application portability
==Power Users' Hightlights==
* Simple Wiki engine: Wikiword links, auto HTTP links, collapsible TOC, bullets, table
* One click to put pre-defined text into Android clipboard, very useful for pasting into [[http://code.google.com/p/connectbot/|connectBot]]: you could have a page listing dozens of links, each of them a pre-defined Linux command string for sending to a remote console terminal
* Blowfish encryption for data security
* Restrict access by IP address, e.g. sharing using public Wifi (SSL not supported; but complete security possible through SSH server)
* Shells commands entered on the web interface
* (Perl) 'do' a file entered on the web interface
* (B)Logging: prepends with date/time stamp
* Converts tab delimited table (e.g. copied from Excel) into wiki table.  Copy/delete a table column
* Develop directly on the phone since only a text editor is needed to create and modify Perl scripts.
* Logging of netstat and ifconfig results.  ifconfig reported total network traffic so you can plot usage vs. time.  netstat reports remote connections so you can find out who talks to what.
** Note that the above relies on a working busybox or actual ifconfig or netstat.  These are natively available on my Motorola Cliq without rooting; you may have to root your phone if they are not natively available.
==What is it==
* It is a framework and a collection of short Perl scripts that can be run from any Perl platforms, including the Android Perl intepreter [[http://code.google.com/p/android-scripting/|SL4A]] on the Android phones
* It allows additional HTTP based applets to be developed, modified, and served on the phone itself
** It is not truely HTTP server because while the HTTP protocol is used, only a bare minimal is used to support my intended use. For example it does not use the Perl scripts in the standard cgi-bin manner.
* It allows one to create applets in Perl (in 200-300 lines) while taking advantage of any web browser as the GUI front end
* Currently it provides several useful utilities that I use a lot:
** A directory and file browser
** Search for file by name and find in file with jump to file.  Optionally find on page with link to wiki section header
** A primitive wikitext renderer (just fine for viewing this page) and editor
** A calendar display. The number of weeks to display can be set from the browser
** A 5-minute timeline display for time management of today's tasks
** A periodic task that can be scripted to poll web site, e.g. Twitter follower count (there is an example monitoring PressSec)
** And many more
* If you don't want to program in Perl, you can simply use whatever I have provided
* If you do program on Perl, it is a really simple environment to add web based applets
==Installation==
* Download l00httpd_v0.24.zip or the latest release from https://sourceforge.net/downloads/l00httpd/
** If you are upgrading and are setup like me, the data are in a separate directory and should have no compatibility issue; they are just simple text files after all
** You probably need something to handle the .zip file.  I use ASTRO, available from the Market.  It moves files too
* You need to install the [[http://code.google.com/p/android-scripting/|Android SL4A and the Perl interpreter]]
** Quoting the site: "To install SL4A, you will need to enable the "Unknown sources" option in your device's "Application" settings"
** On the 'Featured downloads' pane on the right hand side, download:
*** sl4a_r3.apk and install first
**** See http://code.google.com/p/android-scripting/wiki/FAQ#How_do_I_install_SL4A?
*** perl_for_android_r1.apk and install second
***** See http://code.google.com/p/android-scripting/wiki/InstallingInterpreters
* On Motorola Cliq, and probably all Android phones, unzip the content of l00httpd_v0.24.zip to /sdcard/sl4a/scripts
** You may need ASTRO to handle .zip download and unzipping.  You can get ASTRO from the Market
** Move all *.pm to /sdcard/com.googlecode.perlforandroid/extras/perl/site_perl
** On desktop computers you can unzip to any where 
* I recommend putting your personal data in the directory /sdcard/l00httpd; create it as necessary
* Run 00l00httpd.pl from the SL4A in background (Start in Background)
** The '00' prefix makes it the first in the sorted list of files
* Use a web browser and browse to http://localhost:20337
** ID: p
** Password: p
** You can change it too, just edit 00l00httpd.pl
* For advanced users, you can also run the whole thing on the desktop
** This is one great way for backup/data redundancy.  Even if you lost your phone, if you have your recent backup, you can be up and running on any desktop, or any other phone that supports Perl
** Windows
*** You need Perl and Cygwin; but it probably will run without Cygwin and will just miss some features
*** Unzip content to say c:\l00httpd and cd to it
*** perl 00l00httpd.pl
*** Browse to http://localhost:20337
** Linux
*** Unzip content to /home/mydir/l00httpd
*** perl 00l00httpd.pl
*** Browse to http://localhost:20337
** Fix up any path issues as the default is for the Android phone
==Quick Start==
* Browse to http://localhost:20337
** You should see a list of all available modules.  Don't be overwhelm
* Using Wiki:
** Click the 'Quick' link near the top.  It should bring you to a demo homepage, /sdcard/sl4a/scripts/l00_sample.txt
** Click the 'ThisFileDoesNotExist' link on the page.  You will see the 'Unable to open file...' message.  Click the 'Edit' button at the bottom.  In the edit window enter the following text and click 'Save':
*** now it exist.  ThisIsMyFile
** Now the file is updated.  The content of the file is shown at the bottom.  In the edit box you can continue to edit it.
** Click the link next to Path: /sdcard/sl4a/scripts/ThisFileDoesNotExist.txt to open it
* See [[/ls.pl?path=./docs_demo/index.txt|more demos at docs_demo/index.txt]]
** Not available on Wikispaces.  Please download and follow the installation instructions to create this page
==List of modules/guide/reference==
===General===
* Since the l00httpd is TCP based, you can browse to it from your desktop too if you have a wifi connection; or from an Internet enabled gaming station or TV
** You can also forward an SSH port from a Linux machine to the phone.  Then someone else could SSH to the Linux machine and forward his local port to the Linux machine for forwarding to your phone.  This way some one any where in the world can securely access information on your phone.  Best of all, this script terminates when you disconnect the SSH connection so you won't forget to turn it off.
** I also have a Perl script for the SSH console for forwarding an open port to the phone.  This script can filter by client IP address so no custom firewall setup is necessary.
* When you have Wifi, you can share data with the desktop, or friends
** It's faster and has more privacy than Gogole bookmarks
* Rudimentary security for remote client access: id:password access control (default id=p, pw=p, hard coded for now:(, but you are free to change))
** You could modify the code to make it more secure than almost anything, e.g. set the password seconds before and communicate verbally to the other party.
** You can also filter by client IP address
** No SSL support, so susceptible to sniffing.  Possible future work?
* I think it is the way to go since it is ultra portable
** You only need Perl
** You can access it from any Internet connected device, gaming station, or even TV and refrigerator. Imagine reviewing your calendar on your living room TV! (I do on my Wii)
** You can serve it from any smart phone, tablet/slate/pad/mat, that supports Perl
** Wiki is one quick way to organize information
* Some links on this page are demonstrations to be run on the phone or desktop and will be broken on wikispaces.com
* For advanced user, if you have adb installed, you can forward desktop port to the phone and use the phone from the full screen and keyboard of your desktop.  This is how I use it when I'm charging the phone
** adb forward tcp:40337 tcp:20337
** From the desktop, browse to: http://localhost:40337
===00l00httpd.pl===
* This is the framework.  This is the only Perl script that you run to launch l00httpd.
* It enumerates and invokes modules.  It handles TCP connections.  It also parses HTTP form data from web submission
* The modules list is sorted by the module descriptions so you can use prefixes (including prefix with space) to order the listing
* [[/nosuch.pl|The homepage]]
** 'Submit' submits the settings in the table below the button:
*** 'Print debug messages to console' sets the debug level: 0=no message, 1=least, 5=most; this useful if you are modifying Perl scripts and need to debug
*** 'Apps on': When checked, ebales all applets to remote clients
**** Settings in l00httpd.cfg take precedence
*** 'Apps off': When checked, disables all applets to remote clients
**** Settings in l00httpd.cfg take precedence
*** 'Client access timeout': The remote client access will timeout in the specified number of seconds
*** Check modules to enable remote client access
** 'Filter IP': When checked, only the checked IP addresses are allowed
*** When enabled, check IP address to allow access
**** Ask client to connect first so that it is listed, then check to allow access
*** This feature is useful when sharing content over open Wifi hot spot.
** ctrl data: All data made available to all applets from the framework.  Useful only if you are developing or modifying applets
* You can use the following links as shortcuts to quickly enable clients access and directory navigation:
** [[/httpd?debug=1&allappson=on&timeout=3000&scratch=on&hello=on|Enable all]]
*** Additional module may be enable via &modname=on
** [[/ls.pl?mode=read&noclinav=on&submit=Submit|CliNav]]
*** This can also be set in l00httpd.cfg.  Check it out
* Allows extra characters between .pl and ?, e.g. /a.jpg, to convince some browsers to display .jpg, etc.
* l00httpd listens on two ports.  By default, they are:
** 20337 ($ctrl_port = 20337; in 00l00httpd.pl): Unrestricted access port: Does not ask for password and impose restriction if client IP is 127.0.0.1.  This is you on your phone so you want no restriction
** 20338 ($cli_port = 20338; in 00l00httpd.pl): Restricted access port: Always ask for password and impose restriction, even if client IP is 127.0.0.1.  Since the SSH port forwarded client IP is also 127.0.0.1, use this port for SSH forwarding to force access restriction, i.e. reverse forward the remote port 20338 to local port 20338 and ask client to connect to remoteIP:20338.  The cliend will be asked to enter id:pw when connecting
===The l00http_ prefix===
* All scripts with the 'l00http_' prefix are plugins and are enumerated by the framework and listed on the homepage.  The prefix is removed before displaying on the homepage
* All plugins are independent, meaning any plugins may be deleted.
** However, l00http_ls.pl is the launching pad for many other plugins.  But it is not required as you can make a link to launch any plugins by manually typing out the full required name
** Some plugins are designed to work together, e.g. l00http_ls.pl send file to l00http_edit.pl for editing
* The following is a complete list of all plugins and other files in alphabetical order
===l00http_adb.pl===
* For advanced user.  Generate cut and paste commands to pull file from and push to the phone using adb for editing file from the desktop
** With Android SDK driver installed, and with the phone connected via USB cable, the 'adb pull' and 'adb 'push' commands allow you to pull a file from the phone, or push a file to the phone.  The following automatically generated text allows one to quickly cut and paste to exchange files between the PC and the phone.
* [[/adb.pl?path=/sdcard/sl4a/scripts/l00httpd__readme.txt|sample result]]:
<pre>
adb shell ls -l /sdcard/sl4a/scripts/l00httpd__readme.txt
adb pull "/sdcard/sl4a/scripts/l00httpd__readme.txt" "c:\x\l00httpd__readme.txt"
c:\x\l00httpd__readme.txt
adb push "c:\x\l00httpd__readme.txt" "/sdcard/sl4a/scripts/l00httpd__readme.txt"
</pre>
* When you are browsing from the desktop, you can quickly pull a file from the phone, edit, and push it back to the phone, so you can use your favorite editor on the desktop with full size keyboard and bit screen
* Suggested usage:
** [[/ls.pl|start from ls.pl]]
** At the bottom of ls.pl, set the destination of "'Size' send to" to 'adb'.  'adb' is the default.  The default is set in l00httpd.cfg (lssize^adb)
** Navigate to the directory containing the file of interest
** Click the file size link for the file of interest
** Copy and paste appropriate text on the desktop
*** c:\x\ is my scratch directory.  You can change it, or update l00http_adb.pl as you please
===l00http_blog.pl===
* [[/blog.pl?launchit=blog&path=/sdcard/ase/scripts/l00_blog.txt|Creates a new blog]] (this link specifies a hard coded directory for on the Android phone; see 'How to send a file to an applet' below for details)
<pre>
20110424 090439
</pre>
* Automatically adds date/time stamp and add the new entry at the top of the file
* The default format is the short form, i.e. one line per entry with a prefix date/time stamp.  All new lines are replaced with space.  These are useful for short and frequent tweeter style logging
* There is a long form where there is a heading with date/time stamp, and bullet for the entry.  You can add more bullets or anything else.  New lines are preserved.  These are useful for longer blog style logging
** [[/blog.pl?launchit=blog&path=/sdcard/ase/scripts/l00_blog.txt&raw=on|Short form blog]]
<pre>
 ===20110424 090439===
 * 
</pre>
** To use it, do as above for the URL and append &blog=on to the URL
* There is no direct link to get to the blog page.  See 'How to send a file to an applet' below to setup a bookmark for it
===l00http_cal.pl===
* A calendar display, [[/cal.pl|cal example]]
* The input is a text file listing a date, duration, and a short description
** 2010/5/22,1,Release l00httpd
** 2010/5/22+7,1,Update l00httpd
*** The second form puts events at multiple of 7 days from the specified date.   For example, 2010/5/22 is a Saturday, so it puts the specified event on every Saturday.
** Anything else is ignored, so you can put any comment there, or prefix with say # to comment something out
* There are two outputs in the HTML page
** A weekly HTML table at the top -- variable width table; wider for longer descriptions
*** The number of weeks to be displayed can be set at the bottom of the web page
** A weekly ASCII table at the bottom -- fixed size table; my original creation for DOS and am reluctant to remove
*** The size of the ASCII table can be set at the bottom of the page
* Encodes month in hex digit to save space on the phone, e.g. Dec 25 is c25
* Can be set to provide a very long range view of the calendar easily scrollable in a browser. You could see the whole year in one page. Most calendar applications don't scroll as easily as a browser.
===l00http_clip.pl===
* Sends the text entered to Android clipboard.  Only works on Android
* Great for ConnectBot : click a link to put text into the clipboard for pasting into the console
** See l00http_ls.pl about || for simplified shorthand
===l00http_coorcalc.pl===
* A coordinate calculator, [[/coorcalc.pl|coorcalc example]]
* A crude coordinate calculator.  Computes the new coordinate from given coordinate, distance, and bearing.  Useful when you don't access to the desktop and need to move a waypoint
===l00http_crypt.pl===
* Encryption, [[/crypt.pl|crypt example]]
* Decrypts a file or encrypt updated content
** The target file is a plain text file with special markers:
*** ---===###crypt:xyz:
*** xyz is rot, base, or blow, specifying the methods being rotate, base64, or Blowfish
*** The marker is automatically added when 'Encrypt' or 'Save' is clicked
*** Do not edit between the markers when encrypted text is displayed
*** Text outside the markers are plain text and are translated by the Wiki engine
*** Decrypted text are also translated by the Wiki engine
* 'Encrypt' and 'Save'
** Encrypts the possibly updated buffer using the selected method and display the encrypted data at the bottom for preview but does not write to file
** Save is similar to Encrypt but actually writes to file
*** Do not save if you don't see plain text through; it hasn't been decrypted properly
*** Passphrases, when applicable, must be entered twice so you won't encrypt with a passphrase with a typo.  Lost passphrase is unrecoverable for the Blowfish algorithm.
** Methods: 3 are currently supported
*** rot: Similar to ROT-13
**** Similar but rotate the entire ASCII table, not just the alphabets.
**** Passphrase should be between 0 and some small numbers.  It specifies the number of position to shift
**** 0 results in no encryption. If the number is too large, it exceeds the ASCII table (technically ends at 127) and I don't know what will happen.  Try yourself.
**** This is really not encryption but obfuscation
*** base: base64
**** This is the same encoding as email attachments.
**** Passphrase is not used.  But the script insists for a passphrase so just enter anything
**** This is really not encryption but obfuscation
*** blow: Blowfish
**** http://cpansearch.perl.org/src/MATTBM/Crypt-Blowfish_PP-1.12/Blowfish_PP.pm
**** Blowfish is a strong encryption algorithm.  But it is only as strong as the weakest link, and I have absolutely no idea if I have introduced a weak link.  But all source codes are available so if you are skilled in the art, you can make your determination.  And please inform me of your analysis results
**** If the passphrase is less than 8 characters long, it is repeated to be at least 8 characters long
**** The plain text is encrypted in 8 bytes chunk and concatenated into one large block which is then base64 encoded as printable text
** Encryption method can be changed by specifying a different method
* 'Decrypt' file
** Decrypt from the file for display
* 'Clear passphrase'
** Clears passphrase stored in memory
** For convenience, passphrase are cached in memory so you don't have to enter all the times.  If you are concern about security, you should clear it before stopping work
** The passphrase will be automatically cleared in the timeout periond specified.  But the form data in the web page can't be cleared, so exit the browser for security
* Other notes:
** The encryption and decryption are performed by pure Perl code so give it time to crunch
** Trust it with care so you don't lose data.  As long as you backup the files and remember the passphrase, you should be able to recover the data
** This is only storage security.  The decrypted content is transmitted in plain, ok if view on the phone, but not secure off the phone.  Use two SSH connections via a publicly accessible but secured SSH host would help greatly
* How to create a new encrypted file:
** Create a new file
** View it in ls.pl, at the bottom of the page, 'Set' to 'crypt', and then click 'crypt' after the button has been updated
** Enter text to be protected between the two marker '---===###crypt:'
** Enter passphrase and 'Encrypt' to preview or 'Save' to save
===l00http_dirnotes.pl===
* A directory annotator, to see the follow the link [[/ls.pl?path=./|dirnotes example]] and then click 'NtDirNotes' at the top right corner
* This utility creates or updates a list of all files in the directory containing the target file, 'NtDirNotes.txt'
** If the target file doesn't exist, a new table of list of files is created
** If the target file does exist, new columns are added to the existing table.  The new columns are status ('new' or 'del') and current date/time stamp
*** Existing columns, which are preserved, may contain old date/time stamps, and any annotation you created
* Suggested usage:
** Create the initial table and use the [[/table.pl|table]] utility to add your annotations
*** Editing on the desktop is easiest.  Alternatively use [[/table.pl|table]] to align all columns and use vi or Touchqode (these supports no wrap viewing) to edit
** During house cleaning, scan for new and deleted files and save the results. Then use [[/table.pl|table]] to sort and vi or Touchqode to edit, or edit on desktop
===l00http_do.pl===
* Perl 'do' (execute) a file.
** Execute Perl code in the specified file
** Print to web browser
** All without shutting down 00l00httpd.pl
* [[/do.pl?do=Do&path=/sdcard/ase/scripts/l00_do.pl|'do' example]] (edit path as needed)
===l00http_edit.pl===
* A simple editor
* No direct launch.  Invoked by through ls.pl
** You can achieve direct launch by creating a link, e.g. [[/edit.pl?edit=Edit&path=/sdcard/ase/scripts/l00_do.pl|edit do.pl]]
* It will also create the file if you try to edit a non-existent file
** How to create a new file
*** Visit any file in the desired directory
*** Enter new filename to the right of the Edit button at the bottom of the page and click Edit
*** Enter new content and Save
** How to create a new file, #2
*** Make a wikilink in a file
*** Follow the link and click edit
*** Enter new content
** How to delete a file
*** Erase all content.  A zero length file will be deleted
* It tries to make a backup by using 'cp', and appends '.bak' to the filename.  It does not warn if backup fails.
** Do you know of a Perl based version control system?  We can try to integrate
* % TOC % will create a table of content (space added to prevent substitution here.  Remove spaces to make a 5 characters sequence.
* It writes a script file (/sdcard/ase/scripts/l00http_cmdedit.sh) that can be set as ConnectBot Post-login Automation to quickly invoke vi for editing.  See 'l00http_cmdedit.sh'
===l00http_eval.pl===
* An [[/eval.pl|eval example]]
** After following the link, enter the following mathematical expressions in the text area and click 'Eval':
<pre>
2+3
3*4
3/5
9+8-7*6/5
9+(8-7*6)/5
</pre>
** You see see the following results:
<pre>
5
12
0.6
8.6
2.2
</pre>
* Multiple mathematical expressions may be entered one per line
* For non Perl user, each line is 'eval'ed.
** Thus you can do:
<pre>
$a=2
$b=3
$c=$a*$b
$c=$c*2
$c=$c*2
$c=$c*2
$pi=atan2(1,1)*4
</pre>
** You see see the following results:
<pre>
2
3
6
12
24
48
3.14159265358979
</pre>
===l00http_filecrypt.pl===
* An [[/filecrypt.pl|filecrypt example]]
* This is an advanced utility
* This utility provides file based encryption.  For example, images of your legal document such as passport may be encrypted for protection, but allows password protected viewing in any browser
* The following is a brief procedure:
** Follow [[/filecrypt.pl|this filecrypt link]] and set password (enter password twice)
*** The 'Comment' field is displayed in clear text.  You may use it as a hint to the password
*** The 'Metadata' field is the new file extension to conseal the original file type for added security
** Follow [[/ls.pl?path=./|this ls link]] and browse to the directory containing the files you want to encrypt
** Goto the bottom of the page and enter 'filecrypt' in the box to the right of "'Size' send to" and click it
** Find the file you want to encrypt and click the 'size' field.  This will encrypt the file.
*** The original file is not deleted.  You may delete it manually
** To decrypt, set the password first, and then click the 'size' field of the encrypted file name
** Follow the 'Click this line once to decrypt:' link
===l00http_find.pl===
* Example: [[/find.pl?fmatch=%5C.pl%24&content=bbox&submit=Submit|Find *.pl containing 'bbox']]
* Field descriptions:
** Filename (regex): regular expression for filename match
*** Examples:
*** Any file containing 'gps'
**** gps
*** Any file with .pl extension.  You should see all Perl scripts
**** \.pl$
** Content (regex): regular expression for content search (matching each line)
*** Examples:
*** Any Perl scripts containing 'gps'.  List each line
**** gps
** Max. lines: limit number of line to search, useful if you have huge files
** Recursive: whether to recurse sub-directories or not
** formatted text: show search results with fixed width font (prevents wrap around)
** Send file to: send the selected file to the destinated module when the filename is clicked
*** When the directory path name is clicked, display the content of the directory
===l00http_gps.pl===
* Display [[/gps.pl|GPS control]]
* Field descriptions:
** Interval: how long to wait between logging
*** 0 to stop logging
*** Interval is not precise, particularly when phone is in sleep mode
** 'Last'/'Loc':
*** 'Last': record last known GPS coordinate.  Does not turn on GPS
*** 'Loc': acquire and log GPS coordinate.  GPS should be enabled
** 'Wake': prevents phone to go into sleep mode when checked.
*** The battery lasts for more than 10 hours when in flight mode with GPS turned on on my Motorola Cliq
** 'Dup': log duplicated coordinates when check.  This will result in lots of duplicated coordinate if the phone is stationary
** 'No log': does not log to gps.trk when checked
* Logs date/time stamps and ocoordinates of GPS track in Garmin's MapSource compatible PCX5 format at specified intervals. 'File'/'Import' in Garmin Map Source to import
** Saves results to gps.trk in the working directory.  Does not save if 'No log' is checked
===l00http_gpsmap.pl===
* [[/gpsmap.pl?path=/sdcard/l00httpd/maps/WORLDBIG.png&submit=yes|World map example]]
* Display GPS coordinate on an HTML page
* This is useful when you want to use GPS mapping but do not have a data connect so Google Maps doesn't work
** MapDroyd works well without data connection.  But gpsmap can:
*** Display a list of waypoints
*** Display gps.trk as track on the map
*** Measure approximate distance between two points
* Field descriptions:
** 'lon': The longitude when 'Set' is clicked
** 'lat': The latitude when 'Set' is clicked
** 'path': The full path and file name to the .png and .map pair
** 'Marker': The character to place when 'Mark' is clicked
** 'Color': The color to use when 'Mark' is clicked
** 'Scale': The scale to shrink large map to fix phone screen
** 'Read GPS': Read coordinate from the GPS
** 'Set': Sets the 'X' marker at lon/lat
** 'Ctr': Sets the 'X' marker at the center of the map
** 'Mark': Mark the lon/lat coordinate as 'Marker' location for distance computation
** 'Waypoint files': full path name to gps.trk for track display, or 
** 'Color': 
** 'Display waypoints': 
* How to make a map:
** Quick and dirty: Simply use a blank .png with grid lines.  Edit the .map file to reflect where you are.  In a pinch this is useful to show the relative positions of places, particularly when you have acquired GPS tracks.  Allows you to make crude distance measurements
*** The blank grid: [[/gpsmap.pl?path=/sdcard/l00httpd/maps/blank.png|blank.png]]
*** Edit the .map file: [[/edit.pl?path=/sdcard/l00httpd/maps/blank.map||edit blank.map]]
** Better:
*** Capture the map and save in PNG or other suitable graphic format (.gif?) For example, display the area of interest in Google Maps and capture the screen
*** Use a text editor to create a map file with the same file name but with .map extension
**** It should have 8 lines, as follow (file coordinate 0,0 is top left):
***** for example, for the USA:
****** 0           # line 1: x of top left of graphic map
****** 0           # line 2: y of top left of graphic map
****** -124.432    # line 3: longitude of top left of map
****** 50.47482    # line 4: latitude of top left of map
****** 949         # line 5: x of bottom right of graphic map
****** 1599        # line 6: y of bottom right of graphic map
****** -64.6826    # line 7: longitude of bottom right of map
****** 23.28759    # line 8: latitude of bottom right of map
* Thins to do:
** [[/gpsmap.pl?path=/sdcard/l00httpd/maps/WORLDBIG.png&submit=yes|World map example]]
** Read current GPS location.
*** The GPS should be turned on and activated
**** Google My Track will activate GPS reliably
**** Log a track in [[/gps.pl|gps.pl]] should work too:
***** Interval: 2
***** 'Loc'
***** Check 'Wake'
***** Check 'Dup'
***** Check 'No logging'
***** Click 'Submit'
*** Click 'Read GPS'
**** Should place a red 'X' marker at your current approximate location
** Measure distance:
*** The map are displayed twice.  The top one is not clickable, but it has the waypoints and tracks.  The bottom one is clickable
*** On the bottom map, click the location where you want to be the origin
**** The red 'X' marker should now be shown at the selected location on the top map
*** Click 'Mark' to set origin
*** Click any where in the bottom map.  The coordinate of clicked location and the distance to the origin will be reported
**** The distance is computed using the great circle route for a spherical earth
** Display waypoints:
*** Set 'Waypoint files' to /sdcard/l00httpd/pub/nopw/tmp.kml and click 'Display waypoints'
*** /sdcard/l00httpd/pub/nopw/tmp.kml example:
**** #long,lat,name
**** 121.386309,31.171295,Huana
**** 121.801729,31.148953,PVG
**** 121.4704,31.22256667,xian-tian-di
** Display GPS track:
*** Set 'Waypoint files' to /sdcard/l00httpd/gps.trk and click 'Display waypoints'
===l00http_hello.pl===
* [[/hello.pl|A HelloWorld demo]]
* This is a template for a starting point if you wanted to develop your own applets
* Demonstrates user interaction via form and form data
===l00http_hexview.pl===
* Display file content in hexadecimals and ASCII
===l00http_jetlag.pl===
* [[/jetlag.pl|jetlag demo]]
* This is a sleep time planner for multi time zone crossing flight
* Displays two timelines depicting day time, evening, and night time:
** '-' is day, '=' is evening, '#' is night
<pre>
CT1         1  1  1  2              1  1  1  2  
0  3  6  9  2  5  8  1  0  3  6  9  2  5  8  1  
########----------=====#########----------=====#
                     zzzzzzzz
----------=====#########----------=====#########
    1  1  1  2              1  1  1  2          
CT2 2  5  8  1  0  3  6  9  2  5  8  1  0  3  6 
</pre>
* Click 'wake-', '+', 'z-', and '+' to move the sleep time 'zzzz' so that it best bridge between the sleep time in the two different time zones
===l00http_kml.pl===
* [[/kml.pl|kml demo]]
* This is a trivial Google Earth .kml file convertor.  There are two uses:
** Extract coordinates of places from .kml file:
*** Point 'Filename' to to a true Google Earth .kml file and click 'Process'
*** coordinates and place names are extracted and printed at the top
*** The result is suitable for copy and paste to make a bare .kml file for the next step
** Create .kml file for Google Earth from simple bare .kml file such as /sdcard/l00httpd/pub/nopw/tmp.kml example (shown above):
*** Point 'Filename' to the target and click 'Process'
*** The result is useful for:
**** Saving to desktop and open in Google Earth
**** And most useful (for me) is to open in Google Maps.  For this you need to make this file accessible to the public Internet:
***** Method 1: save the file and then upload to your public web site, or upload to http://bbs.keyhole.com/
***** Method 2: (I love this)
****** Assuming you have a publicly accessible Linux server, at 10.10.10.10
****** From your phone use ConnectBot to connect to the server
****** Forward remote port 20337 (i.e. 10.10.10.10:20337, and allowing external host) to local port 20338 (l00httpd's public port)
****** Open the following URL in Google Maps:
******* http://10.10.10.10:60123/kml.pl?path=/sdcard/l00httpd/pub/nopw/tmp.kml
******* You need to put the following line in your l00httpd.cfg to allow Google in without asking for a password. Adjust your path to match
******** nopwpath^/sdcard/l00httpd/nopw/
****** Google Maps will fetch this dynamically created .kml and display in realtime.
****** Since tmp.kml is a simple text file, you can update it easily.
****** [[/gpsmap.pl|gpsmap.pl]] (when properly setup) can quickly provide approximately coordinates
===l00http_launcher.pl===
===l00http_ls.pl===
* The [[/ls.pl|ls demo]]
* This is a directory browser. You can browse to any where on the phone that you have permission
* This is a plain text file viewer
** You can view any file. Of course only text makes sense.  I don't know what will happen when you view a large binary file, probably at a minumum the HTML tags may messed up.
* There is a simple plain text editor (l00httpd_edit.pl)
** To be used in conjunction with cal and tr for quick updates, but you can use it with any text file.  Makes a backup with .bak extension.
* This is a binary file server
** You can use it as a static HTML file server. You can view any HTML files that doesn't require server side computing, i.e. no cgi-bin.
** You can use it to view any image file on your phone (computing device)
*** There seems to be file transfer error for large file, will debug
** Supports JavaScript, since it is the browser that does the work
*** Examples: [[l00_timer.htm&raw=on|a large font timer]], [[l00_dualtime.htm&raw=on|dual time clock]]
* The selected file can be sent in one of three ways:
** 'reading' selected:
*** If it looks like wiki, with at least a couple of line with = and * for wikiwords, it renders wikiwords
*** Othewise it assumes it is plain text and does:
**** Converts < to &lt; and > to &gt; so they are render by the browser as character and not HDML tags
**** Appends &lt;br&gt; to each line to preserve line breaks
** 'raw' selected: sends the raw binary content without any header nor footer
* There is access control for remote users
** Directory browsing is disabled by default (so are modules). Uncheck NoCliNav checkbox to enable 
** You can restrict directory navigation to a certain level and below.  On the phone browse to desired level and check 'NoCliNav'
* If you are on Android phone and are familiar with vi, download ConnectBot from the Android Market
** vi is built in to Motorola Cliq's busybox! Start by 'busybox vi'
* Default launcher (the Set button at the bottom) for ls.pl, e.g. launches table.pl, specified in l00httpd.cfg
** lsset^table
* Appends filenames, e.g. a.jpg, to ls.pl/a.jpg, to convince some browsers to display .jpg, etc.
* A plain path to the file sends the file in binary mode. For example, this brings the Java Script stopwatch:
** http://127.0.0.1:20337/sdcard/ase/scripts/l00_stopwatch.htm
====What's on a wiki page====
* There are several links on the page that are often common for other modules too:
** 'Path': A full path name to the file. Useful to me at one time; no good reason to remove it
** link to the directory: A list of all files in the directory
** 'Home': A list of all l00httpd modules
** 'QUICK': Links to a URL defined in 'l00httpd.cfg', e.g.:
*** quick^/ls.pl?path=/sdcard/l00httpd/index.txt
*** You can ake this your homepage where everything is linked from this
** 'Jump to end': Simply jumps to the bottom of this page.
** 'Jump to end': Simply jumps to the
* ls.pl unique links and controls:
** 'bk&vi': Backup current file for external editing.  By default writes this line with full path name of the target file:
*** busybox vi /sdcard/sl4a/scripts/l00httpd/thefilename.txt
*** To this file:
*** /sdcard/sl4a/scripts/l00httpd/l00http_cmdedit.sh
*** All this to allow ConnectBot (local ternminal) shell automation:
*** busybox sh /sdcard/sl4a/scripts/l00httpd/l00http_cmdedit.sh
*** If you have Motorola Cliq, the unrooted busybox supports vi and sh and a whole lot more out of the box.  Otherwise root is require
** 'Top': Appears automatically to the right of a heading. Allows you to jump instantly to the top of the page
** 'Edit': Sends the current file ti l00httpd_edit.pl for editing
====Sending filename to modules====
* Some modules (blog, cal, tr) require a file to operate on.  You can compose the URL yourself or use the following technique:
** Use ls.pl to browse to the content of the file
** At the bottom of the page type 'blog' (without qoute; or tr, cal, etc.) in the edit box to the right of the 'Set' button
** Click 'Set', the button at the right most now says 'blog'
** Click 'blog'
** Bookmark the resulting URL
====Sending filename to modules #2====
* In the ls.pl directory listing, click on the corresponding file size link to send to Medit.pl' by default.
* To set new target module, set "'Size' send to" box at the bottom of the page.
** Obviously the target module must exist
====Find In File====
* Search in file and display the record containing the searched text
** Reg Ex specifies the regular expression to search.  If you are not familar with regular expression, you can simply enter a single word to search, since a single word is a valid regular expression.
** A record is everything between two Blockmark.  When searching Wiki text with heading, Blockmark:^= causes all the text between two headings to be displayed.  For Blockmark:. (the period,) causes the line containing the text to be displayed (because every line will match and displayed as a record.)
* Treats the file being viewed as delimited records.  A record is everything between two Blockmark.
* Tips:
** If you put a person's name in the heading, and all the contact information and notes in the body, you can search Reg Ex:name, and Blockmark:^=, to display the record at the top of the whole list
** To search for the line containing a specified test, Reg Ex:word, and Blockmark:., to display the lines contain the word
====Wiki Shorthands====
* The followings have special meaning in a wiki:
* =A heading=
* ==A level 2 heading==
* * A bullet
* ** A level 2 bullet
* %BOOKMARK%
** Switches from normal wiki mode to bookmarking wiki
** The purpose of the bookmarking mode is to make it easier to make a bookmarking page by using the following simplified method of making links. When in wiki mode, the followings apply:
** *'s starting in the first column makes a new bullet
** A newline does not make a new paragraph. It makes a ' - mp' separator
** A link is made simply by:
*** description | Http://domain.com/more/path.htm
*** and will look like this: [[Http://domain.com/more/path.htm|description]]
**** this is similar except that the link is also used as the description
**** ?| Http://domain.com/more/path.htm
** This makes a special l00httpd link to invoke clip.pl to put the text to the right of ||into Android's clipboard
*** desc||mount -t cifs -o username=id,pass=pw //name/path
*** and will look like this: [[/clip.pl?update=Copy+to+clipboard&clip=mount+-t+cifs+-o+username%3Did%2Cpass%3Dpw+%2F%2Fname%2Fpath|desc]]
**** this is similar except that the clip text is also used as the description
**** ?||mount -t cifs -o username=id,pass=pw //name/path
* %END%
** Terminates bookmarking mode
* Font styles
** &#42;&#42;bold&#42;&#42;: **bold**
** &#47;&#47;italics&#47;&#47;: //italics//
** &#95;&#95;underline&#95;&#95;: __underline__
** &#123;&#123;fixed width&#125;&#125;: {{fixed width}}
** &#42;&#42;&#47;&#47;&#95;&#95;combination&#95;&#95;&#47;&#47;&#42;&#42;: **//__bold italics underline__//**
===l00http_notify.pl===
* [[/notify.pl|Notify]]
* Puts a Notification message in the Notification Bar
** A silent reminder for you, e.g. pick up bread on the way home
** A really quick way to make a note of something before you forget, and you won't forget the note you just made
* All notification messages are written to the file '/sdcard/l00httpd/l00_notify.txt'
** They are reposted on restarting SL4A/00l00httpd.pl
** Force repost (e.g. when you have clear all Notification messages) by clicking 'Re-post'
** Remove Notification by editing '/sdcard/l00httpd/l00_notify.txt' (by following the link and click Edit)
* 'Speech to text' uses the Android text to speech engine
===l00http_myfriends.pl===
* Not really a plugin
* Shows up as a link on the homepage
* Makes it easy for connected friend to go to a pre-defined page without sending long URL
===l00http_periodic.pl===
* The [[/periodic.pl|periodic demo]]
* A sample script that run at the specified interval in seconds
** Enter interval in seconds and watch the SL4A console
* You can modify it to do anything you want
* When phone sleeps, interval may be much longer than specified
* Currently SL4A runs from any where between 1 to 12 hours and mysteriously terminates scripting (socket select doesn't return; I don't know how to debug
* It is not timer based, but instead sets the socket timeout to be the desired interval.  Thus the periodic tasks gets called whenever there was socket activity, or when it timed out. There is a check to simply return if the time isn't up yet
===l00http_perioifconfig.pl===
* [[/perioifconfig.pl|perioifconfig.pl demo]]
* You have to have busybox ifconfig available on your phone to use this feature.  My Motorola Cliq does without root.  You can always root to get it
* ifconfig reports the number of bytes received and transmitted
* This periodic task logs this information at the interval you specify
* With this you can find out your data usage against time
===l00http_periolog.pl===
* This is for advanced use.  You have to modify the Perl script to make it do something useful
* This script periodically record a parameter (currently batteryGetTemperature()) and prints to the screen and the console output
* Look for the following two lines in the source:
** print $buf;
** $perbuf .= $buf;
===l00http_perionetstat.pl===
* [[/perionetstat.pl|perionetstat.pl demo]]
* You have to have busybox netstat available on your phone to use this feature.  My Motorola Cliq does without root.  You can always root to get it
* netstat reports established network connections
* This periodic tasks logs this information at the interval you specify
* When logging at frequently enough interval, you create a log of all data connection from your phone to the public Internet so you can find out when your phone phones homes, and which homes
===l00http_play.pl===
* Sends the song specifies in the URL to the music player
** Facilate the creation of a list of click to play URL's
* [[/play.pl?path=/sdcard/media/songs.mp3|mp3 example]], but you can't play it because /sdcard/media/songs.mp3 does not exist
* There may be other ways to do this but I don't know how
* This method works only when you have a data connection.  It won't work while in flight mode
** The workaround is l00http_playcopy.pl
====Making URL====
* You can hand craft the URL using the example above, or you can use some helps:
* [[/ls.pl?path=/sdcard|Navigate to the directory containing the songs]]
* At the bottom of the screen, enter 'play' (without quotes) in "'Size' send to" and click
* Find the song and copy the URL in the file size field
** If you want to create lots of URL's, browse it from the desktop and view source.  All the URL are there
===l00http_playcopy.pl===
* TBD
* This is similar to l00http_play.pl but it works in flight mode
** It works by copying the selected song to a predefined name
** Set your music player to play the predefined song
===l00http_readme.pl===
* [[/readme.pl|readme demo]]
* Not really a script.  Displays a URL link to this file in its description so you can click to view this file
===l00http_recedit.pl===
===l00http_reminder.pl===
* [[/reminder.pl|reminder demo]]
* This is a reminder some where between an alarm (which is loud and demanding, i.e. you must response immediately to silent it) and a calendar event (the non alarming type) where you have to check to be reminded
* This reminder puts out a silent toast that is displayed for a few seconds starting and optionally vibrartes at a date/time you specify at interval you specify
** You will see this whenever you look at your phone.  If it is something more pressing, you would use an alarm.
* The fields should be self-explanatory
===l00http_scratch.pl===
* The [[/scratch.pl|scratch demo]]
* A scratch pad
** 'Refresh as HTML' renders URL as links
* Useful to put text/http links, etc. from the phone/desktop and read at/jump to link on the desktop/phone, i.e. easiest way to exchange a URL with the desktop
* How to send URL from phone to TV or back
** Say interested in a URL from Twitter on the phone, copy and paste the URL into the text box of scratch.pl
** browse to scratch.pl from TV (I have Wii; may be your fancy new TV has Internet browser:) or any Internet connected gaming console
** URL is automatically made into a link; just click to follow
* Exchange any text between any device and the phone
===l00http_screen.pl===
* Sets screen brightness
** [[/screen.pl?bright=0&setbright=Set+brightness|min. brightness]] - [[/screen.pl?bright=255&setbright=Set+brightness|max. brightness]]
* Facilitate the creation of URL for click to set brightness
===l00http_search.pl===
===l00http_shell.pl===
* Shells commands entered and display the results
* Big warning: you are allowed to do many bad things, like issuing a command to delete all files in a directory tree.  You have been warned.
* If you are still curious but aren't sure of what you can safely do, you can try:
** busybox date
** busybox uname -a
** busybox cat /proc/cpuinfo
** logcat -d
* Get web page or other HTTP content
** Get numerical IP address from say: http://www.kloth.net/services/nslookup.php. wget can't seem to resolve domain name for me.
** busybox wget http://74.125.39.99 -q -O /sdcard/l00httpd/wget.tmp
*** That's Google
** cat /sdcard/l00httpd/wget.tmp
* > and >> do not work. They are treated by the script to simulate the effect
===l00http_sleep.pl===
* This is a special utility just for myself, but you might find it useful or adaptable.
* I wanted to log the time I go to bed and get up.  I also want to set the phone screen brightness to 0 when I go to bed, and to 30% when I get up.
** The following links do the trick.  The log file is '/sdcard/l00httpd/log.txt':
** [[/sleep.pl?path=/sdcard/l00httpd/log.txt&buffer=sleep&bright=0&save=y|/sleep.pl?path=/sdcard/l00httpd/log.txt&buffer=sleep&bright=0&save=y]]
** [[/sleep.pl?path=/sdcard/l00httpd/log.txt&buffer=up&bright=61&save=y|/sleep.pl?path=/sdcard/l00httpd/log.txt&buffer=up&bright=61&save=y]]
* Study the Perl script for details
===l00http_solver.pl===
* This is hard to explain.  It mimics the Solver on the HP 200LX palmtop
* TBD examples
===l00http_speech.pl===
* [[/speech.pl|speech to text]]
* Uses Android's speech to text conversion to put spoken word into the clipboard
===l00http_table.pl===
* The [[/table.pl|table demo]]
* Appends A number of empty rows at the end. A is limited up to the number of column.
* Delete, add, or copy column in table
* Paste a block of cells from Excel and click 'Convert / Save'.  It converts tab into ||.
* There is also Add a Column, Delete a Column, and Copy a Column.
* You can also do multi-level sort.  The sort keys are extracted through Perl RegExp.
** Cells with only '.' will be sorted to the bottom
* This will take a long time to describe all the usage so next time:(
===l00http_tableedit.pl===
===l00http_timelog.pl===
* The [[/timelog.pl?path=/sdcard/l00httpd/timelog.txt|/timelog.pl?path=/sdcard/l00httpd/timelog.txt]]
* This is another one of my personal utility.  I use it to log my time at work.
* Each time I start a new task, I log a brief description, with the automatically generated date/time stamp
* It lists the last few entries so I can easily edit the them
* I have another Perl script to process the output and generate my time card entry
===l00http_timestamp.pl===
* The [[/timestamp.pl|timestamp demo]]
* Simply generates a new date/time stamp, in my format
** It should be trivial to update the script to your liking
** Also put it in the clipboard on the phone
===l00http_toast.pl===
* The [[/toast.pl|simple toast demo]]
* Simply put the entered text in a toast.  My first test
===l00http_tr.pl===
* The [[/tr.pl|tr demo]]
* A timeline for time management, [[/tr.pl|tr example]]
* The input is a text file listing time, or task duration and description
* The output is a linear timeslot listing of what task should be done when so as to meet the overall time planning
===l00http_twitter.pl===
* A periodic tasks to polls the Twitter follower count and logs to a file
** Example results: http://l00g33k.wikispaces.com/presssec
* Anything else you care to create
===l00http_txtdopl.pl===
* [[/ls.pl?path=./docs_demo/TxtDoPlDemo.txt|txtdopl demo]]
* You need to be a Perl programmer to make use of this utility.  And you have to modify this script to suit.
* This is a special text file with embedded Perl script.  A Perl function (sub txtdopl) is defined within the text file.  The control loop calls this user defined function for each line of the text file, excluding the Perl function definition.  This function should generate new output lines to replace the original lines
* For example, I use this to [[/blog.pl?path=./docs_demo/TxtDoPlDemo.txt|log for txtdopl]] by entering my electric meter reading at various time of the day.  The result looks like [[/ls.pl?path=./docs_demo/TxtDoPlDemo.txt|this]]
** When a number of new entries have been logged, I goto the bottom of the page and click 'run calculation', then click the 'Run' button on the page
** The embedded Perl function computes the difference between two readings and the average date consumption rate
* The details:
** The user defined function are passed 6 arguments:
*** $sock: The socket so you can print to the browser
*** $ctrl: The l00httpd runtime environment.  See 00l00httpd.pl for details
*** $lnno: The line number of '$this' line
*** $last: The previous line to '$this' line
*** $this: '$this' line
*** $next: The next line to '$this' line
** $last, $this, and $next together makes it easy for the Perl function to make computation that based on the difference between adjacent lines
** The function return replaces the current '$this' line
*** In this example, '$this' is unmodified, so the output does not change.
*** However, a new line is created in '$buf' and prints to the screen (print $sock "$buf\n";)
*** If you add '$this = $buf' the file will be updated
*** %TXTDOPL% are the Perl function delimiters and must be kept
*** The function must be called txtdopl
===l00http_view.pl===
* [[/view.pl?path=./TxtDoPlDemo.txt|jsut a viewer demo]] looking at this file
* Let you view the raw text especially for special file types like .htm
* The simplest use is to manuall modify the current browser URL from /ls.pl to /view.pl
===l00http_wget.pl===
===l00_ascii.pl===
===l00_chart.pl===
* One of do.pl demo
* The [[/do.pl?do=Do&path=l00_chart.pl|do l00_chart.pl]] demo
* Uses Google Chart API to create a graph and save to /sdcard/tmp/del.png
===l00_do.pl===
* One of l00_do.pl demo
* The [[/do.pl?do=Do&path=l00_do.pl|'do' demo]]
* Prints the Perl INC environment variable
===l00_pwget.pl===
* Demonstrates how to fetch http://www.google.com in the simplest form
===l00_timer.htm===
* [[l00_timer.htm&raw=on|a large font timer]]
===l00_dualtime.htm===
* [[l00_dualtime.htm&raw=on|dual time clock]]
===l00_stopwatch.htm===
* [[l00_stopwatch.htm&raw=on|dual stopwatch]]
===l00wikihtml.pm===
* This is an internal Perl module for l00httpd.  Users do not interact whit this module directly.  I am just finding a place to describe it.
* A wiki text renderer
==Screen Shots==
* Since the browser is really the visible front end, it's your browser that gives it the look.  I'm capturing these from the desktop as I'm not setup to capture the Android phone
* Main screen
[[image:l00httpd_main.png]]
* cal: A calendar
[[image:l00httpd_cal.png]]
* edit: Simple editor
[[image:l00httpd_edit.png]]
* find: Find files or find in files
[[image:l00httpd_find.png]]
* hello: a sample script
[[image:l00httpd_hello.png]]
* ls: directory and file browser
[[image:l00httpd_ls.png]]
* ls: also doubles as a wiki render
[[image:l00httpd_wiki.png]]
* scratch: a scratch pad for exchanging text/URL between desktop/phone
[[image:l00httpd_scratch.png]]
* tr: time management, i.e. visualize time
[[image:l00httpd_tr.png]]
* twitter: Twitter follower count polling.  Edit Perl script to do anything you want
[[image:l00httpd_twitter.png]]
==Why write in Perl==
* Because it doesn't need JDK. All is needed is a text editor (and I used the vi in the Motorola Cliq's busybox) and you can develop on the phone itself
==Known bugs==
* The SL4A Perl interpreter sometimes terminates by itself for unknown reasons
* periodic tasks tends to cause failed timeout and non-return in the select function causing the script to not response to HTTP connection
==Tips==
* Step by step installation of SL4A and Perl
** Download the latest SL4A from [[http://code.google.com/p/android-scripting/|here]]
** One of many way to install it is to open it in Astro File Manager.  Tap it, select 'Open App Manager', and tap Install or Upgrade
** If you haven't installed Perl interpreter, open ASE, 'Menu', 'Interpreters', 'Menu', 'Add', and select Perl.  SL4A will automatically download the lastest Perl interpreter
** If you have already installed Perl interpreter, and want to upgrade the interpreter, first uninstall it, and then reinstall as above
* How to create a file:
** Start at ls.pl
** Navigate to the desired directory (not absolutely necessary but saves some typing)
** View any file
** Goto the bottom, change the full path name to the right of the 'Edit' button
** Click 'Edit'
** Enter content in the edit box and click 'Save'
* How to send a file to an applet:
** Start at ls.pl
** Navigate to the desired directory
** View the file
** Goto the bottom, change the edit box to the right of 'Set' to the name of the applet, without leading 'l00http_' nor trailing '.pl'
** The button to the right most will change to the name after you clicked 'Set'
** Click the button you have changed
** The applet is activated with the target file
* I have Motorola Cliq and am describing my setup.  Yours may be different
* Useful utilities. Install from Android Market:
** ConnectBot: for the vi editor if you choose to use it.  vi clone is a least common denominator editor that is installed by default on nearly every Unix/Linux platform
** Astro File Manager
** AndroNotes
** Dolphin Browser
* My setup
** search-a for SL4A
** search-n for AndroNotes
*** can't type [ and ] in vi so type it here and copy; necessary only if there isn't another line near by to copy, which is much faster
** search-v for ConnectBot
*** Main reason for it is because the Mototola Cliq includes vi which I use
**** I prefer it because it can goto line number, has forward and backward search, and cut and paste don't take 4 seconds of long press
**** mc / 'c to bookmark and return to bookmark
**** ls.pl writes a script file that can be set as ConnectBot Post-login Automation to quickly invoke vi for editing:
*** Rename 'Local' to '0 Local' so it shows up first
*** Set Post-login Automation to:
**** busybox sh /sdcard/ase/scripts/l00http_cmdmain.sh
***** It uses the bash command 'read' to select different commands.  Edit to suit
*** l00http_cmdedit.sh is written by ls.pl each time you try to edit a file
**** So all I do is Edit a file from browser then close browser
**** search-v (my app short-cut), b<Enter> and I'm in vi editing the file
**** Refresh in browser to see result
*** search-v, tap, a<Enter> and you are editing a file
*** Edit /sdcard/ase/scripts/l00http_cmdmain.sh to anything you want
** search-b for built-in Browser
*** Set its homepage to http://localhost:20337/ls.pl?path=/sdcard/l00httpd/index.txt
** search-p for Dolphin Browser
*** Set Dolphin Browser as default browser
*** search-b to bring up an index page, click any link and brings you to Dolphin Browser and start browsing
*** You can easily sqeeze 10 to 20 links on the index page, and many more just one tap away, much faster than Google Bookmarks
===A sample: my 'Quick' page===
* Daily: [[/blog.pl?log=on&path=/sdcard/l00httpd/log.txt|log]] - [[Happenings.txt|Happenings]] - [[HouseWorks.txt|HouseWorks]] - [[Routine.txt|Routine]]
* Main: [[/blog.pl?path=/sdcard/l00httpd/blog.txt|blog]] - [[main.txt|main]] - [[inbox.txt|inbox]] - [[/tr.pl|tr]] - [[/cal.pl|cal]]
* Bookmarks: [[bookmarks.txt|bookmarks]] - [[MyWebSites.txt|MyWebSites]]
* Info: [[movie.txt|movie]] - [[tdr.txt|TDR]] - [[http://www.google.com|Google]]
* Logs: [[/blog.pl?launchit=blog&path=/sdcard%2Fl00httpd%2Fbigevents.txt&log=on|bigevents]] - [[/blog.pl?launchit=blog&path=%2Fsdcard%2Fl00httpd%2Fwhereami.txt&log=on|whereami]]
* l00httpd: [[/ls.pl?path=/sdcard/ase/scripts/l00httpd__readme.txt|l00httpd__readme.txt]]
* Client: [[/httpd?debug=1&allappson=on&timeout=3600&scratch=on&hello=on|Enable all]] - [[/ls.pl?path=%2Fsdcard%2Fase%2Fscripts%2F&mode=read&submit=Submit|CliNav]]
* GPS [[/gps.pl?interval=15&submit=Submit|15 sec]] - [[/gps.pl?interval=2&submit=Submit|2 sec]] - [[/gps.pl?interval=0&submit=Submit|Off]]
* Timer: [[/ls.pl?path=/sdcard/ase/scripts/l00_timer.htm&raw=on|Timer]] - [[/ls.pl?path=/sdcard/ase/scripts/l00_dualtime.htm&raw=on|Dual time]]
===End sample===
===Making your phone based l00httpd accessible to the world===
* Not really to any one in the world, but to any specific peoson
* You need a publicly accessible computer with a well protect ssh server, and an opened port
** Setup ConnectBot (from the Market) on the phone to access the ssh server.  Use DSA or similar for added security
*** Setup up ConnectBot to forward remote port 20337 to local 127.0.0.2:20337.  127.0.0.2 just so that l00httpd will ask for password
** Connect to the ssh server and run:
*** perl portfwrd.pl cliip ctrl_port=12345
**** Assuming the opened port is 12345
**** This open port is quite safe because you are not installing any server on this port
**** Have your friend connect to http://serverip:12345
**** Note the reported IP in ConnectBot
*** perl portfwrd.pl fwrd srvr=127.0.0.1 server_port=20337 only=208.1.1.2
**** Assuming 208.1.1.2 is your friend's IP.  Access is restricted to only the IP specified.  Plus id:pw are also required so you are pretty secure, except when it is behind a big corporate NAT in which case every one behind the NAT can access.  I would have to implement IP plus port match to secure it.
**** Have your friend refresh and l00httpd should be accessible
*** Your l00httpd is accessible as long as ConnectBot remains connected
==Comments and Feedbacks==
* Comments and feedbacks are welcome.  Leave them here, or tweet to @l00g33k.
* I tweet to #l00httpd more frequently than updating this web site
* If people are interested I will host it on Google Code
* Contents on this page are updated randomly.  Use the History tab on wikispaces.com to find out what has changed since your last visit
==Todo==
* fix broken GPS?
* httpd: log view
* slideshow.pl
* solver.pl
* ls.pl busybox copy paste edit to use clip.pl
* gps.pl; Don't get location if over-slept, i.e. phone standing-by; JSON and TCP not working right sleeping?
* Plot GPS track using Google chart
* Alarm using MakeToast (i.e. persistent but not noisy)
* Alternate location for modules in sub-directory
* Save backup in sub-directory
==Release histories==
===0.24 - future release===
* hexview.pl
* mkclip.pl
* mkclip in crypt.pl
* file size link send to
* solver.pl
* ls.pl: fixed so that the first wikiword after a bullet doesn't need a space
* ls.pl: Added: Content-Type: image/png
* ls.pl: Sends Content-Type: text/html for wikitext pages
* ls.pl: The file size link in the directory listing sends the file to modules
* ls.pl: Find on page
* ls.pl & l00wikihtml.pm: add &tx=x.htm so Palm TX will display wiki as HTML
* notify.pl: Puts a Notification on the Notification Bar
* adb.pl: push/pull file via adb, clipboarding busybox vi
* speech.pl: STT to clipboard
===0.23 - 2010/05/23===
* Too lazy to list:(
* l00http_do.pl
** do.pl
** chart.pl
** pwget.pl
* l00http_clip.pl
* l00http_toast.pl
* Updated:
** l00http_find.pl
** l00http_edit.pl
** l00http_scratch.pl
** l00http_shell.pl
** l00http_crypt.pl
** l00http_table.pl
** l00http_ls.pl
** l00http_blog.pl
* l00_stopwatch.htm
===0.22 - 2010/04/22===
* 00l00httpd.pl sets HTML title
* $ctrl->{'msglog'} .= "$_";
* Fixed http link creation
* table.pl: added missing \n after table sort
* table.pl: now also render wiki text so you can view a sorted table without having to save it first
===0.21 - 2010/04/01===
* I plan to stop updating this section and just update the appropriate section.  Use the History tab to find out what's changed
* gps.pl switch to log last known location, or readLocation (which only reports coarse location)
* periodic.pl: prints date/time stamp instead of sec since 1970
* periodic.pl: added a link to refresh output
===0.2 - 2010/03/20===
* Considered beta release
* ls.pl: &raw=on enables raw mode by URL
* gps.pl: Added GPS logging with GMT date/time stamps
* table.pl: Append rows at the end
* table.pl: provides means to manupulate tables.
* *.pl: added Quick whose URL is specified in l00httpd.cfg
* edit.pl: writes a script file that can be set as ConnectBot Post-login Automation to quickly invoke vi for editing
* ls.pl: added a text box near edit for cut and paste command line to invoke busybox vi editing the current file.  (I use vi:)
* ls.pl: added an option to create non-existent file
* ls.pl: allowing [ [/relative URL] ] (spaces to prevent a wikilink) to work for both 127.0.0.1 as well as 192.*.*.* Wifi IP
* ls.pl: allowing full path name to be specified for invoking edit.pl so you can create a new file by specifying a new file name
* find.pl: click on file name jumps to line found
* Client enable timeout
* Client enable always on overwrite can be specified in l00httpd.cfg
* Change scratch.pl, edit.pl to POST to allow edit size larger than about 2000 bytes allowed by PUT
* Blog.pl
===0.11 - 2010/03/02===
* little changes
===0.1 -- 2010/02/26===
* Considered alpha release
===0.02 -- 2010/02/21===
* Better structure
* use strict
===0.01 -- 2010/02/14===
* Initial release
==Credits==
* base64: http://www.mhonarc.org/MHonArc/lib/base64.pl
* Blowfish: http://cpansearch.perl.org/src/MATTBM/Crypt-Blowfish_PP-1.12/Blowfish_PP.pm
----
[[image:http://www3.clustrmaps.com/stats/maps-no_clusters/l00g33k.wikispaces.com-thumb.jpg link="http://www3.clustrmaps.com/user/04aac1ba"]]
