# Release under GPLv2 or later version by l00g33k@gmail.com

use Cwd;
use strict;
use warnings;

my $hiresclock = 1;
eval "use Time::HiRes qw( time )";
if ( $@ ) {
     $hiresclock = 0;
}
my ($hiresclockmsec);
$hiresclockmsec = 0;

my ($plpath);


$plpath = cwd();
$plpath =~ s/\r//g;
$plpath =~ s/\n//g;
if (!($plpath =~ /\/$/)) {
    # make sure path ends in '/'
    $plpath .= '/';
}
$plpath =~ s\/cygdrive/(.)\$1:\;
if ($0 =~ /^(.+[\\\/])[^\\\/]+$/) {
    $plpath = $1;
}
# shrink // to /
$plpath =~ s/\/\/+/\//g;

use lib ".";        # include current directory
use l00base64;      # used for decoding authentication
use l00httpd;
use IO::Socket;     # for networking
use IO::Select;     # for networking

eval "use Android";
#die "couldn't load module : $!n" if ($@);  # ok, not on Android!


# This is a simple HTTP applet server with modular plugin features
# What it does:
# 1) Searches in own directory for filenames like l00http_(\w*)\.pl and remember them
# 2) Open a listening socket
# 3) Parse client HTTP submission and identify module plugin name
# 3.1) if found, invoke module
# 3.2) if not, provide a list of known modules



my ($addr, $checked, $client_ip, $cmd_param_pair);
my ($ishost, $ctrl_lstn_sock, $cli_lstn_sock, $ctrl_port, $ctrl_port_first, $cli_port, $debug, $file, $hour);
my ($idpw, $idpwmustbe, $isdst, $key, $mday, $min, $host_ip);
my ($modcalled, $mod, $mon, $name, $param, $tmp, $dnspattern, $ipaddr, $buf);
my ($rethash, $retval, $sec, $sock, $tickdelta, $postlen);
my ($urlparams, $val, $wday, $yday, $year, $subname);
my ($httpbuf, $httphdr, $httpbdy, $httpmax, $l00time, $rin, $rout, $eout);
my ($httpbuz, $httphdz, $httpbdz, $httpsiz, $clicnt, $nopwtimeout);
my ($httpsz, $httpszhd, $httpszbd, $open, $shutdown, $poormanrdnssub);
my (@cmd_param_pairs, $timeout, $cnt, $cfgedit, $postboundary);
my (%ctrl, %FORM, %httpmods, %httpmodssig, %httpmodssort, %modsinfo, %moddesc, %ifnet);
my (%connected, %cliipok, $cliipfil, $uptime, $ttlconns, $needpw, %ipallowed);
my ($htmlheadV1, $htmlheadV2, $htmlheadB0, $skip, $skipfilter, $httpmethod);
my ($cmdlnhome, $waketil, $ipage, $battpct, $batttime, $quitattime, $quitattimer, $quitmsg1, $quitmsg2, $fixedport);
my ($cmdlnmod, $cmdlnparam, $rammaxitems, $ramfilehtml, $ramfiledisp, $ramfiletxt);


# set listening port
$ctrl_port = 20337;
$cli_port = 20338;
$fixedport = 0;
$host_ip = '0.0.0.0';
$idpwmustbe = "p:p";  # change as you wish
$debug = 1;         # 0=none, 1=minimal, 5=max
$open = 0;
$shutdown = 0;
$httpmax = 1024 * 1024 * 3;
$ctrl{'bannermute'} = 0;
$cmdlnhome = '';
$waketil = 0;
$ipage = 0;
$battpct = '';
$batttime = 0;
$rammaxitems = 1000;

# These two implement a special Openshift demo auto quit and restart
# $quitattimer is set from command line
# When a module other than 'hello' is invoked, do:
#   if ($quitattimer != 0) {
#       $quitattime = time + $quitattimer
#       $quitattimer = 0;
#   }
$quitattimer = 0;
$quitattime = 0x7fffffff;
$quitmsg1 = "<font style=\"color:black;background-color:lime\">This demo will be wiped and restarted in ";
$quitmsg2 = " seconds.</font> ";

$cmdlnmod = '';
$cmdlnparam = '';

undef $timeout;

# Flushing the print buffers.
# http://www.perlmonks.org/?node_id=669369
$| = 1;

sub dlog {
    my ($level, $logm) = @_;

    if ($ctrl_port_first == $ctrl_port) {
        if ($debug >= $level) {
            print $logm;
            if (open (OUT, ">>${plpath}l00httpd.log")) {
                print OUT $logm;
                close OUT;
            }
        }
    }
}

sub perlvmsize {
    my ($vmsize);

    $vmsize = -1;

    if (open(IN, "</proc/$$/status")) {
        $vmsize = 0;
        while (<IN>) {
            if (/VmSize:.+?(\d+)/) {
                $vmsize = int(($1 + 512) / 1024);
                last;
            }
        }
    }

    $vmsize;
}


sub getsvrip {
    my ($ip, $now);

    $now = time;
    if ($ipage + 300 > $now) {
        # server ip less than 60 seconds old, use cache
        $ip = $ctrl{'myip'};
    } else {
        $ipage = $now;

        if ($ctrl{'os'} eq 'and') {
            if ($ctrl{'machine'} eq 'Morrison') {
                $ip = `busybox ifconfig`;
            } else {
                $ip = `ip addr show`;
                undef %ifnet;
                foreach $_ (split ("\n", $ip)) {
                    #1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue
                    if (/^\d+: *(\w+):/) {
                        $tmp = $1;
                    }
                    #    inet 127.0.0.1/8 scope host lo
                    if (/inet *(\d+\.\d+\.\d+\.\d+)\//) {
                        $ifnet {$tmp} = $1;;
                    }
                }
                $ip = '';
                foreach $_ (keys %ifnet) {
                    if (/wlan/) {
                        $ip .= "$ifnet{$_} ";
                    } elsif (/eth/) {
                        $ip .= "$ifnet{$_} ";
                    }
                }
                if ($ip eq '') {
                    # didn't find wifi, try mobile net
                    foreach $_ (keys %ifnet) {
                        if (/rmnet/) {
                            $ip .= "$ifnet{$_} ";
                        }
                    }
                }
            }
        } elsif (($ctrl{'os'} eq 'win') || ($ctrl{'os'} eq 'cyg')) {
            $ip = `ipconfig`;
        } else {
            #print "shell /sbin/ifconfig\n", if ($debug >= 5);
            print "shell ifconfig\n", if ($debug >= 5);
            if (-f "/sbin/ifconfig") {
                $ip = `/sbin/ifconfig`;
            } else {
                $ip = `ifconfig`;
            }
        }
        print "raw ip = $ip\n", if ($debug >= 5);
        if (($ctrl{'os'} eq 'win') || ($ctrl{'os'} eq 'cyg')) {
#           if ($ip =~ /(192\.168\.\d+\.\d+)/)
            if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ms) {
                $ip = $1;
            }
        } else {
            if (defined ($ip)) {
#               if (@_ = $ip =~ /inet (\d+\.\d+\.\d+\.\d+)/g)
                if (@_ = $ip =~ /inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/g) {
                    $ip = '';
                    foreach $_ (@_) {
                        if (!/^172\./ && !/^127\.0\./) {
                            if ($ip eq '') {
                                $ip .= "$_";
                            } else {
                                $ip .= " $_";
                            }
                        }
                    }
#               } elsif ($ip =~ /(\d+\.\d+\.\d+\.\d+) +Bcast/) {
                } elsif ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) +Bcast/) {
                    $ip = $1;
#               } elsif ($ip =~ /addr:(\d+\.\d+\.\d+\.\d+)/) {
                } elsif ($ip =~ /addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
                    $ip = $1;
                }
            } else {
                $ip = '(unknown)';
            }
        }
        $ip =~ s/ //g;
    }

    if ($ip !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        $ip = '(unknown)';
    }

    $ctrl{'myip'} = $ip;
    $ip;
}

sub updateNow_string {
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    $ctrl{'now_string'} = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);
    $ctrl{'now_day'} = $wday;
}
&updateNow_string ();


# predefined to make it easy for the modules
$ctrl{'httphead'}  = "HTTP/1.0 200 OK\x0D\x0A\x0D\x0A";
#::now::f705
$htmlheadV1 = "<!DOCTYPE html PUBLIC \"-//WAPFORUM//DTD XHTML Mobile 1.0//EN\" \"http://www.wapforum.org/DTD/xhtml-mobile10.dtd\">\x0D\x0A";
$htmlheadV2 = "<!DOCTYPE html>\x0D\x0A";
$htmlheadB0 = "<html>\x0D\x0A".
              "<head>\x0D\x0A".
              "<meta name=\"generator\" content=\"WikiPland: https://github.com/l00g33k/WikiPland\">\x0D\x0A".
              "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\x0D\x0A".
              "<link rel=\"shortcut icon\" type=\"image/x-icon\" href=\"/favicon.ico\" />\x0D\x0A".
              # so arrow keys scroll page in my browser
              "<meta http-equiv=\"X-UA-Compatible\" content=\"IE=EmulateIE7\" />\x0D\x0A".
              "";
$ctrl{'htmlhead'} = $htmlheadV1 . $htmlheadB0;

$ctrl{'htmlhead2'} = "</head>\x0D\x0A<body>\n";
$ctrl{'htmlfoot'}  = "\x0D\x0A</body>\x0D\x0A</html>";
$ctrl{'dlog'}  = \&dlog;
$ctrl{'txtw'}  = 32;
$ctrl{'txth'}  = 8;
$ctrl{'cryptto'}  = 15;
$ctrl{'ipfil'}  = "off";
$ctrl{'lssize'}  = "launcher";
$ctrl{'blogwd'}  = 64;
$ctrl{'blogmaxln'}  = 50;
$ctrl{'noclinav'}  = 1;
$ctrl{'l00file'}->{'l00://_notes.txt'} = "A sample ram file.\nContent is lost when shutdown\nChange 'ram' for a separate ram file";
$ctrl{'iamsleeping'} = 'no';
$ctrl{'adbrsyncopt'} = "-e 'ssh -p 30339'";

$nopwtimeout = 0;


#my $dlog  =  $ctrl{'dlog'};
#&$dlog ("asd");


