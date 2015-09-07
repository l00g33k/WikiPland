use strict;
use warnings;
use l00httpd;
use l00backup;
use l00crc32;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_tree_proc",
              desc => "l00http_tree_desc");

my (@list, $lvl, $md5support, $depthmax);

$md5support = -1;
$depthmax = 20;

sub l00Http_tree_proxy {
    my ($sock, $target) = @_;
    my ($server_socket, $result, $ctrl_lstn_sock, $retry, $retrymax);

    $retrymax = 1000;

    $result = '';

    $retry = 0;
    while ($retry++ < $retrymax) {
        $server_socket = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => 20336,
            Timeout  => 1,
            Proto    => 'tcp');
        if (defined($server_socket)) {
            last;
        }
    }
    #print "cmd retry $retry\n";
    if (defined($server_socket)) {
        #print "connected to 20336\n";
        print $server_socket $target;
        #print "target $target\n";
        $server_socket->close;

        $retry = 0;
        while ($retry++ < $retrymax) {
            $server_socket = IO::Socket::INET->new(
                PeerAddr => '127.0.0.1',
                PeerPort => 20335,
                Timeout  => 1,
                Proto    => 'tcp');
            if (defined($server_socket)) {
                last;
            }
        }
        #print "rst retry $retry\n";
        if (defined($server_socket)) {
            #print "connected to 20335\n";
            sysread ($server_socket, $result, 2048);
            #print "md5sum $result\n";
            $server_socket->close;
            $result =~ s/ .*//;
            $result =~ s/\r//g;
            $result =~ s/\n//g;
        } else {
            $md5support = 0;
        }
    } else {
        $md5support = 0;
    }

    $result;
}


sub l00http_tree_list {
    my ($sock, $path) = @_;
	my ($file);


    if ($lvl <= $depthmax) {
        $lvl++;
        if (opendir (DIR, $path)) {
            foreach $file (readdir (DIR)) {
      	        if ($file =~ /^\.+$/) {
			        next;
                }
      	        if (-d $path.$file) {
                    &l00http_tree_list ($sock, "$path$file/");
                    push (@list, $path.$file.":");
                } else {
                    push (@list, $path.$file);
                }
            }
        }
        $lvl--;
    }
}



sub l00http_tree_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "tree: list all files in sub-directories as a tree";
}

