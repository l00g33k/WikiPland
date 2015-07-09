# Release under GPLv2 or later version by l00g33k@gmail.com

use Cwd;
use strict;
use warnings;

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


#use l00base64;      # used for decoding authentication
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



my ($addr, $checked, $client_ip, $cmd_param_pair, $conf);
my ($ishost, $ctrl_lstn_sock, $cli_lstn_sock, $ctrl_port, $ctrl_port_first, $cli_port, $debug, $file, $hour);
my ($idpw, $idpwmustbe, $ip, $isdst, $key, $mday, $min, $host_ip);
my ($modcalled, $mod, $mon, $name, $param, $tmp, $buf);
my ($rethash, $retval, $sec, $sock, $tickdelta, $postlen);
my ($urlparams, $val, $wday, $yday, $year, $subname);
my ($httpbuf, $httphdr, $httpbdy, $httpmax, $l00time, $rin, $rout, $eout);
my ($httpbuz, $httphdz, $httpbdz, $httpsiz, $clicnt, $nopwtimeout);
my ($httpsz, $httpszhd, $httpszbd, $open, $shutdown);
$httpmax = 1024 * 1024 * 10 + 4096;
my (@cmd_param_pairs, $timeout, $cnt, $cfgedit, $postboundary);
my (%ctrl, %FORM, %httpmods, %httpmodssig, %httpmodssort, %modsinfo, %moddesc, %ifnet);
my (%connected, %cliipok, $cliipfil, $uptime, $ttlconns, $needpw, %ipallowed);
my ($htmlheadV1, $htmlheadV2, $htmlheadB0);


# set listening port
$ctrl_port = 20337;
$cli_port = 20338;
$host_ip = '0.0.0.0';
$idpwmustbe = "p:p";  # change as you wish
$debug = 1;         # 0=none, 1=minimal, 5=max
$open = 0;
$shutdown = 0;
$cfgedit = '';

undef $timeout;

# Flushing the print buffers.
# http://www.perlmonks.org/?node_id=669369
$| = 1;

sub dlog {
    my $logm = pop;
    if ($debug >= 2) {
        if (open (OUT, ">>$plpath"."l00httpd.log")) {
            print OUT $logm;
            close OUT;
        }
    }
}

# predefined to make it easy for the modules
$ctrl{'httphead'}  = "HTTP/1.0 200 OK\x0D\x0A\x0D\x0A";
#::now::f705
$htmlheadV1 = "<!DOCTYPE html PUBLIC '-//WAPFORUM//DTD XHTML Mobile 1.0//EN' 'http://www.wapforum.org/DTD/xhtml-mobile10.dtd'>\x0D\x0A";
$htmlheadV2 = "<!DOCTYPE html>\x0D\x0A";
$htmlheadB0 = "<html>\x0D\x0A".
              "<head>\x0D\x0A".
              "<meta name=\"generator\" content=\"WikiPland: https://github.com/l00g33k/WikiPland\">\x0D\x0A".
              "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\x0D\x0A".
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
$ctrl{'l00file'}->{'l00://ram'} = "A sample ram file.\nContent is lost when shutdown\nChange 'ram' for a separate ram file";

$nopwtimeout = 0;


#my $dlog  =  $ctrl{'dlog'};
#&$dlog ("asd");


