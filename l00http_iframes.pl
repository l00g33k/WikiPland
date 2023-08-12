use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# iframes simulating multiple screen

my %config = (proc => "l00http_iframes_proc",
              desc => "l00http_iframes_desc");

my ($height, $spec, $overwritehtflag);

$height = 300;
$spec = '';
$overwritehtflag = '';

sub l00http_iframes_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: iframes: simulating multiple screen";
}


sub l00http_iframes_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($url, $width, @urls, $u, $wd, $ht, $lf, $out, $row, $frame);
    my ($nocol, $nocolstar, $colwd, $tmp, $overwriteht, $rowidx, $colidx);
    my ($formout);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>iframes</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"iframestop\"></a>\n";
    $formout = '';
    if (!defined ($form->{"noform"}) || ($form->{"noform"} ne 'on')) {
        $formout .= "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    } else {
        $formout .= "$ctrl->{'HOME'}\n";
    }
    $formout .= "<a href=\"#end\">Jump to end</a><br>\n";

    if (defined ($form->{'spec'}) && 
        (length($form->{'spec'}) > 4)) {
        $spec = $form->{'spec'};
    }
    if (defined ($form->{'add'}) && 
        defined ($form->{'url'}) && 
        ($form->{'url'} =~ /(https*:\/\/[^ \n\r\t]+)/)) {
        if (defined ($form->{'height'}) && $form->{'height'} =~ /(\d+%*)/) {
            $height = $1;
        }
    }
    if (defined ($form->{'cb'})) {
        $url = &l00httpd::l00getCB($ctrl);
        $form->{'url'} = $url;
        if ($url =~ /(https*:\/\/[^ \n\r\t]+)/) {
            $form->{'add'} = 1;
            $form->{'url'} = $1;
        }
    }
