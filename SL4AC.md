# Write C programs that can access the Android API #

Most Android programs are written in Java.  The major exception is [SL4A](http://code.google.com/p/android-scripting/), "Scripting Languages for Android", which ships quite a few different scripting languages and a simplified Android API.

sl4a-C, the library described here, adds C to the list of languages supported by SL4A.

A neat side effect of this is that, as with the other SL4A languages, you can also use sl4a-C to compile programs on your host computer and access the SL4A API over a USB cable or network.

If you want to try it out, [check out android-cruft from subversion](http://code.google.com/p/android-cruft/source/checkout), and check out the [README.txt](http://code.google.com/p/android-cruft/source/browse/trunk/sl4a-c/README.txt) and [INSTALL.txt](http://code.google.com/p/android-cruft/source/browse/trunk/sl4a-c/INSTALL.txt) for more details on how it works and how to compile it for Android or Linux.

# Static Type Checking #

As with the other SL4A languages, the low-level interface doesn't know what methods are available or how to call them; you have to look it up on the SL4A API page:
http://code.google.com/p/android-scripting/wiki/ApiReference

If you call a method incorrectly, you won't know it until you try to make the call and the SL4A server sends back an error.

But sl4a-c also has a listing of all the available SL4A calls in api-listing.txt, with a shorthand notation for return and argument types. generate-api.pl reads that file and generates sl4a-wrapper.c and .h.

Using the high level sl4a-wrapper, you can see all the functions available and get compile-time errors if you attempt to misuse them.