$ctrl{'bbox'} = '';
# overwritable from l00httpd.cfg
$ctrl{'machine'} = '(unknown)';
if (defined ($ENV{'ANDROID_ROOT'})) {
    $ctrl{'os'} = 'and';
    $ctrl{'bbox'} = 'busybox ';
    $ctrl{'droid'} = Android->new();
    if (open (IN, "</proc/cpuinfo")) {
        while (<IN>) {
            if (/Hardware\W*: *(.+) */) {
                $ctrl{'machine'} = $1;
            }
        }
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
} else {
    if ($plpath =~ /\/var\/lib\/openshift\//) {
        # on RHC
        $ctrl{'os'} = 'rhc';
        $ctrl{'machine'} = $ENV{'HOSTNAME'};
    } else {
        $ctrl{'os'} = 'lin';
        $ctrl{'machine'} = $ENV{'HOSTNAME'};
    }
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



$ctrl{'clipath'}  = $plpath;


$conf = "l00httpd.cfg";
$tmp = $plpath; # first time, find in l00httpd script directory
for ($cnt = 0; $cnt < 3; $cnt++) {
    if (open (IN, "<$tmp$conf")) {
        if ($cfgedit eq '') {
            $cfgedit = "Edit l00httpd.cfg at:<br>\n";
        }
        $cfgedit .= "&nbsp;&nbsp;&nbsp;<a href=\"/edit.htm?path=$tmp$conf\">$tmp$conf</a><br>\n";
        print "Reading $tmp$conf...\n";;
        while (<IN>) {
            if (/^#/) {
                next;
            }
        
            s/\r//g;
            s/\n//g;
            ($key, $val) = split ('\^');
            if ((defined ($key)) &&
                (length ($key) > 0) && 
                (defined ($val)) &&
                (length ($val) > 0)) {
                print ">$key< = >$val<\n";;
                if ($key eq 'workdir') {
                    # special case workdir to accept only if exist
                    if (-d $val) {
                        $ctrl{$key} = $val;
                    }
                } else {
                    $ctrl{$key} = $val;
                }
                if ($key =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                    $ipallowed{$1}  = "yes";
                }
            }
        }
        close (IN);
    }
    if ($cnt == 0) {
        $tmp = $ctrl{'workdir'}; # second time, find in workdir directory
	} else {
        if (defined($ctrl{'altcfg'})) {
            $tmp = $ctrl{'altcfg'};
		} else {
            last;
		}
	}
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
    } elsif (/^hostip=(.+)/) {
        $host_ip = $1;
        print "hostip set to $host_ip\n";
    } elsif (/^debug=(.+)/) {
        $debug = $1;
        $ctrl{'debug'} = $debug;
        print "debug set to $debug\n";
    } elsif (/^open$/) {
	    $nopwtimeout = 0x7fffffff;
        $ctrl{'noclinav'}  = 0;
        $ctrl{'clipath'}  = '/';
		$open = 1;
	}
}
$ctrl_port_first = $ctrl_port;


if ((defined ($ctrl{'debug'})) && ($ctrl{'debug'} =~ /^[0-5]$/)) {
    $debug = $ctrl{'debug'};
}

if (defined ($ctrl{'idpwmustbe'})) {
    $idpwmustbe = $ctrl{'idpwmustbe'};
    $ctrl{'idpwmustbe'} = undef;
}

# check 'workdir' from 'l00httpd.cfg'
if (!defined ($ctrl{'workdir'})) {
    # sets default if not defined in l00httpd.txt
    $ctrl{'workdir'} = "$plpath"."l00httpd/";      # make it available to modules
} elsif (!-d $ctrl{'workdir'}) {
    # workdir is not a dir, use default
    $ctrl{'workdir'} = "$plpath"."l00httpd/";      # make it available to modules
}

foreach $key (keys %ctrl) {
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
}

# RHC special: make clipath at Perl directory so everything below is viewable by default
#if ($ctrl{'clipath'} =~ /\/var\/lib\/openshift\//) {
if ($ctrl{'os'} eq 'rhc') {
    # on RHC
    $ctrl{'clipath'} =~ s/\/l00httpd\/pub\/$/\//;
    $ctrl{'nopwpath'} = $ctrl{'clipath'};
    $nopwtimeout = 0x7fffffff;
    # more RHC special
    $ctrl{'alwayson_clip'} = 'rhc';
    $ctrl{'alwayson_debug'} = 'rhc';
    $ctrl{'alwayson_launcher'} = 'rhc';
    $ctrl{'alwayson_readme'} = 'rhc';
    $ctrl{'alwayson_solver'} = 'rhc';
    $ctrl{'alwayson_tree'} = 'rhc';
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


sub loadmods {
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks);
    # scan directory
    if (opendir (DIR, $plpath)) {
        foreach $file (sort readdir (DIR)) {
            if ($file =~ /^l00http_(\w*)\.pl/) {
                # match prefix and suffix, remember it
                $httpmods {$1} = $plpath . "l00http_$1.pl";
            }
        }
        closedir (DIR);
    }

    # load modules
    print "(Re)Loading modules from $plpath...\n";
    foreach $mod (sort keys %httpmods) {
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
        = stat($httpmods{$mod});

        if ((!defined($httpmodssig{$mod})) || 
            ($httpmodssig{$mod} ne "$size $mtimea")) {
            # never loaded or signature changed, reload
            # remember file signature for smart reload
            $httpmodssig{$mod} = "$size $mtimea";

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
    print "\nReady\n";
}




# 2) Open a listening socket

# create a listening socket 
$ctrl_lstn_sock = IO::Socket::INET->new (
    LocalPort => $ctrl_port,
    LocalAddr => $host_ip,
    Listen => 5, 
    ReuseAddr => 0  # Reuse => 1
);
if (!$ctrl_lstn_sock) {
    $ctrl_port += 10;
    $ctrl_lstn_sock = IO::Socket::INET->new (
        LocalPort => $ctrl_port,
        LocalAddr => $host_ip,
        Listen => 5, 
        ReuseAddr => 0  # Reuse => 1
    );
    if (!$ctrl_lstn_sock) {
        $ctrl_port += 10;
        $ctrl_lstn_sock = IO::Socket::INET->new (
            LocalPort => $ctrl_port,
            LocalAddr => $host_ip,
            Listen => 5, 
            ReuseAddr => 0  # Reuse => 1
        );
    }
}
die "Can't create socket for listening: $!" unless $ctrl_lstn_sock;
print "ctrl_port is $ctrl_port\n";
$ctrl{'ctrl_port_first'}  = $ctrl_port_first;
$ctrl{'ctrl_port'} = $ctrl_port;

# load modules
&loadmods;

$cli_lstn_sock = IO::Socket::INET->new (
    LocalPort => $cli_port,
    LocalAddr => $host_ip,
    Listen => 5, 
    ReuseAddr => 0  # Reuse => 1
);
if (!$cli_lstn_sock) {
    $cli_port += 10;
    $cli_lstn_sock = IO::Socket::INET->new (
        LocalPort => $cli_port,
        LocalAddr => $host_ip,
        Listen => 5, 
        ReuseAddr => 0  # Reuse => 1
    );
    if (!$cli_lstn_sock) {
        $cli_port += 10;
        $cli_lstn_sock = IO::Socket::INET->new (
            LocalPort => $cli_port,
            LocalAddr => $host_ip,
            Listen => 5, 
            ReuseAddr => 0  # Reuse => 1
        );
    }
}
die "Can't create socket for listening: $!" unless $cli_lstn_sock;
print "ctrl_port is $ctrl_port\n";
print "cli_port  is $cli_port\n";

my $readable = IO::Select->new;     # Create a new IO::Select object
$readable->add($ctrl_lstn_sock);    # Add the lstnsock to it
$readable->add($cli_lstn_sock);    # Add the lstnsock to it


sub periodictask {
    $tickdelta = 3600;	# tick once an hour
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    $ctrl{'now_string'} = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);
    foreach $mod (sort keys %httpmods) {
        if (defined ($modsinfo{"$mod:fn:perio"})) {
            $ctrl{'httphead'}  = "HTTP/1.0 200 OK\x0D\x0A\x0D\x0A";
            $subname = $modsinfo{"$mod:fn:perio"};
            $retval = 60;
            $retval = __PACKAGE__->$subname(\%ctrl);
            print "$mod:fn:perio -> $retval\n", if ($debug >= 4);
            if (defined ($retval) && ($retval > 0)) {
                if ($tickdelta > $retval) {
                    $tickdelta = $retval;
                }
            }
        }
    }
    my ($timeis);
    $timeis = localtime (time);
    print "tickdelta $tickdelta $timeis\n", if ($debug >= 4);
}

$tickdelta = 3600;
$uptime = time;
$ttlconns = 0;


($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
$ctrl{'now_string'} = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);
if (open (OUT, ">$plpath"."l00httpd.log")) {
    print OUT "$ctrl{'now_string'} l00httpd starts\n";
    close OUT;
}


$l00time = time;

if ($ctrl_port_first == $ctrl_port) {
    # execute periodic tasks only on first instance
    &periodictask ();
}

if ($ctrl{'os'} eq 'and') {
    $ctrl{'droid'}->makeToast("Welcome to l00httpd\nPlease browse to http://127.0.0.1:$ctrl_port\nSee Notification");
    $ctrl{'droid'}->notify ("Welcome to l00httpd", "Browse to http://127.0.0.1:$ctrl_port");
}

while(1) {
    # Get a list of sockets that are ready to talk to us.
    print "Before Select->select()\n", if ($debug >= 5);
    my ($ready) = IO::Select->select($readable, undef, undef, $tickdelta);
    print "After Select->select()\n", if ($debug >= 5);
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    $ctrl{'now_string'} = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);
    &dlog  ("$ctrl{'now_string'} ".sprintf ("%4d ", time - $l00time));
    $l00time = time;
    $clicnt = 0;
    foreach my $curr_socket (@$ready) {
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
            $ctrl{'ishost'} = $ishost;
            if ($ctrl{'os'} eq 'and') {
                if ($ctrl{'machine'} eq 'Morrison') {
                    $ip = `busybox ifconfig`;
#               } elsif ($ctrl{'machine'} eq 'doubleshot') {
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
#               } else {
#                   # don't know how to find self IP yet
#                   $ip = undef;
                }
            } elsif (($ctrl{'os'} eq 'win') || ($ctrl{'os'} eq 'cyg')) {
                $ip = `ipconfig`;
            } else {
                print "shell /sbin/ifconfig\n", if ($debug >= 5);
                $ip = `/sbin/ifconfig`;
            }
            print "raw ip = $ip\n", if ($debug >= 5);
            if (($ctrl{'os'} eq 'win') || ($ctrl{'os'} eq 'cyg')) {
                $ip = `ipconfig`;
                if ($ip =~ /(192\.168\.\d+\.\d+)/) {
                    $ip = $1;
                }
            } else {
                if (defined ($ip)) {
                    if ($ip =~ /(\d+\.\d+\.\d+\.\d+) +Bcast/) {
                        $ip = $1;
                    } elsif ($ip =~ /addr:(\d+\.\d+\.\d+\.\d+)/) {
                        $ip = $1;
                    }
                } else {
                    $ip = '(unknown)';
                }
            }
            $ip =~ s/ //g;
            print "ip = $ip\n", if ($debug >= 5);
            $ctrl{'myip'} = $ip;
            if (defined ($connected{$client_ip})) {
                $connected{$client_ip}++;
            } else {
                $connected{$client_ip} = 1;
            }
            $ttlconns++;
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
            if (($ishost) ||           # client enabled or is server
                ((defined ($modsinfo{"ls:ena:checked"})) &&
                 ($modsinfo{"ls:ena:checked"} eq "checked"))) {
                $modcalled = "_none_";     # aka module name
            } else {
                # invoke 'hello' if not host and 'ls' not enabled
                $modcalled = "hello";     # aka module name
            }

            # print date, time, client IP, password, and module names
            print "------------ processing HTTP request header ----------------------\n", if ($debug >= 2);

            # 3) Parse client HTTP submission and identify module plugin name
            $rin = '';
            vec($rin,fileno($sock),1) = 1;
            select ($rout = $rin, undef, $eout = $rin, 1); # public network needs 3 sec?
            if (vec($eout,fileno($sock),1) == 1) {
                print "sock error\n";
                next;
            } elsif (vec($rout,fileno($sock),1) == 1) {
                $httpsiz = sysread ($sock, $httpbuf, $httpmax);
            } else {
                print "sock timeout 1s\n";
                $sock->close;
                next;
            }
            print "httpsiz $httpsiz\n", if ($debug >= 4);
            &dlog  ("client $client_ip ");
            $postlen = -1;
            $httphdz = -1;
            if ($httpbuf =~ /^POST +/) {
                $tmp = index ($httpbuf, "Content-Length:");
                if ($tmp >= 0) {
                    if (substr ($httpbuf, $tmp + 15, 8)  =~ /(\d+)/) {
                        $postlen = $1;
                    }
                }
                $httphdz = index ($httpbuf, "\x0D\x0A\x0D\x0A");
                if ($httphdz >= 0) {
                    $httphdz += 4;
                }
                print "postlen = $postlen $httpsiz $httphdz\n", if ($debug >= 3);
                while (($postlen == -1) || ($httphdz == -1) ||
                    ($httpsiz < ($httphdz + $postlen))) {
                    $tmp = sysread ($sock, $buf, $httpmax);
                    print "httpsiz tmp $tmp\n", if ($debug >= 4);
                    if ($tmp > 0) {
                        $httpbuf .= $buf;
                        $httpsiz += $tmp;
                    } else {
                        last;
                    }
                    $tmp = index ($httpbuf, "Content-Length:");
                    if ($tmp >= 0) {
                        if (substr ($httpbuf, $tmp + 15, 8)  =~ /(\d+)/) {
                            $postlen = $1;
                        }
                    }
                    $httphdz = index ($httpbuf, "\x0D\x0A\x0D\x0A");
                    if ($httphdz >= 0) {
                        $httphdz += 4;
                    }
                    print "postlen = $postlen $httpsiz $httphdz\n", if ($debug >= 3);
                }
            } else {
                $postlen = -1;
                $httphdz = $httpsiz;
            }
            print "httpsiz $httpsiz >>>$httpbuf<<<\n", if ($debug >= 4);



            if ($httpbuf =~ /^POST /) {
                # POST
                $httphdr = substr ($httpbuf, 0, $httphdz);
                $httpbdz = $httpsiz - $httphdz;
                $httpbdy = substr ($httpbuf, $httphdz, $httpbdz);
            } else {
                # GET
                $httphdr = $httpbuf;
                print "GET?\n", if ($debug >= 3);
            }
            print "httpsiz $httpsiz httphdz $httphdz\n", if ($debug >= 3);


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
                } elsif (/^X-Client-IP: ([0-9.:a-fA-F]+)/) {
                    # extract the client IP when hosting on rhcloud.com
                    $client_ip = $1;
                    # double IP recording but that's ok
                    if (defined ($connected{$client_ip})) {
                        $connected{$client_ip}++;
                    } else {
                        $connected{$client_ip} = 1;
                    }
                } elsif (/^User-Agent:.*Android +5/i) {
                    # Android 5.1: <!DOCTYPE html XHTML Mobile seems to make single colume display
                    # This makes it more compact
                    $ctrl{'htmlhead'} = $htmlheadV2 . $htmlheadB0;
                } elsif (m|^Content-Type: multipart/form-data; boundary=(-----+.+)$|i) {
                    $postboundary = $1;
                    l00httpd::dbp("l00httpd", "Content-Type: multipart/form-data; boundary=$postboundary\n");
                }
            }

            print "FORM urlparams:$urlparams\n", if ($debug >= 3);
            # Wii will not render HTML if URL ends in .txt; it ignores after '?'
            if (($urlparams eq '/') &&      # no path
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
            } elsif ($urlparams =~ /^(\/.+)$/) {
                # of form: http://localhost:20337/ls?path=/sdcard
                $modcalled = "ls";
                $urlparams = "path=$1&raw=on";
            }
            print "$ctrl{'now_string'}: $client_ip Auth>$idpw< /$modcalled\n", if ($debug >= 1);

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
                next;
            }
            &dlog  ("url:: $urlparams ");
            &dlog  ("$modcalled\n");
            
            if ($postlen > 0) {
                $urlparams = $httpbdy;
            }
            print "FORM mod:$modcalled\n", if ($debug >= 3);
            if ($debug >= 3) {
                $tmp = substr ($urlparams, 0, 160);
                print "FORM urlget:$tmp\n";
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
                        if ($debug >= 3) {
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

            # handle URL
            print "Start handling URL\n", if ($debug >= 5);
            if ($modcalled eq "restart") {
                $modcalled = '';
                $shutdown = 0;
                # reload all modules
                l00httpd::dbp("l00httpd", "Restart/reloading modules\n");
                print "Restart/reloading modules\n", if ($debug >= 2);
                &loadmods;
            }
            if ($shutdown == 1) {
                print "You told me to shutdown\n";
                print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title>" . $ctrl{'htmlhead2'};
                print $sock "Click <a href=\"/\">here</a> to initiate shutdown.  Note: If this is an APK installation, you must uninstall to update l00httpd.\n";
                print $sock $ctrl{'htmlfoot'};
                print "shutting down by shutdown module\n";
                exit (1);
            } elsif ($modcalled eq "shutdown") {
                $shutdown = 1;
                print "You told me to shutdown\n";
                print $sock $ctrl{'httphead'} . $ctrl{'htmlhead'} . "<title>l00httpd</title>" . $ctrl{'htmlhead2'};
                print $sock "Click <a href=\"/\">here</a> to initiate shutdown<p>\n";
                print $sock "Click <a href=\"/restart.htm\">here</a> to restart<p>\n";
                print $sock $ctrl{'htmlfoot'};
                next;
            } elsif ($modcalled =~ /^redirect/) {
                if (defined ($ctrl{$modcalled})) {
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
                $shutdown = 0;

                # 3.1) if found, invoke module

                # make data available to module
                $ctrl{'client_ip'} = $client_ip;
                $ctrl{'FORM'} = \%FORM;
                $ctrl{'sock'} = $sock;
                $ctrl{'debug'} = $debug;
                $ctrl{'htmlttl'} = "<title>$modcalled (l00httpd)</title>\n";
                $ctrl{'home'} = "<a href=\"/httpd.htm\">#</a> <a href=\"/ls.htm/HelpMod$modcalled.htm?path=$plpath"."docs_demo/HelpMod$modcalled.txt\">?</a>";

                # a generic scheme to support system wide banner
                # $ctrl->{'BANNER:modname'} = '<center>TEXT</center><p>';
                # $ctrl->{'BANNER:modname'} = '<center><form action="/do.htm" method="get"><input type="submit" value="Stop Alarm"><input type="hidden" name="path" value="/sdcard/dofile.txt"><input type="hidden" name="arg1" value="stop"></form></center><p>';
                foreach $_ (sort keys %ctrl) {
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
                }

                # invoke module
                if (defined ($modsinfo{"$modcalled:fn:proc"})) {
                    $subname = $modsinfo{"$modcalled:fn:proc"};
                    $ctrl{'msglog'} = "";
                    $retval = __PACKAGE__->$subname(\%ctrl);
                    &dlog  ($ctrl{'msglog'}."\n");
                }
            } else {
                print "Start handling host control\n", if ($debug >= 5);
                $shutdown = 0;
                # process Home control data
                if ($modcalled eq 'httpd') {
                    print "Start processing host control\n", if ($debug >= 5);
                    if ((defined ($FORM{'debuglvl'})) && ($FORM{'debuglvl'} =~ /^[0-5]$/)) {
                        $debug = $FORM{'debuglvl'};
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
                            }
                            if ($FORM{'wake'} eq 'off') {
                                $ctrl{'droid'}->wakeLockRelease();
                            }
                        }
                        if (defined ($FORM{'wakeon'}) && ($FORM{'wakeon'} eq 'on')) {
                            $ctrl{'droid'}->wakeLockAcquirePartial();
                        }
                        if (defined ($FORM{'wakeof'}) && ($FORM{'wakeof'} eq 'on')) {
                            $ctrl{'droid'}->wakeLockRelease();
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
                print $sock "$ctrl{'now_string'}: $client_ip connected to the WikiPland. \n";
                print $sock "Server IP: <a href=\"/clip.htm?update=Copy+to+CB&clip=http%3A%2F%2F$ip%3A20338%2Fclip.htm
\">$ip</a>, up: ";
                print $sock sprintf ("%.3f", (time - $uptime) / 3600.0);
                print $sock "h, connections: $ttlconns<p>\n";
                
                print $sock "<a name=\"top\"></a>\n";
                print $sock "<form action=\"/httpd\" method=\"get\">\n";
                print $sock "<input type=\"submit\" value=\"Edit box size\">\n";
                print $sock "W <input type=\"text\" size=\"4\" name=\"txtw\" value=\"$ctrl{'txtw'}\">\n";
                print $sock "H <input type=\"text\" size=\"4\" name=\"txth\" value=\"$ctrl{'txth'}\">";
                print $sock "</form>\n";

                if ($ishost) {
                    # on server, also display client controls
                    print $sock "<form action=\"/httpd\" method=\"get\">\n";
                    # on server: display submit button
                    print $sock "<input type=\"submit\" name=\"Submit\" value=\"Submit\">\n";
                }
                print $sock "<a href=\"/httpd.htm\">#</a>\n";
                print $sock "<a href=\"/ls.htm/HelpModl00httpd.htm?path=${plpath}docs_demo/HelpModl00httpd.txt\">?</a>\n";
                print $sock "$ctrl{'HOME'}\n";
                print $sock "<a href=\"/ls.htm/QuickStart.htm?path=$plpath"."docs_demo/QuickStart.txt\">QuickStart</a>\n";
                print $sock "<a href=\"#end\">end</a> \n";
                if ($ctrl{'os'} eq 'and') {
                    print $sock "<a href=\"#wifi\">wifi</a> \n";
                }
                print $sock "<a href=\"#ram\">ram</a> \n";
                print $sock "<p>\n";
 
                # build table of modules
                print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                if ($ishost) {
                    # with link control
                    print $sock "<tr><td>Client enabled</td><td>Plugins</td><td>Descriptions</td>\n";

                    # on server: display debug option
                    print $sock "<tr>";
                    print $sock "<td><input type=\"text\" size=\"2\" name=\"debuglvl\" value=\"$debug\"></td>\n";
                    print $sock "<td><a href=\"/view.htm?path=${plpath}l00httpd.pl\">l00httpd.pl</a></td>\n";
                    print $sock "<td>Print debug messages to console</td>\n";

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
                    print $sock "<td><a href=\"/httpd?allappson=on&timeout=43200&noclinavof=on\">wide open</a></td>\n";
                    print $sock "<td>Suspends password protection for specified seconds, or ':modname: (always no password for 'nopwpath'.) <a href=\"/httpd.htm?defaulton=on&allappoff=on&timeout=300&noclinavon=on\">Default only</a></td>\n";

                    print $sock "<tr>";
                    print $sock "<td><input type=\"checkbox\" name=\"allappson\">Apps on</td>\n";
                    print $sock "<td><a href=\"/restart.htm\">(Restart)</a></td><td>Enable all Applets for external clients.\n";

                    print $sock "<tr>";
                    print $sock "<td><input type=\"checkbox\" name=\"allappsoff\">Apps off</td>\n";
                    print $sock "<td><a href=\"/shutdown.htm\">(Shutdown)</a></td><td>Disable all Applets for external clients</td>\n";

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
                    print $sock "<tr><td>Plugins</td><td>Descriptions</td>\n";
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
                    $ipallowed{"127.0.0.1"} = "yes";
                    for $key (sort keys %connected) {
                        $val = $connected{$key};
                        $tmp = "";
                        if (defined ($ipallowed{$key})) {
                            $checked = "checked";
                        } else {
                            $checked = "";
                        }
                        $tmp = "<td><input type=\"checkbox\" name=\"$key\" $checked>allow</td>";
                        print $sock "<tr>$tmp<td>$val</td><td>$key connection</td>\n";
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
                        print $sock "<td><input type=\"checkbox\" name=\"wakeon\">on</td>\n";
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

                    # dump all ctrl data
                    print $sock "<p>ctrl data:<p><table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
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
                        print $sock "<tr><td>$key</td><td>$val</td>\n";
                    }
                    print $sock "</table>\n";

                    # dump all form data
                    if ($modcalled eq 'httpd') {
                        print $sock "<p>FORM data:<p><table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                        for $key (sort keys %FORM) {
                            $val = $FORM{$key};
                            $val =~ s/</&lt;/g;
                            $val =~ s/>/&gt;/g;
                            print $sock "<tr><td>$key</td><td>$val</td>\n";
                        }
                        print $sock "</table>\n";
                    }
                }
                print $sock "<hr><a name=\"ram\"></a>\n";
                print $sock "<a href=\"#top\">top</a><p>\n";
                # list ram files
                print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                print $sock "<tr>\n";
                print $sock "<td>names</td>\n";
                print $sock "<td>bytes</td>\n";
                print $sock "<td>launcher</td>\n";
                print $sock "</tr>\n";
                # list ram files
                $tmp = $ctrl{'l00file'};

                foreach $_ (sort keys %$tmp) {
                    if (($_ eq 'l00://ram') ||
                       (defined($ctrl{'l00file'}->{$_}) &&
                        (length($ctrl{'l00file'}->{$_}) > 0))) {

                        print $sock "<tr>\n";

                        print $sock "<td><small><a href=\"/ls.htm?path=$_\">$_</a></small></td>\n";

                        print $sock "<td><small>" . length($ctrl{'l00file'}->{$_}) . "</small></td>\n";

                        print $sock "<td><small><a href=\"/$ctrl{'lssize'}.htm?path=$_\">launcher</a></small></td>\n";

                        print $sock "</tr>\n";
	            	}
                }
                print $sock "</table>\n";
                print $sock "<p>End of page.<p>\n";

                # send HTML footer and ends
                print $sock $ctrl{'htmlfoot'};
                print "Completed host control page\n", if ($debug >= 5);
            }
            $sock->close;
        }
    }
    print "no more socket ready\n", if ($debug >= 5);
    if ($ctrl_port_first == $ctrl_port) {
        # execute periodic tasks only on first instance
        &periodictask ();
    }
}

print "WikiPland forever loop existed at now_string = $ctrl{'now_string'}\n", if ($debug >= 1);
