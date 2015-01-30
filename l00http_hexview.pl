#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules
my ($offset, $length, $width, $group);
$offset = 0;
$length = 0x200;
$width = 8;
$group = 4;

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
    my ($blklen, $tmp, $iiend, $hex, $ascii);

    $sock = $ctrl->{'sock'};     # dereference network socket

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a><hr>\n";
    
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
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><p>\n";
    } else {
        print $sock "Path: <a href=\"/ls.htm?path=$ctrl->{'workdir'}\">Select solver equation file</a> and 'Set' to 'solver'<p>\n";
        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
        return;
    }
    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;


    # read the file
    if (open (IN, "<$form->{'path'}")) {
        binmode (IN);
        # http://www.perlmonks.org/?node_id=1952
        local $/ = undef;
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
        for ($ii = 0; $ii < $iiend; $ii++) {
            if ((($ii) % $width) == 0) {
                $tmp = "$hex $ascii\n";
                $tmp =~ s/\\/\\\\/g;
                $tmp =~ s/%/%%/g;
                $tmp =~ s/</&lt;/g;
                $tmp =~ s/>/&gt;/g;
                printf $sock ($tmp);
                #printf $sock ("$hex $ascii\n");
                $hex = sprintf ("%06x", $ii + $offset);
                $ascii = '';
            }
            if ((($ii % $width) % $group) == 0) {
                $hex .= ' ';
            }
            $hex .= sprintf (" %02x",
                unpack ("C", substr ($buffer, $ii, 1)));
            $tmp = substr ($buffer, $ii, 1);
            $tmp =~ s/([^a-zA-Z0-9])/((ord($1)<32)||(ord($1)>95))?'.':$1/ge;
            $ascii .= "$tmp";
        }
        printf $sock ("$hex $ascii\n");
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
    print $sock "<input type=\"submit\" name=\"hexview\" value=\"View\">\n";
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
    print $sock "</table>\n";
    print $sock "</form><p>\n";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
