use strict;
use warnings;
use l00wikihtml;
use l00backup;
use l00httpd;
use l00crc32;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# This module allows directory browsing and file retrieval.
# It also render a very rudimentary set of Wikiwords


# What it does:
# 1) Determine operating path and mode
# 2) If the path is not a directory:
# 2.1) If in raw mode, send raw binary
# 2.2) If not, try reading 30 lines and look for Wikitext
# 2.3) If Wikitexts were found, render rudimentary Wiki
# 2.4) If no Wikitext were found, a <br> as linefeed
# 3) If the path is a directory, make a table with links
# 4) If not in raw mode, also display a control table


my %config = (proc => "l00http_ls_proc",
              desc => "l00http_ls_desc");
my ($atime, $blksize, $blocks, $buf, $bulvl, $ctime, $dev);
my ($el, $file, $fullpath, $gid, $hits, $hour, $htmlend, $ii);
my ($ino, $intbl, $isdst, $editable, $len, $ln, $lv, $lvn);
my ($mday, $min, $mode, $mon, $mtime, $nlink, $raw_st, $rdev);
my ($readst, $pre_st, $sec, $size, $ttlbytes, $tx, $uid, $url);
my ($wday, $yday, $year, @cols, @el, @els, $sortkey1name2date, $lastpname);
my ($fileout, $dirout, $bakout, $http, $desci, $httphdr, $sendto);
my ($pname, $fname, $target, $findtext, $block, $found, $prefmt, $sortfind, $showpage);
my ($lfisbr, $embedpic, $chno, $bare, $hilite);

my $path;
my $read0raw1 = 0;
$intbl = 0;
$findtext = "";
$block = ".";
#$sendto = 'edit';
$prefmt = 'checked';
$sortfind = '';
$showpage = 'checked';
$sortkey1name2date = 1;
$lastpname = '';
$lfisbr = '';
$embedpic = '';
$chno = '';
$bare = '';
$hilite = '';

sub l00http_ls_sortfind {
    my ($rst, $aa, $bb);

    ($aa, $bb) = ($a, $b);
    $aa =~ s/%l00httpd:lnno:\d+%//g;
    $bb =~ s/%l00httpd:lnno:\d+%//g;
    # remote leading line number
    $aa =~ s/^\d+: *//g;
    $bb =~ s/^\d+: *//g;
    
    $rst = lc($bb) cmp lc($aa);

    $rst;
}

sub l00http_ls_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition


    " B: ls: Files and directories browser";
}

sub llstricmp {
    my ($rst);
    
    $rst = lc($a) cmp lc($b);

    $rst;
}

my ($llspath);
sub llsfn  {
    my ($rst);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $mtimeb, $ctime, $blksize, $blocks);
    
    if ((-d $llspath.$a) && (-d $llspath.$b)) {
        # both dir
        $rst = lc($a) cmp lc($b);
    } elsif (!(-d $llspath.$a) && !(-d $llspath.$b)) {
        # both file
        # it's not a directory, print a link to a file
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
        = stat($llspath.$a);
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimeb, $ctime, $blksize, $blocks)
        = stat($llspath.$b);
        $rst = $mtimeb <=> $mtimea;
    } elsif (-d $llspath.$a) {
        $rst = 1;
    } else {
        $rst = -1;
    }
    $rst;
}

sub l00http_ls_conttype {
    my ($path) = @_;
    my ($conttype, $urlraw);
    my ($pname, $fname);

    ($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/;

    $urlraw = 0;

    #HTTP/1.1 200 OK
    #Server: nginx/0.7.65
    #Date: Sat, 08 May 2010 00:45:04 GMT
    #Content-Type: application/x-zip
    #Connection: keep-alive
    #Cache-Control: must-revalidate
    #Expires:
    #$conttype .= "Content-Disposition: inline; size=\"$size\"\r\n";
    #X-Whom: s5-x
    #Content-Length: 23215
    #Etag: "947077edb066e7c363df5cc2a40311e5"
    #Last-Modified: Mon, 11 Jan 2010 05:54:08 GMT
    #P3P: CP: ALL DSP COR CURa ADMa DEVa CONo OUR IND ONL COM NAV INT CNT STA
    if (($fname =~ /\.zip$/i) ||
        ($fname =~ /\.kmz$/i)) {
        $urlraw = 1;
        $conttype = "Content-Type: application/x-zip\r\n";
        $conttype .= "Content-Disposition: inline; filename=\"$fname\"; size=\"$size\"\r\n";
    } elsif ($fname =~ /\.kml$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: application/vnd.google-earth.kml+xml\r\n";
    } elsif ($fname =~ /\.css$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: text/css\r\n";
    } elsif ($fname =~ /\.apk$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: application/vnd.android.package-archive\r\n";
    } elsif (($fname =~ /\.jpeg$/i) ||
             ($fname =~ /\.jpg$/i)) {
        $urlraw = 1;
        $conttype = "Content-Type: image/jpeg\r\n";
    } elsif ($fname =~ /\.wma$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: audio/x-ms-wma\r\n";
    } elsif ($fname =~ /\.3gp$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: audio/3gp\r\n";
    } elsif ($fname =~ /\.pdf$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: application/pdf\r\n";
    } elsif ($fname =~ /\.mp3$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: audio/mpeg\r\n";
    } elsif ($fname =~ /\.mp4$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: video/mp4\r\n";
    } elsif ($fname =~ /\.bmp$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: image/bmp\r\n";
    } elsif ($fname =~ /\.gif$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: image/gif\r\n";
    } elsif ($fname =~ /\.svg$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: image/svg+xml\r\n";
    } elsif ($fname =~ /\.js$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: application/javascript\r\n";
    } elsif ($fname =~ /\.png$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: image/png\r\n";
    } elsif ($fname =~ /\.wmf$/i) {
        $urlraw = 1;
        $conttype = "Content-Type: image/wmf\r\n";
    } elsif (($fname =~ /\.bin$/i) ||
             ($fname =~ /\.exe$/i) ||
             ($fname =~ /\.dat$/i)) {
        $urlraw = 1;
        $conttype = "Content-Type: application/octet-octet-stream\r\n";
    } elsif (($fname =~ /\.html$/i) ||
             ($fname =~ /\.htm$/i)) {
        $urlraw = 1;
        $conttype = "Content-Type: text/html\r\n";
    } else {
    #} elsif (($fname =~ /\.html$/i) ||
    #         ($fname =~ /\.htm$/i) ||
    #         ($fname =~ /\.bak$/i) ||
    #         ($fname =~ /\.way$/i) ||
    #         ($fname =~ /\.trk$/i) ||
    #         ($fname =~ /\.trk$/i) ||
    #         ($fname =~ /\.txt$/i) ||
    #         ($fname !~ /\./)           # doesn't have '.'
    #         ) {
        $conttype = "Content-Type: text/html\r\n";
    #} else {
    #    $conttype = "Content-Type: application/octet-octet-stream\r\n";
    }

    if (defined($size)) {
        $conttype .= "Content-Disposition: inline; filename=\"$fname\"; size=\"$size\"\r\n";
    }

    ($conttype, $urlraw);
}

sub l00http_ls_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($nofiles, $nodirs, $showbak, $dir, @dirs);
    my ($skipped, $showtag, $showltgt, $showlnno, $lnno, $searchtag, %showdir);
    my ($wikihtmlflags, $tmp, $tmp2, $foundhdr, $intoc, $filedata, $skipto, $stopat);
    my ($clipdir, $clipfile, $docrc32, $crc32, $pnameup, $urlraw, $path2, $skiptohdr);


    $wikihtmlflags = 0;
    $skiptohdr = '';

    # 1) Determine operating path and mode

    $path = $ctrl->{'plpath'};
    if (defined ($form->{'path'}) && (length ($form->{'path'}) >= 1)) {
        $path = $form->{'path'};
    }
    $path =~ tr/\\/\//;     # converts all \ to /, which work on Windows too
    $path =~ s/%20/ /g;

    # http://127.0.0.1:20347/C:/x/ram/del/first-demo/index.html
    # becomes
    # ls: path >/C:/x/ram/del/first-demo/index.html<
    # removes leading /
    $path2 = $path;
    $path2 =~ s/^\/([a-zA-Z]:\/)/$1/;

    if (!defined ($target)) {
        if (defined ($ctrl->{'lsset'})) {
            $target = $ctrl->{'lsset'}; 
        } else {
            $target = "blog";
        }
    }

    $skipto = '';
    $stopat = '';
    if ((defined ($form->{'submit'})) && ($form->{'submit'} eq 'Submit')) {
        if (defined ($form->{'sort'}) && ($form->{'sort'} eq 'on')) {
            $sortkey1name2date = 2;
        } else {
            $sortkey1name2date = 1;
        }

        if (defined ($form->{'lfisbr'}) && ($form->{'lfisbr'} eq 'on')) {
            $lfisbr = 'checked';
        } else {
            $lfisbr = '';
        }
        if (defined ($form->{'embedpic'}) && ($form->{'embedpic'} eq 'on')) {
            $embedpic = 'checked';
        } else {
            $embedpic = '';
        }
        if (defined ($form->{'chno'}) && ($form->{'chno'} eq 'on')) {
            $chno = 'checked';
        } else {
            $chno = '';
        }
        if (defined ($form->{'bare'}) && ($form->{'bare'} eq 'on')) {
            $bare = 'checked';
        } else {
            $bare = '';
        }
        if (defined ($form->{'hilite'})) {
            $hilite = $form->{'hilite'};
        }

        if (defined ($form->{'skipto'}) && ($form->{'skipto'} =~ /(\d+)/)) {
            $skipto = $1;
            $stopat = $skipto + 10;
        }
        if (defined ($form->{'stopat'}) && ($form->{'stopat'} =~ /(\d+)/)) {
            $stopat = $1;
            if ($skipto >= $stopat) {
                $skipto  = $stopat - 10;
                if ($skipto < 0) {
                    $skipto = 0;
                }
            }
        }
    }

    if ($lfisbr eq 'checked') {
        $wikihtmlflags += 16;      # flags for &l00wikihtml::wikihtml for 16=newline is always <br>
    }
    if ($embedpic eq 'checked') {
        $wikihtmlflags += 32;      # flags for &l00wikihtml::wikihtml for 32=to embed pictures<br>
    }

    print "ls: path >$path<\n", if ($ctrl->{'debug'} >= 3);

    if ($ctrl->{'ishost'}) {
        if ((defined ($form->{'submit'})) && ($form->{'submit'} eq 'Submit')) {
            if ((defined ($form->{'noclinav'})) && ($form->{'noclinav'} eq 'on')) {
                $ctrl->{'noclinav'} = 1;
                $ctrl->{'clipath'} = $path;
            } else {
                $ctrl->{'noclinav'} = 0;
            }
        }
    } else {
        # restrict remote directory navigation is enabled
        if ($ctrl->{'noclinav'}) {
            if (($ctrl->{'clipath'} ne '*') &&  
                # not * (wide open)
                ($ctrl->{'clipath'} ne substr ($path, 0, length ($ctrl->{'clipath'})))) {
                # and not approved path
                # then dset to approved path
                $path = $ctrl->{'clipath'};
            }
        }
    }
    print "ls: path after client restriction (noclinav $ctrl->{'noclinav'}) >$path<\n", if ($ctrl->{'debug'} >= 5);

    $read0raw1 = 0;     # always reset to reading mode
#   if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'read')) {
#       $read0raw1 = 0;     # reading mode, i.e. add <br> for linefeed
#   }
    if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'raw')) {
        $read0raw1 = 1;     # raw mode, i.e. unmodified binary transfer, e.g. view .jpg
    }
