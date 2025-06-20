use strict;
use warnings;
use l00backup;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# edit notify and reminder

my %config = (proc => "l00http_recedit_proc",
              desc => "l00http_recedit_desc");
my ($record1, $displen, $filter, $eval, $dueonly, $notdue);

$record1 = '^\d{8,8} \d{6,6} ';
$filter = '.';
$eval = '';
$displen = 50;
$dueonly = '';
$notdue = '';

sub l00http_recedit_dropseq {
    my ($aa, $bb);
    $aa = $a;
    $bb = $b;

    $aa =~ s/^\d+ //;
    $bb =~ s/^\d+ //;
    $aa = lc($aa);
    $bb = lc($bb);
    $aa cmp $bb;
}

sub l00http_recedit_output_row {
    my ($ctrl, $sock, $form, $line, $id, $obuf, $path, $lnno, $dispcnt) = @_;
    my ($tmp, $disp, $lf, $leading, $html, $color1, $color2, $chkalldel, $chkall16h, 
        $chkall1d, $chkallRB, $chkallnow, $chkallFB, $eval1);

    $html = '';

    # record before the current record was a hit, print
    $html .= "    <tr>\n";
    
    $chkalldel = '';
    if (defined ($form->{'chkall'})) {
        $chkalldel = 'checked';
    }
    $chkall16h = '';
    if (defined ($form->{'chkall16h'})) {
        $chkall16h = 'checked';
    }
    $chkall1d = '';
    if (defined ($form->{'chkall1d'})) {
        $chkall1d = 'checked';
    }
    $chkallRB = '';
    if (defined ($form->{'chkallRB'})) {
        $chkallRB = 'checked';
    }
    $chkallnow = '';
    if (defined ($form->{'chkallnow'})) {
        $chkallnow = 'checked';
    }
    $chkallFB = '';
    if (defined ($form->{'chkallFB'})) {
        $chkallFB = 'checked';
    }
    if (defined ($form->{'reminder'})) {
        # print reminder specific checkboxes
        $html .= "        <td><a name=\"__end${id}__\"></a>";
        if ($path =~ /^l00:\/\//) {
            # RAM file, 2, 1, 7 hours (or 4)
            $html .= "<font style=\"color:black;background-color:silver\">";
            $html .=                "<input type=\"checkbox\" name=\"add2h$id\"  $chkallRB>+4h</font>\n";
            $html .=             "\@0<input type=\"checkbox\" name=\"add0h$id\"  $chkallnow><br>\n";
            $html .=                "<input type=\"checkbox\" name=\"add16h$id\" $chkall16h>+1h\n";
            $html .= "<font style=\"color:black;background-color:silver\">";
            $html .=             "del<input type=\"checkbox\" name=\"id$id\" $chkalldel></font></td>\n";
        } else {
            # disk file, 1, 2 days
            $html .= "<font style=\"color:black;background-color:silver\">";
            $html .=                "<input type=\"checkbox\" name=\"add$id\"  $chkall1d>+1d</font><br>\n";
            $html .=             "+2d<input type=\"checkbox\" name=\"add2d$id\" $chkallFB><br>\n";
            $html .=                "<input type=\"checkbox\" name=\"id$id\" $chkalldel>del</td>\n";
        }
        $obuf =~ s/(\d+:\d+:\d+:\d+:)/$1\n/;
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
            # process eval
            if (length($eval) > 0) {
                foreach $eval1 (split(";;", $eval)) {
                    eval "\$line =~ $eval1";
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
    $html .= " - <a href=\"/edit.htm?path=$path&blklineno=$lnno\" target=\"_blank\">$lnno</a>.$dispcnt";
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
    my ($path, $found, $line, $id, $output, $delete, $cmted, $editln, $keeplook, $nowsort);
    my ($yr, $mo, $da, $hr, $mi, $se, $tmp, $tmp2, @table, $ii, $lnno, $afterline);
    my ($filter_found_true, $filtered, $cnt, $eval1, $now, $nowtime, @nowtime, $due, $nowcnt, $duecnt, $dispcnt);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
    } else {
        $path = "$ctrl->{'workdir'}l00_notify.txt";
    }

    if (defined ($form->{'filter'}) && (length($form->{'filter'}) > 0)) {
        $filter = $form->{'filter'};
    } else {
        $filter = '.';
    }

    if (defined ($form->{'eval'}) && (length($form->{'eval'}) > 0)) {
        $eval = $form->{'eval'};
    } else {
        $eval = '';
    }

    if (defined ($form->{'record1'})) {
        $record1 = $form->{'record1'};
    }

    if (defined ($form->{'update'})) {
        if (defined ($form->{'dueonly'})) {
            $dueonly = 'checked';
            $notdue = '';
        } else {
            $dueonly = '';
        }
    }
    if (defined ($form->{'update'})) {
        if (defined ($form->{'notdue'})) {
            $notdue = 'checked';
            $dueonly = '';
        } else {
            $notdue = '';
        }
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>recedit</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'homesml'} ";
    print $sock "$ctrl->{'HOME'} ";
    print $sock "<a href=\"#banner\">jump to banner</a> - \n";
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

    if ((defined ($form->{'submit'}) || defined ($form->{'nowplus'}) || defined ($form->{'nowplus1'}) || defined ($form->{'nowplus2'})) 
        && (length($record1) > 0)) {
        if (&l00httpd::l00freadOpen($ctrl, $path)) {
            $found = 0;
            $cmted = '';
            $output = '';
            $id = 1;
            $filter_found_true = 0;
            $cnt = 0;
            l00httpd::dbp($config{'desc'}, "SMT: $filter\n"), if ($ctrl->{'debug'} >= 3);
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $cnt++;
                # keeps blank or commented
                if (/^ *$/ || /^#/) {
                    $output .= "$_";
                    next;
                }
                $line = $_;
                # process eval
                if (length($eval) > 0) {
                    foreach $eval1 (split(";;", $eval)) {
                        l00httpd::dbp($config{'desc'}, "EVAL: $eval1\n"), if ($ctrl->{'debug'} >= 3);
                        l00httpd::dbp($config{'desc'}, "eval: $line"), if ($ctrl->{'debug'} >= 3);
                        eval "\$line =~ $eval1";
                        l00httpd::dbp($config{'desc'}, "eval' $line"), if ($ctrl->{'debug'} >= 3);
                    }
                }
                if (/$record1/) {
                    # found record starter
                    $delete = '';
                    if ($line =~ /$filter/) {
                        if (defined ($form->{'submit'})) {
                            if (defined($form->{"id$id"}) && ($form->{"id$id"} eq 'on')) {
                                if (defined($form->{"add0h$id"}) && ($form->{"add0h$id"} eq 'on')) {
                                    # both @0 and del checked, do =+4am instead
                                    $form->{"add0h$id"} = 'flag';
                                    $form->{"nowplus2"} = 'on';
                                } else {
                                    $_ = "#$_";
                                }
                            }
                        }
                        if (defined($form->{"nowplus"})) {
                            if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                #20130408 100000:10:0:60:copy hurom
                                $yr -= 1900;
                                $mo--;
                                # timestamp of the item
                                $tmp = l00httpd::now_string2time(substr ($_, 0, 15));
                                # timestamp now
                                $tmp2 = l00httpd::now_string2time($ctrl->{'now_string'});
                                if (($tmp2 + 5 * 60) > $tmp) {
                                    # if past, move to now + 5 min
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = localtime (time + 5 * 60 + int(($tmp - $tmp2) / 60));
#                               } else {
#                                   $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
#                                   $tmp += 5 * 60; # 5 min
#                                   ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
#                                   # if future, + 5 min
                                }
                                $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                     $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                     substr ($_, 15, 9999));
                            }
                        }
                        if (defined($form->{"nowplus1"})) {
                            if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                #20130408 100000:10:0:60:copy hurom
                                $yr -= 1900;
                                $mo--;
                                # timestamp of the item
                                $tmp = l00httpd::now_string2time(substr ($_, 0, 15));
                                # timestamp now
                                $tmp2 = l00httpd::now_string2time($ctrl->{'now_string'});
                                if (($tmp2 + 1 * 3600) > $tmp) {
                                    # if past, move to now + 5 min
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = localtime (time + 1 * 3600 + int(($tmp - $tmp2) / 60));
                                }
                                $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                     $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                     substr ($_, 15, 9999));
                            }
                        }
                        if (defined($form->{"nowplus2"})) {
                            if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                #20130408 100000:10:0:60:copy hurom
                                $yr -= 1900;
                                $mo--;
                                # timestamp of the item
                                $tmp = l00httpd::now_string2time(substr ($_, 0, 15));
                                # timestamp 23:00
                               #$tmp2 = l00httpd::now_string2time($ctrl->{'now_string'});
                                if ($ctrl->{'now_string'} lt substr($ctrl->{'now_string'}, 0, 9)."040000") {
                                    # if now is before 4am, set it to today 4am
                                    $tmp2 = l00httpd::now_string2time(substr($ctrl->{'now_string'}, 0, 9)."000000") + 3600 * 4;
                                } else {
                                    $tmp2 = l00httpd::now_string2time(substr($ctrl->{'now_string'}, 0, 9)."000000") + 3600 * 28;
                                }
                                if ($tmp2 > $tmp) {
                                    # if before tomorrow (or today) 4am, set to it
                                    $tmp = &l00httpd::time2now_string ($tmp2);
                                    ($yr, $mo, $da, $hr, $mi, $se) = $tmp =~ /^(....)(..)(..) (..)(..)(..)/;
                                    $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                         $yr, $mo, $da, $hr, $mi, $se,
                                         substr ($_, 15, 9999));

                                }
                            }
                            if (defined($form->{"add0h$id"}) && ($form->{"add0h$id"} eq 'flag')) {
                                # normally @0 and nowplus2 can't be set at the same time
                                # it is using as a special flag; now reset it
                                $form->{"nowplus2"} = undef;
                            }
                        }
                        if (defined ($form->{'submit'})) {
                            if (defined($form->{"add0h$id"}) && ($form->{"add0h$id"} eq 'on')) {
                                l00httpd::dbp($config{'desc'}, "smt:add0h$id $_"), if ($ctrl->{'debug'} >= 3);
                                # set to now
                                if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                    #20130408 100000:10:0:60:copy hurom
                                    $tmp = l00httpd::now_string2time ($ctrl->{'now_string'});
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                        $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                        substr ($_, 15, 9999));
                                } elsif (($yr, $mo, $da, $tmp2) = /^(\d+)\/(\d+)\/(\d+)(.*)$/) {
                                    #2013/4/11,1,411test 
                                    $tmp = l00httpd::now_string2time ($ctrl->{'now_string'});
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%d/%d/%d%s", 
                                        $yr + 1900, $mo + 1, $da, $tmp2);
                                }
                            }
                            if (defined($form->{"add2h$id"}) && ($form->{"add2h$id"} eq 'on')) {
                                l00httpd::dbp($config{'desc'}, "smt:add2h$id $_"), if ($ctrl->{'debug'} >= 3);
                                # add 4 hours
                                if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                    #20130408 100000:10:0:60:copy hurom
                                    $yr -= 1900;
                                    $mo--;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 4 * 3600; # add2h
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                        $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                        substr ($_, 15, 9999));
                                } elsif (($yr, $mo, $da, $tmp2) = /^(\d+)\/(\d+)\/(\d+)(.*)$/) {
                                    #2013/4/11,1,411test 
                                    $yr -= 1900;
                                    $mo--;
                                    $hr = 0;
                                    $mi = 0;
                                    $se = 0;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 4 * 3600; # add2h
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%d/%d/%d%s", 
                                        $yr + 1900, $mo + 1, $da, $tmp2);
                                }
                            }
                            if (defined($form->{"add16h$id"}) && ($form->{"add16h$id"} eq 'on')) {
                                if (defined($form->{"add2h$id"}) && ($form->{"add2h$id"} eq 'on')) {
                                    # if both checked, add another 4h for 8h total
                                    l00httpd::dbp($config{'desc'}, "smt:add2h$id $_"), if ($ctrl->{'debug'} >= 3);
                                    # add 4 hours
                                    if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                        #20130408 100000:10:0:60:copy hurom
                                        $yr -= 1900;
                                        $mo--;
                                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                        $tmp += 4 * 3600; # add2h
                                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                        $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                            $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                            substr ($_, 15, 9999));
                                    } elsif (($yr, $mo, $da, $tmp2) = /^(\d+)\/(\d+)\/(\d+)(.*)$/) {
                                        #2013/4/11,1,411test 
                                        $yr -= 1900;
                                        $mo--;
                                        $hr = 0;
                                        $mi = 0;
                                        $se = 0;
                                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                        $tmp += 4 * 3600; # add2h
                                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                        $_ = sprintf ("%d/%d/%d%s", 
                                            $yr + 1900, $mo + 1, $da, $tmp2);
                                    }
                                } else {
                                    l00httpd::dbp($config{'desc'}, "smt:add16h$id $_"), if ($ctrl->{'debug'} >= 3);
                                    # add 1 hours
                                    if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                        #20130408 100000:10:0:60:copy hurom
                                        $yr -= 1900;
                                        $mo--;
                                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                        $tmp += 1 * 3600; # add16h
                                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                        $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                            $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                            substr ($_, 15, 9999));
                                    } elsif (($yr, $mo, $da, $tmp2) = /^(\d+)\/(\d+)\/(\d+)(.*)$/) {
                                        #2013/4/11,1,411test 
                                        $yr -= 1900;
                                        $mo--;
                                        $hr = 0;
                                        $mi = 0;
                                        $se = 0;
                                        $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                        $tmp += 1 * 3600; # add16h
                                        ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                        $_ = sprintf ("%d/%d/%d%s", 
                                            $yr + 1900, $mo + 1, $da, $tmp2);
                                    }
                                }
                            }
                            if (defined($form->{"add4h$id"}) && ($form->{"add4h$id"} eq 'on')) {
                                l00httpd::dbp($config{'desc'}, "smt:add4h$id $_"), if ($ctrl->{'debug'} >= 3);
                                # add 4 hours
                                if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                    #20130408 100000:10:0:60:copy hurom
                                    $yr -= 1900;
                                    $mo--;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 4 * 3600; # add4h
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                        $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                        substr ($_, 15, 9999));
                                } elsif (($yr, $mo, $da, $tmp2) = /^(\d+)\/(\d+)\/(\d+)(.*)$/) {
                                    #2013/4/11,1,411test 
                                    $yr -= 1900;
                                    $mo--;
                                    $hr = 0;
                                    $mi = 0;
                                    $se = 0;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 4 * 3600; # add4h
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%d/%d/%d%s", 
                                        $yr + 1900, $mo + 1, $da, $tmp2);
                                }
                            }
                            if (defined($form->{"add2d$id"}) && ($form->{"add2d$id"} eq 'on')) {
                                l00httpd::dbp($config{'desc'}, "smt:add2d$id $_"), if ($ctrl->{'debug'} >= 3);
                                # add 48 hours
                                if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                    #20130408 100000:10:0:60:copy hurom
                                    $yr -= 1900;
                                    $mo--;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 48 * 3600; # add2d
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                        $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                        substr ($_, 15, 9999));
                                } elsif (($yr, $mo, $da, $tmp2) = /^(\d+)\/(\d+)\/(\d+)(.*)$/) {
                                    #2013/4/11,1,411test 
                                    $yr -= 1900;
                                    $mo--;
                                    $hr = 0;
                                    $mi = 0;
                                    $se = 0;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 48 * 3600; # add2d
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%d/%d/%d%s", 
                                        $yr + 1900, $mo + 1, $da, $tmp2);
                                }
                            }
                            if (defined($form->{"add$id"}) && ($form->{"add$id"} eq 'on')) {
                                l00httpd::dbp($config{'desc'}, "smt:add$id $_"), if ($ctrl->{'debug'} >= 3);
                                # add 1 day
                                if (($yr, $mo, $da, $hr, $mi, $se) = /^(....)(..)(..) (..)(..)(..)/) {
                                    #20130408 100000:10:0:60:copy hurom
                                    $yr -= 1900;
                                    $mo--;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 24 * 3600;
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%04d%02d%02d %02d%02d%02d%s", 
                                        $yr + 1900, $mo + 1, $da, $hr, $mi, $se, 
                                        substr ($_, 15, 9999));
                                } elsif (($yr, $mo, $da, $tmp2) = /^(\d+)\/(\d+)\/(\d+)(.*)$/) {
                                    #2013/4/11,1,411test 
                                    $yr -= 1900;
                                    $mo--;
                                    $hr = 0;
                                    $mi = 0;
                                    $se = 0;
                                    $tmp = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                                    $tmp += 24 * 3600;
                                    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($tmp);
                                    $_ = sprintf ("%d/%d/%d%s", 
                                        $yr + 1900, $mo + 1, $da, $tmp2);
                                }
                            }
                        }
                        $id++;
                    }
                }
                $output .= "$_";
            }

            &l00backup::backupfile ($ctrl, $path, 1, 5);
            if (&l00httpd::l00fwriteOpen($ctrl, $path)) {
                &l00httpd::l00fwriteBuf($ctrl, $output);
                &l00httpd::l00fwriteClose($ctrl);
            } else {
                print $sock "<p>Unable to save '$path'<p>\n";
            }
        }
    }

    $_ = '';
    if (defined($ctrl->{'receditextra'})) {
        $_ = $ctrl->{'receditextra'};
    }
    if (defined ($form->{'reminder'})) {
        print $sock "<a href=\"/ls.htm?path=l00://recedit_active.txt\" target=\"_blank\">(LIST</a> - ";
        print $sock "<a href=\"#recedit_active2\">time</a> - ";
        print $sock "<a href=\"#recedit_active\">here</a> - ";
        print $sock "<a href=\"#recedit_active_sort\">sort)</a> - ";
        print $sock "<a href=\"/ls.htm?path=l00://recedit_due.txt\" target=\"_blank\">DUE</a> - ";
    }
    print $sock "<a name=\"_top_\"></a><a href=\"/ls.htm?path=$path$_\">$path</a> - ";
    print $sock "<a href=\"/view.htm?path=$path\">vw</a>";
    if (defined ($form->{'reminder'})) {
        print $sock " - <a href=\"/reminder.htm?path=$path\">rem</a>";
    }
    print $sock "<p>";

    print $sock "<form action=\"/recedit.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    if (defined ($form->{'reminder'})) {
        print $sock "        <td style=\"vertical-align:top\"><input type=\"submit\" name=\"submit\" value=\"U&#818;pdate\" accesskey=\"u\"><p>\n";
        print $sock "            <input type=\"submit\" name=\"update\" value=\"R&#818;efresh\" accesskey=\"r\"></td>\n";
        print $sock "        <td>\n";
    } else {
        print $sock "        <td style=\"vertical-align:top\"><input type=\"submit\" name=\"submit\" value=\"U&#818;pdate\" accesskey=\"u\"></td>\n";
        print $sock "        <td>\n";
    }
    print $sock "        <input type=\"submit\" name=\"chkall\" value=\"a&#818;Del\" accesskey=\"a\">\n";
    if (defined ($form->{'reminder'})) {
        if ($path =~ /^l00:\/\//) {
            print $sock "        <input type=\"submit\" name=\"chkall16h\" value=\"1h&#818;\" accesskey=\"h\">\n";
        } else {
            print $sock "        <input type=\"submit\" name=\"chkall1d\" value=\"1d&#818;\" accesskey=\"d\">\n";
        }
    }
    if (defined ($form->{'reminder'})) {
        if ($path =~ /^l00:\/\//) {
            print $sock "        <input type=\"submit\" name=\"chkallRB\" value=\"4 h&#818;\" accesskey=\"h\">\n";
            print $sock "        <input type=\"submit\" name=\"nowplus\" value=\"+5m\"><p>\n";
            print $sock "        <input type=\"submit\" name=\"nowplus1\" value=\"+1h\">\n";
            print $sock "        <input type=\"submit\" name=\"nowplus2\" value=\"=4+\">\n";
            print $sock "        <input type=\"submit\" name=\"chkallnow\" value=\"\@0\"><p>\n";
        } else {
            print $sock "        <input type=\"submit\" name=\"chkallFB\" value=\"2d&#818;\" accesskey=\"d\"><p>\n";
        }
        print $sock "                <input type=\"checkbox\" name=\"dueonly\" accesskey=\"d\" $dueonly>d&#818;ue\n";
        print $sock "                <input type=\"checkbox\" name=\"notdue\" accesskey=\"n\" $notdue>n&#818;ot\n";
    } else {
        print $sock "            <input type=\"submit\" name=\"update\" value=\"R&#818;efresh\" accesskey=\"r\">\n";
    }
    if (defined ($form->{'reminder'})) {
        $_ = 'checked';
    } else {
        $_ = '';
    }
    print $sock "                <input type=\"checkbox\" name=\"reminder\" $_>Enable reminder specific\n";
    print $sock "    </td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Path:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"></td>\n";
    print $sock "        </tr>\n";
                                                
    if (length($record1) > 0) {
        undef @table;
        $now = "<pre>\n";
        undef @nowtime;
        $due = "<pre>\n";
        $nowcnt = 0;
        $duecnt = 0;
        if (&l00httpd::l00freadOpen($ctrl, $path)) {
            $id = 1;
            $lnno = 0;
            $filtered = '';
            $dispcnt = 1;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $lnno++;
                if (/^ *$/ || /^#/) {
                    $filtered .= $_;
                    next;
                }
                $line = $_;
                # process eval
                if (length($eval) > 0) {
                    foreach $eval1 (split(";;", $eval)) {
                        l00httpd::dbp($config{'desc'}, "EVAL: $eval1\n"), if ($ctrl->{'debug'} >= 3);
                        l00httpd::dbp($config{'desc'}, "eval: $line"), if ($ctrl->{'debug'} >= 3);
                        eval "\$line =~ $eval1";
                        l00httpd::dbp($config{'desc'}, "eval' $line"), if ($ctrl->{'debug'} >= 3);
                    }
                }
                if (/$record1/) {
                    # found start of new record
                    l00httpd::dbp($config{'desc'}, "FIL: $filter\n"), if ($ctrl->{'debug'} >= 3);
                    if ($line =~ /$filter/) {
                        l00httpd::dbp($config{'desc'}, "HIT: $line"), if ($ctrl->{'debug'} >= 3);
                        if ($lnno > $afterline) {
                            $filtered .= $_;
                            $nowcnt++;
                            $tmp = $_;
                            push(@nowtime, $tmp);
                            $tmp =~ s/^\d+ \d+:\d+:\d+:\d+://;
                            $now .= sprintf("%03d %s", $nowcnt, $tmp);
                            # make due list with past due items
                            if (defined ($form->{'reminder'})) {
                                if ($line =~ /^(\d{8,8} \d{6,6}):\d+/) {
                                    if ($1 lt $ctrl->{'now_string'}) {
                                        $duecnt++;
                                        $due .= sprintf("%03d %s", $duecnt, $_);
                                    }
                                }
                                if ($dueonly eq 'checked') {
                                    if ($line =~ /^(\d{8,8} \d{6,6}):\d+/) {
                                        if ($1 lt $ctrl->{'now_string'}) {
                                            push (@table, &l00http_recedit_output_row($ctrl, $sock, $form, $line, $id, $_, $path, $lnno, $dispcnt++));
                                        }
                                    }
                                } elsif ($notdue eq 'checked') {
                                    if ($line =~ /^(\d{8,8} \d{6,6}):\d+/) {
                                        if ($1 gt $ctrl->{'now_string'}) {
                                            push (@table, &l00http_recedit_output_row($ctrl, $sock, $form, $line, $id, $_, $path, $lnno, $dispcnt++));
                                        }
                                    }
                                } else {
                                    push (@table, &l00http_recedit_output_row($ctrl, $sock, $form, $line, $id, $_, $path, $lnno, $dispcnt++));
                                }
                            } else {
                                push (@table, &l00http_recedit_output_row($ctrl, $sock, $form, $line, $id, $_, $path, $lnno, $dispcnt++));
                            }
                            $id++;
                        }
                    } else {
                        l00httpd::dbp($config{'desc'}, "mis: $_"), if ($ctrl->{'debug'} >= 3);
                    }
                } else {
                    $filtered .= $_;
                }
            }
        }
        # put an anchor at the last row of the table
        $ii = $#table + 1;
        foreach $_ (@table) {
            s/__end${ii}__/end/;
            print $sock $_;
        }

        $now .= "</pre>\n";
        $nowtime = "<pre>\n";
        $nowcnt = 0;
        foreach $tmp (sort(@nowtime)) {
            $nowcnt++;
            $nowtime .= sprintf("%03d %s", $nowcnt, $tmp);
        }
        $nowtime .= "</pre>\n";
        $due .= "</pre>\n";

        # sort $now to $nowsort
        $nowsort = "<pre>\n";
        $nowcnt = 0;

        foreach $tmp (sort l00http_recedit_dropseq split("\n", $now)) {
            if ($tmp =~ /^<\/*pre>/) {
                next;
            }
            $nowcnt++;
            # drop leading sequence #
            $tmp =~ s/^\d+ //;
            $nowsort .= sprintf("%03d %s\n", $nowcnt, $tmp);
        }
        $nowsort .= "</pre>\n";

		&l00httpd::l00fwriteOpen($ctrl, "l00://recedit_due.txt");
        &l00httpd::l00fwriteBuf($ctrl, $due);
		&l00httpd::l00fwriteClose($ctrl);

		&l00httpd::l00fwriteOpen($ctrl, "l00://recedit_active.txt");
        &l00httpd::l00fwriteBuf($ctrl, $now);
		&l00httpd::l00fwriteClose($ctrl);

		&l00httpd::l00fwriteOpen($ctrl, "l00://recedit_filtered.txt");
		&l00httpd::l00fwriteBuf($ctrl, "filtered\n");
		&l00httpd::l00fwriteBuf($ctrl, $filtered);
		&l00httpd::l00fwriteClose($ctrl);
    }

    print $sock "    <tr>\n";
    print $sock "        <td style=\"vertical-align:top\"><input type=\"submit\" name=\"submit\" value=\"Update\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"update\" value=\"Refresh\">\n";
    if (defined ($form->{'reminder'})) {
        $_ = 'checked';
    } else {
        $_ = '';
    }
    print $sock "                <input type=\"checkbox\" name=\"reminder\" $_>Enable reminder specific\n";
    print $sock "        <input type=\"submit\" name=\"chkall\" value=\"Chk All del\">\n";
    print $sock "    </td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Record 1:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"record1\" value=\"$record1\">.".
                                " After line: <input type=\"text\" size=\"4\" name=\"afterline\" value=\"$afterline\">.".
                                " Max len: <input type=\"text\" size=\"4\" name=\"displen\" value=\"$displen\">.".
                                "</td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>F&#818;ilter:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"filter\" value=\"$filter\" accesskey=\"f\">";
    if ($filter eq '.') {
        print $sock "        </td>\n";
    } else {
        print $sock "        - <a href=\"/ls.htm?path=l00://recedit_filtered.txt\">filtered</a></td>\n";
    }
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>E&#818;val:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"eval\" value=\"$eval\" accesskey=\"e\"></td>\n";
    print $sock "        </tr>\n";
                                                

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<p><a name=\"recedit_active\"></a>Past due: <a href=\"#_top_\">(jump to top)</a><br>\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $now, 0);
    print $sock "<p>\n";
    print $sock "<a href=\"#_top_\">(jump to top)</a><br>\n";

    print $sock "<p><a name=\"recedit_active_sort\"></a>Past due sorted: <a href=\"#_top_\">(jump to top)</a><br>\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $nowsort, 0);
    print $sock "<p>\n";
    print $sock "<a href=\"#_top_\">(jump to top)</a><br>\n";

    print $sock "<p><a name=\"recedit_active2\"></a>Past due with time: <a href=\"#_top_\">(jump to top)</a><br>\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $nowtime, 0);
    print $sock "<p>\n";
    print $sock "<a href=\"#_top_\">(jump to top)</a><br>\n";

    print $sock "<p><a name=\"banner\"></a>$ctrl->{'home'}<p>";

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
