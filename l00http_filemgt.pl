use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_filemgt_proc",
              desc => "l00http_filemgt_desc");

sub l00http_filemgt_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "filemgt: Simple file management: delete only";
}

sub l00http_filemgt_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buffer, $path2);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> - ";
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
    print $sock "<p>\n";

    if ((defined ($form->{'delete'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
        }
        unlink ($form->{'path'});
        print $sock "Deleted $form->{'path'}<p>\n";
        undef $form->{'path'};
    }

    if ((defined ($form->{'copy'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        if (defined ($form->{'urlonly'})) {
            # URL only, do nothing
        } else {
            local $/ = undef;
            if (open (IN, "<$form->{'path'}")) {
                $buffer = <IN>;
                close (IN);
                if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
                    &l00backup::backupfile ($ctrl, $form->{'path2'}, 1, 5);
                }
                open (OU, ">$form->{'path2'}");
                print OU $buffer;
                close (OU);
            }
        }
	}

    if ((defined ($form->{'rename'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        if (defined ($form->{'urlonly'})) {
            # URL only, do nothing
        } else {
            local $/ = undef;
            if (open (IN, "<$form->{'path'}")) {
                $buffer = <IN>;
                close (IN);
                if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
                    &l00backup::backupfile ($ctrl, $form->{'path2'}, 1, 5);
                }
                open (OU, ">$form->{'path2'}");
                print OU $buffer;
                close (OU);
            }
            unlink ($form->{'path'});
            print $sock "Deleted $form->{'path'}<p>\n";
            undef $form->{'path'};
        }
    }

    # delete
    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    }
    print $sock "<form action=\"/filemgt.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"delete\" value=\"Delete\">\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"nobak\">Do not backup\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";

    # copy
    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    }
    if (defined ($form->{'urlonly'})) {
        # if from URL only, use path2
        $path2 = $form->{'path2'};
    } else {
        if (length ($form->{'path'}) > 0) {
            $path2 = $form->{'path'};
            if (!($path2 =~ /\/[^\/.]+$/)) {
                $path2 =~ s/(\.[^.]+)$/.2$1/;
            }
        } else {
            $path2 = '';
        }
    }
    print $sock "<form action=\"/filemgt.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"copy\" value=\"Copy\">\n";
    print $sock "<input type=\"submit\" name=\"rename\" value=\"Move\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "fr: <input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "to: <input type=\"text\" size=\"16\" name=\"path2\" value=\"$path2\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"nobak\">Do not backup\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"urlonly\">Make URL only\n";
    print $sock "</td></tr>\n";
    if (defined ($form->{'copy'}) &&
        (defined ($form->{'urlonly'})) && 
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/filemgt.htm?copy=Copy&path=$form->{'path'}&path2=$form->{'path2'}&urlonly=on\">Copy URL</a>\n";
        print $sock "</td></tr>\n";
    }
    print $sock "</table><br>\n";
    print $sock "</form>\n";



    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
