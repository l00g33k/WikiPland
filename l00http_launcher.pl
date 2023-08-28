use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_launcher_proc",
              desc => "l00http_launcher_desc");

my @targets;


sub l00http_launcher_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "launcher: to start other modules";
}

sub l00http_launcher_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $file, $name, $col, $extra, $path, $fname);
    my ($lpname, $lfname, $pathuri, $plpath);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        $path =~ s/\r//g;
        $path =~ s/\n//g;
        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
            $path =~ s/\//\\/g;
        }
        print $sock " <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$path\">Path</a>:";

        if (($lpname, $lfname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/) {
            if ($lpname eq 'l00://') {
                print $sock " <a href=\"/#ram\">$lpname</a>";
            } else {
                print $sock " <a href=\"/ls.htm?path=$lpname\">$lpname</a>";
            }
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$lfname</a> - \n";
            if ($form->{'path'} =~ /^\//) {
                print $sock "<a href=\"$form->{'path'}\">html</a> -- \n";
                print $sock "<a href=\"file://$form->{'path'}\">file:///</a><p>\n";
            } else {
                print $sock "<a href=\"/$form->{'path'}\">html</a> -- \n";
                print $sock "<a href=\"file:///$form->{'path'}\">file:///</a><p>\n";
            }
        }
    } else {
        $path = '';
    }
    #print $sock "<br>\n";

    ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
     $size, $atime, $mtime, $ctime, $blksize, $blocks)
     = stat($form->{'path'});
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
     = localtime($mtime);
    printf $sock ("<pre>%9d %4d/%02d/%02d %02d:%02d:%02d</pre>\n", 
        $size, 1900+$year, 1+$mon, $mday, $hour, $min, $sec) ;


    if ($#targets == -1) {
        foreach $plpath (("$ctrl->{'plpath'}", "$ctrl->{'extraplpath'}")) {
            if (defined($plpath) && 
                opendir (DIR, $plpath)) {
                foreach $file (sort readdir (DIR)) {
                    if ($file =~ /^l00http_(\w+)\.pl$/) {
                        $name = $1;
                        if (open (IN, "<$plpath$file")) {
                            while (<IN>) {
                                # does this module reference 'path'?
                                if (/\$form->\{'path'\}/) {
                                    push (@targets, $name);
                                    last;
                                }
                            }
                            close (IN);
                        }
                    }
                }
            }
        }
    }

    print $sock "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n";
    print $sock "<tr><td>\n";
    print $sock "<form action=\"/view.htm\" method=\"get\">".
                "<input type=\"submit\" name=\"submit\" value=\"V&#818;iew\" accesskey=\"v\">".
                "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">".
                "</form> ";
    print $sock "</td><td>\n";
    print $sock "&nbsp;&nbsp;\n";
    print $sock "</td><td>\n";
    print $sock "<form action=\"/lineproc.htm\" method=\"get\">".
                "<input type=\"submit\" name=\"submit\" value=\"l&#818;ineproc\" accesskey=\"l\">".
                "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">".
                "</form>";
    print $sock "</td><td>\n";
    print $sock "&nbsp;&nbsp;\n";
    print $sock "</td><td>\n";
    print $sock "<form action=\"/do.htm\" method=\"get\">".
                "<input type=\"submit\" name=\"submit\" value=\"Do&#818;\" accesskey=\"o\">".
                "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">".
                "</form>";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";



    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

    $col = 0;
    $fname = $path;
    $fname =~ s/.+([\/\\].+)/$1/;
    $pathuri = $path;
    $pathuri =~ s/([^^A-Za-z0-9\-_.!~*'()])/ sprintf "%%%02x", ord $1 /eg;
    foreach $name (@targets) {
        if ($col == 0) {
            print $sock "<tr><td>\n";
        }
        $extra = '';
        if ($name eq 'kml') {
           $extra = '.kml';
        } else {
           # add .htm as some browser won't open .txt as HTML
           $extra = '.htm';
        }

        print $sock "<a href=\"/$name.htm$fname$extra?path=$pathuri\">$name</a>\n";
        $col++;
        # change number of column here and below
        if ($col >= 3) {
            $col = 0;
            print $sock "</td></tr>\n";
        } else {
            print $sock "</td><td>\n";
        }
    }

    while ($col != 0) {
        print $sock "&nbsp;\n";
        $col++;
        # change number of column here and above
        if ($col >= 3) {
            $col = 0;
            print $sock "</td></tr>\n";
        } else {
            print $sock "</td><td>\n";
        }
    }

    print $sock "</table>\n";

    print $sock "<p>Update l00http_launcher.pl to add new target<p>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