$ctrl{'bbox'} = '';
# overwritable from l00httpd.cfg
$ctrl{'os'} = '(unknown)';
$ctrl{'machine'} = '(unknown)';
if (defined ($ENV{'ANDROID_ROOT'})) {
    if (open (IN, "</proc/cpuinfo")) {
        while (<IN>) {
            if (/Hardware\W*: *(.+) */) {
                $ctrl{'machine'} = $1;
            }
        }
    }
    if ($ENV{'HOME'} eq '/data/data/com.termux/files/home') {
        $ctrl{'os'} = 'tmx';
        $ctrl{'machine'} = "TERMUX: $ctrl{'machine'}";
    } else {
        $ctrl{'os'} = 'and';
        $ctrl{'bbox'} = 'busybox ';
        $ctrl{'droid'} = Android->new();
    }
} elsif ($^O eq 'cygwin') {
    $ctrl{'os'} = 'cyg';
    $ctrl{'machine'} = $ENV{'COMPUTERNAME'};
} elsif ($^O eq 'MSwin32') {
    $ctrl{'os'} = 'win';
    $ctrl{'machine'} = $ENV{'COMPUTERNAME'};
} elsif (defined ($ENV{'WINDIR'}) || defined ($ENV{'windir'})) {
    $ctrl{'os'} = 'win';
    $ctrl{'machine'} = $ENV{'COMPUTERNAME'};
} elsif ($^O eq 'linux') {
    # are we running on Openshift?
    if (defined($ENV{'OPENSHIFT_BUILD_SOURCE'}) && 
        ($ENV{'OPENSHIFT_BUILD_SOURCE'} =~ 
        /l00g33k/)) {
        # on RHC
        $ctrl{'os'} = 'rhc';
    } else {
        $ctrl{'os'} = 'lin';
    }
    # didn't work on ubuntu
    #$ctrl{'machine'} = $ENV{'HOSTNAME'};
    $ctrl{'machine'} = `echo \$HOSTNAME`;
}
print "Running on '$ctrl{'os'}' OS '$ctrl{'machine'}' machine\n";

# 1) Searches in own directory for filenames like l00http_(\w*)\.pl and remember them

# find out the path to this script and search for modules (matching l00http_(\w*)\.pl)
#if ($ctrl{'os'} eq 'and') {
#    $plpath = `busybox pwd`;
#} elsif ($ctrl{'os'} eq 'lin') {
#    $plpath = `pwd`;
#} else {
#    $plpath = `cd`;
#}
#$plpath = cwd();
#$plpath =~ s/\r//g;
#$plpath =~ s/\n//g;
#$plpath .= '/';
#$plpath =~ s\/cygdrive/(.)\$1:\;
#if ($0 =~ /^(.+[\\\/])[^\\\/]+$/) {
#    $plpath = $1;
#}
$ctrl{'plpath'} = $plpath;      # make it available to modules

if ($ctrl{'os'} eq 'rhc') {
    $ctrl{'demomsg'} = "<font style=\"color:black;background-color:aqua\">See this <a href=\"https://l00g33k.wordpress.com/category/wikiplandintro/\">blog</a> for details about this site.</font> ";
}


sub readl00httpdcfg {
    my ($confpath, $cnt, $key, $val);

    # set default 'workdir' on first run
    if (!defined ($ctrl{'workdir'})) {
        # sets default if not defined in l00httpd.txt
        $ctrl{'workdir'} = "$plpath"."l00httpd/";      # make it available to modules
    } elsif (!-d $ctrl{'workdir'}) {
        # workdir is not a dir, use default
        $ctrl{'workdir'} = "$plpath"."l00httpd/";      # make it available to modules
    }


# Looking fir l00httpd.cfg in 4 places
# 0: ${plpath}l00httpd.cfg
# 1: $ctrl{'workdir'}l00httpd.cfg
# 2: ${plpath}l00httpd.cfg.local
# 3: $ctrl{'altcfg'}l00httpd.cfg

    # Looking fir l00httpd.cfg in 4 places
    # 0: ${plpath}l00httpd.cfg
    # 1: ${plpath}l00httpd.cfg.local
    # 2: $ctrl{'workdir'}l00httpd.cfg
    # 3: $ctrl{'workdir'}l00httpd.cfg.local
    $cfgedit = '';
    for ($cnt = 0; $cnt <= 3; $cnt++) {
        if ($cnt == 0) {
            $confpath = "${plpath}l00httpd.cfg";
        } elsif ($cnt == 1) {
            # $plpath could change but not expected
            $confpath = "${plpath}l00httpd.cfg.local";
        } elsif ($cnt == 2) {
            $confpath = "$ctrl{'workdir'}l00httpd.cfg";
	    } else {
            $confpath = "$ctrl{'workdir'}l00httpd.cfg.local";
	    }
        print "Trying  $confpath...\n";
        if (open (IN, "<$confpath")) {
            if ($cfgedit eq '') {
                $cfgedit = "Edit l00httpd.cfg at:<br>\n";
            }
            $cfgedit .= "&nbsp;&nbsp;&nbsp;<a href=\"/edit.htm?path=$confpath\">$confpath</a><br>\n";
            print "Reading $confpath...\n";
            # machine specific filter
            $skip = 0;
            $skipfilter = '.';
            while (<IN>) {
                if (/^#/) {
                    next;
                }
        
                s/\r//g;
                s/\n//g;
                if (/^machine=~\/(.+)\/ */) {
                    # new machine filter
                    $skipfilter = $1;
                    if ($ctrl{'machine'} =~ /$skipfilter/) {
                        # matched, don't skip
                        $skip = 0;
                    } else {
                        # no match, skipping
                        $skip = 1;
                    }
                    next;
                }
                if ($skip) {
                    next;
                }

                ($key, $val) = split ('\^');
                if ((defined ($key)) &&
                    (length ($key) > 0)) {
                    if ((defined ($val)) &&
                        (length ($val) > 0)) {
                        print ">$key< = >$val<\n";;
                        if ($key eq 'workdir') {
                            # special case workdir to accept only if exist
                            $val =~ s/%PLPATH%/$plpath/;    # only fly plpath translation
                            if (-d $val) {
                                $ctrl{$key} = $val;
                            }
                            print "workdir EXIST: $ctrl{$key}\n";
                        } else {
                            $ctrl{$key} = $val;
                        }
                        if ($key =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                            $ipallowed{$1}  = "yes";
                        }
                    } else {
                        # undefine it
                        print "Undefine >$key<\n";;
                        undef $ctrl{$key};
                    }
                }
            }
            close (IN);
        }
    }


    foreach $key (keys %ctrl) {
        if (defined($ctrl{$key})) {
            if ($ctrl{$key} =~ /%PLPATH%/) {
                print "$ctrl{$key} => ";
                $ctrl{$key} =~ s/%PLPATH%/$plpath/g;
                print "$ctrl{$key}\n";
            }
            if ($ctrl{$key} =~ /%WORKDIR%/) {
                print "$ctrl{$key} => ";
                $ctrl{$key} =~ s/%WORKDIR%/$ctrl{'workdir'}/g;
                print "$ctrl{$key}\n";
            }
            if ($ctrl{$key} =~ /%WORKDIR2%/) {
                print "$ctrl{$key} => ";
                $ctrl{$key} =~ s/%WORKDIR2%/$ctrl{'workdir2'}/g;
                print "$ctrl{$key}\n";
            }
        }
    }

    # RHC special: make clipath at Perl directory so everything below is viewable by default
    if ($ctrl{'os'} eq 'rhc') {
        # on RHC
        $nopwtimeout = 0x7fffffff;
    }

    # check 'quick' from 'l00httpd.cfg'
    if (!defined ($ctrl{'quick'})) {
        # sets default if not defined in l00httpd.txt
        # make it available to modules
        $ctrl{'quick'} = "/ls.htm/quick.htm?path=$ctrl{'workdir'}index.txt";
    }
    # check if target exist
    if ($ctrl{'quick'} =~ m|^/ls\.htm|) {
        # points to ls.pl
        if (($_) = $ctrl{'quick'} =~ m|path=(.+)&*|) {
            print "Quick target: $_\n";
            if (!-f $_) {
                print "target does not exist >$_<\n";
                $ctrl{'quick'} = "/ls.htm/quick.htm?path=$ctrl{'workdir'}index.txt";
            }
        }
    }
    if (!defined ($ctrl{'HOME'})) {
        # sets default if not defined in l00httpd.txt
        # make it available to modules
        $ctrl{'HOME'} = "<a href=\"/ls.htm/HOME.htm?path=$ctrl{'workdir'}index.txt\">HOME</a>"
    }
    # check if target exist
    if ($ctrl{'HOME'} =~ m|^/ls\.htm|) {
        # points to ls.pl
        if (($_) = $ctrl{'HOME'} =~ m|path=(.+)&*|) {
            print "HOME target: $_\n";
            if (!-f $_) {
                print "target does not exist >$_<\n";
                $ctrl{'HOME'} = "<a href=\"/ls.htm/HOME.htm?path=$ctrl{'workdir'}index.txt\">HOME</a>"
            }
        }
    }
    if ($cmdlnhome ne '') {
        # use command line supplied HOME target
        # on start up $ctrl{'HOME'} is set by ARGV parser
        $ctrl{'HOME'} = "<a href=\"/ls.htm/HOME.htm?path=$cmdlnhome\">HOME</a>"
    }


    # tmp not defined in l00httpd.cfg
    if (!defined ($ctrl{'tmp'})) {
        $ctrl{'tmp'} = "$ctrl{'workdir'}/";      # make it available to modules
    }
}

&readl00httpdcfg;

# read .whoami
print "Reading $ctrl{'workdir'}.whoami\n";
if (open(IN, "<$ctrl{'workdir'}.whoami")) {
    $ctrl{'whoami'} = <IN>;
    $ctrl{'whoami'} =~ s/[\r\n]//g;
    close(IN);
}
if (!defined($ctrl{'whoami'})) {
    $ctrl{'whoami'} = 'unknown';
}


# parse commandline arguments
while ($_ = shift) {
    # perl l00httpd.pl cliport=8080 ctrlport=10000 hostip=?
    if (/^ctrlport=(\d+)/) {
        $ctrl_port = $1;
        print "ctrlport set to $ctrl_port\n";
    } elsif (/^cliport=(\d+)/) {
        $cli_port = $1;
        print "cliport set to $cli_port\n";
    } elsif (/^fixedport/) {
        $fixedport = 1;
        print "fixedport set to 1\n";
    } elsif (/^cfg=(\w+?)\^(.+)/) {
        # looks like config name^value
        $ctrl{$1} = $2;
        print "cfg=$1^$2\n";
    } elsif (/^quitinsec=(\d+)/) {
        $quitattimer = $1;
    } elsif (/^hostip=(.+)/) {
        $host_ip = $1;
        print "hostip set to $host_ip\n";
    } elsif (/^debug=(.+)/) {
        $debug = $1;
        $ctrl{'debug'} = $debug;
        print "debug set to $debug\n";
    } elsif (/^home=(.+)/) {
        $cmdlnhome = $1;
        print "home set to $cmdlnhome\n";
        $ctrl{'HOME'} = "<a href=\"/ls.htm/HOME.htm?path=$cmdlnhome\">HOME</a>"
    } elsif (/^nopwmod=(.+)/) {
        $nopwtimeout = ":$1:";
        print "nopwmod is ':$nopwtimeout:'\n";
    } elsif (/^open$/) {
	    $nopwtimeout = 0x7fffffff;
        $ctrl{'noclinav'}  = 0;
        $ctrl{'clipath'}  = '/';
		$open = 1;
	} elsif (($key, $val) = /(\w+)\^(.+)/) {
        # looks like config name^value
        if ((defined ($key)) &&
            (length ($key) > 0) && 
            (defined ($val)) &&
            (length ($val) > 0)) {
            print "cmdln>$key< = >$val<\n";;
            if ($key eq 'workdir') {
                # special case workdir to accept only if exist
                if (-d $val) {
                    $ctrl{$key} = $val;
                }
            } else {
                $ctrl{$key} = $val;
            }
        }
	} elsif (($key) = /(\w+)\^$/) {
        if ((defined ($key)) &&
            (length ($key) > 0)) {
            undef $ctrl{$key};
        }
    } else {
        # none of the above
        # if it has '\' or '/', it's a path
        # else it's a module name
        if (/[\\\/]/) {
            $cmdlnparam = $_;
        } else {
            $cmdlnmod = $_;
        }
    }
}
$ctrl_port_first = $ctrl_port;


