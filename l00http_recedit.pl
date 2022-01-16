use strict;
use warnings;
use l00backup;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# edit notify and reminder

my %config = (proc => "l00http_recedit_proc",
              desc => "l00http_recedit_desc");
my ($record1, $displen);

$record1 = '^\d{8,8} \d{6,6} ';
$displen = 50;

sub l00http_recedit_output_row {
    my ($ctrl, $sock, $form, $line, $id, $obuf, $path, $lnno) = @_;
    my ($tmp, $disp, $lf, $leading, $html, $color1, $color2, $chkalldel);

    $html = '';

    # record before the current record was a hit, print
    $html .= "    <tr>\n";
    
    $chkalldel = '';
    if (defined ($form->{'chkall'})) {
        $chkalldel = 'checked';
    }
    if (defined ($form->{'reminder'})) {
        # print reminder specific checkboxes
        $html .= "        <td><a name=\"__end${id}__\"></a>";
        if ($path =~ /^l00:\/\//) {
            # RAM file, 1, 6 hours (or 4)
            $html .= "<font style=\"color:black;background-color:silver\"><input type=\"checkbox\" name=\"add1h$id\">+1h</font><br>\n";
           #$html .= "            +4h<input type=\"checkbox\" name=\"add4h$id\"><br>\n";
            $html .= "            +6h<input type=\"checkbox\" name=\"add6h$id\"><br>\n";
        } else {
            # disk file, 1, 2 days
            $html .= "<font style=\"color:black;background-color:silver\"><input type=\"checkbox\" name=\"add$id\">+1d</font><br>\n";
            $html .= "            +2d<input type=\"checkbox\" name=\"add2d$id\"><br>\n";
        }
        $html .= "            <input type=\"checkbox\" name=\"id$id\" $chkalldel>del</td>\n";
        $obuf=~ s/(\d+:\d+:\d+:\d+:)/$1\n/;
    } else {
        $html .= "        <td><a name=\"__end${id}__\"></a><input type=\"checkbox\" name=\"id$id\" $chkalldel>del</td>\n";
    }
    $html .= "        <td><font face=\"Courier New\">";
    $lf = '';
    foreach $line (split("\n", $obuf)) {
        $line =~ s/\r//;
        $line =~ s/\n//;
        # notify specific
        if ($line =~ /^MSG:(.+)/) {
            # make link to copy to clipboard
            $line = $1;
            if (length ($line) < 1) {
                $line = '&nbsp;';
            }
            $tmp = $1;
            $tmp =~ s/ /+/g;
            $tmp =~ s/:/%3A/g;
            $tmp =~ s/&/%26/g;
            $tmp =~ s/=/%3D/g;
            $tmp =~ s/"/%22/g;
            $tmp =~ s/#/%23/g;
            $tmp =~ s/\//%2F/g;
            $tmp =~ s/\|/%7C/g;
            $disp = substr($line,0,$displen);
            $disp =~ s/ /&nbsp;/g;
            $line = "MSG:<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newclip\">$disp</a>";
        } elsif (($leading, $tmp) = $line =~ /^(\d+\/\d+\/\d+\+*\d*,\d+, *)(.+)/) {
            # cal specific
            $line = $tmp;
            if (length ($line) < 1) {
                $line = '&nbsp;';
            }
            $tmp =~ s/ /+/g;
            $tmp =~ s/:/%3A/g;
            $tmp =~ s/&/%26/g;
            $tmp =~ s/=/%3D/g;
            $tmp =~ s/"/%22/g;
            $tmp =~ s/#/%23/g;
            $tmp =~ s/\//%2F/g;
            $tmp =~ s/\|/%7C/g;
            $disp = substr($line,0,$displen);
            $disp =~ s/ /&nbsp;/g;
            $line = "$leading<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newclip\">$disp</a>";
        } elsif ($record1 eq '.') {
            # drop leading date/time
            $line =~ s/^\d{8,8} \d{6,6} //;
            if (length ($line) < 1) {
                $line = '&nbsp;';
            }
            # match any specific
            $tmp = $line;
            $tmp =~ s/ /+/g;
            $tmp =~ s/:/%3A/g;
            $tmp =~ s/&/%26/g;
            $tmp =~ s/=/%3D/g;
            $tmp =~ s/"/%22/g;
            $tmp =~ s/#/%23/g;
            $tmp =~ s/\//%2F/g;
            $tmp =~ s/\|/%7C/g;
            $disp = substr($line,0,$displen);
            $disp =~ s/ /&nbsp;/g;
            $line = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newclip\">$disp</a>";
        } else {
            if (length ($line) < 1) {
                $line = '&nbsp;';
            }
            # match reminder
            # 20171005 110000:10:0:60:
            $color1 = '';
            $color2 = '';
            if (defined ($form->{'reminder'})) {
                if ($line =~ /^(\d{8,8} \d{6,6}):\d+/) {
                    if ($1 lt $ctrl->{'now_string'}) {
                        $color1 = '<font style="color:black;background-color:silver">';
                        $color2 = '</font>';
                    } else {
                        # time to fire
                        $tmp = l00httpd::now_string2time ($1) -
                               l00httpd::now_string2time ($ctrl->{'now_string'});
                        if (($tmp < 14400) && ($tmp > 1)) {
                            # firing in the next 4 hours
                            $color1 = '<font style="color:black;background-color:#d0f0d0">';
                            $color2 = '</font>';
                        }
                    }
                }
            }
            # match any specific
            $tmp = $line;
            $tmp =~ s/ /+/g;
            $tmp =~ s/:/%3A/g;
            $tmp =~ s/&/%26/g;
            $tmp =~ s/=/%3D/g;
            $tmp =~ s/"/%22/g;
            $tmp =~ s/#/%23/g;
            $tmp =~ s/\//%2F/g;
            $tmp =~ s/\|/%7C/g;
            $disp = substr($line,0,$displen);
            $disp =~ s/ /&nbsp;/g;
            $line = "$color1<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newclip\">$disp</a>$color2";
        }
        $html .= "$lf$line";
        $lf = "<br>\n";
    }
    $html .= " - <a href=\"/edit.htm?path=$path&blklineno=$lnno\" target=\"_blank\">$lnno</a>";
    $html .= "</font></td>\n";
    $html .= "    </tr>\n";

    $html;
}

