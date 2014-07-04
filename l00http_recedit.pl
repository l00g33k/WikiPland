use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# edit notify and reminder

my %config = (proc => "l00http_recedit_proc",
              desc => "l00http_recedit_desc");
my $record1;
$record1 = '^\d{8,8} \d{6,6} ';

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
    my ($path, $obuf, $found, $line, $id, $output, $delete, $cmted);
    my ($yr, $mo, $da, $hr, $mi, $se, $tmp, $leading, $tmp2);

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
    print $sock "<a href=\"/recedit.htm\">recedit</a><p>\n";

    if (length($record1) == 0) {
        $record1 = '^\d{8,8} \d{6,6} ';
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
                    } else {
                        if (defined($form->{"id$id"}) && ($form->{"id$id"} eq 'on')) {
                            $delete = '#';
                        }
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
                if (defined($form->{"add$id"}) && ($form->{"add$id"} eq 'on')) {
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

    print $sock "<a href=\"/ls.htm?path=$path\">$path</a>:<p>";

    print $sock "<form action=\"/recedit.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Record 1:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"record1\" value=\"$record1\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Path:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Update\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"update\" value=\"Refresh\">\n";
    if (defined ($form->{'reminder'})) {
        $output = 'checked';
    } else {
        $output = '';
    }
    print $sock "                <input type=\"checkbox\" name=\"reminder\" $output>Enable reminder specific</td>\n";
    print $sock "    </tr>\n";

    if (length($record1) > 0) {
        if (&l00httpd::l00freadOpen($ctrl, $path)) {
            $obuf = '';
            $found = 0;
            $id = 1;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                if (/^ *$/) {
                    next;
                }
                if (/^#/) {
                    next;
                }
                if (/$record1/) {
                    if ($found) {
                        print $sock "    <tr>\n";
                        if (defined ($form->{'reminder'})) {
                            print $sock "        <td><input type=\"checkbox\" name=\"id$id\">delete<br>\n";
                            print $sock "            <input type=\"checkbox\" name=\"add$id\">+1 day</td>\n";
                            $obuf =~ s/(\d+:\d+:\d+:\d+:)/$1\n/;
                        } else {
                            print $sock "        <td><input type=\"checkbox\" name=\"id$id\">delete</td>\n";
                        }
                        print $sock "        <td><pre>";
                        foreach $line (split("\n", $obuf)) {
                            # notify specific
                            if ($line =~ /^MSG:(.+)/) {
                                # make link to copy to clipboard
                                $line = $1;
                                $tmp = $1;
                                $tmp =~ s/ /+/g;
                                $tmp =~ s/:/%3A/g;
                                $tmp =~ s/&/%26/g;
                                $tmp =~ s/=/%3D/g;
                                $tmp =~ s/"/%22/g;
                                $tmp =~ s/\//%2F/g;
                                $tmp =~ s/\|/%7C/g;
                                $line = "MSG:<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">".substr($line,0,30)."</a>";
                            }
                            if (($leading, $tmp) = $line =~ /^(\d+\/\d+\/\d+\+*\d*,\d+, *)(.+)/) {
                               # cal specific
                               $line = $tmp;
                               $tmp =~ s/ /+/g;
                               $tmp =~ s/:/%3A/g;
                               $tmp =~ s/&/%26/g;
                               $tmp =~ s/=/%3D/g;
                               $tmp =~ s/"/%22/g;
                               $tmp =~ s/\//%2F/g;
                               $tmp =~ s/\|/%7C/g;
                               $line = "$leading<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">".substr($line,0,30)."</a>";
                            }
                            if ($record1 eq '.') {
                               # drop leading date/time
                               $line =~ s/^\d{8,8} \d{6,6} //;
                               # match any specific
                               $tmp = $line;
                               $tmp =~ s/ /+/g;
                               $tmp =~ s/:/%3A/g;
                               $tmp =~ s/&/%26/g;
                               $tmp =~ s/=/%3D/g;
                               $tmp =~ s/"/%22/g;
                               $tmp =~ s/\//%2F/g;
                               $tmp =~ s/\|/%7C/g;
                               $line = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">".substr($line,0,30)."</a>";
                            }
                            print $sock "$line<br>";
                        }
                        print $sock "</pre></td>\n";
                        print $sock "    </tr>\n";
                        $id++;
                    }
                    $found = 1;
                    $obuf = '';
                }
                if ($found) {
                    #$obuf .= substr ($_, 0, 40);
                    $obuf .= $_;
                }
            }
            if ($found) {
                print $sock "    <tr>\n";
                if (defined ($form->{'reminder'})) {
                    print $sock "        <td><input type=\"checkbox\" name=\"id$id\">delete<br>\n";
                    print $sock "            <input type=\"checkbox\" name=\"add$id\">+ 1 day</td>\n";
                    $obuf=~ s/(\d+:\d+:\d+:\d+:)/$1\n/;
                } else {
                    print $sock "        <td><input type=\"checkbox\" name=\"id$id\">delete</td>\n";
                }
                print $sock "        <td><pre>";
                foreach $line (split("\n", $obuf)) {
                    # notify specific
                    if ($line =~ /^MSG:(.+)/) {
                        # make link to copy to clipboard
                        $line = $1;
                        $tmp = $1;
                        $tmp =~ s/ /+/g;
                        $tmp =~ s/:/%3A/g;
                        $tmp =~ s/&/%26/g;
                        $tmp =~ s/=/%3D/g;
                        $tmp =~ s/"/%22/g;
                        $tmp =~ s/\//%2F/g;
                        $tmp =~ s/\|/%7C/g;
                        $line = "MSG:<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">".substr($line,0,30)."</a>";
                    }
                    if (($leading, $tmp) = $line =~ /^(\d+\/\d+\/\d+\+*\d*,\d+, *)(.+)/) {
                        # cal specific
                        $line = $tmp;
                        $tmp =~ s/ /+/g;
                        $tmp =~ s/:/%3A/g;
                        $tmp =~ s/&/%26/g;
                        $tmp =~ s/=/%3D/g;
                        $tmp =~ s/"/%22/g;
                        $tmp =~ s/\//%2F/g;
                        $tmp =~ s/\|/%7C/g;
                        $line = "$leading<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">".substr($line,0,30)."</a>";
                    }
                    if ($record1 eq '.') {
                        # drop leading date/time
                        $line =~ s/^\d{8,8} \d{6,6} //;
                        # match any specific
                        $tmp = $line;
                        $tmp =~ s/ /+/g;
                        $tmp =~ s/:/%3A/g;
                        $tmp =~ s/&/%26/g;
                        $tmp =~ s/=/%3D/g;
                        $tmp =~ s/"/%22/g;
                        $tmp =~ s/\//%2F/g;
                        $tmp =~ s/\|/%7C/g;
                        $line = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">".substr($line,0,30)."</a>";
                    }
                    print $sock "$line<br>";
                }
                print $sock "</pre></td>\n";
                print $sock "    </tr>\n";
            }
            close (IN);
        }
    }

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
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