#   if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'pre')) {
#       $read0raw1 = 2;     # raw mode, i.e. unmodified binary transfer, e.g. view .jpg
#   }
    if ($chno eq 'checked') {
        $wikihtmlflags += 2;      # flags for &l00wikihtml::wikihtml
    }
    if ($bare eq 'checked') {
        $wikihtmlflags += 4;      # flags for &l00wikihtml::wikihtml for 'bare'
    }
    if (defined ($form->{'newwin'})) {
        $wikihtmlflags += 8;      # flags for &l00wikihtml::wikihtml for 'newwin'
    }

    if ((defined ($form->{'target'})) && (defined ($form->{'setlaunch'})) && (length ($form->{'setlaunch'}) > 0)) {
        $target = $form->{'target'};
    }

    if ((defined ($form->{'altsendto'})) && (defined ($form->{'sendto'})) && (length ($form->{'sendto'}) > 0)) {
        #$sendto = $form->{'sendto'};
        $ctrl->{'lssize'} = $form->{'sendto'};
    }
#   if (defined ($form->{'prefmt'})) {
#       $prefmt = 'checked';
#   } else {
#       $prefmt = '';
#   }
    if (defined ($form->{'showpage'})) {
        $showpage = 'checked';
    } else {
        $showpage = '';
    }
    if (defined ($form->{'sortfind'})) {
        $sortfind = 'checked';
    } else {
        $sortfind = '';
    }
    if (defined ($form->{'timestamp'}) &&
        ($form->{'timestamp'} eq 'on')) {
        $hilite = '^\d{8,8} \d{6,6} ';
    }
    if (defined($form->{'lineno'})) {
        $form->{'SHOWLINENO'} = 1;
    }

    $editable = 0;
    $htmlend = 1;
    # try to open as a directory
    print "ls: try open as directory >$path<\n", if ($ctrl->{'debug'} >= 5);
    if (!opendir (DIR, $path2)) {
        print "ls: it is not a directory >$path<\n", if ($ctrl->{'debug'} >= 5);

        # 2) If the path is not a directory:

        # not a dir, try as file
        #print $sock "Try '$path' as a file<br>\n";
        # special case for /favicon.ico
        if ($path eq '/favicon.ico') {
            $path = "$ctrl->{'plpath'}favicon.ico";
        } else {
            if ($path !~ /[\\\/]/) {
                # $path is filename only without path, append last pname
                $path = "$lastpname$path";
                $path2 = $path;
            } elsif (($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/) {
                # $path has pathname, save it
                $lastpname= $pname;
            }
        }
        undef $filedata;
        #l00:
        if (($pname, $fname) = $form->{'path'} =~ /^(l00:\/\/)(.+)/) {
            print "ls: it is l00:// >$path<\n", if ($ctrl->{'debug'} >= 5);
            if (defined($ctrl->{'l00file'})) {
                if (!defined($ctrl->{'l00file'}->{$form->{'path'}})) {
                    $httphdr = "Content-Type: text/html\r\n";
                    print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                    ($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/;
                    print $sock $ctrl->{'htmlhead'} . "<title>$fname ls</title>" .$ctrl->{'htmlhead2'};
                    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
                    print $sock "File $form->{'path'} not found.<p>\n";
                } else {
                    $filedata = $ctrl->{'l00file'}->{$form->{'path'}};
                    $editable = 1;

                    ($httphdr, $urlraw) = &l00http_ls_conttype($form->{'path'});

                    if (defined ($form->{'raw'}) && ($form->{'raw'} eq 'on')) {
                        $urlraw = 1;
                    }
                    if ($httphdr eq "Content-Type: application/octet-octet-stream\r\n") {
                        # treat unknown as text for RAM file
                        $urlraw = 0;
                        $httphdr = "Content-Type: text/html\r\n";
                    }

                    if ($urlraw == 1) {
                        $size = length($filedata);

                        $httphdr .= "Content-Length: $size\r\n";
                        $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                        print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";

                        $ttlbytes = 0;
                        # send file in block of 0x10000 bytes
                        do {
#                            $len = read (FILE, $buf, 0x10000);
                            $len = length($filedata) - $ttlbytes;
                            if ($len > 0x10000) {
                                $len = 0x10000;
                            }
                            $buf = substr($filedata, $ttlbytes, $len);
                            if ($len > 0) {
                                $ttlbytes += $len;
                            }
                            syswrite ($sock, $buf, $len);
                            select (undef, undef, undef, 0.001);    # 1 ms delay. Without it Android looses data
                        } until ($len < 0x10000);
                        print "sent $ttlbytes\n", if ($ctrl->{'debug'} >= 3);
                        $sock->close;
                        return;

                    } else {
                        print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                        if ($bare ne 'checked') {
                            if (($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/) {
                                print $sock $ctrl->{'htmlhead'} . "<title>$fname ls</title>" .$ctrl->{'htmlhead2'};
                                # not ending in / or \, not a dir
                                # clip.pl with \ on Windows
                                $tmp = $path;
                                if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                                    $tmp =~ s/\//\\/g;
                                }
                                print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>:&nbsp;<a href=\"/ls.htm?path=$pname\">$pname</a><a href=\"/ls.htm?path=$pname$fname\">$fname</a><br>\n";
                            } else {
                                print $sock $ctrl->{'htmlhead'} . "<title>$path ls</title>" .$ctrl->{'htmlhead2'};
                                # clip.pl with \ on Windows
                                $tmp = $path;
                                if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                                    $tmp =~ s/\//\\/g;
                                }
                                print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>:&nbsp;$path<br>\n";
                            }
                            print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
                            print $sock "<a href=\"#end\">end</a>\n";
                            print $sock "<a href=\"#__toc__\">TOC</a>\n";
                            if (defined ($form->{'bkvish'})) {
                                print $sock "<a href=\"/ls.htm?path=$path\">view</a> \n";
                            } else {
                                print $sock "<a href=\"/ls.htm?bkvish=bk&path=$path\">bk&vi</a> \n";
                            }
                            print $sock "<a href=\"/blog.htm?path=$path\">log</a> \n";
                            print $sock "<a href=\"/edit.htm?path=$path\">Ed</a> \n";
                            print $sock "<a href=\"/view.htm?path=$path\">Vw</a><hr>\n";
                            if (defined ($form->{'bkvish'})) {
                                print $sock &l00httpd::pcSyncCmdline($ctrl, "$path");
                                print $sock "<hr>\n";
                            }
                        } else {
                            ($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/;
                            print $sock $ctrl->{'htmlhead'} . "<title>$fname ls</title>" .$ctrl->{'htmlhead2'};
                        }
    #l00:
                        # rendering as wiki text
                        $buf = "";
                        $showltgt = 0;
                        $showlnno = 0;
                        undef %showdir;
                        $lnno = 0;
                        $searchtag = 1;
                        foreach $_ (split ("\n", $filedata)) {
                            $_ .= "\n";
                            $lnno++;

                            if (/(.*)%INCLUDE<(.+?)>%(.*)/) {
								    if (defined($1)) {
                                        $buf .= $1;
								    }
                                    $_ = $2;
								    if (defined($3)) {
								        $tmp = $3;
								    } else {
								        $tmp = '';
								    }
                                    # include file
                                    #s/^%INCLUDE%://;
                                    #s/\r//;
                                    #s/\n//;

                                    # is this superceded by path=./ substitution in ls.pl?
                                    # subst %INCLUDE<./xxx> as 
                                    #       %INCLUDE</absolute/path/xxx>
                                    s/^\.\//$pname\//;
                                    # drop last directory from $pname for:
                                    # subst %INCLUDE<../xxx> as 
                                    #       %INCLUDE</absolute/path/../xxx>
                                    $pnameup = $pname;
                                    $pnameup =~ s/([\\\/])[^\\\/]+[\\\/]$/$1/;
                                    s/^\.\.\//$pnameup\//;

                                    if (&l00httpd::l00freadOpen($ctrl, $_)) {
                                        # %INCLUDE%: here
                                        while ($_ = &l00httpd::l00freadLine($ctrl)) {
                                            if (/^##/) {
                                                # skip to next ^#
                                                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                                                    if (/^#/) {
                                                        last;
                                                    }
                                                }
                                            }
                                            if (/^#/) {
                                                # skip ^#
                                                next;
                                            }
#                                           # translate all %L00HTTP<plpath>% to $ctrl->{'plpath'}
#                                           if (/%L00HTTP<(.+?)>%/) {
#                                               if (defined($ctrl->{$1})) {
#                                                   s/%L00HTTP<(.+?)>%/$ctrl->{$1}/g;
#                                               }
#                                           }
                                            $buf .= $_;
                                        }
                                    }
                                    $buf .= $tmp;
                                next;
                            }

                            # highlighting
                            if (defined ($hilite) && (length($hilite) > 1)) {
                                s/($hilite)/<font style=\"color:black;background-color:lime\">$1<\/font>/g;
                            }

						    # path=$ substitution
                            s/path=\$/path=$path/g;

                            # convert leading spaces to no break spaces
                            # but not leading */_{ which are font formatting (//})
                            if (!/^ *$/) {
                                # and not blank lines
                                s/^( +)([^*\/_\{])/'&nbsp;' x length($1).$2/e;
                                # This } matches the search pattern just above so editor matching works
                            }

                            $_ = "%l00httpd:lnno:$lnno%$_";
                            $buf .= $_;
			            }
                
                        $buf = &l00wikihtml::wikihtml ($ctrl, $pname, $buf, $wikihtmlflags, $fname);
                        if (defined ($form->{'hiliteln'})) {
                            foreach $_ (split ("\n", $buf)) {
                                if (/<a name=\"line$form->{'hiliteln'}\"><\/a>/) {
                                    s/>(.+)</><font style="color:black;background-color:lime">$1<\/font></g;
                                    print $sock "$_\n";
                                } else {
                                    print $sock "$_\n";
                                }
                            }
                        } else {
                            print $sock $buf;
                        }
                    }
#l00:
                }
            }
        } elsif (open (FILE, "<$path2")) {
            ($pname, $fname) = $path2 =~ /^(.+\/)([^\/]+)$/;
            print "ls: opened as a file >$path<\n", if ($ctrl->{'debug'} >= 5);
            if (defined ($form->{'bkvish'})) {
                &l00backup::backupfile ($ctrl, $path2, 1, 5);
                if (open (OUT, ">$ctrl->{'plpath'}l00http_cmdedit.sh")) {
                    #print OUT "$ctrl->{'bbox'}vi $path2\n";
                    print OUT "vim $path2\n";
                    close (OUT);
                }
            }
            # launch editor
            if (defined ($form->{'exteditor'})) {
                if ($ctrl->{'os'} eq 'and') {
                    $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path", "text/plain");
                } elsif (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                    my ($pid);
                    if ($pid = fork) {
                    } else {
                        # http://www.oreilly.com/openbook/cgi/ch10_10.html
                        # child process
                        $_ = $path2;
                        s/\//\\/g;
                        system ("cmd /c \"start notepad ^\"$path2^\"\"");
                        exit (0);
                    }
                }
            }
            $urlraw = 0;
            if (defined ($form->{'raw'}) && ($form->{'raw'} eq 'on')) {
                $urlraw = 1;
            }
            if (($read0raw1 == 0) && ($urlraw == 0)) {
                # auto raw for reading
                # if not usual text file extension, make it raw
                #if (!($fname =~ /\.txt$/i) &&
                #    !($fname =~ /\.way$/i) &&
                #    !($fname =~ /\.trk$/i) &&
                #    !($fname =~ /\.inc$/i) &&
                #    !($fname =~ /\.bak$/i) &&
                #    !($fname =~ /\.csv$/i) &&
                #    !($fname =~ /\.log$/i) &&
                #    !($fname =~ /\.md$/i) &&
                #    !($fname =~ /\.pl$/i) &&
                #    !($fname =~ /\.pm$/i) &&
                #    !($fname =~ /\.h$/i) &&
                #    !($fname =~ /\.c$/i) &&
                #    !($fname =~ /\.js$/i) &&
                #    !($fname =~ /\.cpp$/i) &&
                #    !($fname =~ /\.htm$/i) &&
                #    !($fname =~ /\.html$/i) &&
                #    !($fname !~ /\./)) {    # doesn't have '.'
                #    $urlraw = 1;
                #}
                #if (($fname =~ /\.bin$/i) ||
                #    ($fname =~ /\.exe$/i) ||
                #    ($fname =~ /\.dat$/i)) { # raw for known binary
                #    $urlraw = 1;
                #}
                ($httphdr, $urlraw) = &l00http_ls_conttype($path);
            }
            # auto raw for
            if (($read0raw1 == 1) || ($urlraw == 1)) {
                # 2.1) If in raw mode, send raw binary

                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat($path2);

                ($httphdr, $urlraw) = &l00http_ls_conttype($path);
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                if ($path =~ /favicon\.ico/) {
                    # special case caching for favicon.ico
                    $httphdr .= "Cache-Control: max-age=2592000\r\n";
                    # //30days (60sec * 60min * 24hours * 30days)
                }
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";

                $htmlend = 0;       # make note not to add control table
                binmode (FILE);
                binmode ($sock);
                $ttlbytes = 0;
                # send file in block of 0x10000 bytes
                do {
                    $len = read (FILE, $buf, 0x10000);
                    if ($len > 0) {
                        $ttlbytes += $len;
                    }
                    syswrite ($sock, $buf, $len);
                    select (undef, undef, undef, 0.001);    # 1 ms delay. Without it Android looses data
                } until ($len < 0x10000);
                print "sent $ttlbytes\n", if ($ctrl->{'debug'} >= 3);
                close (FILE);
                $sock->close;
                return;
            } else {
                $editable = 1;

                $httphdr = "Content-Type: text/html\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";

                if ($bare ne 'checked') {
                    if (($pname, $fname) = $path2 =~ /^(.+\/)([^\/]+)$/) {
                        print $sock $ctrl->{'htmlhead'} . "<title>$fname ls</title>" .$ctrl->{'htmlhead2'};
                        # not ending in / or \, not a dir
                        # clip.pl with \ on Windows
                        $tmp = $path2;
                        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                            $tmp =~ s/\//\\/g;
                        }
                        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>:&nbsp;<a href=\"/ls.htm?path=$pname\">$pname</a><a href=\"/ls.htm?path=$pname$fname\">$fname</a><br>\n";
                    } else {
                        print $sock $ctrl->{'htmlhead'} . "<title>$path2 ls</title>" .$ctrl->{'htmlhead2'};
                        # clip.pl with \ on Windows
                        $tmp = $path2;
                        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                            $tmp =~ s/\//\\/g;
                        }
                        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>:&nbsp;$path2<br>\n";
                    }
                    print $sock "$ctrl->{'home'} \n";
                    if ($path =~ /^$ctrl->{'plpath'}docs_demo[\\\/]HelpMod(.+)\.txt$/) {
                        # we are displaying help text, also generate a link to source code
                        print $sock "<a href=\"/view.htm/$fname?path=$ctrl->{'plpath'}l00http_$1.pl\">code</a>\n";
                    }
                    print $sock "$ctrl->{'HOME'} \n";
                    print $sock "<a href=\"#end\">end</a>\n";
                    print $sock "<a href=\"#__toc__\">TOC</a>\n";
                    if (defined ($form->{'bkvish'})) {
                        print $sock "<a href=\"/ls.htm?path=$path2\">view</a> \n";
                    } else {
                        print $sock "<a href=\"/ls.htm?bkvish=bk&path=$path2\">bk&vi</a> \n";
                    }
                    print $sock "<a href=\"/blog.htm?path=$path2\">log</a> \n";
                    print $sock "<a href=\"/edit.htm?path=$path2\">Ed</a>/";
                    print $sock "<a href=\"/ls.htm?path=$path2&exteditor=on\">ext</a>\n";
                    print $sock "<a href=\"/view.htm?path=$path2\">Vw</a><hr>\n";
                    if (defined ($form->{'bkvish'})) {
                        print $sock &l00httpd::pcSyncCmdline($ctrl, "$path2");
                        print $sock "<hr>\n";
                    }
                } else {
                    ($pname, $fname) = $path2 =~ /^(.+\/)([^\/]+)$/;
                    print $sock $ctrl->{'htmlhead'} . "<title>$fname ls</title>" .$ctrl->{'htmlhead2'};
                }

                # 2.2) If not, try reading 30 lines and look for Wikitext

                $ln = 4000;
                $hits = 0;
                while (<FILE>) {
                    # count wikitext keywords
                    if (/=+[^=]+=+/) {
                        #==title==
                        $hits++;
                    }
                    if (/^\*+ /) {
                        #* bullet
                        $hits++;
                    }
                    if (/^\|\|/) {
                        #|| table
                        $hits++;
                        if ($ctrl->{'debug'} >= 3) {
                            $ctrl->{'msglog'} .= "ls:table >$_<\n";
                        }
                    }
                    if ($hits >= 1) {
                        last;
                    }
                    if (--$ln < 0) {
                        last;
                    }
                }
                close (FILE);

                open (FILE, "<$path2");
                $bulvl = 0;
                if ($hits >= 1) {
                    # rendering as wiki text
                    $buf = "";
                    undef $showtag;
                    $showltgt = 0;
                    $showlnno = 0;
                    undef %showdir;
                    $lnno = 0;
                    $searchtag = 1;
                    if (defined($form->{'SHOWTAG'})) {
                        # SHOWTAG specified in URL, to ignore definitions in file
                        $showtag = $form->{'SHOWTAG'};
                        if (length($showtag) < 1) {
                            $showtag = '.*';
                        }
                        $searchtag = 0;
                    }
                    if (defined($form->{'SHOWLINENO'})) {
                        # SHOWLINENO specified in URL, turn on SHOWLINENO mode
                        $showlnno = 1;
                    }
                    while (<FILE>) {
                        $lnno++;
                        if (($skipto ne '') && ($lnno < $skipto)) {
                            next;
                        }
                        if ($stopat ne '') {
                            my ($length, $start, $end);
                            $skiptohdr  = "Content limited to between line $skipto-$lnno. Show: ";
                            $length = $lnno - $skipto;

                            $start = $skipto - $length;
                            if ($start < 1) {
                                $start = 1;
                            }
                            $end = $start + $length;
                            $skiptohdr .= "<a href=\"/ls.htm?path=$path2&submit=Submit&skipto=$start&stopat=$end\">$start-$end</a> - ";
                            $start = $skipto - int($length/2);
                            if ($start < 1) {
                                $start = 1;
                            }
                            $end = $start + $length;
                            $skiptohdr .= "<a href=\"/ls.htm?path=$path2&submit=Submit&skipto=$start&stopat=$end\">$start-$end</a> - ";
                            $start = $skipto + int($length/2);
                            $end = $start + $length;
                            $skiptohdr .= "<a href=\"/ls.htm?path=$path2&submit=Submit&skipto=$start&stopat=$end\">$start-$end</a> - ";
                            $start = $skipto + $length;
                            $end = $start + $length;
                            $skiptohdr .= "<a href=\"/ls.htm?path=$path2&submit=Submit&skipto=$start&stopat=$end\">$start-$end</a> - ";
                            $skiptohdr .= "<br>\n";
                        }
                        if (($stopat ne '') && ($lnno > $stopat)) {
                            last;
                        }

                        # special case for wikispaces
                        # images has the form:
                        # [[image:rear_medium.jpg width="560" height="261" caption="caption text"]]
                        # [[image:path/rear_medium.jpg
                        # images are stored at path/pages/../files
                        if (($pname =~ /pages[\\\/]$/) &&
                            (($tmp, $tmp2) = /^\[\[image:(.+?) .*caption="(.+)"\]\]/)) {
                            # strip path
                            $tmp =~ s/^.*?([^\\\/]+)$/$1/;
                            $_ = $pname;
                            s/pages([\\\/])$/files$1/;
                            $_ = "<img src=\"${_}$tmp\"><br><i>caption: $tmp2</i><p>\n";
                        }


                        if (defined ($form->{'editline'})) {
                            s/\r//;
                            s/\n//;
                            $_ = "$_ <a href=\"/edit.htm?path=$path2&editline=on&blklineno=$lnno\">[edit line $lnno]</a>\n";
                        }

                        # highlighting
                        if (defined ($hilite) && (length($hilite) > 1)) {
                            s/($hilite)/<font style=\"color:black;background-color:lime\">$1<\/font>/g;
                        }


                        # path=./ substitution
                        s/path=\.\//path=$pname/g;
                        # path=$ substitution
                        s/path=\$/path=$path2/g;

                        # translate all %L00HTTP<plpath>% to $ctrl->{'plpath'}
                        if (/%L00HTTP<(.+?)>%/) {
                            if (defined($ctrl->{$1})) {
                                s/%L00HTTP<(.+?)>%/$ctrl->{$1}/g;
                            }
                        }

                        # implement %SHOWLINENO%; see sl4a/scripts/l00httpd/docs_demo/DemO_developer_journal.txt
                        if (/^%SHOWLINENO%/) {
                            $showlnno = 1;
                            next;
                        }
                        # prepend line number
                        if ($showlnno) {
                            if (/^[^=*%:]/) {
                                # prepend line number
                                $_ = sprintf("%04d: ", $lnno). $_;
                            }
                            if (/^(=+.+[^=])(=+)$/) {
                                $_ = "$1 ($lnno) $2\n";
                            }
                        }
                        # implement %SHOWLEADINGSPACES%; see sl4a/scripts/l00httpd/docs_demo/DemO_developer_journal.txt
                        # convert leading spaces to no break spaces
                        # but not leading */_{ which are font formatting (//})
                        if (!/^ *$/) {
                            # and not blank lines
                            s/^( +)([^*\/_\{])/'&nbsp;' x length($1).$2/e;
                            # This } matches the search pattern just above so editor matching works
                        }
                        # implement %SHOWLTGT%; see sl4a/scripts/l00httpd/docs_demo/DemO_developer_journal.txt
                        if (/^%SHOWLTGT%/) {
                            $showltgt = 1;
                            next;
                        }
                        if (/^%NOSHOWLTGT%/) {
                            $showltgt = 0;
                            next;
                        }
                        if ($showltgt) {
                            s/</&lt;/g;
                            s/>/&gt;/g;
                        }
                        # implement SHOWTAG; see sl4a/scripts/l00httpd/docs_demo/DemO_developer_journal.txt
                        if ($searchtag) {
                            # SHOWTAG not defined in URL, search in file
                            if (/^%SHOWTAG(.*?)%/) {
                                $showtag = $1;
                                if (length($showtag) < 1) {
                                    $showtag = '.*';
                                }
                                next;
                            }
                        } elsif (/^%SHOWTAG/) {
                            # hides all %SHOWTAG
                            next;
                        }

                        # search SHOWON/SHOWOFF for directory
                        if (/^%SHOWO[FN]+(.*?)%/) {
                            if (length ($1) > 0) {
                                $showdir {$1} = 1;
                            }
                        }
                        # implement SHOWOFF and SHOWON
                        if (defined($showtag)) {
                            # skip if SHOWOFF is found
                            if (/^%SHOWOFF$showtag%/ || /^%SHOWOFF:ALWAYS%/) {
                                $showdir {$showtag} = 1;
                                $skipped = 0;
                                # skipping until %SHOWON%
                                while (<FILE>) {
                                    $lnno++;
                                    $skipped++;
                                    if (/^%SHOWO[FN]+(.*?)%/) {
                                        if (length ($1) > 0) {
                                            $showdir {$1} = 1;
                                        }
                                    }
                                    if (/^%SHOWON$showtag%/ || /^%SHOWON:ALWAYS%/) {
#                                            if ($bare ne 'checked') {
#                                                $buf .= "&nbsp;&nbsp;&nbsp;&nbsp; (%SHOWTAG%: skipped $skipped lines)\n";
#                                            }
                                        last;
                                    }
                                }
                                next;
                            } elsif (/^%SHOWOFF/) {
                                # hide all %SHOW...
                                next;
                            } elsif (/^%SHOWO/) {
                                # in SHOWOFF/SHOWON mode, hide all controls
                                next;
                            }
                        }

                        if (/(.*)%INCLUDE<(.+?)>%(.*)/) {
                            if (defined($1)) {
                                $buf .= $1;
                            }
                            $_ = $2;
                            if (defined($3)) {
                                $tmp = $3;
                            } else {
                                $tmp = '';
                            }
                            # include file
                            #s/^%INCLUDE%://;
                            #s/\r//;
                            #s/\n//;

                            # is this superceded by path=./ substitution in ls.pl?
                            # subst %INCLUDE<./xxx> as 
                            #       %INCLUDE</absolute/path/xxx>
                            s/^\.\//$pname\//;
                            # drop last directory from $pname for:
                            # subst %INCLUDE<../xxx> as 
                            #       %INCLUDE</absolute/path/../xxx>
                            $pnameup = $pname;
                            $pnameup =~ s/([\\\/])[^\\\/]+[\\\/]$/$1/;
                            s/^\.\.\//$pnameup\//;

                            if (&l00httpd::l00freadOpen($ctrl, $_)) {
                                # %INCLUDE%: here
                                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                                    if (/^##/) {
                                        # skip to next ^#
                                        while ($_ = &l00httpd::l00freadLine($ctrl)) {
                                            if (/^#/) {
                                                last;
                                            }
                                        }
                                    }
                                    if (/^#/) {
                                        # skip ^#
                                        next;
                                    }
                                    # translate all %L00HTTP<plpath>% to $ctrl->{'plpath'}
                                    if (/%L00HTTP<(.+?)>%/) {
                                        if (defined($ctrl->{$1})) {
                                            s/%L00HTTP<(.+?)>%/$ctrl->{$1}/g;
                                        }
                                    }
                                    $buf .= $_;
                                }
                            }
                            $tmp = "%l00httpd:lnno:$lnno%$tmp";
                            $buf .= $tmp;
                            next;
                        }
                        $_ = "%l00httpd:lnno:$lnno%$_";
                        $buf .= $_;
                    }
                    if (%showdir) {
                        if ($bare ne 'checked') {
                            $found = "---\n<b><i>SHOWTAG directory</i></b>\n"; # borrow variable
                            $found .= "* :ALWAYS:";
                            $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=:ALWAYS\">SHOW</a>";
                            $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=:ALWAYS&SHOWLINENO=\">with line#</a>";
                            $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=:ALWAYS&submit=Submit&bare=on\">no header/footer</a>";
                            $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=:ALWAYS&submit=Submit&bare=on&chno=on\">+ ch no</a>";
                            $found .= "\n";
                            foreach $_ (sort keys %showdir) {
                                $found .= "* $_:";
                                $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=$_\">SHOW</a>";
                                $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=$_&SHOWLINENO=\">with line#</a>";
                                $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=$_&submit=Submit&bare=on\">no header/footer</a>";
                                $found .= " <a href=\"/ls.htm?path=$path2&SHOWTAG=$_&submit=Submit&bare=on&chno=on\">+ ch no</a>";
                                $found .= "\n";
                            }
                            $buf = "$found\n$buf";
                        }
                    }
                    $found = '';
                    if (defined ($form->{'find'})) {
                        $foundhdr = "<font style=\"color:black;background-color:lime\">Find in this file results:</font> <a href=\"#__find__\">(jump to results end)</a>\n";
                        if (defined ($form->{'findtext'})) {
                            $findtext = $form->{'findtext'};
                        }
                        if (defined ($form->{'prefmt'})) {
                            $prefmt = 'checked';
                        } else {
                            $prefmt = '';
                        }
                        if (defined ($form->{'block'})) {
                            $block = $form->{'block'};
                        }
                        if ($prefmt ne '') {
                            $foundhdr .= "<pre>\n";
                        }
                        $found = &l00httpd::findInBuf ($findtext, $block, $buf);
                        if ($block eq '.') {
                            if ($sortfind ne '') {
                                $found = join("\n", sort l00http_ls_sortfind split("\n", $found));
                            }
                            # add line number
                            $tmp = '';
                            foreach $_ (split ("\n", $found)) {
                                if (/%l00httpd:lnno:(\d+)%/) {
                                    $tmp2 = $1 - 10;
                                    if ($tmp2 < 1) {
                                        $tmp2 = 1;
                                    }
                                    $_ = "<a href=\"/view.htm?path=$path2&skip=$tmp2#line$1\">".sprintf("%05d", $1)."</a>: $_";
                                }
                                $tmp .= "$_\n";
                            }
                            $found = $tmp;
                        }
                        $found = $foundhdr . $found;
                        if ($prefmt ne '') {
                            $found .= "</pre>\n";
                        } else {
                            # remove line number
                            $found =~ s/^\d+: //gm;
                        }
                        $found .= "<br><a name=\"__find__\"></a><font style=\"color:black;background-color:lime\">Find in this file results end</font><hr>\n";
                        # render found results
                        print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $found, $wikihtmlflags, $fname);
                    }
                    
                    if ((defined ($form->{'find'})) &&
                        ($showpage ne 'checked')) {
                        # find without displaying page
                    } else {
                        $buf = &l00wikihtml::wikihtml ($ctrl, $pname, $buf, $wikihtmlflags, $fname);
                        $buf = "$skiptohdr$buf<br>\n$skiptohdr\n";
                        if (defined ($form->{'hiliteln'})) {
                            foreach $_ (split ("\n", $buf)) {
                                if (/<a name=\"line$form->{'hiliteln'}\"><\/a>/) {
                                    s/>(.+)</><font style="color:black;background-color:lime">$1<\/font></g;
                                    print $sock "$_\n";
                                } else {
                                    print $sock "$_\n";
                                }
                            }
                        } else {
                            print $sock $buf;
                        }
                    }
                } else {
                    # rendering as raw text

                    $buf = "";
                    while (<FILE>) {
                        $buf .= $_;
                    }
                    # 2.4) If no Wikitext were found, a <br> as linefeed

                    $found = '';
                    if (defined ($form->{'find'})) {
                        $found = "<font style=\"color:black;background-color:lime\">Find in this file results:</font> <a href=\"#__find__\">(jump to results end)</a>\n";
                        if (defined ($form->{'findtext'})) {
                            $findtext = $form->{'findtext'};
                        }
                        if (defined ($form->{'block'})) {
                            $block = $form->{'block'};
                        }
                        if ($prefmt ne '') {
                            $found .= "<pre>\n";
                        }
                        $found .= &l00httpd::findInBuf ($findtext, $block, $buf);
                        if ($prefmt ne '') {
                            $found .= "</pre>\n";
                        }
                        $found .= "<br><a name=\"__find__\"></a><font style=\"color:black;background-color:lime\">Find in this file results end</font><hr>\n";
                        # rendering as raw text
                        print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $found, $wikihtmlflags, $fname);
                    }

                    $ln = 1;
                    foreach $_ (split ("\n", $buf)) {
                        s/</&lt;/g;  # no HTML tags
                        s/>/&gt;/g;
                        print $sock "<a name=\"$ln\">$_</a><br>\n";
                        $ln++;
                    }
                }
            }
            close (FILE);
        } else {
            print "ls: failed to open as a file >$path<\n", if ($ctrl->{'debug'} >= 5);
            print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
            print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
            print $sock "<a href=\"#end\">end</a><br>\n";
            print $sock "Path: $path<hr>\n";
            print $sock "Unable to open file '$path'<br>\n";
            $dir = $path;
            $dir =~ s/\/[^\/]+$/\//;
            print $sock "View: <a href=\"/ls.htm?path=$dir\">$dir</a><br>\n";
            # allow edit to create new file
            $editable = 1;
        }
    } else {
        #.dir
        # yes, it is a directory, read files in the directory
        print "ls: it is a directory >$path2<\n", if ($ctrl->{'debug'} >= 5);

        if ((defined ($form->{'showbak'})) && ($form->{'showbak'} eq 'on')) {
            $showbak = 1;
        } else {
            $showbak = 0;
        }
        if ((defined ($form->{'crc32'})) && ($form->{'crc32'} eq 'on')) {
            $docrc32 = 1;
        } else {
            $docrc32 = 0;
        }

        
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$path2 ls</title>" .$ctrl->{'htmlhead2'};
        # clip.pl with \ on Windows
        $tmp = $path2;
        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>:&nbsp;$path2\n";
        print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
        print $sock "<a href=\"#end\">Jump to end</a> \n";
        print $sock "<a href=\"/dirnotes.htm?path=$path2"."NtDirNotes.txt\">NtDirNotes</a><hr>\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

        print $sock "<tr>\n";
        print $sock "<td>names</td>\n";
        print $sock "<td>bytes</td>\n";
        print $sock "<td>crc32</td>\n", if ($docrc32);
        print $sock "<td>date/time</td>\n";
        print $sock "</tr>\n";
        

        # 3) If the path is a directory, make a table with links

        $nofiles = 0;
        $nodirs = 0;
        $bakout = '';
        $dirout = '';
        $fileout = '';
        $clipfile = '';
        $clipdir = '';
        #if (defined ($form->{'sort'}) && ($form->{'sort'} eq 'on')) 
        if ($sortkey1name2date == 2) {
            # sort by reverse time
            $llspath = $path2;
            @dirs = sort llsfn readdir (DIR);
        } else {
            @dirs = sort llstricmp readdir (DIR);
        }
        foreach $file (@dirs) {
            if (-d $path2.$file) {
                # it's a directory, print a link to a directory
                if ($file =~ /^\.$/) {
                    next;
                }
                $fullpath = $path2 . $file;
                if ($file =~ /^\.\.$/) {
                    $fullpath =~ s!/[^/]+/\.\.!!;
                    if ($fullpath eq "/..") {
                        $fullpath = "";
                    }
                }
                # get timestamp
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat($fullpath);
                ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                 = localtime($mtime);

                # escape to %xx
                $fullpath =~ s/([^^A-Za-z0-9\-_.!~*'()])/ sprintf "%%%02x", ord $1 /eg;

                # clip path listing
                $tmp = $fullpath;
                if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                    $tmp =~ s/\//\\/g;
                }
                $clipdir .= "&lt;<a href=\"/clip.htm?update=on&clip=$tmp\">$file</a>&gt; - ";
                                
                $dirout .= "<tr>\n";
                $dirout .= "<td><small><a href=\"/ls.htm?path=$fullpath/\">$file/</a></small></td>\n";
                if ($file eq '..') {
                    $dirout .= "<td><small><a href=\"/tree.htm?path=$path2\">&lt;dir&gt;</a></small></td>\n";
                } else {
                    $dirout .= "<td><small><a href=\"/tree.htm?path=$fullpath/\">&lt;dir&gt;</a></small></td>\n";
                }
                $dirout .= "<td>&nbsp;</td>\n", if ($docrc32);
                $dirout .= "<td><small>". 
                    sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec) 
                    ."</small></td>\n";
                $dirout .= "</tr>\n";
                $nodirs++;
            } else {
                # it's not a directory, print a link to a file
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat($path2.$file);
                if (!defined($mtime)) {
                    $mtime = 0;
                }
                ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                 = localtime($mtime);

                $fullpath = $path2 . $file;
                $fullpath =~ s/([^^A-Za-z0-9\-_.!~*'()])/ sprintf "%%%02x", ord $1 /eg;

                $buf = "<tr>\n";
                if ($file =~ /\.txt$/i) {
                    # tx=$file.htm so it ends in .htm for Palm TX
                    $buf .= "<td><small><a href=\"/ls.htm/$file?path=$fullpath\">$file</a>"
                        ."</small></td>\n";
                } else {
                    $buf .= "<td><small><a href=\"/ls.htm/$file?path=$fullpath\">$file</a>"
                        ."</small></td>\n";
                }
                $buf .= "<td align=right><small>"
                    ."<a href=\"/$ctrl->{'lssize'}.htm?path=$fullpath\">$size</a>"
                    ."</small></td>\n";
                # compute crc32
                if ($docrc32) {
                    my ($crcbuf);
                    local $/ = undef;
                    if(open(IN, "<$path2$file")) {
                        binmode (IN);
                        $crcbuf = <IN>;
                        close(IN);
                    } else {
                        $buf = '';
                    }
                    $crc32 = sprintf("%08x", &l00crc32::crc32($crcbuf));
                    $buf .= "<td><small>$crc32</small></td>\n";
                }
                $buf .= "<td><small>". 
                    sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec) 
                    ."</small></td>\n";
                $buf .= "</tr>\n";

                $tmp = "$path2$file";
                if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                    $tmp =~ s/\//\\/g;
                }
                $tmp2 = $file;
                if ($path2 eq $ctrl->{'plpath'}) {
                    if ($clipfile eq '') {
                        $clipfile = 'shorten l00http_X.pl to X - ';
					}
                    # shorten listing name if viewing source code
                    $tmp2 =~ s/l00http_(.+)\.pl/$1/;
				}
                if ($file =~ /\.bak$/) {
                    $bakout .= $buf;
                    if ($showbak) {
                        # clip path listing
                        $clipfile .= "<a href=\"/clip.htm?update=on&clip=$tmp\">$tmp2</a> - ";
                    }
                } else {
                    $fileout .= $buf;
                    # clip path listing
                    $clipfile .= "<a href=\"/clip.htm?update=on&clip=$tmp\">$tmp2</a> - ";
                }

                $nofiles++;
            }
        }
        closedir (DIR);

        if (defined ($form->{'clippath'}) && ($form->{'clippath'} eq 'on')) {
            print $sock "</table>\n";
            print $sock "<p><hr>$clipfile - $clipdir<p><hr>\n";
        } else {
            print $sock $dirout;
            print $sock $fileout;
            if ($showbak) {
                print $sock $bakout;
            }
            print $sock "</table>\n";
        }
        print $sock "<p>There are $nodirs director(ies) and $nofiles file(s)<br>\n";
    }
    print "ls: processed >$path2<\n", if ($ctrl->{'debug'} >= 5);

    # 4) If not in raw mode, also display a control table
    if (!defined($pname)) {
        $pname = '';
    }

    if (!defined($fname)) {
        $fname = '';
    }

    if ($htmlend) {
        if ($bare ne 'checked') {
            if ($ctrl->{'ishost'}) {
                if ($ctrl->{'noclinav'}) {
                    print $sock "Client access mode: limited: $ctrl->{'clipath'} <br>\n";
                } else {
                    print $sock "Client access mode: full<br>\n";
                }
            }
            print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
            print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

            print $sock "<tr>\n";
            print $sock "  <td>Settings</td>\n";
            print $sock "  <td>Descriptions</td>\n";
            print $sock "</tr> <tr>\n";
            print $sock "  <td>Path:</td>\n";
            print $sock "  <td><input type=\"text\" size=\"10\" name=\"path\" value=\"$path2\"></td>\n";
            print $sock "</tr>\n";

#           if ($read0raw1 == 0) {
#               $readst = "checked";
#               $raw_st = "unchecked";
#               $pre_st = "unchecked";
#           } elsif ($read0raw1 == 1) {
#               $readst = "unchecked";
#               $raw_st = "checked";
#               $pre_st = "unchecked";
#           } else {
#               $readst = "unchecked";
#               $raw_st = "unchecked";
#               $pre_st = "checked";
#           }
            print $sock "    <tr>\n";
            print $sock "<td><input type=\"checkbox\" name=\"bare\">No header/footer</td>\n";
#           print $sock "        <td>".
#             "<input type=\"radio\" name=\"mode\" value=\"read\" $readst>reading<br>".
#             "<input type=\"radio\" name=\"mode\" value=\"raw\"  $raw_st>raw<br>".
#             "<input type=\"radio\" name=\"mode\" value=\"pre\"  $pre_st>pre<br>".
#             "&nbsp;</td>\n";
            print $sock "        <td><a href=\"/ls.htm?path=$pname$fname&submit=Submit&raw=on\">Raw binary</a></td>\n";
            print $sock "    </tr>\n";

            print $sock "    <tr>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"editline\">Edit line link</td>\n";

            if ($sortkey1name2date == 2) {
                $buf = "checked";
            } else {
                $buf = "";
            }
            print $sock "        <td><input type=\"checkbox\" $buf name=\"sort\">dir sort by time</td>\n";

            print $sock "    </tr>\n";

            print $sock "    <tr>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"timestamp\">Hilite <a href=\"/ls.htm?path=$pname$fname&timestamp=on\">time-stamps</a></td>\n";
            print $sock "        <td>Hilite: <input type=\"text\" size=\"10\" name=\"hilite\" value=\"$hilite\"></td>\n";
            print $sock "    </tr>\n";

            print $sock "    <tr>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"chno\" $chno>Show chapter #.\n";
            print $sock "            <input type=\"checkbox\" name=\"lineno\">line#</td>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"newwin\">Open new window</td>\n";
            print $sock "    </tr>\n";

            print $sock "    <tr>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"clippath\">Clip path</td>\n";
            print $sock "        <td><a href=\"/ls.htm?path=$pname$fname&submit=Submit&bare=on&chno=on\">Bare without forms</a></td>\n";
            print $sock "    </tr>\n";

            print $sock "    <tr>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"crc32\">Compute crc32</td>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"lfisbr\" $lfisbr>Newline is paragraph<br>\n";
            print $sock "            <input type=\"checkbox\" name=\"embedpic\" $embedpic>Embed pictures</td>\n";
            print $sock "    </tr>\n";

            if ($form->{'path'} !~ /^l00:\/\/.+/) {
                # not RAM file, print entry fields
                print $sock "    <tr>\n";
                print $sock "        <td>Skip to: <input type=\"text\" size=\"10\" name=\"skipto\" value=\"$skipto\"></td>\n";
                print $sock "        <td>Stop at: <input type=\"text\" size=\"10\" name=\"stopat\" value=\"$stopat\"></td>\n";
                print $sock "    </tr>\n";

            }
            print $sock "    <tr>\n";
            print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
            print $sock "        <td><input type=\"checkbox\" name=\"showbak\">Show .bak files</td>\n";
            print $sock "    </tr>\n";

            print $sock "</table>\n";
            print $sock "</form>\n";

            if ($ctrl->{'ishost'}) {
                print $sock "<hr>\n";
                print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
                print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

                print $sock "<tr>\n";
                print $sock "  <td>Path:</td>\n";
                print $sock "  <td><input type=\"text\" size=\"10\" name=\"path\" value=\"$path2\"></td>\n";
                print $sock "</tr>\n";
                if ($ctrl->{'noclinav'}) {
                    $buf = "checked";
                } else {
                    $buf = "";
                }
                print $sock "    <tr>\n";
                print $sock "        <td><input type=\"checkbox\" $buf name=\"noclinav\">NoCliNav</td>\n";
                print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
                print $sock "    </tr>\n";
                print $sock "</table>\n";
                print $sock "</form>\n";
            }

            if ($editable) {
                # find
                print $sock "<hr><a name=\"find\"></a>\n";
                print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
                print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
                print $sock "<tr><td>\n";
                print $sock "<input type=\"submit\" name=\"find\" value=\"Find\">\n";
                print $sock "</td><td>\n";
                print $sock "Find in this file\n";
                print $sock "</td></tr>\n";
                print $sock "<tr><td>\n";
                print $sock "RegEx:\n";
                print $sock "</td><td>\n";
                print $sock "<input type=\"text\" size=\"12\" name=\"findtext\" value=\"$findtext\">\n";
                print $sock "</td></tr>\n";
                print $sock "<tr><td>\n";
                print $sock "Block mark:\n";
                print $sock "</td><td>\n";
                print $sock "<input type=\"text\" size=\"12\" name=\"block\" value=\"$block\">\n";
                print $sock "</td></tr>\n";
                print $sock "<tr><td>\n";
                print $sock "<input type=\"checkbox\" name=\"prefmt\" $prefmt>Fixed font\n";
                print $sock "</td><td>\n";
                if ($block eq '.') {
                    print $sock "<input type=\"checkbox\" name=\"sortfind\" $sortfind>Sort found\n";
                } else {
                    print $sock "Sort found\n";
                }
                print $sock "</td></tr>\n";
                print $sock "<tr><td>\n";
                print $sock "<input type=\"checkbox\" name=\"showpage\" $showpage>Show page\n";
                print $sock "</td><td>\n";
                print $sock "&nbsp;\n";
                print $sock "</td></tr>\n";
                print $sock "<tr><td>\n";
                print $sock "File:\n";
                print $sock "</td><td>\n";
                print $sock "<input type=\"text\" size=\"12\" name=\"path\" value=\"$form->{'path'}\">\n";
                print $sock "</td></tr>\n";
                print $sock "</table>\n";
                print $sock "</form>\n";
                print $sock "Blockmark: Regex matching start of block. e.g. '^=' or '^\\* '\n";


                print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\"><tr>\n";
                print $sock "<form action=\"/edit.htm\" method=\"get\">\n";
                print $sock "<td><input type=\"submit\" name=\"edit\" value=\"Edit\"></td>\n";
                print $sock "<td><input type=\"text\" size=\"7\" name=\"path\" value=\"$path2\"></td>\n";
                #print $sock "<td><input type=\"text\" size=\"4\" name=\"busybox\" value=\"busybox vi $path\"></td>\n";
                print $sock "</form>\n";
                print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
                print $sock "<td><input type=\"submit\" name=\"bkvish\" value=\"bk&vi\"></td>\n";
                print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                print $sock "</form>\n";

                print $sock "</tr><tr>\n";

                print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
                print $sock "<td><input type=\"submit\" name=\"setlaunch\" value=\"Set\"></td>\n";
                print $sock "<td><input type=\"text\" size=\"7\" name=\"target\" value=\"$target\"></td>\n";
                print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                print $sock "</form>\n";

                print $sock "<form action=\"/$target.htm\" method=\"get\">\n";
                print $sock "<td><input type=\"submit\" name=\"launchit\" value=\"$target\"></td>\n";
                print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                print $sock "</form>\n";
                print $sock "</tr></table>\n";
            }

            print $sock "<hr><a name=\"end\"></a>\n";
            if (!defined ($file)) {
                $dir = $path2;
                $dir =~ s/\/[^\/]+$/\//;
                print $sock "<p><a href=\"/find.htm?path=$dir&fmatch=%5C.txt%24\">find in files</a> in $dir\n";
                print $sock "<p>Send $path2 to <a href=\"/launcher.htm?path=$path2\">launcher</a>.\n";
                print $sock "<a href=\"/ls.htm?path=$path2&raw=on\">Raw</a>\n";
                print $sock "<p><a href=\"/view.htm?path=$path2\">View</a> $path2\n";
                print $sock "<p><table border=\"1\" cellpadding=\"5\" cellspacing=\"3\"><tr>\n";
                print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
                print $sock "<td><input type=\"submit\" name=\"altsendto\" value=\"'Size' send to\"></td>\n";
                print $sock "<td><input type=\"text\" size=\"7\" name=\"sendto\" value=\"$ctrl->{'lssize'}\"></td>\n";
                if (!defined ($form->{'path'})) {
                    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path2\">\n";
                } else {
                    print $sock "<input type=\"hidden\" name=\"path\"\">\n";
                }
                print $sock "</form>\n";
                print $sock "</tr></table>\n";
            }
        } else {
            print $sock "<p><a href=\"/ls.htm?path=$path2&submit=Submit&bare=&chno=\">form</a>\n";
        }
        print $sock $ctrl->{'htmlfoot'};
    }
    print "ls: return after processed >$path2<\n", if ($ctrl->{'debug'} >= 5);

}


\%config;
