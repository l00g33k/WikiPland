use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_scratch_proc",
              desc => "l00http_scratch_desc");
my ($scratch, $scratchhtml, $tmp, $eval);
$eval = '';

sub l00http_scratch_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " A: scratch: A scratch pad";
}


sub l00http_scratch_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>scratch</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a href=\"#end\">Jump to end</a>. \n";
    print $sock "Go to <a href=\"/clip.htm\">clip</a> - \n";
    print $sock "<a href=\"/httpd.htm#ram\">RAM files</a><br>\n";

    if (defined ($form->{'eval'})) {
        $eval = $form->{'eval'};
    }
    if (defined ($form->{'cbmobi'})) {
        $scratch = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'prepend'})) {
        $scratch = &l00httpd::l00getCB($ctrl);
        if (defined ($form->{'scratchbuf'})) {
            $scratch = "$scratch $form->{'scratchbuf'}";
        }
    } elsif (defined ($form->{'append'})) {
        $scratch = &l00httpd::l00getCB($ctrl);
        if (defined ($form->{'scratchbuf'})) {
            $scratch = "$form->{'scratchbuf'} $scratch";
        }
    } elsif (defined ($form->{'update'})) {
        if (defined ($form->{'scratchbuf'})) {
            $scratch = $form->{'scratchbuf'};
        } else {
            $scratch = "";
        }
    } elsif (defined ($form->{'clear'})) {
        $scratch = "";
    } else {
        if (!defined ($scratch)) {
            $scratch = "";
        }
    }
    if (defined ($form->{'cburl'})) {
        if ($ctrl->{'os'} eq 'and') {
            if (($tmp) = $scratch =~ /(http:\/\/[^ \n\r\t]+)/) {
                &l00httpd::l00setCB($ctrl, $tmp);
            }
        }
    }
    $tmp = $scratch;
    if (defined ($form->{'2l00'})) {
        print $sock "<br>Scratch copied to <a href=\"/view.htm?path=l00://clipboard\">l00://clipboard</a><p>\n";
        &l00httpd::l00fwriteOpen($ctrl, 'l00://clipboard');
        &l00httpd::l00fwriteBuf($ctrl, $scratch);
        &l00httpd::l00fwriteClose($ctrl);
    }
    if (defined ($form->{'cbcopy'})) {
        &l00httpd::l00setCB($ctrl, $scratch);
    }

    print "scratch: >$scratch<\n", if ($ctrl->{'debug'} >= 5);

#    $tmp =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    print $sock "<form action=\"/scratch.htm\" method=\"post\">\n";
    print $sock "<textarea name=\"scratchbuf\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$tmp</textarea>\n";
    print $sock "<p><input type=\"submit\" name=\"update\" value=\"Set\"> \n";
    print $sock "<input type=\"submit\" name=\"cbmobi\" value=\"paste CB\"> \n";
    print $sock "<input type=\"submit\" name=\"cbcopy\" value=\"cp2CB\"> \n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Clr\">\n";
    print $sock "<br>\n";
    print $sock "<input type=\"submit\" name=\"append\" value=\"Append\"> \n";
    print $sock "<input type=\"submit\" name=\"prepend\" value=\"Prepend\">\n";
    print $sock "<input type=\"submit\" name=\"cburl\" value=\"cp URL 2CB\">\n";
    print $sock "<input type=\"submit\" name=\"2l00\" value=\"2 ram file\">\n";

    print $sock "<br><input type=\"text\" size=\"10\" name=\"eval\" value=\"$eval\">\n";
    print $sock "The whole content of the scratch buffer is put in \$_ and then this string is \"eval'ed\", e.g. 'print \$sock \$_' prints the content to this HTML page\n";
    print $sock "</form>\n";

    print $sock "<form action=\"/scratch.htm\" method=\"get\">\n";
    print $sock "Refresh as:<br>\n";
    print $sock "<input type=\"submit\" name=\"mobi\" value=\"Mobilize\">\n";
    print $sock "<input type=\"submit\" name=\"html\" value=\"HTML\">\n";
    print $sock "<input type=\"submit\" name=\"text\" value=\"text\">\n";
    print $sock "<input type=\"submit\" name=\"formatted\" value=\"Formatted\">\n";
    print $sock "</form><p>\n";


    print $sock "Send l00://clipboard to <a href=\"/launcher.htm?path=l00://clipboard\">launcher</a>, \n";
    print $sock "<a href=\"/view.htm?path=l00://clipboard\">View</a> l00://clipboard.<p>\n";

    # get submitted name and print greeting
    if (defined ($form->{'text'})) {
        $scratchhtml = $scratch;
        $scratchhtml =~ s/</&lt;/g;
        $scratchhtml =~ s/>/&gt;/g;
        $scratchhtml =~ s/\r\n/<br>/g;
        $scratchhtml =~ s/\r/<br>/g;
        $scratchhtml =~ s/\n/<br>/g;
        $scratchhtml =~ s/<br>/<br>\n/g;
    } elsif (defined ($form->{'formatted'})) {
        $scratchhtml = $scratch;
        $scratchhtml =~ s/</&lt;/g;
        $scratchhtml =~ s/>/&gt;/g;
        $scratchhtml =~ s/\r\n/\n/g;
        $scratchhtml =~ s/\r/\n/g;
        $scratchhtml = "<pre>\n$scratchhtml\n</pre>\n";
    } else {
        $scratchhtml = $scratch;
        $scratchhtml =~ s/\r//g;
        if (length ($eval) > 2) {
            print $sock "<pre>eval: $eval</pre>\n";
            $_ = $scratchhtml;
            eval "$eval";
            $scratchhtml = $_;
        }
        @alllines = split ("\n", $scratchhtml);
        $scratchhtml = "";
        foreach $line (@alllines) {
            if (defined ($form->{'mobi'})) {
                #http://www.google.com/gwt/n?u=http%3A%2F%2Fwww.a.com
                $line =~ s|:|%3A|g;
                $line =~ s|/|%2F|g;
                $line =~ s|(https*%3A%2F%2F[^ ]+)|<a href=\"http://www.google.com/gwt/n?u=$1\">http://www.google.com/gwt/n?u=$1</a>|g;
            } else {
                $line =~ s|(https*://[^ ]+)|<a href=\"$1\">$1</a>|g;
            }
            $scratchhtml .= "$line<br>";
        }
    }

    print $sock "$scratchhtml\n";

    print $sock "<p><p><hr>\n";
    print $sock "<p><p><hr>\n";
    print $sock "<p><p><hr>\n";
    print $sock "<hr><a name=\"end\"></a><p><p>\n";

 
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