sub l00http_tree_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buffer, $path2, $path, $file, $cnt, $cntbak, $crc32, $export, $buf);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $time0, $nodir, $nofile, $showbak,
        $size, $atime, $mtimea, $ctime, $blksize, $blocks, $nobytes, $isdir);
    my (%countext, $ext, %sizeMd5sum, $md5sum, $fname, $dir);


    $time0 = time;

    if (defined($form->{'md5svr'}) && ($form->{'md5svr'} eq 'on')) {
        # check md5sum service again
        $md5support = -1;
    }
    if (defined($form->{'depth'}) && ($form->{'depth'} =~ /(\d+)/)) {
        # max directory depth
        $depthmax = $1;
    } else {
        $depthmax = 20;
    }

    if ($md5support < 0) {
        $md5support = 0;
        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
            $_ = `certutil`;
            l00httpd::dbp($config{'desc'}, "Windows testing certutil: $_\n");
            if (/command completed successfully/) {
                $md5support = 1;
            }
        } elsif ($ctrl->{'os'} eq 'and') {
            $_ = &l00Http_tree_proxy($sock, "$ctrl->{'plpath'}l00httpd.pl");
            if ($_ ne '') {
                $md5support = 1;
            }
        } elsif ($ctrl->{'os'} eq 'lin') {

        }
    }

    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    }

    if (!defined ($form->{'filter'})) {
        $form->{'filter'} = '';
    }

    if (defined($form->{'showbak'})) {
        $showbak = 'checked';
    } else  {
        $showbak = '';
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock " Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
    print $sock " <a href=\"#__end__\">jump to end</a><br>\n";
    print $sock "Links: line#=clip path, path=ls.pl, filename=view.pl<p>\n";


    if (-f $form->{'path'}) {
        # path is a file
        if (open(IN, "<$form->{'path'}")) {
            # get directory
            $dir = $form->{'path'};
            # keep path only
            $dir =~ s/\/[^\/]+$/\//;

            #print $sock "<pre>\n";
            undef %sizeMd5sum;
            $cnt = 0;
            $cntbak = 0;
            while (<IN>) {
                s/\n//;
                s/\r//;
                # cygwin md5sum puts *./. Delete *
                s/ \*\.\// .\//;
                #print $sock "$_\n";
                if (/^(\d+) \.\/(.+)/) {
                    $cnt++;
                    $size = $1;
                    $fname = $2;
                    $sizeMd5sum{$fname} = sprintf("|| %8d ||", $size);
                } elsif (/^([0-9a-fA-F]+) \.\/(.+)/) {
                    $cntbak++;
                    $md5sum = $1;
                    $fname = $2;
                    $sizeMd5sum{$fname} .= " $md5sum ||";
                }
            }
            close (IN);
            print $sock "Read $cnt file size and $cntbak file md5sum<p>\n";

	        $export = '';
            foreach $fname (sort keys %sizeMd5sum) {
                $export .= "$sizeMd5sum{$fname} $dir$fname ||\n";
                #print $sock "$sizeMd5sum{$fname} $dir$fname ||\n";
            }
            #print $sock "</pre>\n";

            &l00httpd::l00fwriteOpen($ctrl, 'l00://tree.htm');
            &l00httpd::l00fwriteBuf($ctrl, "* wiki\n\n$export\n\n");
            &l00httpd::l00fwriteClose($ctrl);
            print $sock "<p><a href=\"/view.htm?path=l00://tree.htm\">View raw listing</a><p>\n";
        }
    } else {
        # path is a directory
        undef @list;
	    $lvl = 0;
        &l00http_tree_list ($sock, $form->{'path'});
        print $sock "<pre>";
	    $cnt = 0;
	    $nodir = 0;
	    $nofile = 0;
	    $cntbak = 0;
	    $export = '';
	    $time0 = time;
        $nobytes = 0;
        undef %countext;
        foreach $file (sort @list) {
            if (defined($form->{'showbak'}) ||
               (!($file =~ /\.bak$/))) {
		        if ($file =~ /:$/) {
		            chop ($file);
		            $isdir = 1;
		        } else {
		            $isdir = 0;
		        }
		        $cnt++;
		        $_ = $file;
			    s/ /%20/g;
                print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\">".
                    sprintf("%3d",$cnt)."</a> ";
		        $_ = $file;
			    ($path, $file) = /^(.+\/)([^\/]+)$/;
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                    = stat($path.$file);
                $nobytes += $size;
                if (defined($form->{'crc32'}) && ($form->{'crc32'} eq 'on')) {
                    if ($isdir) {
                        $crc32 = 0;
                        $file = "$file/ &lt;dir&gt;";
                        $nodir++;
                    } else {
                        $nofile++;
                        local $/ = undef;
                        if(open(IN, "<$path$file")) {
                            binmode (IN);
                            $buf = <IN>;
                            close(IN);
                        } else {
                            $buf = '';
                        }
                        $crc32 = &l00crc32::crc32($buf);
                    }
                    print $sock sprintf ("<a href=\"/view.htm?path=$path$file\">%8d</a> %08x ", $size, $crc32);
                    $export .= sprintf("|| %8d || %08x || %s ||\n",$size, $crc32, $path.$file);
                } elsif (($md5support > 0) && defined($form->{'md5'}) && ($form->{'md5'} eq 'on')) {
                    $crc32 = "00000000000000000000000000000000";
                    if ($isdir) {
                        $file = "$file/ &lt;dir&gt;";
                        $nodir++;
                    } else {
                        $nofile++;
                        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                            # make command line to call certutil.exe
                            $_ = "certutil -hashfile \"$path$file\" MD5";
                            # shell
                            $_ = `$_`;
                            # extract the second line
                            @_ = split ("\n", $_);
                            $_ = $_[1];
                            # delete \n, \r, ' '
                            s/\n//g;
                            s/\r//g;
                            s/ //g;
                            # results
                            $crc32 = "$_";
                        } elsif ($ctrl->{'os'} eq 'and') {
                            $crc32 = &l00Http_tree_proxy($sock, "$path$file");
                        } elsif ($ctrl->{'os'} eq 'lin') {
                        }
                    }
                    print $sock sprintf ("<a href=\"/view.htm?path=$path$file\">%8d</a> %s ", $size, $crc32);
                    $export .= sprintf("|| %8d || %s || %s ||\n",$size, $crc32, $path.$file);
                } else {
                    if ($isdir) {
                        $file = "$file/ &lt;dir&gt;";
                        $nodir++;
                    } else {
                        $nofile++;
                        # count extension
                        if ($file =~ /\.([^.]+)$/) {
                            $ext = $1;
                        } else {
                            $ext = '(no ext)';
                        }
                        if (defined ($countext{$ext})) {
                            $countext{$ext}++;
                        } else {
                            $countext{$ext} = 1;
                        }
                    }
                    print $sock sprintf ("<a href=\"/view.htm?path=$path$file\">%8d</a> ", $size);
                    $export .= sprintf("|| %8d || %s ||\n",$size, $path.$file);
                }
                # show path from base down only
			    $path2 = $path;
			    $path2 =~ s/^$form->{'path'}//;
                print $sock "<a href=\"/ls.htm?path=$path\">$path2</a>";
                print $sock "<a href=\"/ls.htm?path=$path$file\">$file</a>\n";
            } else {
                $cntbak++;
            }
        }
        print $sock "</pre>";

        print $sock "<p>There are $nobytes bytes in $nofile files $nodir directories ";
        print $sock sprintf("in %d seconds for %d bytes/sec.\n", time - $time0, $nobytes / (time - $time0 + 1));
        print $sock "<p>Showing maximum $depthmax directories deep\n";
        print $sock "<p>$cntbak '*.bak' files not shown\n";

        print $sock "<p><table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        print $sock "<tr>\n";
        print $sock "<td>#</td>\n";
        print $sock "<td>Extension</td>\n";
        print $sock "<td>Count</td>\n";
        print $sock "</tr>\n";
        $cnt = 1;
        foreach $ext (sort keys %countext) {
            print $sock "<tr>\n";
            print $sock "<td>$cnt</td>\n";
            print $sock "<td>$ext</td>\n";
            print $sock "<td>$countext{$ext}</td>\n";
            print $sock "</tr>\n";
            $cnt++;
        }
        print $sock "</table>\n";


        &l00httpd::l00fwriteOpen($ctrl, 'l00://tree.htm');
        &l00httpd::l00fwriteBuf($ctrl, "* wiki\n\n$export\n\n");
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "<p><a href=\"/view.htm?path=l00://tree.htm\">View raw listing</a><p>\n";
    }


    print $sock "<form action=\"/tree.htm\" method=\"post\"><hr>\n";
    print $sock "<input type=\"submit\" name=\"submit\" value=\"Path\">\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<br>Depth: <input type=\"text\" size=\"6\" name=\"depth\" value=\"20\">\n";