if (($cmdlnmod ne '') && ($cmdlnparam ne '')) {
    # use command line supplied mod and path as HOME target
    $ctrl{'HOME'} = "<a href=\"/$cmdlnmod.htm?path=$cmdlnparam\">HOME</a>";
}

if ((defined ($ctrl{'debug'})) && ($ctrl{'debug'} =~ /^\d$/)) {
    $debug = $ctrl{'debug'};
}

if (defined ($ctrl{'idpwmustbe'})) {
    $idpwmustbe = $ctrl{'idpwmustbe'};
    $ctrl{'idpwmustbe'} = undef;
}



sub loadmods {
    my ($thisplpath) = @_;
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks);
    my ($newestmtime, $newestmod);

    if (defined($thisplpath)) {
        # scan directory
        if (opendir (DIR, $thisplpath)) {
            foreach $file (sort readdir (DIR)) {
                if ($file =~ /^l00http_(\w*)\.pl/) {
                    # match prefix and suffix, remember it
                    $httpmods {$1} = $thisplpath . "l00http_$1.pl";
                }
            }
            closedir (DIR);
        }

        $newestmtime = 0;
        # load modules
        print "(Re)Loading modules from $thisplpath...\n";
        foreach $mod (sort keys %httpmods) {
            ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
            $size, $atime, $mtimea, $ctime, $blksize, $blocks)
            = stat($httpmods{$mod});

            if ((!defined($httpmodssig{$mod})) || 
                ($httpmodssig{$mod} ne "$size $mtimea")) {
                # never loaded or signature changed, reload
                # remember file signature for smart reload
                $httpmodssig{$mod} = "$size $mtimea";

                if ($newestmtime < $mtimea) {
                    $newestmtime = $mtimea;
                    $newestmod = $mod;
                }

                print "$mod ";
                $rethash = do $httpmods{$mod};
                if (!defined ($rethash)) {
                    if ($!) {
                        print "Can't read module '$httpmods{$mod}': $!\n";
                    } elsif ($@) {
                        print "Can't parse module '$httpmods{$mod}': $@\n";
                    }
                } else {
                    # default to disabled to non local clients
                    $modsinfo{"$mod:ena:checked"} = "";
                    $modsinfo{"$mod:fn:desc"} = $rethash->{'desc'};
                    $modsinfo{"$mod:fn:proc"} = $rethash->{'proc'};
                    $modsinfo{"$mod:fn:perio"} = $rethash->{'perio'};
                    $modsinfo{"$mod:fn:shutdown"} = $rethash->{'shutdown'};
                    $subname = $modsinfo{"$mod:fn:desc"};
                    $moddesc{$mod} = __PACKAGE__->$subname(\%ctrl);
                    $tmp = 'unknown:';
                    if ($moddesc{$mod} =~ /^( *[^ ]+ *[^ ]*)/) {
                        $tmp = $1;
                    }
                    $tmp .= $mod;
                    $httpmodssort{$tmp} = $mod;
                    l00httpd::dbp("l00httpd", "Loaded $mod\n");
                }
            }
        }

        # print l00httpd.pl time stamp
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
        = stat("${plpath}l00httpd.pl");
        ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
         = localtime($mtimea);
        printf ("\nl00httpd.pl at %4d/%02d/%02d %02d:%02d:%02d\n", 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
        if ($newestmtime > 0) {
            # print newest module time stamp
            ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
             = localtime($newestmtime);
            print "Newest module loaded is '$newestmod' at ";
            printf ("%4d/%02d/%02d %02d:%02d:%02d\n", 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
        }
        print "Ready\n";
    }
}
$ctrl{'modsinfo'} = \%modsinfo;



# 2) Open a listening socket
my ($reuseflag);
if ($ctrl{'os'} eq 'win') {
    $reuseflag = 0;
} else {
    # so won't have to wait to reuse same port on Android
    $reuseflag = 1;
}

# create a listening socket 
$tmp = 100;
do {
    $ctrl_lstn_sock = IO::Socket::INET->new (
        LocalPort => $ctrl_port,
        LocalAddr => $host_ip,
        Listen => 5, 
        ReuseAddr => $reuseflag  # Reuse => 1
    );
    if (!$ctrl_lstn_sock) {
        if ($fixedport) {
            # wait for port to be available
            print "Port $ctrl_port is not available. Sleep 3 secs and try again. ($tmp)\n";
            sleep (3);
        } else {
            $ctrl_port += 10;
        }
        $tmp--;
    }
} while (!$ctrl_lstn_sock && ($tmp >= 0));
die "Can't create socket for listening: $!" unless $ctrl_lstn_sock;
print "ctrl_port is $ctrl_port\n";
$ctrl{'ctrl_port_first'}  = $ctrl_port_first;
$ctrl{'ctrl_port'} = $ctrl_port;

# load modules
&loadmods($plpath);
&loadmods($ctrl{'extraplpath'});

$tmp = 100;
do {
    $cli_lstn_sock = IO::Socket::INET->new (
        LocalPort => $cli_port,
        LocalAddr => $host_ip,
        Listen => 5, 
        ReuseAddr => 0  # Reuse => 1
    );
    if (!$cli_lstn_sock) {
        if ($fixedport) {
            # wait for port to be available
            print "Port $cli_port is not available. Sleep 3 secs and try again. ($tmp)\n";
            sleep (3);
        } else {
            $cli_port += 10;
        }
        $tmp--;
    }
} while (!$cli_lstn_sock && ($tmp >= 0));
die "Can't create socket for listening: $!" unless $cli_lstn_sock;
print "ctrl_port is $ctrl_port\n";
print "cli_port  is $cli_port\n";
print STDERR "ctrl_port http://localhost:$ctrl_port\n";
print STDERR "cli_port  http://localhost:$cli_port\n";
$_ = &getsvrip();
print STDERR "cli_port  http://$_:$cli_port\n";

if (($cmdlnmod ne '') && ($cmdlnparam ne '')) {
    print STDERR "\n\nYou have specified the module '$cmdlnmod' ".
        "for the target '$cmdlnparam'.  Visit it at this URL\n".
        "\nhttp://localhost:$ctrl_port\n";
}

my $readable = IO::Select->new;     # Create a new IO::Select object
$readable->add($ctrl_lstn_sock);    # Add the lstnsock to it
$readable->add($cli_lstn_sock);    # Add the lstnsock to it

sub periodictask {
    my ($who);

    if ($ctrl_port_first == $ctrl_port) {
        # execute periodic tasks only on first instance
        $tickdelta = 3600;	# tick once an hour
        &updateNow_string ();

        $who = 'unknown';

        foreach $mod (sort keys %httpmods) {
            if (defined ($modsinfo{"$mod:fn:perio"})) {
                $ctrl{'httphead'}  = "HTTP/1.0 200 OK\x0D\x0A\x0D\x0A";
                $subname = $modsinfo{"$mod:fn:perio"};
                $retval = 60;
                $retval = __PACKAGE__->$subname(\%ctrl);
                if (defined ($retval) && ($retval > 0)) {
                    if ($retval < 1000000) {
                        &dlog (6, "perio: $mod:fn:perio -> $retval\n");
                    }
                    if ($tickdelta > $retval) {
                        $tickdelta = $retval;
                        $who = $mod;
                    }
                }
            }
        }

        # don't sleep beyond time to quit
        if ($tickdelta > ($quitattime - time)) {
            $tickdelta = ($quitattime - time);
        }
        # sleep at least 1 second
        if ($tickdelta <= 0) {
            $tickdelta = 1;
        }

        &dlog (2, "$ctrl{'now_string'} tick $tickdelta (next: $who)\n");

        if (($waketil != 0) &&
            ($waketil < time) &&
            ($ctrl{'os'} eq 'and')) {
            # $waketil is active, turn it off
            $waketil = 0;
            # release wake lock
            $ctrl{'droid'}->wakeLockRelease();
            $ctrl{'BANNER:wakelock'} = undef;
        }
    }
}

$uptime = time;
$ttlconns = 0;
$tickdelta = 3600;
# don't sleep beyond time to quit
if ($tickdelta > ($quitattime - time)) {
    $tickdelta = ($quitattime - time);
}
# sleep at least 1 second
if ($tickdelta <= 0) {
    $tickdelta = 1;
}

&updateNow_string ();
# start new log
dlog (2, "$ctrl{'now_string'} WikiPland started ($cli_port)\n");


$ctrl{'l00file'}->{'l00://server.log'} = '';
# disable restoration...
## restore server.log
#if (open(OU,"<${plpath}.server.log.persist")) {
#    while (<OU>) {
#        $ctrl{'l00file'}->{'l00://server.log'} .= $_;
#    }
#    close(OU);
#    unlink("${plpath}.server.log.persist");
#}

$ctrl{'l00file'}->{'l00://server.log'} .= "$ctrl{'now_string'} WikiPland started\n";

# disable restoration...
## restore client log
#if (open(OU,"<${plpath}.client.log.persist")) {
#    while (<OU>) {
#        s/\n//;
#        s/\r//;
#        if (/^(.+)=>(\d+)$/) {
#            $connected{$1} = $2;
#        }
#    }
#    close(OU);
#    unlink("${plpath}.client.log.persist");
#}


$l00time = time;

&periodictask ();

if ($ctrl{'os'} eq 'and') {
    $ctrl{'droid'}->makeToast("Welcome to l00httpd\nPlease browse to http://127.0.0.1:$ctrl_port\nSee Notification");
    $ctrl{'droid'}->notify ("Welcome to l00httpd", "Browse to http://127.0.0.1:$ctrl_port");
}

