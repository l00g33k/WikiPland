use strict;
use warnings;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($key, $val);
my %config = (proc => "l00http_gitkk_proc",
              desc => "l00http_gitkk_desc");

my ($gitkkpath, $gitpath, $gitloglen);
$gitkkpath = '';
$gitpath = '';
$gitloglen = 1000;



sub gitkk_finddotgit {
    my ($ctrl, $orgpath) = @_;
    my ($gitkkpath, $gitpath, $sane);

    $sane = 20;
    $gitkkpath = $orgpath;
    $gitpath = '';

    l00httpd::dbp($config{'desc'}, "orgpath = $orgpath\n"), if ($ctrl->{'debug'} >= 5);
    if (-f $gitkkpath) {
        # drop filename
        $gitkkpath =~ s/[^\\\/]+$//;
        l00httpd::dbp($config{'desc'}, "dropped filename: gitkkpath = $gitkkpath\n"), if ($ctrl->{'debug'} >= 5);
    }

    while ((length($gitkkpath) > 2) && ($sane-- > 0)) {
        if (-f "${gitkkpath}.git/config") {
            l00httpd::dbp($config{'desc'}, "found .git/config from $gitkkpath\n"), if ($ctrl->{'debug'} >= 5);
            $gitpath = $orgpath;
            $gitpath =~ s/$gitkkpath//;
            l00httpd::dbp($config{'desc'}, "git path is $gitpath\n"), if ($ctrl->{'debug'} >= 5);
            last;
        }
        # drop filename
        $gitkkpath =~ s/[^\\\/]+[\\\/]$//;
        l00httpd::dbp($config{'desc'}, "$sane: dropped filename: gitkkpath = $gitkkpath\n"), if ($ctrl->{'debug'} >= 5);
    }

    ($gitkkpath, $gitpath);
}


sub l00http_gitkk_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "gitkk: A browser interface to a gitkk alias like utility";
}



