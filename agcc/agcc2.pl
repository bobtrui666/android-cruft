#!/usr/bin/perl -w
use strict;

# XXX: Change this to point to your ndk install
my $NDK = '/path/to/android-ndk-r5c';

# Copyright 2008, Andrew Ross andy@plausible.org
# Distributable under the terms of the GNU GPL, see COPYING for details

# UPDATE: 6 Jul 2011.  Changed paths around to work with
# android-ndk-r5c-linux-x86.tar.bz2.

# The Android toolchain is ... rough.  Rather than try to manage the
# complexity directly, this script wraps the tools into an "agcc" that
# works a lot like a gcc command line does for a native platform or a
# properly integrated cross-compiler.  It accepts arbitrary arguments,
# but interprets the following specially:
#
# -E/-S/-c/-shared - Enable needed arguments (linker flags, include
#                    directories, runtime startup objects...) for the
#                    specified compilation mode when building under
#                    android.
#
# -O<any> - Turn on the optimizer flags used by the Dalvik build.  No
#           control is provided over low-level optimizer flags.
#
# -W<any> - Turn on the warning flags used by the Dalvik build.  No
#           control is provided over specific gcc warning flags.
#
# Notes:
# + The prebuilt arm-eabi-gcc from a built (!) android source
#   directory must be on your PATH.
# + All files are compiled with -fPIC to an ARMv5TE target.  No
#   support is provided for thumb.
# + No need to pass a "-Wl,-soname" argument when linking with
#   -shared, it uses the file name always (so don't pass a directory in
#   the output path for a shared library!)

my $ALIB = "$NDK/platforms/android-8/arch-arm";
my $PREBUILT  = "$NDK/toolchains/arm-eabi-4.4.0/prebuilt/linux-x86";
my $TOOLCHAIN = "$NDK/toolchains/arm-eabi-4.4.0";
my $INTERWORK = $PREBUILT;

my $LDSCRIPTS = "$PREBUILT/arm-eabi/lib/ldscripts/";

my @include_paths = (
    "-I$NDK/platforms/android-8/arch-arm/usr/include",
  );

my @preprocess_args = (
    "-D__ARM_ARCH_5__",
    "-D__ARM_ARCH_5T__",
    "-D__ARM_ARCH_5E__",
    "-D__ARM_ARCH_5TE__", # Already defined by toolchain
    "-DANDROID",
    "-DSK_RELEASE",
    "-DNDEBUG",
    # "-include", "$DROID/system/core/include/arch/linux-arm/AndroidConfig.h",
    "-UDEBUG");

my @warn_args = (
    "-Wall",
    "-Wno-unused", # why?
    "-Wno-multichar", # why?
    "-Wstrict-aliasing=2"); # Implicit in -Wall per texinfo

my @compile_args = (
    "-march=armv5te",
    "-mtune=xscale",
    "-msoft-float",
    "-mthumb-interwork",
    "-fpic",
    "-fno-exceptions",
    "-ffunction-sections",
    "-funwind-tables", # static exception-like tables
    "-fstack-protector", # check guard variable before return
    "-fmessage-length=0"); # No line length limit to error messages

my @optimize_args = (
    "-O2",
    "-finline-functions",
    "-finline-limit=300",
    "-fno-inline-functions-called-once",
    "-fgcse-after-reload",
    "-frerun-cse-after-loop", # Implicit in -O2 per texinfo
    "-frename-registers",
    "-fomit-frame-pointer",
    "-fstrict-aliasing", # Implicit in -O2 per texinfo
    "-funswitch-loops");

my @link_args = (
    "-Bdynamic",
    "-Wl,-T,$PREBUILT/arm-eabi/lib/ldscripts/armelf.x",
    "-Wl,-dynamic-linker,/system/bin/linker",
    "-Wl,--gc-sections",
    "-Wl,-z,nocopyreloc",
    "-Wl,--no-undefined",
    "-Wl,-rpath-link=$ALIB",
    "-L$ALIB/usr/lib",
    "-nostdlib",
    "$ALIB/usr/lib/crtend_android.o",
    "$ALIB/usr/lib/crtbegin_dynamic.o",
    "-lc",
    "-ldl",
    "$PREBUILT/lib/gcc/arm-eabi/4.4.0/libgcc.a",
    "-lm"
);

# Also need: -Wl,-soname,libXXXX.so
my @shared_args = (
    "-nostdlib",
    "-Wl,-T,$PREBUILT/arm-eabi/lib/ldscripts/armelf.xsc",
    "-Wl,--gc-sections",
    "-Wl,-shared,-Bsymbolic",
    "-L$ALIB",
    "-Wl,--no-whole-archive",
    "-lc",
    "-lm",
    "-Wl,--no-undefined",
    "$PREBUILT/lib/gcc/arm-eabi/4.4.0/libgcc.a",
    "-Wl,--whole-archive"); # .a, .o input files go *after* here

# Now implement a quick parser for a gcc-like command line

my %MODES = ("-E"=>1, "-c"=>1, "-S"=>1, "-shared"=>1);

my $mode = "DEFAULT";
my $out;
my $warn = 0;
my $opt = 0;
my @args = ();
my $have_src = 0;
while(@ARGV) {
    my $a = shift;
    if(defined $MODES{$a}) {
	die "Can't specify $a and $mode" if $mode ne "DEFAULT";
	$mode = $a;
    } elsif($a eq "-o") {
	die "Missing -o argument" if !@ARGV;
	die "Duplicate -o argument" if defined $out;
	$out = shift;
    } elsif($a =~ /^-W.*/) {
	$warn = 1;
    } elsif($a =~ /^-O.*/) {
	$opt = 1;
    } else {
	if($a =~ /\.(c|cpp|cxx)$/i) { $have_src = 1; }
	push @args, $a;
    }
}

my $need_cpp = 0;
my $need_compile = 0;
my $need_link = 0;
my $need_shlink = 0;
if($mode eq "DEFAULT") { $need_cpp = $need_compile = $need_link = 1; }
if($mode eq "-E") { $need_cpp = 1; }
if($mode eq "-c") { $need_cpp = $need_compile = 1; }
if($mode eq "-S") { $need_cpp = $need_compile = 1; }
if($mode eq "-shared") { $need_shlink = 1; }

if($have_src and $mode ne "-E") { $need_cpp = $need_compile = 1; }

# Assemble the command:
my @cmd = ("arm-eabi-gcc");
if($mode ne "DEFAULT") { @cmd = (@cmd, $mode); }
if(defined $out) { @cmd = (@cmd, "-o", $out); }
if($need_cpp) { @cmd = (@cmd, @include_paths, @preprocess_args); }
if($need_compile){
    @cmd = (@cmd, @compile_args);
    if($warn) { @cmd = (@cmd, @warn_args); }
    if($opt) { @cmd = (@cmd, @optimize_args); }
}
if($need_shlink) { @cmd = (@cmd, @shared_args); }
@cmd = (@cmd, @args);
if($need_link) { @cmd = (@cmd, @link_args); }

print join(" ", @cmd), "\n"; # Spit it out if you're curious
exec(@cmd);