while(1) {
    # Get a list of sockets that are ready to talk to us.
    print "Before Select->select()\n", if ($debug >= 5);
    my ($ready) = IO::Select->select($readable, undef, undef, $tickdelta);
    print "After Select->select()\n", if ($debug >= 5);
    &updateNow_string ();
    &dlog (2, "$ctrl{'now_string'} ".sprintf ("%4ds ago ", time - $l00time));
    $l00time = time;
    $clicnt = 0;
    foreach my $curr_socket (@$ready) {
        if (($debug >= 3) && $hiresclock) {
            $hiresclockmsec = Time::HiRes::time();
        }
        print "curr_socket = $curr_socket\n", if ($debug >= 5);
        if(($curr_socket == $ctrl_lstn_sock) ||
           ($curr_socket == $cli_lstn_sock)) {
            print "ready curr_socket = $curr_socket\n", if ($debug >= 5);
            $clicnt++;
            if($curr_socket == $ctrl_lstn_sock) {
                # some one sent to our listening socket
                $sock = $ctrl_lstn_sock->accept;
            } else {
                # some one sent to our listening socket
                $sock = $cli_lstn_sock->accept;
            }
            $addr = $sock->peeraddr ();         # get peer address
            if ((!defined ($addr)) || (length ($addr) != 4)) {
                # bad peer address?
                $sock->close;
                next;
            }
            $client_ip = inet_ntoa ($addr);     # convert to readable
            print "client_ip = $client_ip\n", if ($debug >= 5);
            if($curr_socket == $ctrl_lstn_sock) {
                if ((($host_ip ne '0.0.0.0') &&
                    ($client_ip eq $host_ip)) ||
                    ($client_ip eq "127.0.0.1")) {
                    $ishost = 1;
                } else {
                    $ishost = 0;
                }
            } else {
                $ishost = 0;
            }
            if (($debug >= 3) && $hiresclock) {
                $hiresclockmsec = Time::HiRes::time() - $hiresclockmsec;
                l00httpd::dbp("l00httpd", sprintf("%8.3f ms Socket connected --------------------\n", $hiresclockmsec * 1000));
                $hiresclockmsec = Time::HiRes::time();
            }
            $ctrl{'ishost'} = $ishost;
            $ctrl{'myip'} = &getsvrip();
            print "ip = $ctrl{'myip'}\n", if ($debug >= 5);
            if (defined ($connected{$client_ip})) {
                $connected{$client_ip}++;
            } else {
                $connected{$client_ip} = 1;
            }
            $ttlconns++;
            if (($debug >= 3) && $hiresclock) {
                $hiresclockmsec = Time::HiRes::time() - $hiresclockmsec;
                l00httpd::dbp("l00httpd", sprintf("%8.3f ms Host identified\n", $hiresclockmsec * 1000));
                $hiresclockmsec = Time::HiRes::time();
            }
            if (($ctrl{'ipfil'} eq "yes") &&
                (!defined ($ipallowed{$client_ip}))) {
                print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title>" . $ctrl{'htmlhead2'};
                print $sock "$ctrl{'now_string'}: Your IP is $client_ip. \n";
                print $sock sprintf ("up: %.3fh", (time - $uptime) / 3600.0);
                print $sock $ctrl{'htmlfoot'};
                $sock->close;
                next;
            }
            $idpw = "";
            $urlparams = "";

            # default module to invoke
            if (($ishost) ||           # client enabled or is server
                ((defined ($modsinfo{"ls:ena:checked"})) &&
                 ($modsinfo{"ls:ena:checked"} eq "checked"))) {
                $modcalled = "_none_";     # aka module name
            } else {
                # invoke 'hello' if not host and 'ls' not enabled
                $modcalled = "hello";     # aka module name
            }

            # print date, time, client IP, password, and module names
            print "------------ processing HTTP request header ----------------------\n", if ($debug >= 4);

            # 3) Parse client HTTP submission and identify module plugin name
            $rin = '';
            vec($rin,fileno($sock),1) = 1;
            select ($rout = $rin, undef, $eout = $rin, 0.25); # public network needs 3 sec?
            if (vec($eout,fileno($sock),1) == 1) {
                print "sock error\n";
                next;
            } elsif (vec($rout,fileno($sock),1) == 1) {
                $httpsiz = sysread ($sock, $httpbuf, $httpmax);
                if (!defined($httpsiz) || ($httpsiz <= 0)) {
                    next;
                }
            } else {
                print "sock timeout 0.01s\n", if ($debug >= 4);
                $sock->close;
                next;
            }
            print "httpsiz $httpsiz\n", if ($debug >= 5);
            if ($httpsiz <= 0) {
                &dlog (3, "\nfailed to read from socket. Abort\n");
                $sock->close;
                next;
            }
            &dlog (2, "client $client_ip ");
            $postlen = -1;
            $httphdz = -1;
            if ($httpbuf =~ /^POST +/) {
                $tmp = index ($httpbuf, "Content-Length:");
                if ($tmp >= 0) {
                    if (substr ($httpbuf, $tmp + 15, 10)  =~ /(\d+)/) {
                        $postlen = $1;
                    }
                }
                $httphdz = index ($httpbuf, "\x0D\x0A\x0D\x0A");
                if ($httphdz >= 0) {
                    $httphdz += 4;
                }
                print "postlen = $postlen $httpsiz $httphdz\n", if ($debug >= 4);
                while (($postlen == -1) || ($httphdz == -1) ||
                    ($httpsiz < ($httphdz + $postlen))) {
                    $tmp = sysread ($sock, $buf, $httpmax);
                    print "httpsiz tmp $tmp\n", if ($debug >= 5);
                    if ($tmp > 0) {
                        $httpbuf .= $buf;
                        $httpsiz += $tmp;
                    } else {
                        last;
                    }
                    $tmp = index ($httpbuf, "Content-Length:");
                    if ($tmp >= 0) {
                        if (substr ($httpbuf, $tmp + 15, 10)  =~ /(\d+)/) {
                            $postlen = $1;
                        }
                    }
                    $httphdz = index ($httpbuf, "\x0D\x0A\x0D\x0A");
                    if ($httphdz >= 0) {
                        $httphdz += 4;
                    }
                    print "postlen = $postlen $httpsiz $httphdz\n", if ($debug >= 4);
                }
            } else {
                $postlen = -1;
                $httphdz = $httpsiz;
            }
            print "httpsiz $httpsiz >>>$httpbuf<<<\n", if ($debug >= 5);

            # Openshift demo: give a warning when we are quiting
            if (time > $quitattime) {
                print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>Openshift WikiPland Demo</title>" . $ctrl{'htmlhead2'};
                print $sock "$ctrl{'now_string'}: Your IP is $client_ip. \n";
                print $sock sprintf ("up: %.3fh", (time - $uptime) / 3600.0);
                print $sock "<p>Live demo timer has expired and the application will quit.\n";
                print $sock "The Docker container will restart erasing all changes made.<p>\n";
                print $sock $ctrl{'htmlfoot'};
                $sock->close;
                next;
            }

            $httpmethod = '(unknown)';
            if ($httpbuf =~ /^HEAD (\/[^ ]*) HTTP/) {
                $httpmethod = 'HEAD';
                # HEAD: post head only
                print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title></head>\x0D\x0A</html>\n";
                $sock->close;
                # log it any way
                $ctrl{'l00file'}->{'l00://server.log'} .= "$ctrl{'now_string'} $client_ip $httpmethod $1\n";
                next;
            } elsif ($httpbuf =~ /^POST /) {
                $httpmethod = 'POST';
                # POST
                $httphdr = substr ($httpbuf, 0, $httphdz);
                $httpbdz = $httpsiz - $httphdz;
                $httpbdy = substr ($httpbuf, $httphdz, $httpbdz);
            } else {
                if ($httpbuf =~ /^(\w+) /) {
                    $httpmethod = $1;
                }
                # GET
                $httphdr = $httpbuf;
                print "GET?\n", if ($debug >= 4);
            }
            if (($debug >= 3) && $hiresclock) {
                $hiresclockmsec = Time::HiRes::time() - $hiresclockmsec;
                l00httpd::dbp("l00httpd", sprintf("%8.3f ms HTTP requested data received\n", $hiresclockmsec * 1000));
                $hiresclockmsec = Time::HiRes::time();
            }
            print "httpsiz $httpsiz httphdz $httphdz\n", if ($debug >= 4);


            # read in browser submission
            $httphdr =~ s/\r//g;
            $postboundary = '';
            $ctrl{'htmlhead'} = $htmlheadV1 . $htmlheadB0;
            foreach $_ (split ("\n", $httphdr)) {
                if (/^\x0D\x0A$/) {
                    # end of submission
                    last;
                }
                if (/Authorization: Basic (.+)/) {
                    # password authentication, save it
                    $idpw = &l00base64::b64decode ($1);
                } elsif (/GET (\/[^ ]*) HTTP/) {
                    # extract the URL after the domain
                    $urlparams = $1;
                } elsif (/POST (\/[^ ]*) HTTP/) {
                    # extract the URL after the domain
                    $urlparams = $1;
                } elsif (/^X-Forwarded-For: *([0-9.:a-fA-F]+)/) {
                    # extract the client IP when hosting on Openshift v3
                    # X-Forwarded-For: 12.34.56.78
                    $client_ip = $1;
                    # double IP recording but that's ok
                    if (defined ($connected{$client_ip})) {
                        $connected{$client_ip}++;
                    } else {
                        $connected{$client_ip} = 1;
                    }
                } elsif (/^X-Client-IP: *([0-9.:a-fA-F]+)/) {
                    # extract the client IP when hosting on rhcloud.com
                    $client_ip = $1;
                    # double IP recording but that's ok
                    if (defined ($connected{$client_ip})) {
                        $connected{$client_ip}++;
                    } else {
                        $connected{$client_ip} = 1;
                    }
                } elsif (/^User-Agent:.*Android +5/i) {
                    # Android 5.1: <!DOCTYPE html XHTML Mobile seems to make single column display
                    # This makes it more compact
                    $ctrl{'htmlhead'} = $htmlheadV2 . $htmlheadB0;
                } elsif (m|^Content-Type: multipart/form-data; boundary=(----+.+)$|i) {
                    $postboundary = $1;
                    l00httpd::dbp("l00httpd", "Content-Type: multipart/form-data; boundary=$postboundary\n");
                }
            }

            print "$ctrl{'now_string'} $client_ip FORM: $urlparams\n", if ($debug >= 1);
            $ctrl{'l00file'}->{'l00://server.log'} .= "$ctrl{'now_string'} $client_ip $httpmethod $urlparams\n";

            # Wii will not render HTML if URL ends in .txt; it ignores after '?'
            if (($urlparams eq '/') &&              # no path
                ($curr_socket != $ctrl_lstn_sock)   # not on control port
                ) {
                # default to hello module
                $modcalled = "hello";
                $urlparams = "";
            } elsif (($urlparams eq '/') &&      # no path
                ($ctrl{'os'} eq 'and') &&   # on Android
                !(-d '/sdcard/l00httpd')    # not localized
                ) {
                # the form 'http://localhost:20337'
                # point to welcome page
                $modcalled = "ls";
                $urlparams = "path=$plpath"."docs_demo/QuickStart.txt";
            } elsif (($urlparams eq '/') &&      # no path
                ($ctrl{'os'} eq 'rhc')           # on RHC
                ) {
                # the form 'http://localhost:20337/'
                # point to welcome page
                $modcalled = "ls";
                $urlparams = "path=$plpath"."docs_demo/QuickStart.txt";
            } elsif ($urlparams =~ /^\/ls\.(pl|htm)\/([^?&]+)$/) {
                # of form: http://localhost:20337/ls.htm//mnt/win/wk/sikulix/irfanview.png
                $modcalled = 'ls';
                $urlparams = "path=$2";
            } elsif ($urlparams =~ /^\/(\w+)\.pl[^?]*\?*(.*)$/) {
                # allows ls.pl/a.jpg to display jpg
                # of form: http://localhost:20337/ls.pl?path=/sdcard
                $modcalled = $1;
                $urlparams = $2;
            } elsif ($urlparams =~ /^\/(\w+)\.htm[^?]*\?*(.*)$/) {
                # allows ls.htm/a.jpg to display jpg
                # of form: http://localhost:20337/ls.htm?path=/sdcard
                $modcalled = $1;
                $urlparams = $2;
            } elsif ($urlparams =~ /^\/(\w+)\?+(.*)$/) {
                # of form: http://localhost:20337/ls?path=/sdcard
                $modcalled = $1;
                $urlparams = $2;
            } elsif ($urlparams =~ /^\/(l00:\/\/.+)$/) {
                # of form: http://localhost:20337/l00://mydata.csv
                $modcalled = "ls";
                $urlparams = "path=$1&raw=on";
            } elsif ($urlparams =~ /^(\/.+)$/) {
                # of form: http://localhost:20337/ls?path=/sdcard
                $modcalled = "ls";
                $urlparams = "path=$1&raw=on";
            }

            if (($modcalled eq '_none_') &&
                ($cmdlnmod ne '') && 
                ($cmdlnparam ne '')) {
                $modcalled = $cmdlnmod;
                $urlparams = "path=$cmdlnparam";
            }

            print "$ctrl{'now_string'}: $client_ip Auth>$idpw< /$modcalled\n", if ($debug >= 4);

            $needpw = 1;
            if ($nopwtimeout =~ /:$modcalled:/) {
                # it works even though it gives this warning message:
                # Argument ":scratch:" isn't numeric in numeric gt (>) at 00l00httpd.pl line 456.
                # disable password protection for module
                $needpw = 0;
            } elsif ($nopwtimeout > time) {
                # disable password protection
                $needpw = 0;
            } elsif (defined ($ctrl{'nopwpath'})) {
                if (($urlparams =~ /^$ctrl{'nopwpath'}/) || 
                    ($urlparams =~ /path=$ctrl{'nopwpath'}/)) {
                    $needpw = 0;
                }
            }
            # check id:pw
            if ($needpw &&
                ($idpw ne $idpwmustbe) &&
                (!$ishost)) {

                $httpszhd = "HTTP/1.0 401 OK\x0D\x0A".
                    "WWW-Authenticate: Basic realm=\"personal\"\x0D\x0A";
                $httpszbd = "<html><body>\x0D\x0ALogin required</body></html>\x0D\x0A";
                $httpsz = length ($httpszbd);
                $tmp = "$httpszhd"."Content-Length: $httpsz\x0D\x0A\x0D\x0A$httpszbd";
                print $sock $tmp;
                $sock->close;
                print "$ctrl{'now_string'}: Requiring login\n", if ($debug >= 5);
                next;
            }
            &dlog (2, "($modcalled): $urlparams\n");
            
            if ($postlen > 0) {
                $urlparams = $httpbdy;
            }
            if ($debug >= 3) {
                $tmp = substr ($urlparams, 0, 160);
                &dlog (3, "FORM mod:$modcalled urlget:$tmp\n");
            }

            # prepare to extract form data
            undef %FORM;
            if ($postboundary ne '') {
                # We saw Content-Type: multipart/form-data; boundary=---------------------------7de3003160be2
                # because we specified enctype="multipart/form-data"
                @cmd_param_pairs = split ("--$postboundary", $urlparams);
                foreach $_ (@cmd_param_pairs) {
                    # look for \r\n\r\n marking start of data
                    $tmp = index ($_, "\x0D\x0A\x0D\x0A");
                    if ($tmp >= 0) {
                        $tmp += 4;
                        # add 4 for \r\n\r\n
                        # extract data
                        $tmp = substr ($_, $tmp, length($_) - $tmp - 2);
                        # - 2 to remove \r\n
                    } else {
                        $tmp = '';
                    }
                    #Content-Disposition: form-data; name="myfile"; filename="C:\x\strings.xml"
                    # 'myfile' must match l00http_uploadfile.pl
                    #     print $sock "<input id=\"myfile\" name=\"myfile\" type=\"file\">\n";
                    if (/Content-Disposition: form-data; name="myfile"; filename="([^"]+)"/i) {
                        $FORM{'filename'} = $1;
                        $FORM{'payload'} = $tmp;
                        l00httpd::dbp("l00httpd", "FORM{'filename'}=>$FORM{'filename'}<\n");
                        #print "FORM{'payload'}=>$FORM{'payload'}<\n";
                    } elsif (/Content-Disposition: form-data; name="([^"]+)"/i) {
                        $FORM{$1} = $tmp;
                        l00httpd::dbp("l00httpd", "FORM{'$1'}=>$FORM{$1}<\n");
                    }
                }
            } else {
                $urlparams =~ s/\r//g;
                $urlparams =~ s/\n//g;
                @cmd_param_pairs = split ('&', $urlparams);
                foreach $cmd_param_pair (@cmd_param_pairs) {
                    ($name, $param) = split ('=', $cmd_param_pair);
                    if (defined ($name) && defined ($param)) {
                        $param =~ tr/+/ /;
                        $param =~ s/\%([a-fA-F0-9]{2})/pack("C", hex($1))/seg;
                        $FORM{$name} = $param;
                        if ($debug >= 4) {
                            $tmp = substr ($FORM{$name}, 0, 160);
                            print "FORMDATA $name=$tmp\n";
                        }
                        # convert \ to /
                        if ($name eq 'path') {
                            $FORM{$name} =~ tr/\\/\//;
                        }
                    }
                }
            }
            print "FORM: completed urlparams processing\n", if ($debug >= 5);

            # zap mod='httpd' if no args
            if (($modcalled eq 'httpd') &&
                !($urlparams =~ /=/)) {
                $modcalled = '';
            }

            # check timeout
            if (defined ($timeout) &&  (time > $timeout)) {
                undef $timeout;
                foreach $mod (sort keys %httpmods) {
                    if (defined ($modsinfo{"$mod:fn:proc"})) {
                        $modsinfo{"$mod:ena:checked"} = "";
                    }
                }
            }

            foreach $mod (sort keys %httpmods) {
                if (defined ($ctrl{"alwayson_$mod"}) ||
                    defined ($ctrl{'allappson'})) {
                    $modsinfo{"$mod:ena:checked"} = "checked";
                }
				if ($open) {
				    # always open
                    $modsinfo{"$mod:ena:checked"} = "checked";
				}
            }

            # reset to selected brightness (Slide lost screen brightness after camera)
            if (($ctrl{'os'} eq 'and') && defined($ctrl{'slideCamBrighnessFix'})) {
                # Define below in l00httpd.cfg to fix Slide camera brightness problem
                # Slide auto switch to max brighness when camera is turned on but 
                # doesn't always restore correctly
                #slideCamBrighnessFix^justdefinethis
                if (defined($ctrl{'screenbrightness'})) {
                    $tmp = $ctrl{'droid'}->getScreenBrightness ();
                    $tmp = $tmp->{'result'};
                    if ($tmp != $ctrl{'screenbrightness'}) {
                       $ctrl{'droid'}->makeToast("Resetting brightness from $tmp to $ctrl{'screenbrightness'}");
                       $ctrl{'droid'}->setScreenBrightness ($ctrl{'screenbrightness'});
                    }
                }
            }

            if (($debug >= 3) && $hiresclock) {
                $hiresclockmsec = Time::HiRes::time() - $hiresclockmsec;
                l00httpd::dbp("l00httpd", sprintf("%8.3f ms Ready to process request\n", $hiresclockmsec * 1000));
                $hiresclockmsec = Time::HiRes::time();
            }
            # handle URL
            print "Start handling URL\n", if ($debug >= 5);
            if ($modcalled eq "restart") {
                $modcalled = '';
                $shutdown = 0;
                # reload all modules
                l00httpd::dbp("l00httpd", "Restart/reloading modules\n");
                &dlog (2, "Restart/reloading modules\n");
                &readl00httpdcfg;
                &loadmods($plpath);
                &loadmods($ctrl{'extraplpath'});
                &l00http_cron_when_next (\%ctrl);
            }
            if ($modcalled eq "exitrestart") {
                print "Exit with code 1 so shell can restart\n";
                exit (1);
            } elsif ($modcalled eq "shutdown") {
                $shutdown++;
                if ($shutdown >= 2) {
                    print "You confirm me to shutdown\n";
                    print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title>" . $ctrl{'htmlhead2'};
                    # call shutdown functions
                    $ctrl{'sock'} = $sock;
                    foreach $mod (sort keys %httpmods) {
                        if (defined ($modsinfo{"$mod:fn:shutdown"})) {
                            $subname = $modsinfo{"$mod:fn:shutdown"};
                            $retval = __PACKAGE__->$subname(\%ctrl);
                            print $sock "Called '$mod' module shutdown function<br>\n";
                        }
                    }

                    print $sock "Start new instance and click <a href=\"/\">here</a> to connect.  Note: If this is an APK installation, you must delete data in App Manager to update l00httpd.\n";
                    print $sock $ctrl{'htmlfoot'};
                    print "shutting down by shutdown module\n";
                    $sock->close;
                    # disable restoration...
                    ## save client log
                    #open(OU,">${plpath}.client.log.persist");
                    #for $key (sort keys %connected) {
                    #    $val = $connected{$key};
                    #    print OU "$key=>$connected{$key}\n";
                    #}
                    #close(OU);
                    ## save server.log
                    #open(OU,">${plpath}.server.log.persist");
                    #print OU $ctrl{'l00file'}->{'l00://server.log'};
                    #close(OU);
                    exit (0);
                } else {
                    $shutdown = 1;
                    print "You told me to shutdown\n";
                    print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title>" . $ctrl{'htmlhead2'};
                    print $sock "Click <a href=\"/shutdown.htm\">here</a> to initiate shutdown<p>\n";
                    print $sock "Click <a href=\"/exitrestart.htm\">here</a> to exit with code 1 so script can restart<p>\n";
                    print $sock "Click <a href=\"/restart.htm\">here</a> to restart<p>\n";
                    print $sock "Click <a href=\"/\">here</a> to cancel<p>\n";
                    print $sock $ctrl{'htmlfoot'};
                    $sock->close;
                    next;
                }
            } elsif ($modcalled =~ /^redirect/) {
                if (defined ($FORM{'redirecturl'})) {
                    $tmp = "<META http-equiv=\"refresh\" content=\"0;URL=$FORM{'redirecturl'}\">\r\n";
                } elsif (defined ($ctrl{$modcalled})) {
                    $tmp = "<META http-equiv=\"refresh\" content=\"0;URL=$ctrl{$modcalled}\">\r\n";
                } else {
                    $tmp = '';
                }
                print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title>" . $tmp . $ctrl{'htmlhead2'};
                print $sock "Redirect to <a href=\"$ctrl{$modcalled}\">$ctrl{$modcalled}</a><p>\n";
                print $sock $ctrl{'htmlfoot'};
            } elsif (($modcalled ne 'httpd') &&                 # not server control
                ((($ishost)) ||           # client enabled or is server
                 ((defined ($modsinfo{"$modcalled:ena:checked"})) &&
                  ($modsinfo{"$modcalled:ena:checked"} eq "checked"))) &&
                (defined $httpmods{$modcalled})) {         # and module defined
                print "Start handling $modcalled\n", if ($debug >= 5);

                # 3.1) if found, invoke module

                # make data available to module
                $ctrl{'uptime'} = sprintf ("%.3fh", (time - $uptime) / 3600.0);
                $ctrl{'client_ip'} = $client_ip;
                $ctrl{'FORM'} = \%FORM;
                $ctrl{'FORMORG'} = $urlparams;
                $ctrl{'sock'} = $sock;
                $ctrl{'debug'} = $debug;
                if(defined($FORM{'path'}) && 
                    ($FORM{'path'} =~ /[\\\/]([^\\\/]+)$/) ) {
                    $ctrl{'htmlttl'} = "<title>$1 ($modcalled)</title>\n";
                } else {
                    $ctrl{'htmlttl'} = "<title>$modcalled (l00httpd)</title>\n";
                }
                $ctrl{'home'} = "<a nam=\"hometop\"></a><a href=\"/httpd.htm\">#</a> ";
                $ctrl{'home'} .= "<a href=\"/ls.htm/HelpMod$modcalled.htm?path=${plpath}docs_demo/HelpMod$modcalled.txt\">?</a> ";
                if (!-f "${plpath}docs_demo/HelpMod$modcalled.txt") {
                    # also point to source code
                    $ctrl{'home'} .= "<a href=\"/view.htm/l00http_$modcalled.pl?path=${plpath}l00http_$modcalled.pl\">code</a> ";
                }
                $ctrl{'homesml'} = $ctrl{'home'};

                if ($ishost && 
                    !defined($ctrl{'nobanners'}) &&
                    ($ctrl{'bannermute'} <= time)) {
                    # a generic scheme to support system wide banner
                    # $ctrl->{'BANNER:modname'} = '<center>TEXT</center><p>';
                    # $ctrl->{'BANNER:modname'} = '<center><form action="/do.htm" method="get"><input type="submit" value="Stop Alarm"><input type="hidden" name="path" value="/sdcard/dofile.txt"><input type="hidden" name="arg1" value="stop"></form></center><p>';
                    foreach $_ (sort { $b cmp $a} keys %ctrl) {
                        if (/^BANNER:(.+)/) {
                            #print "key $_\n";
                            if (defined($ctrl{$_})) {
                                #$ctrl{'home'} = $ctrl{$_} . $ctrl{'home'};
                                #$buf = &l00wikihtml::wikihtml ($ctrl, $pname, $buf, $wikihtmlflags, $fname);
                                # process banner content through wikihtml to make wiki links, etc.
                                $_ = &l00wikihtml::wikihtml (\%ctrl, '', $ctrl{$_}, 4, '');
                                # remove ending <br> added
                                s/<br>$//;
                                $ctrl{'home'} = $_ . $ctrl{'home'};
                            }
                        }
                        if (/^BANNERSML:(.+)/) {
                            if (defined($ctrl{$_})) {
                                # process banner content through wikihtml to make wiki links, etc.
                                $_ = &l00wikihtml::wikihtml (\%ctrl, '', $ctrl{$_}, 4, '');
                                # remove ending <br> added
                                s/<br>$//;
                                $ctrl{'homesml'} = $_ . $ctrl{'home'};
                            }
                        }
                    }
                }
                if ($quitattime < 0x7fffffff) {
                    $_ = $quitattime  - time;
                    $ctrl{'home'} .= "$quitmsg1$_$quitmsg2";
                    $ctrl{'homesml'} .= "$quitmsg1$_$quitmsg2";
                }
                if (defined($ctrl{'demomsg'})) {
                    # Give Openshift demo notice
                    $ctrl{'home'} .= $ctrl{'demomsg'};
                }

                # invoke module
                if (($debug >= 3) && $hiresclock) {
                    $hiresclockmsec = Time::HiRes::time() - $hiresclockmsec;
                    l00httpd::dbp("l00httpd", sprintf("%8.3f ms Ready to invoke module\n", $hiresclockmsec * 1000));
                    $hiresclockmsec = Time::HiRes::time();
                }
                if (defined ($modsinfo{"$modcalled:fn:proc"})) {
                    $subname = $modsinfo{"$modcalled:fn:proc"};
                    $ctrl{'msglog'} = "";
                    print "Invoking $modcalled\n", if ($debug >= 5);
                    $retval = __PACKAGE__->$subname(\%ctrl);
                    print "Returned from $modcalled\n", if ($debug >= 5);
                    &dlog (4, $ctrl{'msglog'}."\n");
                    # special Openshift demo handling
                    if (($quitattimer != 0) && 
                        (!($modcalled eq 'hello') &&
                         !(($modcalled eq 'ls') &&
                           ($urlparams eq 'path=/favicon.ico&raw=on'))
                        )) {
                        $tmp = 1;

                        # if secret exist, don't quit
                        if(-f "${plpath}secret") {
                            # compute md5sum
                            $_ = `md5sum ${plpath}secret`;
                            if ((/^(\S+)/) &&
                                ($1 eq '5d568a56813cd2031e8ea893d95aade8')) {
                                print "Found secret; don't quit.\n";
                                $tmp = 0;
                            }
                        }
                        if ($tmp) {
                            print "Quit timer trigger and will quit in $quitattimer seconds\n";
                            $quitattime = time + $quitattimer;
                            $quitattimer = 0;
                        }
                    }
                }
            } else {
                print "Start handling host control\n", if ($debug >= 5);
                $shutdown = 0;
                $ipage = 0;     # reset IP cache age so next httpd.htm loading will show new IP
                # process Home control data
                if ($modcalled eq 'httpd') {
                    print "Start processing host control\n", if ($debug >= 5);
                    if ((defined ($FORM{'debuglvl'})) && ($FORM{'debuglvl'} =~ /^\d+$/)) {
                        $debug = $FORM{'debuglvl'};
                        if ($debug < 0) {
                            $debug = 0;
                        } elsif ($debug > 7) {
                            $debug = 7;
                        }
                    }
                    # indivisual check marks
                    foreach $mod (sort keys %httpmods) {
                        if ((defined ($FORM{$mod})) && ($FORM{$mod} eq "on")) {
                            # enabled
                            $modsinfo{"$mod:ena:checked"} = "checked";
                        } else {
                            $modsinfo{"$mod:ena:checked"} = "";
                        }
                    }
                    # setting banner mute
                    if (defined ($FORM{'bannermute'}) &&
                        (length ($FORM{'bannermute'}) > 0) &&
                        (int ($FORM{'bannermute'}) >= 0)) {
                        $ctrl{'bannermute'} = time + $FORM{'bannermute'} * 60;
                    }
                    # setting new timeout
                    if (defined ($FORM{'timeout'}) &&
                        (length ($FORM{'timeout'}) > 0) &&
                        (int ($FORM{'timeout'}) > 0)) {
                        $timeout = time + $FORM{'timeout'};
                    }
                    # text edit size
                    if (defined ($FORM{'txth'}) &&
                        (length ($FORM{'txth'}) > 0) &&
                        (int ($FORM{'txth'}) > 0)) {
                        $ctrl{'txth'} = $FORM{'txth'};
                    }
                    if (defined ($FORM{'txtw'}) &&
                        (length ($FORM{'txtw'}) > 0) &&
                        (int ($FORM{'txtw'}) > 0)) {
                        $ctrl{'txtw'} = $FORM{'txtw'};
                    }
                    if (defined ($FORM{'httpmax'}) &&
                        (length ($FORM{'httpmax'}) > 0) &&
                        (int ($FORM{'httpmax'}) > 0)) {
                        $httpmax = $FORM{'httpmax'};
                        $httpmax *= 1024 * 1024;
                    }
                    if (defined ($FORM{'noclinav'}) &&
                        (length ($FORM{'noclinav'}) > 0) &&
                        (int ($FORM{'noclinav'}) >= 0) && 
                        (int ($FORM{'noclinav'}) <= 1)) {
                        $ctrl{'noclinav'} = $FORM{'noclinav'};
                    }
                    if (defined ($FORM{'noclinavon'}) && ($FORM{'noclinavon'} eq 'on')) {
                        $ctrl{'noclinav'} = 1;
                    }
                    if (defined ($FORM{'noclinavof'}) && ($FORM{'noclinavof'} eq 'on')) {
                        $ctrl{'noclinav'} = 0;
                    }
                    if (defined ($FORM{'clipath'}) &&
                        (length ($FORM{'clipath'}) > 0)) {
                        $ctrl{'clipath'} = $FORM{'clipath'};
                    }
                    if (defined ($FORM{'clipathset'}) &&
                        ($FORM{'clipathset'} =~ /(\S+)/)) {
                        $ctrl{'clipath'} = $1;
                    }
                    if ($ctrl{'os'} eq 'and') {
                        if ((defined ($FORM{'wake'})) && ($ctrl{'os'} eq 'and')) {
                            if ($FORM{'wake'} eq 'on') {
                                $ctrl{'droid'}->wakeLockAcquirePartial();
                                $ctrl{'BANNER:wakelock'} = '<center><font style="color:yellow;background-color:red">WAKELOCK ON</font></center><p>';
                            }
                            if ($FORM{'wake'} eq 'off') {
                                $ctrl{'droid'}->wakeLockRelease();
                                $ctrl{'BANNER:wakelock'} = undef;
                            }
                        }
                        if (defined ($FORM{'wakeon'}) && ($FORM{'wakeon'} eq 'on') && ($ctrl{'os'} eq 'and')) {
                            $ctrl{'droid'}->wakeLockAcquirePartial();
                            $ctrl{'BANNER:wakelock'} = '<center><font style="color:yellow;background-color:red">WAKELOCK ON</font></center><p>';
                            if (defined ($FORM{'waketil'}) && 
                                ($FORM{'waketil'} =~ /(\d+)/)) {
                                # sleep time
                                $waketil = time + $1 * 60;
                            }
                        }
                        if (defined ($FORM{'wakeof'}) && ($FORM{'wakeof'} eq 'on') && ($ctrl{'os'} eq 'and')) {
                            $ctrl{'droid'}->wakeLockRelease();
                            $ctrl{'BANNER:wakelock'} = undef;
                            $waketil = 0;
                        }
                        if (defined ($FORM{'wifi'})) {
                            if ($FORM{'wifi'} eq 'on') {
                                $ctrl{'droid'}->toggleWifiState (1);
                            }
                            if ($FORM{'wifi'} eq 'off') {
                                $ctrl{'droid'}->toggleWifiState (0);
                            }
                        }
                        if (defined ($FORM{'wifion'}) && ($FORM{'wifion'} eq 'on')) {
                            $ctrl{'droid'}->toggleWifiState (1);
                        }
                        if (defined ($FORM{'wifiof'}) && ($FORM{'wifiof'} eq 'on')) {
                            $ctrl{'droid'}->toggleWifiState (0);
                        }
                    }

                    # enable all Applets overwrites
                    if (((defined ($FORM{'allappson'})) && ($FORM{'allappson'} eq "on")) ||
                        defined ($ctrl{'allappson'})) {
                        foreach $mod (sort keys %httpmods) {
                            if (defined ($modsinfo{"$mod:fn:proc"})) {
                                $modsinfo{"$mod:ena:checked"} = "checked";
                            }
                        }
                    }
                    # disable all Applets overwrites
                    if ((defined ($FORM{'allappsoff'})) && ($FORM{'allappsoff'} eq "on")) {
                        foreach $mod (sort keys %httpmods) {
                            if (defined ($modsinfo{"$mod:fn:proc"})) {
                                $modsinfo{"$mod:ena:checked"} = "";
                            }
                        }
                    }
                    if (defined ($FORM{'defaulton'})) {
                        # disable all
                        foreach $mod (sort keys %httpmods) {
                            if (defined ($modsinfo{"$mod:fn:proc"})) {
                                $modsinfo{"$mod:ena:checked"} = "";
                            }
                        }
                        # then enable always on modules
                        foreach $mod (sort keys %httpmods) {
                            if (defined ($ctrl{"alwayson_$mod"})) {
                                $modsinfo{"$mod:ena:checked"} = "checked";
                            }
                        }
                    }
                    if (defined ($FORM{'ipfilon'})) {
                        $ctrl{'ipfil'} = "yes";
                    } else {
                        $ctrl{'ipfil'} = "";
                    }
                    if ($ctrl{'ipfil'} eq "yes") {
                        undef %ipallowed;
                        for $key (sort keys %FORM) {
                            if ($key =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                                $ipallowed{$1}  = "yes";
                            }
                        }
                    }
                    if (defined ($FORM{'nopw'})) {
                        if ($FORM{'nopw'} =~ /^ *(\d+) *$/) {
                            $nopwtimeout = time + $1;
                        } elsif (length ($FORM{'nopw'}) > 2) {
                            $nopwtimeout = $FORM{'nopw'};
                        } else {
                            $nopwtimeout = 0;
                        }
                    } else {
                        $nopwtimeout = 0;
                    }
                }


                # 3.2) if not, provide a list of known modules

                # on server: provide client control
                # on client: provide a table of modules, and links if enabled
                # Send HTTP and HTML headers
                print "Send host control HTTP header\n", if ($debug >= 5);
                print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title>" . $ctrl{'htmlhead2'};
                print $sock "$ctrl{'now_string'}: $client_ip connected to WikiPland on '$ctrl{'machine'}' aka '$ctrl{'whoami'}'. \n";
                print $sock "Server IP: <a href=\"/clip.htm?update=Copy+to+CB&clip=http%3A%2F%2F$ctrl{'myip'}%3A20338%2Fclip.htm\">$ctrl{'myip'}</a>, up: ";
                print $sock sprintf ("%.3f", (time - $uptime) / 3600.0);
                print $sock "h, connections: $ttlconns.\n";
                print $sock "PID $$ VM ", &perlvmsize(), " MBytes.\n";
                if (($ctrl{'os'} eq 'win') || ($ctrl{'os'} eq 'cyg')) {
                    $_ = `wmic OS get FreePhysicalMemory`;
                    /(\d+)/ms;
                    $_ = int($1 / 1024);
                    print $sock "Free mem $_ MBytes\n";
                }
                print $sock "<p>\n";

                print "Send host control HTTP form\n", if ($debug >= 6);
                print $sock "<a name=\"top\"></a>\n";
                if ($ishost) {
                    print $sock "Banner mute: ";
                    print $sock "<a href=\"/httpd.htm?bannermute=0\">off</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=5\">5'</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=10\">10'</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=15\">15'</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=20\">20'</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=30\">30'</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=45\">45'</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=60\">1h</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=90\">1.5h</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=120\">2h</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=150\">2.5h</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=180\">3h</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=240\">4h</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=300\">5h</a> - ";
                    print $sock "<a href=\"/httpd.htm?bannermute=43200\">1mo</a><p>";
                }
                if ($quitattime < 0x7fffffff) {
                    $_ = $quitattime  - time;
                    print $sock "$quitmsg1$_$quitmsg2";
                }
                if (defined($ctrl{'demomsg'})) {
                    # Give Openshift demo notice
                    print $sock "$ctrl{'demomsg'}";
                }

                print $sock "<a href=\"/httpd.htm\">#</a>\n";
                print $sock "<a href=\"/ls.htm/HelpModl00httpd.htm?path=${plpath}docs_demo/HelpModl00httpd.txt\">?</a>\n";
                print $sock "$ctrl{'HOME'}\n";
                print $sock "<a href=\"/ls.htm/QuickStart.htm?path=$plpath"."docs_demo/QuickStart.txt\">QuickStart</a>\n";
                print $sock "<a href=\"#end\">end</a> \n";
                if ($ctrl{'os'} eq 'and') {
                    print $sock "<a href=\"#wifi\">wifi</a> \n";
                    if ($ishost) {
                        if ($batttime + 300 < time) {
                            $batttime = time;
                            if (open(IN,"</sys/class/power_supply/battery/uevent")) {
                                while (<IN>) {
                                    if (/POWER_SUPPLY_CAPACITY=(\d+)/) {
                                        $battpct = "=$1\%";
                                    }
                                }
                                close(IN);
                            }
                        }
                        print $sock "<a href=\"/view.htm?path=/sys/class/power_supply/battery/uevent\">Batt$battpct</a> \n";
                    }
                }
                if (($ctrl{'os'} eq 'win') || ($ctrl{'os'} eq 'cyg')) {
                    if ($ishost) {
                        if ($batttime + 300 < time) {
                            $batttime = time;
                            $battpct = `WMIC PATH Win32_Battery Get EstimatedChargeRemaining`;
                            if ($battpct =~ /(\d+)/m) {
                                $battpct = "=$1\%";
                            }
                        }
                        print $sock "<a href=\"/shell.htm?buffer=WMIC+PATH+Win32_Battery+Get+EstimatedChargeRemaining&exec=Exec\">Batt$battpct</a> \n";
                    }
                }
                if ($ishost) {
                    print $sock "<a href=\"#ram\">ram</a> \n";
                }
                print $sock "<p>\n";

                if ($ishost) {
                    print $sock "<form action=\"/httpd\" method=\"get\">\n";
                    print $sock "<input type=\"submit\" value=\"Edit box size\">\n";
                    print $sock "W <input type=\"text\" size=\"4\" name=\"txtw\" value=\"$ctrl{'txtw'}\">\n";
                    print $sock "H <input type=\"text\" size=\"4\" name=\"txth\" value=\"$ctrl{'txth'}\">\n";
                    $tmp = int($httpmax / 1024 / 1024);
                    print $sock "<input type=\"submit\" value=\"Max upload\">\n";
                    print $sock "<input type=\"text\" size=\"4\" name=\"httpmax\" value=\"$tmp\"> MBytes\n";
                    print $sock "</form>\n";

                    # on server, also display client controls
                    print $sock "<form action=\"/httpd\" method=\"get\">\n";
                    # on server: display submit button
                    print $sock "<input type=\"submit\" name=\"Submit\" value=\"Submit\">\n";
                }
 
                # build table of modules
                print "build table of modules\n", if ($debug >= 6);
                print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                if ($ishost) {
                    # with link control
                    print $sock "<tr><th>Client enabled</th><th>Plugins</th><th>Descriptions</th>\n";

                    print $sock "<tr>";
                    print $sock "<td><input type=\"checkbox\" name=\"allappson\">Apps on</td>\n";
                    print $sock "<td><a href=\"/restart.htm\">(Restart)</a></td><td>Enable all Applets for external clients.</td></tr>\n";

                    print $sock "<tr>";
                    print $sock "<td><input type=\"checkbox\" name=\"allappsoff\">Apps off</td>\n";
                    print $sock "<td><a href=\"/shutdown.htm\">(Shutdown)</a></td><td>Disable all Applets for external clients</td></tr>\n";

                    # on server: display debug option
                    print $sock "<tr>";
                    print $sock "<td><input type=\"text\" size=\"2\" name=\"debuglvl\" value=\"$debug\"></td>\n";
                    print $sock "<td><a href=\"/view.htm?path=${plpath}l00httpd.pl\">l00httpd.pl</a></td>\n";
                    print $sock "<td>Print debug messages to console</td></tr>\n";

                    if ($nopwtimeout =~ /^ *\d+ *$/) {
                        if ($nopwtimeout > time) {
                            $tmp = $nopwtimeout - time;
                        } else {
                            $tmp = 0;
                        }
                    } else {
                        if (length ($nopwtimeout) > 2) {
                            $tmp = $nopwtimeout;
                        } else {
                            $tmp = '';
                        }
                    }
                    print $sock "<tr>";
                    print $sock "<td><input type=\"text\" size=\"4\" name=\"nopw\" value=\"$tmp\"></td>\n";
                    print $sock "<td><a href=\"/httpd?allappson=on&timeout=1800&noclinavof=on\">wide open</a></td>\n";
                    print $sock "<td>Suspends password protection for specified seconds, or ':modname: (always no password for 'nopwpath'.) <a href=\"/httpd.htm?defaulton=on&allappoff=on&timeout=300&noclinavon=on\">Default only</a></td></tr>\n";

                    $tmp = "stopped";
                    $buf = $ctrl{'timeout'};
                    if (defined ($timeout)) {
                        $tmp =  $timeout - time;
                        $buf = $tmp;
                    }
                    print $sock "<tr>";
                    print $sock "<td><input type=\"text\" size=\"5\" name=\"timeout\" value=\"$buf\"></td>\n";
                    print $sock "<td><a href=\"/view.htm/l00httpd.htm?path=$plpath"."l00httpd.pl\">".
                        "$tmp</a></td><td>Client access timeout (sec)</td>\n";
                } else {
                    print $sock "<tr><th>Plugins</th><th>Descriptions</th>\n";
                }
                # list all modules
                print "List all modules\n", if ($debug >= 5);
                foreach $tmp (sort keys %httpmodssort) {
                    $mod = $httpmodssort{$tmp};
                    # get description
                    if (!defined ($modsinfo{"$mod:fn:desc"})) {
                        next;
                    }
                    if ($ishost) {
                        # on the server, display controls
                        print $sock "<tr>";
                        $checked = $modsinfo{"$mod:ena:checked"};
                        print $sock "<td><input type=\"checkbox\" name=\"$mod\" $checked>".
                            "<a href=\"/view.htm/$mod.htm?path=$plpath"."l00http_$mod.pl\">".
                            "$mod</a></td>\n";
                        print $sock "<td><a href=\"/$mod.htm\">$mod</a></td><td>$moddesc{$mod}</td>\n";
                        print $sock "</tr>\n";
                    } else {
                        # on client, enable links if enabled
                        if ($modsinfo{"$mod:ena:checked"} eq "checked") {
                            print $sock "<tr><td><a href=\"/$mod.htm\">$mod</a></td><td>$moddesc{$mod}</td>\n";
                        } else {
                            print $sock "<tr><td>$mod</td><td>$moddesc{$mod}</td>\n";
                        }
                        print $sock "</tr>\n";
                    }
                }
                # list clients
                if ($ishost) {
                    print $sock "<tr>";
                    if ($ctrl{'ipfil'} eq "yes") {
                        $checked = "checked";
                    } else {
                        $checked = "";
                    }
                    print $sock "<td><input type=\"checkbox\" name=\"ipfilon\" $checked></td>\n";
                    print $sock "<td>Filter IP</td><td>Enable IP filtering</td>\n";
                }
                if ($ishost) {
                    &l00httpd::l00npoormanrdns(\%ctrl, 'l00httpd', "${plpath}poormanrdns.cfg");
                    $poormanrdnssub = &l00httpd::l00npoormanrdnshash(\%ctrl);

                    $ipallowed{"127.0.0.1"} = "yes";
                    for $key (sort keys %connected) {
                        $val = $connected{$key};
                        $tmp = "";
                        if (defined ($ipallowed{$key})) {
                            $checked = "checked";
                        } else {
                            $checked = "";
                        }
                        $tmp = "<input type=\"checkbox\" name=\"$key\" $checked>allow";
                        print $sock "<tr><td>$tmp</td><td>$val</td>";
                        # http://cqcounter.com/whois/?query=52.20.6.114
                        # poor man's reverse dns
                        $ipaddr = $key;
                        foreach $dnspattern (sort keys %$poormanrdnssub) {
                            $ipaddr =~ s/$dnspattern/$poormanrdnssub->{$dnspattern}/g;
                        }
                        $tmp = "<a href=\"http://cqcounter.com/whois/?query=$key\">$key</a>";
                        print $sock "<td>$tmp connection ($ipaddr)</td>\n";
                    }

                    print $sock "<tr>";
                    print $sock "<td><input type=\"checkbox\" name=\"noclinavon\">on</td>\n";
                    print $sock "<td><input type=\"checkbox\" name=\"noclinavof\">off</td>\n";
                    print $sock "<td>noclinav: on to restrict client directory navigation</td>\n";
                    print $sock "</tr>\n";

                    print $sock "<tr>";
                    print $sock "<td>clipath:</td>\n";
                    print $sock "<td><input type=\"text\" size=\"2\" name=\"clipathset\" value=\"\"></td>\n";
                    print $sock "<td>clipath: restrict client to directory below this</td>\n";
                    print $sock "</tr>\n";

                    if ($ctrl{'os'} eq 'and') {
                        print $sock "<tr>";
                        print $sock "<td><input type=\"checkbox\" name=\"wakeon\">on\n";
                        $tmp = '';
                        if ($waketil != 0) {
                            $tmp = int(($waketil - time) / 60);
                        }
                        print $sock "<input type=\"text\" size=\"2\" name=\"waketil\" value=\"$tmp\">min</td>\n";
                        print $sock "<td><input type=\"checkbox\" name=\"wakeof\">off</td>\n";
                        print $sock "<td>wake: on to prevent Android from sleeping</td>\n";
                        print $sock "</tr>\n";

                        print $sock "<tr>";
                        print $sock "<td><input type=\"checkbox\" name=\"wifion\">on</td>\n";
                        print $sock "<td><input type=\"checkbox\" name=\"wifiof\">off</td>\n";
                        print $sock "<td>wifi: turn wifi on/off</td>\n";
                        print $sock "</tr>\n";
                    }
                }

                print $sock "</table>\n";
                print $sock "<hr><a name=\"end\"></a>\n";
                print $sock "Scroll up for wiki/wake control. Jump to <a href=\"#top\">top</a> \n";

                if ($ishost) {
                    print $sock "<a name=\"wifi\"></a>\n";
                    # on server: display submit button
                    print $sock "</form>\n";

                    if ($cfgedit ne '') {
                        print $sock "$cfgedit\n";
                    }

                    # show log file
                    print $sock "<br>View log file <a href=\"/view.htm?path=${plpath}l00httpd.log\">l00httpd.log</a>\n";


                    # dump all ctrl data
                    print $sock "<p>ctrl data:<p><table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                    print $sock "<tr><th>Keys</th><th>Values</th>\n";
                    for $key (sort keys %ctrl) {
                        $val = $ctrl{$key};
                        if (defined($val)) {
                            $val =~ s/</&lt;/g;
                            $val =~ s/>/&gt;/g;
                        } else {
                            $val = '(undefined)';
                        }
                        if ($val eq '') {
                            $val = '&nbsp;';
                        }
                        $key = "<a href=\"/eval.htm?eval=%24ctrl-%3E{%27$key%27}%0D%0A%24a%3D%27$val%27\">$key</a>";
                        print $sock "<tr><td>$key</td><td>$val</td>\n";
                    }
                    print $sock "</table>\n";

                    # list all periodic tasks
                    print $sock "<p>Perio task:<p><table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                    print $sock "<tr><th>Mod names</th><th>Secs to fire</th></tr>\n";
                    foreach $mod (sort keys %httpmods) {
                        if (defined ($modsinfo{"$mod:fn:perio"})) {
                            if ($ctrl_port_first == $ctrl_port) {
                                # on first instance, call module to get time to wake
                                $ctrl{'httphead'}  = "HTTP/1.0 200 OK\x0D\x0A\x0D\x0A";
                                $subname = $modsinfo{"$mod:fn:perio"};
                                $retval = 60;
                                $retval = __PACKAGE__->$subname(\%ctrl);
                                print "perio: $mod:fn:perio -> $retval\n", if ($debug >= 5);
                                print $sock "<tr><td><a href=\"/$mod.htm\">$mod</a></td><td>$retval secs</td></tr>\n";
                            } else {
                                # not on first instance, just list module
                                print $sock "<tr><td><a href=\"/$mod.htm\">$mod</a></td><td>inactive</td></tr>\n";
                            }
                        }
                    }
                    print $sock "</table>\n";


                    # dump all form data
                    if ($modcalled eq 'httpd') {
                        print $sock "<p>FORM data:<p><table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                        print $sock "<tr><th>Keys</th><th>Values</th>\n";
                        for $key (sort keys %FORM) {
                            $val = $FORM{$key};
                            $val =~ s/</&lt;/g;
                            $val =~ s/>/&gt;/g;
                            print $sock "<tr><td>$key</td><td>$val</td></tr>\n";
                        }
                        print $sock "</table>\n";
                    }
                }
                print $sock "<hr><a name=\"ram\"></a>\n";
                print $sock "<a href=\"#top\">top</a><p>\n";

                if ($ishost) {
                    # list ram files
                    $ramfilehtml = '';
                    $ramfiletxt = '';
                    $cnt = 0;

                    $ramfilehtml .= "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                    $ramfilehtml .= "<tr>\n";
                    $ramfilehtml .= "<th>names</th>\n";
                    $ramfilehtml .= "<th>bytes</th>\n";
                    $ramfilehtml .= "<th>time</th>\n";
                    $ramfilehtml .= "</tr>\n";
                    # list ram files
                    $tmp = $ctrl{'l00file'};

                    $ramfiledisp = $ramfilehtml;
                    foreach $_ (sort keys %$tmp) {
                        if (($_ eq 'l00://_notes.txt') ||
                           (defined($ctrl{'l00file'}->{$_}) &&
                            (length($ctrl{'l00file'}->{$_}) > 0))) {
                            my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

                            $buf = '';
                            $buf .= "<tr>\n";
                            $buf .= "<td><small><a href=\"/ls.htm?path=$_\">$_</a></small></td>\n";
                            $buf .= "<td><small><a href=\"/$ctrl{'lssize'}.htm?path=$_\">" . 
                                length($ctrl{'l00file'}->{$_}) . "</a></small></td>\n";

                            # display time
                            if (!defined($ctrl{'l00filetime'}->{$_})) {
                                $ctrl{'l00filetime'}->{$_} = 0;
                            }
                            ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                                = localtime($ctrl{'l00filetime'}->{$_});
                            $buf .= sprintf ("<td><small>%4d/%02d/%02d %02d:%02d:%02d</small></td>\n", 
                                1900+$year, 1+$mon, $mday, $hour, $min, $sec);

                            $buf .= "</tr>\n";

                            $ramfiletxt .= sprintf ("%4d/%02d/%02d %02d:%02d:%02d %8d %s\n", 
                                1900+$year, 1+$mon, $mday, $hour, $min, $sec, 
                                length($ctrl{'l00file'}->{$_}), $_);
                            if ($cnt++ < $rammaxitems) {
                                $ramfiledisp .= $buf;
                            }
                            $ramfilehtml .= $buf;
	            	    }
                    }
                    $ramfiledisp .= "</table>\n";
                    $ramfilehtml .= "</table>\n";
                }
                &l00httpd::l00fwriteOpen(\%ctrl, "l00://ls_all_ram.html");
                &l00httpd::l00fwriteBuf(\%ctrl, $ramfilehtml);
                &l00httpd::l00fwriteClose(\%ctrl);
                &l00httpd::l00fwriteOpen(\%ctrl, "l00://ls_all_ram.txt");
                &l00httpd::l00fwriteBuf(\%ctrl, $ramfiletxt);
                &l00httpd::l00fwriteClose(\%ctrl);
                if ($cnt >= $rammaxitems) {
                    print $sock "RAM file listing limited to $rammaxitems.  See <a href=\"/ls.htm?path=l00://ls_all_ram.html\" target=\"_blank\">l00://ls_all_ram.html</a>\n";
                    print $sock " -- <a href=\"/view.htm?path=l00://ls_all_ram.txt\" target=\"_blank\">.txt</a><p>\n";
                }
                print $sock "$ramfiledisp";
                print $sock "<p>End of page.<p>\n";

                # send HTML footer and ends
                if (defined ($ctrl{'FOOT'})) {
                    print $sock "$ctrl{'FOOT'}\n";
                }
                print $sock $ctrl{'htmlfoot'};
                print "Completed host control page\n", if ($debug >= 5);
            }
            if (($debug >= 3) && $hiresclock) {
                if ($hiresclockmsec > 0) {
                    $hiresclockmsec = Time::HiRes::time() - $hiresclockmsec;
                    l00httpd::dbp("l00httpd", sprintf("%8.3f ms Request serviced\n", $hiresclockmsec * 1000));
                }
                $hiresclockmsec = Time::HiRes::time();
            }
            $sock->close;
        }
    }
    print "no more socket ready\n", if ($debug >= 5);
    &periodictask ();

    if (time > $quitattime + 3) {
        # give extra 3 seconds to allow last page to go out
        # call shutdown functions
        $ctrl{'sock'} = undef;
        foreach $mod (sort keys %httpmods) {
            if (defined ($modsinfo{"$mod:fn:shutdown"})) {
                $subname = $modsinfo{"$mod:fn:shutdown"};
                $retval = __PACKAGE__->$subname(\%ctrl);
                print "Called '$mod' module shutdown function\n";
            }
        }
        exit(2);
    }
}

print "WikiPland forever loop existed at now_string = $ctrl{'now_string'}\n";
exit(3);