sub l00http_gitkk_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($fullpath);
    my ($httphdr, $cnt, $files, $file, $bytes, $buf, $cmd);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtime, $ctime, $blksize, $blocks);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
    my ($tmp, $tmp2, $tbldir, $tblfile, $dircnt, $filecnt);

    # create HTTP and HTML headers
    $httphdr = "$ctrl->{'httphead'}$ctrl->{'htmlhead'}$ctrl->{'htmlttl'}$ctrl->{'htmlhead2'}";
    $httphdr .= "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'}<a href=\"#end\">end</a> -\n";
    if (defined ($form->{'path'})) {
        $httphdr .= "Path: <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    }
    print $sock "$httphdr<br>\n";
    print $sock "Jump to <a href=\"#form\">form</a> - \n";
    print $sock "Jump to <a href=\"#listing\">listing</a> -- \n";

    # process 'path' into
    # $gitkkpath: path to dir containint .git
    # $gitpath: path from $gitkkpath to target file or dir
    if (($tmp, $tmp2) = &gitkk_finddotgit($ctrl, $form->{'path'})) {
         ($gitkkpath, $gitpath) = ($tmp, $tmp2);
    }
    l00httpd::dbp($config{'desc'}, "'path' = $form->{'path'} - gitkkpath = $gitkkpath - gitpath = $gitpath"), if ($ctrl->{'debug'} >= 3);

    if (!defined($gitkkpath)) {
        $gitkkpath = $ctrl->{'workdir'};;
    }
#   # parse ppath
#   if (defined($form->{'path'})) {
#       if (-f $form->{'path'}) {
#           # is a file, get dir
#           #
#           $form->{'path'} =~ s/[^\\\/]+$//;
#       }
#       if (-d $form->{'path'}) {
#           $gitkkpath = $form->{'path'};
#       }
#   }


    if (defined ($form->{'dogitkk'}) && ($form->{'dogitkk'} eq 'on')) {
        # print gitkk
        $cmd = "cd $gitkkpath && git log -n $gitloglen --all --graph --pretty=format:'\%Cred\%h\%Creset\%Cgreen(\%ci)\%Creset\%C(bold blue)<\%an>\%Creset\%C(magenta)\%d\%Creset \%s' --abbrev-commit";
        $buf = `$cmd`;
        $buf =~ s/</&lt;/mg;
        $buf =~ s/>/&gt;/mg;
        print $sock "Command line<br>$cmd\n\n";
        print $sock "<pre>\n";
        print $sock "$buf\n";
        print $sock "</pre>\n";
    } else {
        print $sock "Click the 'gitkk' button to show gitkk<p>\n";
    }

    print $sock "<a name=\"form\"></a>";
    print $sock "Jump to <a href=\"#top\">top</a><p>\n";

    print $sock "<form action=\"/gitkk.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"submit\" name=\"submit\" value=\"g&#818;itkk\" accesskey=\"g\"></td>\n";
    print $sock "            <td>Path: <input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"checkbox\" name=\"dogitkk\" checked accesskey=\"k\">show gitk&#818;k</td>\n";
    print $sock "            <td></td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "</form><p>\n";

    print $sock "<a name=\"listing\"></a>";
    print $sock "Jump to <a href=\"#top\">top</a><p>\n";
    # dir navigation and print dir listing
    if (!opendir (DIR, $gitkkpath)) {
        print $sock "Unable to read directory $gitkkpath<p>\n";
    } else {
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

        print $sock "<tr>\n";
        print $sock "<td>names</td>\n";
        print $sock "<td>bytes</td>\n";
        print $sock "<td>date/time</td>\n";
        print $sock "</tr>\n";
        
        $tbldir = '';
        $tblfile = '';
        $dircnt = 0;
        $filecnt = 0;

        foreach $file (sort readdir (DIR)) {
            if ($file eq '.') {
                next;
            }
            $fullpath = $gitkkpath . $file;
            # get timestamp
            ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
             $size, $atime, $mtime, $ctime, $blksize, $blocks)
             = stat($gitkkpath.$file);
            ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
             = localtime($mtime);
            $tmp = '';
            $tmp .= "<tr>\n";
            if (-d "$gitkkpath$file") {
                if ($file eq '..') {
                    $tmp2 = $gitkkpath;
                    $tmp2 =~ s/[^\\\/]+[\\\/]$//;
                    $tmp .= "<td><small><a href=\"/ls.htm?path=$tmp2\">../</a></small></td>\n";
                    $tmp .= "<td><small><a href=\"/gitkk.htm?path=$tmp2\">../</a></small></td>\n";
                } else {
                    $tmp .= "<td><small><a href=\"/ls.htm?path=$fullpath/\">$file/</a></small></td>\n";
                    $tmp .= "<td><small><a href=\"/gitkk.htm?path=$fullpath/\">&lt;dir&gt;</a></small></td>\n";
                }
            } else {
                $tmp .= "<td><small><a href=\"/view.htm?path=$fullpath\">$file</a></small></td>\n";
                $tmp .= "<td><small><a href=\"/gitkk.htm?path=$fullpath\">$size</a></small></td>\n";
            }
            $tmp .= "<td><small>". 
                sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec) 
                ."</small></td>\n";
            $tmp .= "</tr>\n";
            if (-d "$gitkkpath$file") {
                $tbldir .= $tmp;
                $dircnt++;
            } else {
                $tblfile .= $tmp;
                $filecnt++;
            }
        }
        closedir (DIR);
        print $sock "$tbldir\n";
        print $sock "$tblfile\n";
        print $sock "</table>\n";
    }

    print $sock "<p>Listed $dircnt directories and $filecnt files<p>\n";

    print $sock "<p>Jump to <a href=\"#top\">top</a> - \n";
    print $sock "Jump to <a href=\"#form\">form</a> - \n";
    print $sock "Jump to <a href=\"#listing\">listing</a><p>\n";

#   if (defined($form->{'path'}) &&
#       &l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
#       $files = &l00httpd::l00freadAll($ctrl);
#       &l00httpd::l00fwriteOpen($ctrl, 'l00://gitkk.txt');
#       $cnt = 0;
#       $bytes = 0;
#       print $sock "View: <a href=\"/view.htm?path=l00://gitkk.txt\">l00://gitkk.txt</a><p>Processing $form->{'path'}:<br>\n";
#       # extract filenames
#       print $sock "<pre>\n";
#       foreach $_ (split("\n", $files)) {
#           if (/^ *\d+ \d+\/\d+\/\d+ \d+:\d+:\d+ (.+)/) {
#               $_ = $1;
#           }
#           if (&l00httpd::l00freadOpen($ctrl, $_)) {
#               $cnt++;
#               print $sock "$cnt: $_\n";
#               $buf = &l00httpd::l00freadAll($ctrl);
#               $bytes += length($buf);
#               &l00httpd::l00fwriteBuf($ctrl, $buf);
#               &l00httpd::l00fwriteBuf($ctrl, "\n");
#           }
#       }
#       &l00httpd::l00fwriteClose($ctrl);
#       print $sock "<a name=\"end\"></a></pre>Processed $cnt files, $bytes bytes<p><a href=\"#top\">top</a><p>\n";
#   }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