#::now::
# add paste CB for this button
#<input type=\"submit\" name=\"row$rowidx\" value=\"Row $rowidx\">
#new row%d to trigger 'update'
#CB -> $form->{"url_$rowidx"}
#::herehere::
    if (defined ($form->{'update'})) {
        $spec = '';
        $rowidx = 0;
        while (1) {
            l00httpd::dbp($config{'desc'}, "update: spec )$spec(\n");
            if (!defined ($form->{"url_$rowidx"}) ||
                !defined ($form->{"wd_$rowidx"}) ||
                !defined ($form->{"ht_$rowidx"})) {
                last;
            }
            if (defined ($form->{"cb_$rowidx"}) && ($form->{"cb_$rowidx"} eq 'on')) {
                $form->{"url_$rowidx"} = &l00httpd::l00getCB($ctrl);
                if ($form->{"url_$rowidx"} =~ /(http:\/\/[^ \n\r\t]+)/) {
                    $form->{"url_$rowidx"} = $1;
                }
                l00httpd::dbp($config{'desc'}, "update: cb: )".$form->{"url_$rowidx"}."(\n");
            }
            if ($spec ne '') {
                if (defined ($form->{"lf_$rowidx"}) && ($form->{"lf_$rowidx"} eq 'on')) {
                    $spec .= '   ';
                } else {
                    $spec .= '  ';
                }
            }
            $spec .= $form->{"url_$rowidx"}.' '.$form->{"wd_$rowidx"}.' '.$form->{"ht_$rowidx"};
            $rowidx++;
        }
    }
    if (defined ($form->{'add'}) && 
        defined ($form->{'url'}) && 
        ($form->{'url'} =~ /(https*:\/\/[^ \n\r\t]+)/)) {
        $url = $1;
        $width = '*';
        if (defined ($form->{'width'}) && $form->{'width'} =~ /(\d+)/) {
            $width = $1;
        }
        if ($spec ne '') {
            if (defined ($form->{'newline'}) && ($form->{'newline'} eq 'on')) {
                $spec .= '   ';
            } else {
                $spec .= '  ';
            }
        }
        $spec .= "$url $width $height";
    }
    if (defined ($form->{'clear'})) {
        $spec = '';
    }


    $overwritehtflag = '';
    if (defined ($form->{'overwriteht'}) && ($form->{'overwriteht'} eq 'on')) {
        $overwritehtflag = 'checked';
    }


    $formout .= "<form action=\"/iframes.htm\" method=\"get\">\n";
    $formout .= "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    $formout .= "        <tr>\n";
    $formout .= "            <td><input type=\"submit\" name=\"add\" value=\"Add\"> URL:</td>\n";
    $formout .= "            <td><input type=\"text\" size=\"16\" name=\"url\" value=\"\"> <input type=\"submit\" name=\"cb\" value=\"CB\"> <input type=\"checkbox\" name=\"newline\"> prepend newline</td>\n";
    $formout .= "        </tr>\n";

    $formout .= "        <tr>\n";
    $formout .= "            <td>Width:</td>\n";
    $formout .= "            <td><input type=\"text\" size=\"6\" name=\"width\" value=\"\"> %. Blank for equal spacing.</td>\n";
    $formout .= "        </tr>\n";
                                                
    $formout .= "        <tr>\n";
    $formout .= "            <td>Height:</td>\n";
    $formout .= "            <td><input type=\"text\" size=\"6\" name=\"height\" value=\"$height\"> pixel. <input type=\"checkbox\" name=\"overwriteht\" $overwritehtflag> overwrite</td>\n";
    $formout .= "        </tr>\n";
                                                
    $formout .= "    <tr>\n";
    $formout .= "        <td><input type=\"submit\" name=\"clear\" value=\"Clear\"></td>\n";
    $formout .= "        <td><input type=\"submit\" name=\"code\" value=\"Refresh\"> <input type=\"submit\" name=\"render\" value=\"Render\"> <input type=\"checkbox\" name=\"noform\"> Hide form</td>\n";
    $formout .= "    </tr>\n";


    if ($spec ne '') {
        $formout .= "    <tr>\n";
        $formout .= "        <td><input type=\"submit\" name=\"update\" value=\"Update\"></td>\n";
        $formout .= "        <td>Frame details:</td>\n";
        $formout .= "    </tr>\n";

        $out = '';
        $overwriteht = 0;
        if ($overwritehtflag eq 'checked') {
            if (defined ($form->{'height'}) && $form->{'height'} =~ /(\d+)/) {
                $overwriteht = $1;
            }
        }
        $rowidx = 0;
        l00httpd::dbp($config{'desc'}, "form: spec )$spec(\n");
        foreach $row (split ('   ', $spec)) {
            l00httpd::dbp($config{'desc'}, "form: row )$row(\n");
            $nocol = 0;
            $nocolstar = 0;
            $colwd = 0;
            foreach $frame (split ('  ', $row)) {
                l00httpd::dbp($config{'desc'}, "frame $frame\n");
                $nocol++;
                if ($frame =~ / \* \d+$/) {
                    $nocolstar++;
                } elsif ($frame =~ / (\d+) \d+$/) {
                    $colwd += $1;
                }
            }
            l00httpd::dbp($config{'desc'}, "nocol $nocol, nocolstar $nocolstar, colwd $colwd\n");
            $colidx = 0;
            foreach $frame (split ('  ', $row)) {
                ($u, $wd, $ht) = split (' ', $frame);

                $formout .= "    <tr>\n";
                $formout .= "        <td>Row $rowidx<input type=\"checkbox\" name=\"cb_$rowidx\"> CB-&gt;</td>\n";
                $formout .= "        <td>";
                if (($colidx == 0) && ($rowidx != 0)) {
                    $tmp = 'checked';
                } else {
                    $tmp = '';
                }
                $formout .= "        <input type=\"checkbox\" name=\"lf_$rowidx\" $tmp> &lt;p&gt; ";
                $formout .= "        <a href=\"$u\">URL</a>: ";
                $formout .= "             <input type=\"text\" size=\"6\" name=\"url_$rowidx\" value=\"$u\"> ";
                $formout .= "        wd: <input type=\"text\" size=\"2\" name=\"wd_$rowidx\" value=\"$wd\"> ";
                $formout .= "        ht: <input type=\"text\" size=\"3\" name=\"ht_$rowidx\" value=\"$ht\"> ";
                $formout .= "        t_${rowidx}_${colidx}</td>\n";
                $formout .= "    </tr>\n";
                $rowidx++;

                if ($wd =~ /\*/) {
                    $wd = int ((98 - $colwd) / $nocolstar);
                }
                if ($overwriteht > 0) {
                    $ht = $overwriteht;
                }
                l00httpd::dbp($config{'desc'}, "($u, $wd, $ht) colwd $colwd\n");
                $out .= "<iframe src=\"$u\" width=\"$wd%\" height=\"$ht\" name=\"t_${rowidx}_${colidx}\">iframe not supported by your browser.</iframe>\n";

                $colidx++;
            }
            $out .= "<br>\n";
#            $rowidx++;
        }
        $tmp = $out;
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        $tmp =~ s/(&lt;iframe src)/<br>$1/g;
        l00httpd::dbp($config{'desc'}, "\n$tmp\n");
    }

    $formout .= "</table>\n";
    $formout .= "<input type=\"hidden\" name=\"spec\" value=\"$spec\">\n";
    $formout .= "</form><p>\n";


    if (defined ($form->{'render'})) {
        print $sock $out;
    } else {
        $out =~ s/</&lt;/g;
        $out =~ s/>/&gt;/g;
        $out =~ s/(&lt;iframe src)/<br>$1/g;
        #print $sock $out;
    }

    if (!defined ($form->{"noform"}) || ($form->{"noform"} ne 'on')) {
        print $sock $formout;
    }

    print $sock "<a name=\"end\"></a>\n";
    print $sock "<p><a href=\"#iframestop\">Jump to top</a>";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