$form->{'filter'} = 'not implemented';
    print $sock "<br>Filter: <input type=\"text\" size=\"16\" name=\"filter\" value=\"$form->{'filter'}\">\n";
    print $sock "<br><input type=\"checkbox\" name=\"crc32\">compute CRC32 (pure Perl CRC32 is slow)\n";
    if ($ctrl->{'os'} eq 'and') {
        if ($md5support > 0) {
            print $sock "<br><input type=\"checkbox\" name=\"md5\">compute md5 (use TerminalIDE service)\n";
        } else {
            print $sock "<br><input type=\"checkbox\" name=\"md5svr\">check TerminalIDE md5sum service. ".
                "(<a href=\"/clip.htm?update=Copy+to+CB&clip=source+$ctrl->{'plpath'}md5sumservice.sh\">start it</a>)\n";
        }
    } else {
        if ($md5support > 0) {
            print $sock "<br><input type=\"checkbox\" name=\"md5\">compute md5 (shell to native)\n";
        }
    }
    print $sock "<br><input type=\"checkbox\" name=\"showbak\" $showbak>Show *.bak too\n";
    print $sock "</form><br>\n";

    print $sock "# md5sum computation can be accelerated by using bash commands as follow:<br>\n";
    print $sock "du -h<br>\n";
    print $sock "rm name_stat_md5sum.txt<br>\n";
    print $sock "time find -name \"*\" -type f -print0 | xargs -0 stat -c \"%s %n\" >> name_stat_md5sum.txt<br>\n";
    print $sock "time find -name \"*\" -type f -print0 | xargs -0 md5sum >> name_stat_md5sum.txt<br>\n";
    print $sock "# and send name_stat_md5sum.txt to <a href=\"/tree.htm\">tree.htm</a> for processing<br>\n";
    print $sock "#speed is approximately 12-26 secs/GB<p>\n";


    print $sock "<a name=\"__end__\"></a>\n";
    print $sock "<a href=\"#__top__\">jump to top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
