#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules
my ($offset, $length, $width, $group, $binary);
$offset = 0;
$length = 0x200;
$width = 8;
$group = 4;
$binary = '';

my %config = (proc => "l00http_hexview_proc",
              desc => "l00http_hexview_desc");

sub l00http_hexview_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "hexview: Hex and ASCII view of file";
}


sub l00http_hexview_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buffer, $buffer2, $cryptex, $rethash, $line, $ii, $len);
    my ($blklen, $tmp, $iiend, $hex, $ascii, $binview, $jj);
	my ($pname, $fname, $decaddr, $swap32, $byteidx);

    $sock = $ctrl->{'sock'};     # dereference network socket

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a><hr>\n";
    
    if (defined ($form->{'binary'}) && ($form->{'binary'} eq 'on')) {
        $binary = 'checked';
    } else {
        $binary = '';
    }
    if (defined ($form->{'decaddr'}) && ($form->{'decaddr'} eq 'on')) {
        $decaddr = 'checked';
    } else {
        $decaddr = '';
    }
    if (defined ($form->{'swap32'}) && ($form->{'swap32'} eq 'on')) {
        $swap32 = 'checked';
    } else {
        $swap32 = '';
    }
    if (defined ($form->{'offset'})) {
        $offset = hex ($form->{'offset'});
    }
    if (defined ($form->{'length'})) {
        $length = hex ($form->{'length'});
    }
    if (defined ($form->{'width'})) {
        $width = $form->{'width'};
    }
    if (defined ($form->{'group'})) {
        $group = hex ($form->{'group'});
    }

    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";

        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a><p>\n";

    } else {
        print $sock "Path: <a href=\"/launcher.htm?path=$ctrl->{'workdir'}\">Select solver equation file</a> and 'Set' to 'solver'<p>\n";
        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
        return;
    }
    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;


    # read the file
    if (open (IN, "<$form->{'path'}")) {
        binmode (IN);
        seek (IN, $offset, 0);
        read (IN, $buffer, $length);
        close (IN);
        $iiend = $length;
        if ($iiend > length ($buffer)) {
            $iiend = length ($buffer);
        }
        print $sock "<pre>\n";
        $ascii = '';
        $hex = '';
        $binview = '';
        for ($ii = 0; $ii < $iiend; $ii++) {
            if ((($ii) % $width) == 0) {
                $tmp = "$hex $ascii $binview\n";
                $tmp =~ s/%/%%/g;
                $tmp =~ s/</&lt;/g;
                $tmp =~ s/>/&gt;/g;
                printf $sock ($tmp);
                if ($decaddr eq 'checked') {
                    $hex = sprintf ("%8d %06x", $ii + $offset, $ii + $offset);
                } else {
                    $hex = sprintf ("%06x", $ii + $offset);
                }
                $ascii = '';
                $binview = '';
            }
            if ((($ii % $width) % $group) == 0) {
                $hex .= ' ';
                $binview .= ' ';
            }
            if ($swap32 eq '') {
                $byteidx = $ii;
            } else {
                $byteidx = ($ii & ~3) + (3 - ($ii & 3));
            }
            $hex .= sprintf (" %02x",
                unpack ("C", substr ($buffer, $byteidx, 1)));
            $tmp = substr ($buffer, $byteidx, 1);
            $tmp =~ s/([^a-zA-Z0-9])/((ord($1)<32)||(ord($1)>95))?'.':$1/ge;
            $ascii .= $tmp;

            # binary view
            if ($binary eq 'checked') {
                for ($jj = 7; $jj >= 0; $jj--) {
                    if ((1 << $jj) & unpack ("C", substr ($buffer, $byteidx, 1))) {
                        $binview .= '1';
                    } else {
                        $binview .= '0';
                    }
                }
                $binview .= ' ';
            }
        }
        $tmp = "$hex $ascii $binview\n";
        $tmp =~ s/%/%%/g;
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        printf $sock ($tmp);
        print $sock "</pre>\n";
    } else {
        print $sock "Failed to open '$form->{'path'}'\n";
        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
        return;
    }


    print $sock "<hr><form action=\"/hexview.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"hexview\" value=\"V&#818;iew\" accesskey=\"v\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" name=\"path\" size=16 value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Offset\n";
    print $sock "</td><td>\n";
    $tmp = sprintf ("%x", $offset);;
    print $sock "0x<input type=\"text\" name=\"offset\" size=8 value=\"$tmp\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Length\n";
    print $sock "</td><td>\n";
    $tmp = sprintf ("%x", $length);;
    print $sock "0x<input type=\"text\" name=\"length\" size=8 value=\"$tmp\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Width\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" name=\"width\" size=8 value=\"$width\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Group\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" name=\"group\" size=8 value=\"$group\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Show\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"binary\" $binary>binary output\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Show\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"decaddr\" $decaddr>decimal address\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Show\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"swap32\" $swap32>32-bit byte swap\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form><p>\n";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