sub l00http_recedit_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    "recedit: Edit notify and reminder input file";
}

sub l00http_recedit_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $obuf, $found, $line, $id, $output, $delete, $cmted, $editln, $keeplook);
    my ($yr, $mo, $da, $hr, $mi, $se, $tmp, $tmp2, @table, $ii, $lnno, $afterline);


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
    } else {
        $path = "$ctrl->{'workdir'}l00_notify.txt";
    }

    if (defined ($form->{'record1'})) {
        $record1 = $form->{'record1'};
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>recedit</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} ";
    print $sock "<a href=\"/recedit.htm\">recedit</a> - \n";
    print $sock "<a href=\"#end\">end</a><p>\n";

    if (length($record1) == 0) {
        $record1 = '^\d{8,8} \d{6,6} ';
    }

    if (defined ($form->{'displen'}) && ($form->{'displen'} =~ /(\d+)/)) {
        $displen = $1;
    }
    $afterline = 0;
    if (defined ($form->{'afterline'}) && ($form->{'afterline'} =~ /(\d+)/)) {
        $afterline = $1;
    }

    if (defined ($form->{'submit'}) && (length($record1) > 0)) {
        if (&l00httpd::l00freadOpen($ctrl, $path)) {
            $obuf = '';
            $found = 0;
            $output = '';
            $id = 1;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                if (/^ *$/) {
                    if ($found) {
                        $cmted .= $_;
                    } else {
                        $output .= "$_";
                    }
                    next;
                }
                if (/^#/) {
                    if ($found) {
                        $cmted .= $_;
                    } else {
                        $output .= "$_";
                    }
                    next;
                }
                if (/$record1/) {
                    $delete = '';
                    if (defined($form->{"add1h$id"}) && ($form->{"add1h$id"} eq 'on')) {
                        # add 1 hours
                        if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                            #20130408 100000:10:0:60:copy hurom
                            $yr -= 1900;
                            $mo--;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 1 * 3600; # add1h
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                substr ($obuf, 15, 9999));
                        } elsif (($yr, $mo, $da, $tmp2) = ($obuf =~ /^(\d+)\/(\d+)\/(\d+)(.*)$/)) {
                            #2013/4/11,1,411test 
                            $yr -= 1900;
                            $mo--;
                            $hr = 0;
                            $mi = 0;
                            $se = 0;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 1 * 3600; # add1h
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%d/%d/%d%s", 
                                $yr + 1900, $mo + 1, $da, $tmp2);
                        }
                    }
                    if (defined($form->{"add6h$id"}) && ($form->{"add6h$id"} eq 'on')) {
                        # add 6 hours
                        if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                            #20130408 100000:10:0:60:copy hurom
                            $yr -= 1900;
                            $mo--;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 6 * 3600; # add6h
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                substr ($obuf, 15, 9999));
                        } elsif (($yr, $mo, $da, $tmp2) = ($obuf =~ /^(\d+)\/(\d+)\/(\d+)(.*)$/)) {
                            #2013/4/11,1,411test 
                            $yr -= 1900;
                            $mo--;
                            $hr = 0;
                            $mi = 0;
                            $se = 0;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 6 * 3600; # add6h
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%d/%d/%d%s", 
                                $yr + 1900, $mo + 1, $da, $tmp2);
                        }
                    }
                    if (defined($form->{"add4h$id"}) && ($form->{"add4h$id"} eq 'on')) {
                        # add 4 hours
                        if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                            #20130408 100000:10:0:60:copy hurom
                            $yr -= 1900;
                            $mo--;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 4 * 3600; # add4h
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                substr ($obuf, 15, 9999));
                        } elsif (($yr, $mo, $da, $tmp2) = ($obuf =~ /^(\d+)\/(\d+)\/(\d+)(.*)$/)) {
                            #2013/4/11,1,411test 
                            $yr -= 1900;
                            $mo--;
                            $hr = 0;
                            $mi = 0;
                            $se = 0;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 4 * 3600; # add4h
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%d/%d/%d%s", 
                                $yr + 1900, $mo + 1, $da, $tmp2);
                        }
                    }
                    if (defined($form->{"add2d$id"}) && ($form->{"add2d$id"} eq 'on')) {
                        # add 4 hours
                        if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                            #20130408 100000:10:0:60:copy hurom
                            $yr -= 1900;
                            $mo--;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 48 * 3600; # add2d
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                substr ($obuf, 15, 9999));
                        } elsif (($yr, $mo, $da, $tmp2) = ($obuf =~ /^(\d+)\/(\d+)\/(\d+)(.*)$/)) {
                            #2013/4/11,1,411test 
                            $yr -= 1900;
                            $mo--;
                            $hr = 0;
                            $mi = 0;
                            $se = 0;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 48 * 3600; # add2d
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%d/%d/%d%s", 
                                $yr + 1900, $mo + 1, $da, $tmp2);
                        }
                    }
                    if (defined($form->{"add$id"}) && ($form->{"add$id"} eq 'on')) {
                        # add 1 day
                        if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                            #20130408 100000:10:0:60:copy hurom
                            $yr -= 1900;
                            $mo--;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 24 * 3600;
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                substr ($obuf, 15, 9999));
                        } elsif (($yr, $mo, $da, $tmp2) = ($obuf =~ /^(\d+)\/(\d+)\/(\d+)(.*)$/)) {
                            #2013/4/11,1,411test 
                            $yr -= 1900;
                            $mo--;
                            $hr = 0;
                            $mi = 0;
                            $se = 0;
                            $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                            $tmp += 24 * 3600;
                            ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                            $obuf = sprintf ("%d/%d/%d%s", 
                                $yr + 1900, $mo + 1, $da, $tmp2);
                        }
                    }
                    if (defined($form->{"id$id"}) && ($form->{"id$id"} eq 'on')) {
                        $delete = '#';
                    }
                    if ($found) {
                        foreach $line (split("\n", $obuf)) {
                            $output .= "$delete$line\n";
                        }
                        $output .= $cmted;
                        $id++;
                    }
                    $found = 1;
                    $obuf = '';
                    $cmted = '';
                } elsif (!$found) {
                    $output .= "$_";
                }
                if ($found) {
                    $obuf .= $_;
                }
            }
            if ($found) {
                $delete = '';
                if (defined($form->{"add1h$id"}) && ($form->{"add1h$id"} eq 'on')) {
                    # add 1 hours
                    if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                        $yr -= 1900;
                        $mo--;
                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                        $tmp += 1 * 3600; # add1h
                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                        $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                            $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                            substr ($obuf, 15, 9999));
                    }
                } elsif (defined($form->{"add6h$id"}) && ($form->{"add6h$id"} eq 'on')) {
                    # add 6 hours
                    if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                        $yr -= 1900;
                        $mo--;
                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                        $tmp += 6 * 3600; # add6h
                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                        $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                            $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                            substr ($obuf, 15, 9999));
                    }
                } elsif (defined($form->{"add4h$id"}) && ($form->{"add4h$id"} eq 'on')) {
                    # add 4 hours
                    if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                        $yr -= 1900;
                        $mo--;
                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                        $tmp += 4 * 3600; # add4h
                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                        $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                            $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                            substr ($obuf, 15, 9999));
                    }
                } elsif (defined($form->{"add2d$id"}) && ($form->{"add2d$id"} eq 'on')) {
                    # add 4 hours
                    if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                        $yr -= 1900;
                        $mo--;
                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                        $tmp += 48 * 3600; # add2d
                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                        $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                            $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                            substr ($obuf, 15, 9999));
                    }
                } elsif (defined($form->{"add$id"}) && ($form->{"add$id"} eq 'on')) {
                    # add 1 day
                    if (($yr, $mo, $da, $hr, $mi, $se) = ($obuf =~ /(....)(..)(..) (..)(..)(..)/)) {
                        $yr -= 1900;
                        $mo--;
                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                        $tmp += 24 * 3600;
                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                        $obuf = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                            $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                            substr ($obuf, 15, 9999));
                    }
                } else {
                    if (defined($form->{"id$id"}) && ($form->{"id$id"} eq 'on')) {
                        $delete = '#';
                    }
                }
                foreach $line (split("\n", $obuf)) {
                    $output .= "$delete$line\n";
                }
                $output .= $cmted;
            }
            close (IN);
            &l00backup::backupfile ($ctrl, $path, 1, 5);
            #print $sock "<pre>$output</pre>$path\n";
            if (&l00httpd::l00fwriteOpen($ctrl, $path)) {
                &l00httpd::l00fwriteBuf($ctrl, $output);
                &l00httpd::l00fwriteClose($ctrl);
            } else {
                print $sock "<p>Unable to save '$path'<p>\n";
            }
        }
    }

    print $sock "<a href=\"/ls.htm?path=$path\">$path</a> - ";
    print $sock "<a href=\"/view.htm?path=$path\">vw</a>:<p>";

    print $sock "<form action=\"/recedit.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Record 1:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"record1\" value=\"$record1\">.".
                                " After line: <input type=\"text\" size=\"4\" name=\"afterline\" value=\"$afterline\">.".
                                " Max len: <input type=\"text\" size=\"4\" name=\"displen\" value=\"$displen\">.".
                                "</td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Path:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"U&#818;pdate\" accesskey=\"u\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"update\" value=\"R&#818;efresh\" accesskey=\"r\">\n";
    if (defined ($form->{'reminder'})) {
        $_ = 'checked';
    } else {
        $_ = '';
    }
    print $sock "        <input type=\"submit\" name=\"chkall\" value=\"Chk A&#818;ll del\" accesskey=\"a\">\n";
    print $sock "                <input type=\"checkbox\" name=\"reminder\" $_>Enable reminder specific\n";
    print $sock "    </td>\n";
    print $sock "    </tr>\n";

    if (length($record1) > 0) {
        undef @table;
        if (&l00httpd::l00freadOpen($ctrl, $path)) {
            $obuf = '';
            $found = 0;
            $id = 1;
            $lnno = 0;
            $keeplook = 1;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $lnno++;
                if (/^ *$/) {
                    next;
                }
                if (/^#/) {
                    $keeplook = 0;  # stop looking after #
                    next;
                }
                if (/$record1/) {
                    # found start of new record
                    if ($found) {
                        if ($lnno > $afterline) {
                            push (@table, &l00http_recedit_output_row($ctrl, $sock, $form, $line, $id, $obuf, $path, $editln));
                        }
                        $id++;
                    }
                    $found = 1;
                    $keeplook = 1;
                    $obuf = '';
                }
                if ($found && $keeplook) {
                    $obuf .= $_;
                    $editln = $lnno;
                }
            }
            if ($found) {
                if ($lnno > $afterline) {
                    push (@table, &l00http_recedit_output_row($ctrl, $sock, $form, $line, $id, $obuf, $path, $editln));
                }
            }
            close (IN);
        }
        # put an anchor at the last row of the table
        $ii = $#table + 1;
        foreach $_ (@table) {
            s/__end${ii}__/end/;
            print $sock $_;
        }
    }

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"U&#818;pdate\" accesskey=\"u\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"update\" value=\"R&#818;efresh\" accesskey=\"r\">\n";
    if (defined ($form->{'reminder'})) {
        $_ = 'checked';
    } else {
        $_ = '';
    }
    print $sock "                <input type=\"checkbox\" name=\"reminder\" $_>Enable reminder specific\n";
    print $sock "        <input type=\"submit\" name=\"chkall\" value=\"Chk A&#818;ll del\" accesskey=\"a\">\n";
    print $sock "    </td>\n";
    print $sock "    </tr>\n";


    print $sock "</table>\n";
    print $sock "</form>\n";


    if (&l00httpd::l00freadOpen($ctrl, $path)) {
        print $sock "<pre>";
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            print $sock "$_";
        }
        print $sock "</pre>\n";
    }
    

    # send HTML footer and ends
    # send HTML footer and ends
    if (defined ($ctrl->{'FOOT'})) {
        print $sock "$ctrl->{'FOOT'}\n";
    }
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
