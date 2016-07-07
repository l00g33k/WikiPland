use strict;
use warnings;
use l00backup;
use l00httpd;


# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_syncview_proc",
              desc => "l00http_syncview_desc");


my ($width, $oldfile, $newfile);
my ($hide, $maxline, $debug, @OLD, @NEW);
$width = 20;
$oldfile = '';
$newfile = '';
$hide = '';
$maxline = 4000;
$debug = 0;


sub l00http_syncview_make_outline {
    my ($oii, $nii, $width, $oldfile, $newfile) = @_;
    my ($oout, $nout, $ospc, $tmp, $clip, $view, $lineno0, $lineno);


    if (($oii >= 0) && ($oii <= $#OLD)) {
        $tmp = sprintf ("%-${width}s", substr($OLD[$oii],0,$width));
        $ospc = sprintf ("%3d: %-${width}s", $oii + 1, ' ');
        $ospc =~ s/./ /g;
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        #$clip = &l00httpd::urlencode ($OLD[$oii]);
        #$clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";

        $lineno = $oii + 1;
        $lineno0 = $lineno - 3;
        if ($lineno0 < 1) {
            $lineno0 = 1;
        }
        $view = "/view.htm?path=$oldfile&hiliteln=$lineno&lineno=on#line$lineno0";
        $oout = sprintf ("%3d<a href=\"%s\">:</a> %s", $oii + 1, $view, $tmp);
    } else {
        # make a string of space of same length
        $ospc = sprintf ("%3d: %-${width}s", 0, ' ');
        $ospc =~ s/./ /g;
        $oout = $ospc;
    }
    if (($nii >= 0) && ($nii <= $#NEW)) {
        $tmp = sprintf ("%-${width}s", substr($NEW[$nii],0,$width));
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        #$clip = &l00httpd::urlencode ($NEW[$nii]);
        #$clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";

        $lineno = $nii + 1;
        $lineno0 = $lineno - 3;
        if ($lineno0 < 1) {
            $lineno0 = 1;
        }
        $view = "/view.htm?path=$newfile&hiliteln=$lineno&lineno=on#line$lineno0";
        $nout = sprintf ("%3d<a href=\"%s\">:</a> %s", $nii + 1, $view, $tmp);
    } else {
        $nout = '';
    }

    ($oout, $nout, $ospc);
}

sub l00http_syncview_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "syncview: synchronized view of two files";
}

sub l00http_syncview_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($htmlout, $cnt, $ln);
my ($max);
my ($oout, $nout, $ospc);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    if ((defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        $_ = $form->{'path'};
        # keep path only
        s/\/[^\/]+$/\//;
        print $sock " Path: <a href=\"/ls.htm?path=$_\">$_</a>";
        $_ = $form->{'path'};
        # keep name only
        s/^.+\/([^\/]+)$/$1/;
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$_</a>\n";
    }
    print $sock "<a href=\"/syncview.htm\">Refresh</a>\n";
    print $sock "- <a href=\"#form\">Jump to end</a>\n";
    print $sock "<p>\n";


    if (defined ($form->{'debug'})) {
        if ($form->{'debug'} =~ /(\d+)/) {
            $debug = $1;
        } else {
            $debug = 5;
        }
    }

    if (defined ($form->{'hide'}) && ($form->{'hide'} eq 'on')) {
        $hide = 'checked';
    } else {
        $hide = '';
    }

    if (defined ($form->{'width'})) {
        if ($form->{'width'} =~ /(\d+)/) {
            $width = $1;
        }
    }
    if (defined ($form->{'maxline'})) {
        if ($form->{'maxline'} =~ /(\d+)/) {
            $maxline = $1;
        }
    }

    # copy paste target
    if (defined ($form->{'swap'})) {
        $_ = $newfile;
        $newfile = $oldfile;
        $oldfile = $_;
    } elsif (defined ($form->{'pasteold'})) {
        # if pasting old file
        # this takes precedence over 'path'
        $oldfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'pastenew'})) {
        # if pasting new file
        # this takes precedence over 'path'
        $newfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'path'})) {
        # could be 'view' or from launcher.htm
        if (defined ($form->{'pathold'})) {
            # 'view' clicked, old file from oldfile field
            $oldfile = $form->{'pathold'};
        } else {
            # from ls.htm, push first file to be oldfile
            $oldfile = $newfile;
        }
        # new file always from 'path' (field or from ls.htm)
        $newfile = $form->{'path'};
    }

    if (defined ($form->{'view'})) {
        # 'view' clicked
        if ((defined ($form->{'pathold'})) && (length($form->{'pathold'}) > 2)) {
            $oldfile = $form->{'pathold'};
        }
        if ((defined ($form->{'pathnew'})) && (length($form->{'pathnew'}) > 2)) {
            $newfile = $form->{'pathnew'};
        }

        $htmlout = "output: $oldfile $newfile\n";

    $htmlout .= "<pre>\n";

    if (&l00httpd::l00freadOpen($ctrl, "$oldfile")) {
        $htmlout .= "&lt; Old file: <a href=\"/view.htm?path=$oldfile\">$oldfile</a>\n";
        undef @OLD;
        $cnt = 0;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $cnt++;
            s/\r//;
            s/\n//;
            push (@OLD, $_);
        }
        $htmlout .= "    read $cnt lines\n";
    } else {
        $htmlout .= "$oldfile open failed\n";
    }

    if (&l00httpd::l00freadOpen($ctrl, "$newfile")) {
        $htmlout .= "&gt; New file: <a href=\"/view.htm?path=$newfile\">$newfile</a>\n";
        undef @NEW;
        $cnt = 0;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $cnt++;
            s/\r//;
            s/\n//;
            push (@NEW, $_);
        }
        $htmlout .= "    read $cnt lines\n\n";
    } else {
        $htmlout .= "$newfile open failed\n";
    }

#    for ($ln = 0; $ln <= $#OLD; $ln++) {
#        $htmlout .= "$ln: <  $OLD[$ln]\n";
#    }

    $max = $#OLD;
    if ($max > $#NEW) {
        $max = $#NEW;
    }
    for ($ln = 0; $ln <= $max; $ln++) {
        ($oout, $nout, $ospc) = &l00http_syncview_make_outline($ln, $ln, $width, $oldfile, $newfile);
        $htmlout .= " $oout =$nout\n";
#        $htmlout .= "$ln: $OLD[$ln] = $NEW[$ln]\n";
    }

        print $sock $htmlout;
    }

    print $sock "<a name=\"form\"></a>\n";
    print $sock "<form action=\"/syncview.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"view\" value=\"View\">\n";
    print $sock "Width: <input type=\"text\" size=\"4\" name=\"width\" value=\"$width\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pastenew\" value=\"CB>New:\">";
    print $sock "<br><textarea name=\"pathnew\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$newfile</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pasteold\" value=\"CB>Old:\">";
    print $sock "<br><textarea name=\"pathold\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$oldfile</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"debug\">debug";
    print $sock "<input type=\"checkbox\" name=\"hide\" $hide>Hide same lines\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "&nbsp;";
    print $sock "<input type=\"submit\" name=\"swap\" value=\"Swap\"> ";
    print $sock "<input type=\"text\" size=\"4\" name=\"maxline\" value=\"$maxline\"> lines max\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
