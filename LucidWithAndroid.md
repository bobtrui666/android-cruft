I just uploaded a stripped-down <a href='http://android-cruft.googlecode.com/files/lucid-on-android-0.1.tar'>72MB stripped down version</a> of the 600MB ubuntu.zip from:
http://nexusonehacks.net/nexus-one-hacks/how-to-install-ubuntu-on-your-nexus-oneandroid/

I took out everything non-essential that I could find and also upgraded it from
karmic (9.10) to lucid (10.04).  Once you get it setup, you'll need to
"apt-get update" to download the package lists and then "apt-get install"
whatever packages you want.

Running ubuntu on Nexus One basically involves mounting a disk image file
with Ubuntu for ARM, then opening a chroot'ed shell inside it.

There's no special "boot" process; the stock android kernel is close enough
to the ubuntu kernel that most things work.  The ubuntu disk image is self
contained, so you don't have to mess up your phone; it runs its usual OS
the whole time.

Most importantly, apt-get works, allowing you to install anything you want
from the ubuntu repository.  The nexusonehacks.net image even comes with
firefox, mplayer and openoffice.org, which you can display on your phone
or workstation over VNC.

How to use it:

> - You'll need a rooted nexus one and a microSD card with at least 2GB free (Other phones might also work).

> - Unpack lucid-on-android-0.1.tar on your computer.

> - Copy all the files inside into /sdcard/ubuntu/

> - If you have busybox on your android, you can uncompress ubuntu.img.bz2 on the phone directly.  In /sdcard/ubuntu/, run "bunzip2 ubuntu.img.bz2". Otherwise, you'll have to uncompress the image on your computer and then copy it over to /sdcard/ubuntu.  It uncompresses to 2GB of mostly empty space; the actual files take up less than 200MB uncompressed.  That leaves you lots of room to apt-get install what you need.

> - From a root shell on the phone, cd /sdcard/ubuntu/, and run ". ./bootubuntu".  It'll mount /sdcard/ubuntu/ubuntu.img as /data/local/ubuntu, set an appropriate PATH, and then run a chroot bash for you.

> - That's it!  Run "apt-get update" to download a list of packages, and then you can "apt-get install" whatever you need.  Things that make funky system calls are more likely to fail; for instance, openssh-server reboots my phone when I start it, probably because it tries to ask the system for login information that isn't supported in the android kernel.