use strict;
use warnings;
use l00wikihtml;
use l00backup;
use l00httpd;

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
my ($wday, $yday, $year, @cols, @el, @els);
my ($fileout, $dirout, $bakout, $http, $desci, $httphdr, $sendto);
my ($pname, $fname, $target, $findtext, $block, $found, $prefmt, $sortfind, $showpage);


my $path;
my $read0raw1 = 0;
$intbl = 0;
$findtext = "";
$block = ".";
#$sendto = 'edit';
$prefmt = 'checked';
$sortfind = '';
$showpage = 'checked';

sub l00http_ls_sortfind {
    my ($rst, $aa, $bb);

    ($aa, $bb) = ($a, $b);
    $aa =~ s/%l00httpd:lnno:\d+%//g;
    $bb =~ s/%l00httpd:lnno:\d+%//g;
    
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

sub l00http_ls_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($nofiles, $nodirs, $showbak, $dir, @dirs);
    my ($skipped, $showtag, $showltgt, $showlnno, $lnno, $searchtag, %showdir);
    my ($showchno, $tmp, $tmp2, $foundhdr, $intoc, $filedata);
#   $showleadingspaces, 

    $showchno = 0;

    # 1) Determine operating path and mode

    $path = $ctrl->{'plpath'};
    if (defined ($form->{'path'}) && (length ($form->{'path'}) >= 1)) {
        $path = $form->{'path'};
    }
    $path =~ tr/\\/\//;     # converts all \ to /, which work on Windows too

    if (!defined ($target)) {
        if (defined ($ctrl->{'lsset'})) {
            $target = $ctrl->{'lsset'}; 
        } else {
            $target = "blog";
        }
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
        if (($ctrl->{'noclinav'}) && 
            ($ctrl->{'clipath'} ne substr ($path, 0, length ($ctrl->{'clipath'})))) {
            $path = $ctrl->{'clipath'};
        }
    }
    $path =~ s/%20/ /g;
    print "ls: path after client restriction (noclinav $ctrl->{'noclinav'}) >$path<\n", if ($ctrl->{'debug'} >= 5);

    if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'read')) {
        $read0raw1 = 0;     # reading mode, i.e. add <br> for linefeed
    }
    if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'raw')) {
        $read0raw1 = 1;     # raw mode, i.e. unmodified binary transfer, e.g. view .jpg
    }
    if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'pre')) {
        $read0raw1 = 2;     # raw mode, i.e. unmodified binary transfer, e.g. view .jpg
    }
    if (defined ($form->{'chno'}) && ($form->{'chno'} eq 'on')) {
        $showchno = 2;      # flags for &l00wikihtml::wikihtml
    }
    if (defined ($form->{'bare'})) {
        $showchno += 4;      # flags for &l00wikihtml::wikihtml for 'bare'
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
    
    $editable = 0;
    $htmlend = 1;
    # try to open as a directory
    if (!opendir (DIR, $path)) {

        # 2) If the path is not a directory:

        # not a dir, try as file
        #print $sock "Try '$path' as a file<br>\n";
        # special case for /favicon.ico
        if ($path eq '/favicon.ico') {
            $path = "$ctrl->{'plpath'}favicon.ico";
        }
        undef $filedata;
#l00:
        if ($form->{'path'} =~ /^l00:\/\//) {
            if (defined($ctrl->{'l00file'})) {
                if (defined($ctrl->{'l00file'}->{$form->{'path'}})) {
                    $filedata = $ctrl->{'l00file'}->{$form->{'path'}};
                    $editable = 1;

                $httphdr = "Content-Type: text/html\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                if (!defined ($form->{'bare'})) {
                    if (($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/) {
                        print $sock $ctrl->{'htmlhead'} . "<title>$fname ls</title>" .$ctrl->{'htmlhead2'};
                        # not ending in / or \, not a dir
                        # clip.pl with \ on Windows
                        $tmp = $path;
                        if ($ctrl->{'os'} eq 'win') {
                            $tmp =~ s/\//\\/g;
                        }
                        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: <a href=\"/ls.htm?path=$pname\">$pname</a>$fname<br>\n";
                    } else {
                        print $sock $ctrl->{'htmlhead'} . "<title>$path ls</title>" .$ctrl->{'htmlhead2'};
                        # clip.pl with \ on Windows
                        $tmp = $path;
                        if ($ctrl->{'os'} eq 'win') {
                            $tmp =~ s/\//\\/g;
                        }
                        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: $path<br>\n";
                    }
                    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> \n";
                    print $sock "<a href=\"#end\">end</a>\n";
                    print $sock "<a href=\"#__toc__\">toc</a>\n";
                    if (defined ($form->{'bkvish'})) {
                        print $sock "<a href=\"/ls.htm?path=$path\">view</a> \n";
                    } else {
                        print $sock "<a href=\"/ls.htm?bkvish=bk&path=$path\">bk&vi</a> \n";
                    }
                    print $sock "<a href=\"/blog.htm?path=$path\">log</a> \n";
                    print $sock "<a href=\"/edit.htm?path=$path\">Edit</a><hr>\n";
                    if (defined ($form->{'bkvish'})) {
                        print $sock "<pre>\n";
                        print $sock "adb pull \"$pname$fname\" \"c:\\x\\$fname\"\n";
                        print $sock "c:\\x\\$fname\n";
                        print $sock "adb push \"c:\\x\\$fname\" \"$pname$fname\"\n";
						print $sock "perl c:\\x\\adb.pl c:\\x\\adb.in\n";
                        print $sock "</pre>\n";
                        print $sock "<hr>\n";
                    }
                } else {
                    ($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/;
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

                        # highlighting
                        if (defined ($form->{'hilite'}) && (length($form->{'hilite'}) > 1)) {
                            s/($form->{'hilite'})/<font style=\"color:black;background-color:lime\">$1<\/font>/g;
                        }


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
                
                    $buf = &l00wikihtml::wikihtml ($ctrl, $pname, $buf, $showchno);
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
#l00:
                }
            }
        } elsif (open (FILE, "<$path")) {
            if (defined ($form->{'bkvish'})) {
                &l00backup::backupfile ($ctrl, $path, 1, 5);
                if (open (OUT, ">$ctrl->{'plpath'}l00http_cmdedit.sh")) {
                    #print OUT "$ctrl->{'bbox'}vi $path\n";
                    print OUT "vim $path\n";
                    close (OUT);
                }
            }
            my $urlraw = 0;
            if (defined ($form->{'raw'}) && ($form->{'raw'} eq 'on')) {
                $urlraw = 1;
            }
            if ($read0raw1 == 0) {
                # auto raw for reading
                if (($path =~ /\.zip$/i) ||
                    ($path =~ /\.kmz$/i) ||
                    ($path =~ /\.kml$/i) ||
                    ($path =~ /\.apk$/i) ||
                    ($path =~ /\.jpeg$/i) ||
                    ($path =~ /\.jpg$/i) ||
                    ($path =~ /\.wma$/i) ||
                    ($path =~ /\.3gp$/i) ||
                    ($path =~ /\.mp3$/i) ||
                    ($path =~ /\.mp4$/i) ||
                    ($path =~ /\.gif$/i) ||
                    ($path =~ /\.svg$/i) ||
                    ($path =~ /\.png$/i) ||
                    ($path =~ /\.pdf$/i) ||
                    ($path =~ /\.html$/i) ||
                    ($path =~ /\.htm$/i)) {
                    $urlraw = 1;
                }
            }
            # auto raw for
            if (($read0raw1 == 1) || ($urlraw == 1)) {

                # 2.1) If in raw mode, send raw binary

                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat($path);

                $httphdr = "";;
                if (($path =~ /\.zip$/i) ||
                    ($path =~ /\.kmz$/i)) {
                    $httphdr = "Content-Type: application/x-zip\r\n";
#HTTP/1.1 200 OK
#Server: nginx/0.7.65
#Date: Sat, 08 May 2010 00:45:04 GMT
#Content-Type: application/x-zip
#Connection: keep-alive
#Cache-Control: must-revalidate
#Expires:
#$httphdr .= "Content-Disposition: inline; size=\"$size\"\r\n";
$httphdr .= "Content-Disposition: inline; filename=\"Socal Eats - will repeat.kmz\"; size=\"$size\"\r\n";
#X-Whom: s5-x
#Content-Length: 23215
#Etag: "947077edb066e7c363df5cc2a40311e5"
#Last-Modified: Mon, 11 Jan 2010 05:54:08 GMT
#P3P: CP: ALL DSP COR CURa ADMa DEVa CONo OUR IND ONL COM NAV INT CNT STA
 
                } elsif ($path =~ /\.kml$/i) {
                    $httphdr = "Content-Type: application/vnd.google-earth.kml+xml\r\n";
                } elsif ($path =~ /\.apk$/i) {
                    $httphdr = "Content-Type: application/vnd.android.package-archive\r\n";
                } elsif (($path =~ /\.jpeg$/i) ||
                         ($path =~ /\.jpg$/i)) {
                    $httphdr = "Content-Type: image/jpeg\r\n";
                } elsif ($path =~ /\.wma$/i) {
                    $httphdr = "Content-Type: audio/x-ms-wma\r\n";
                } elsif ($path =~ /\.3gp$/i) {
                    $httphdr = "Content-Type: audio/3gp\r\n";
                } elsif ($path =~ /\.pdf$/i) {
                    $httphdr = "Content-Type: application/pdf\r\n";
                } elsif ($path =~ /\.mp3$/i) {
                    $httphdr = "Content-Type: audio/mpeg\r\n";
                } elsif ($path =~ /\.mp4$/i) {
                    $httphdr = "Content-Type: video/mp4\r\n";
                } elsif ($path =~ /\.gif$/i) {
                    $httphdr = "Content-Type: image/gif\r\n";
                } elsif ($path =~ /\.svg$/i) {
                    $httphdr = "Content-Type: image/svg+xml\r\n";
                } elsif ($path =~ /\.png$/i) {
                    $httphdr = "Content-Type: image/png\r\n";
                } elsif (($path =~ /\.html$/i) ||
                         ($path =~ /\.htm$/i) ||
                         ($path =~ /\.txt$/i)) {
                    $httphdr = "Content-Type: text/html\r\n";
                } else {
                    $httphdr = "Content-Type: application/octet-octet-stream\r\n";
                }
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
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
                print "sent $ttlbytes\n", if ($ctrl->{'debug'} >= 2);
                close (FILE);
                $sock->close;
                return;
            } else {
                $editable = 1;

                $httphdr = "Content-Type: text/html\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";

                if (!defined ($form->{'bare'})) {
                    if (($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/) {
                        print $sock $ctrl->{'htmlhead'} . "<title>$fname ls</title>" .$ctrl->{'htmlhead2'};
                        # not ending in / or \, not a dir
                        # clip.pl with \ on Windows
                        $tmp = $path;
                        if ($ctrl->{'os'} eq 'win') {
                            $tmp =~ s/\//\\/g;
                        }
                        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: <a href=\"/ls.htm?path=$pname\">$pname</a>$fname<br>\n";
                    } else {
                        print $sock $ctrl->{'htmlhead'} . "<title>$path ls</title>" .$ctrl->{'htmlhead2'};
                        # clip.pl with \ on Windows
                        $tmp = $path;
                        if ($ctrl->{'os'} eq 'win') {
                            $tmp =~ s/\//\\/g;
                        }
                        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: $path<br>\n";
                    }
                    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> \n";
                    print $sock "<a href=\"#end\">end</a>\n";
                    print $sock "<a href=\"#__toc__\">toc</a>\n";
                    if (defined ($form->{'bkvish'})) {
                        print $sock "<a href=\"/ls.htm?path=$path\">view</a> \n";
                    } else {
                        print $sock "<a href=\"/ls.htm?bkvish=bk&path=$path\">bk&vi</a> \n";
                    }
                    print $sock "<a href=\"/blog.htm?path=$path\">log</a> \n";
                    print $sock "<a href=\"/edit.htm?path=$path\">Edit</a><hr>\n";
                    if (defined ($form->{'bkvish'})) {
                        print $sock "<pre>\n";
                        print $sock "adb pull \"$pname$fname\" \"c:\\x\\$fname\"\n";
                        print $sock "c:\\x\\$fname\n";
                        print $sock "adb push \"c:\\x\\$fname\" \"$pname$fname\"\n";
						print $sock "perl c:\\x\\adb.pl c:\\x\\adb.in\n";
                        print $sock "</pre>\n";
                        print $sock "<hr>\n";
                    }
                } else {
                    ($pname, $fname) = $path =~ /^(.+\/)([^\/]+)$/;
                }

                # 2.2) If not, try reading 30 lines and look for Wikitext

                if ($read0raw1 == 2) {
                    # formatted
                    print $sock "<pre>\n";
                    while (<FILE>) {
                        print $sock "$_";
                    }
                    print $sock "</pre>\n";
                    close (FILE);
                } else {
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

                    open (FILE, "<$path");
                    $bulvl = 0;
                    if ($hits >= 1) {
                        # rendering as wiki text
                        $buf = "";
                        undef $showtag;
                        $showltgt = 0;
                        $showlnno = 0;
                        undef %showdir;
                        $lnno = 0;
#                        $chno = 0;
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
                            if (defined ($form->{'editline'})) {
							    s/\r//;
							    s/\n//;
                                $_ = "$_ <a href=\"/edit.htm?path=$path&editline=on&blklineno=$lnno\">[edit line $lnno]</a>\n";
							}

                            # highlighting
                            if (defined ($form->{'hilite'}) && (length($form->{'hilite'}) > 1)) {
                                s/($form->{'hilite'})/<font style=\"color:black;background-color:lime\">$1<\/font>/g;
                            }


                            # path=./ substitution
                            s/path=\.\//path=$pname/g;
							# path=$ substitution
                            s/path=\$/path=$path/g;

                            # translate all %L00HTTP<plpath>% to $ctrl->{'plpath'}
                            s/%L00HTTP<(.+?)>%/$ctrl->{$1}/g;

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
#                                if (/^(=+)(.+=+)$/) {
#                                    # insert chapter number
#                                    $chno++;
#                                    $_ = "$1$chno) $2\n";
#                                }
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
#                                            if (!defined ($form->{'bare'})) {
#                                                $buf .= "&nbsp;&nbsp;&nbsp;&nbsp; (%SHOWTAG%: skipped $skipped lines)\n";
#                                            }
                                            last;
                                        }
                                    }
                                    next;
                                } elsif (/^%SHOWOFF/) {
                                    # hide all %SHOW...
                                    next;
                                }
                            }

                            if (/(.*)%INCLUDE<(.+)>%(.*)/) {
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

                                if (open (INC, "<$_")) {
                                    # %INCLUDE%: here
                                    while (<INC>) {
                                        if (/^##/) {
                                            # skip to next ^#
                                            while (<INC>) {
                                                if (/^#/) {
                                                    last;
                                                }
                                            }
                                        }
                                        if (/^#/) {
                                            # skip ^#
                                            next;
                                        }
                                        $buf .= $_;
                                    }
                                    close (INC);
                                }
                                $tmp = "%l00httpd:lnno:$lnno%$tmp";
                                $buf .= $tmp;
								next;
                            }
                            $_ = "%l00httpd:lnno:$lnno%$_";
                            $buf .= $_;
                        }
                        if (%showdir) {
                            if (!defined ($form->{'bare'})) {
                                $found = "---\n<b><i>SHOWTAG directory</i></b>\n"; # borrow variable
                                $found .= "* :ALWAYS:";
                                $found .= " <a href=\"/ls.htm?path=$path&SHOWTAG=:ALWAYS\">SHOW</a>";
                                $found .= " <a href=\"/ls.htm?path=$path&SHOWTAG=:ALWAYS&SHOWLINENO=\">with line#</a>";
                                $found .= " <a href=\"/ls.htm?path=$path&SHOWTAG=:ALWAYS&SHOWLINENO=&bare=on\">no header/footer</a>";
                                $found .= "\n";
                                foreach $_ (sort keys %showdir) {
                                    $found .= "* $_:";
                                    $found .= " <a href=\"/ls.htm?path=$path&SHOWTAG=$_\">SHOW</a>";
                                    $found .= " <a href=\"/ls.htm?path=$path&SHOWTAG=$_&SHOWLINENO=\">with line#</a>";
                                    $found .= " <a href=\"/ls.htm?path=$path&SHOWTAG=$_&SHOWLINENO=&bare=on\">no header/footer</a>";
                                    $found .= "\n";
                                }
                                $buf = "$found$buf";
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
                                        $_ = "<a href=\"/view.htm?path=$path&skip=$tmp2#line$1\">".sprintf("%05d", $1)."</a>: $_";
                                    }
                                    $tmp .= "$_\n";
                                }
                                $found = $tmp;
                            }
                            $found = $foundhdr . $found;
                            if ($prefmt ne '') {
                                $found .= "</pre>\n";
                            }
                            $found .= "<br><a name=\"__find__\"></a><font style=\"color:black;background-color:lime\">Find in this file results end</font><hr>\n";
                            # render found results
                            print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $found, $showchno);
                        }
                        
                        if ((defined ($form->{'find'})) &&
                            ($showpage ne 'checked')) {
                            # find without displaying page
                        } else {
#                            if (defined ($form->{'lineno'})) {
#                                # display with line numbers
#                                $buf = &l00wikihtml::wikihtml ($ctrl, $pname, $buf, $showchno);
#                                $ln = 1;
#                                $intoc = 0; # counting line here is not precise, in fact, poor
#                                foreach $_ (split ("\n", $buf)) {
#                                    if (/"__toc__"/) {
#                                        # we encounter TOC, no line number
#                                        $intoc = 1;
#                                    }
#                                    if (/"__tocend__"/) {
#                                        # we encounter TOC end, resume line number
#                                        $intoc = 0;
#                                    }
#                                    if ($intoc || /^<\/ul>$/) {
#								        # special case at end of bullet list
#                                        print $sock "$_\n";
#                                    } else {
##if($ln<9999){
##print "$ln :: " . substr($_,0,50)."\n";
##}
##                                        if (defined ($form->{'hiliteln'}) && ($form->{'hiliteln'} == $ln)) {
##									        # make all non tags text lime
##                                            s/>([^<]+)</><font style="color:black;background-color:lime">$1<\/font></g;
##                                            print $sock "<a name=\"line$ln\"></a>$_\n";
##									    } else {
##                                            print $sock "<a name=\"line$ln\"></a>$_\n";
##									    }
#                                        print $sock "$_\n";
#                                        $ln++;
#                                    }
#                                }
#                            } else {
#                                # normal display without line numbers
                            $buf = &l00wikihtml::wikihtml ($ctrl, $pname, $buf, $showchno);
                            if (defined ($form->{'hiliteln'})) {
                                foreach $_ (split ("\n", $buf)) {
                                    if (/<a name=\"line$form->{'hiliteln'}\"><\/a>/) {
#                                       print $sock "<font style=\"color:black;background-color:lime\">$_</font>\n";
                                        s/>(.+)</><font style="color:black;background-color:lime">$1<\/font></g;
                                        print $sock "$_\n";
                                    } else {
                                        print $sock "$_\n";
                                    }
                                }
                            } else {
                                print $sock $buf;
                            }
#                            }
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
                            print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $found, $showchno);
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
            }
            close (FILE);
        } else {
            print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
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

        if ((defined ($form->{'showbak'})) && ($form->{'showbak'} eq 'on')) {
            $showbak = 1;
        } else {
            $showbak = 0;
        }
        
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$path ls</title>" .$ctrl->{'htmlhead2'};
        # clip.pl with \ on Windows
        $tmp = $path;
        if ($ctrl->{'os'} eq 'win') {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: $path\n";
        print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> \n";
        print $sock "<a href=\"#end\">Jump to end</a> \n";
        print $sock "<a href=\"/dirnotes.htm?path=$path"."NtDirNotes.txt\">NtDirNotes</a><hr>\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

        print $sock "<tr>\n";
        print $sock "<td>names</td>\n";
        print $sock "<td>bytes</td>\n";
        print $sock "<td>date/time</td>\n";
        print $sock "</tr>\n";
        

        # 3) If the path is a directory, make a table with links

        $nofiles = 0;
        $nodirs = 0;
        $bakout = '';
        $dirout = '';
        $fileout = '';
        # list internal pseudo files too
#$ctrl->{'l00file'}->{'l00://test'} = 'test content';
        if (defined($ctrl->{'l00file'})) {
            $tmp = $ctrl->{'l00file'};
            foreach $_ (sort keys %$tmp) {
                if (($_ eq 'l00://ram') || (length($ctrl->{'l00file'}->{$_}) > 0)) {
                    $dirout .= "<tr>\n";
                    $dirout .= "<td><small><a href=\"/ls.htm?path=$_\">$_</a></small></td>\n";
                    $dirout .= "<td><small>" . length($ctrl->{'l00file'}->{$_}) . "</small></td>\n";
                    $dirout .= "<td><small><a href=\"/$ctrl->{'lssize'}.htm?path=$_\">launcher</a></small></td>\n";
                    $dirout .= "</tr>\n";
                }
            }
		}
        if (defined ($form->{'sort'}) && ($form->{'sort'} eq 'on')) {
            # sort by reverse time
            $llspath = $path;
            @dirs = sort llsfn readdir (DIR);
        } else {
            @dirs = sort llstricmp readdir (DIR);
        }
        foreach $file (@dirs) {
            if (-d $path.$file) {
                # it's a directory, print a link to a directory
                if ($file =~ /^\.$/) {
                    next;
                }
                $fullpath = $path . $file;
                if ($file =~ /^\.\.$/) {
                    $fullpath =~ s!/[^/]+/\.\.!!;
                    if ($fullpath eq "/..") {
                        $fullpath = "";
                    }
                }
                
                $dirout .= "<tr>\n";
                $dirout .= "<td><small><a href=\"/ls.htm?path=$fullpath/\">$file/</a></small></td>\n";
                if ($file eq '..') {
                    $dirout .= "<td><small>&lt;dir&gt;</small></td>\n";
                } else {
                    $dirout .= "<td><small><a href=\"/tree.htm?path=$fullpath/\">&lt;dir&gt;</a></small></td>\n";
                }
                $dirout .= "<td>&nbsp;</td>\n";
                $dirout .= "</tr>\n";
                $nodirs++;
            } else {
                # it's not a directory, print a link to a file
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat($path.$file);
                ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                 = localtime($mtime);
                
                $buf = "<tr>\n";
                if ($file =~ /\.txt$/i) {
                    # tx=$file.htm so it ends in .htm for Palm TX
                    #$buf .= "<td><small><a href=\"/ls.htm/$file?path=$path$file&tx=$file.htm\">$file</a>"
                    $buf .= "<td><small><a href=\"/ls.htm/$file?path=$path$file\">$file</a>"
                        ."</small></td>\n";
                } else {
                    $buf .= "<td><small><a href=\"/ls.htm/$file?path=$path$file\">$file</a>"
                        ."</small></td>\n";
                }
                $buf .= "<td align=right><small>"
                    ."<a href=\"/$ctrl->{'lssize'}.htm?path=$path$file\">$size</a>"
                    ."</small></td>\n";
                $buf .= "<td><small>". 
                    sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec) 
                    ."</small></td>\n";
                $buf .= "</tr>\n";
                if ($file =~ /\.bak$/) {
                    $bakout .= $buf;
                } else {
                    $fileout .= $buf;
                }
                $nofiles++;
            }
        }
        print $sock $dirout;
        print $sock $fileout;
        if ($showbak) {
            print $sock $bakout;
        }
        print $sock "</table>\n";
        closedir (DIR);
        print $sock "<p>There are $nodirs director(ies) and $nofiles file(s)<br>\n";
    }

    # 4) If not in raw mode, also display a control table

    if (($htmlend) && (!defined ($form->{'bare'}))) {
        print $sock "<hr><a name=\"end\"></a>\n";
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
        print $sock "  <td><input type=\"text\" size=\"10\" name=\"path\" value=\"$path\"></td>\n";
        print $sock "</tr>\n";

        if ($read0raw1 == 0) {
            $readst = "checked";
            $raw_st = "unchecked";
            $pre_st = "unchecked";
        } elsif ($read0raw1 == 1) {
            $readst = "unchecked";
            $raw_st = "checked";
            $pre_st = "unchecked";
        } else {
            $readst = "unchecked";
            $raw_st = "unchecked";
            $pre_st = "checked";
        }
        print $sock "    <tr>\n";
        print $sock "        <td>".
          "<input type=\"radio\" name=\"mode\" value=\"read\" $readst>reading<br>".
          "<input type=\"radio\" name=\"mode\" value=\"raw\"  $raw_st>raw<br>".
          "<input type=\"radio\" name=\"mode\" value=\"pre\"  $pre_st>pre<br>".
          "</td>\n";
        print $sock "        <td>add new line for reading<br>raw dump<br>".
                    "<input type=\"checkbox\" name=\"bare\">No header/footer</td>\n";
        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
#       print $sock "        <td>&nbsp;</td>\n";
        print $sock "        <td><input type=\"checkbox\" name=\"editline\">Edit line link</td>\n";

        if ($showchno == 2) {
            $buf = "checked";
        } else {
            $buf = "";
        }
        print $sock "        <td><input type=\"checkbox\" $buf name=\"sort\">sort by time</td>\n";

        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
        print $sock "        <td><input type=\"checkbox\" $buf name=\"chno\">Show chapter #</td>\n";
        print $sock "        <td>Hilite: <input type=\"text\" size=\"10\" name=\"hilite\" value=\"\"></td>\n";
        print $sock "    </tr>\n";

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
            print $sock "  <td><input type=\"text\" size=\"10\" name=\"path\" value=\"$path\"></td>\n";
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
            print $sock "<td><input type=\"text\" size=\"7\" name=\"path\" value=\"$path\"></td>\n";
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

        if (!defined ($file)) {
            $dir = $path;
            $dir =~ s/\/[^\/]+$/\//;
            print $sock "<p><a href=\"/find.htm?path=$dir&fmatch=%5C.txt%24\">find in files</a> in $dir\n";
            print $sock "<p>Send $path to <a href=\"/launcher.htm?path=$path\">launcher</a>\n";
            print $sock "<p><a href=\"/view.htm?path=$path\">View</a> $path\n";
            print $sock "<p><table border=\"1\" cellpadding=\"5\" cellspacing=\"3\"><tr>\n";
            print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
            print $sock "<td><input type=\"submit\" name=\"altsendto\" value=\"'Size' send to\"></td>\n";
            print $sock "<td><input type=\"text\" size=\"7\" name=\"sendto\" value=\"$ctrl->{'lssize'}\"></td>\n";
            if (!defined ($form->{'path'})) {
                print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
            } else {
                print $sock "<input type=\"hidden\" name=\"path\"\">\n";
            }
            print $sock "</form>\n";
            print $sock "</tr></table>\n";
        }

        print $sock $ctrl->{'htmlfoot'};
    }

}


\%config;
