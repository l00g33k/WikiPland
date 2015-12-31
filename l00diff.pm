# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;

package l00diff;

our (@diffout, @OLD, @NEW, $OC, $NC, $OLNO, $NLNO, @OA, @NA, %SYMBOL);


sub l00http_diff_make_outline {
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


sub l00http_diff_output {
    my ($width, $oldfile, $newfile, $hide, $maxline, $debug) = @_;
    my ($ln, $jj, $oii, $nii, $nfor, $nptr, $hiding, $hiding2);
    my ($lastold, $oldFromNew, $oout, $nout, $ospc, $out, $debugbuf);
    my ($blocksize, $blockstart, $mxblocksize, $mxblockstart, $firstnew);
    my ($outlinks, $deleted, $added, $moved, $same, $lastact, $firstact, $anchor);
    my ($mxblockstartNew);

    # find first non added lines in NEW
    $firstnew = -1;
    for ($nii = 0; $nii <= $#NEW; $nii++) {
        if ($NA[$nii] < 0) {
            # an added line, skip it
            next;
        }
        $firstnew = $nii;
        last;
    }

    # find largest same block and start location
    $lastold = -1;
    $blocksize = 1;
    $mxblocksize = -1;
    $debugbuf = '';
    for ($oii = 0; $oii <= $#OLD; $oii++) {
        if ($OA[$oii] < 0) {
            # a deleted line, skip it
            next;
        }
        # not a deleted line so there is a match in NEW
        if (($lastold == -1) ||  # first line is a start of a block
            ($OA[$oii] == $firstnew)) {     # the same line as the first line in NEW
            if ($lastold == -1) {
                $blockstart = $oii;
                if ($debug >= 3) {
                    l00httpd::dbp('l00diff.pm', "first same in old: blockstart $blockstart\n");
                }
            }
            if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
                # end of last block counting, record max
                $mxblocksize  = $blocksize;
                $mxblockstart = $blockstart;
            }
            if ($debug >= 3) {
                $debugbuf .= "blocksize A $blocksize @ $blockstart\n";
                l00httpd::dbp('l00diff.pm', $debugbuf);
                $debugbuf = 'nw bk 1 ';
            }
            # start new block count
            $blocksize = 1;
            $blockstart = $oii;
        } else {
            # we are counting more line in the same block
            $oldFromNew = -1;
            for ($nii = $OA[$oii] - 1; $nii >= 0; $nii--) {
                if ($NA[$nii] < 0) {
                    # added lines
                    next;
                }
                $oldFromNew = $NA[$nii];
                last;
            }
            if ($lastold != $oldFromNew) {
                if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
                    $mxblocksize  = $blocksize;
                    $mxblockstart = $blockstart;
                }
                if ($debug >= 3) {
                    $debugbuf .= "blocksize B $blocksize @ $blockstart\n";
                    l00httpd::dbp('l00diff.pm', $debugbuf);
                    $debugbuf = 'nw bk 2 ';
                }
                $blocksize = 1;
                $blockstart = $oii;
            } else {
                if ($debug >= 3) {
                    $debugbuf .= '        ';
                }
                $blocksize++;
            }
        }
        $lastold = $oii; # old file last 'same' line number
        if ($debug >= 3) {
            $debugbuf .= "oii $oii -> $OA[$oii]\n";
            l00httpd::dbp('l00diff.pm', $debugbuf);
            $debugbuf = '';
        }
    }
    if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
        $mxblocksize  = $blocksize;
        $mxblockstart = $blockstart;
    }
    if ($debug >= 3) {
        l00httpd::dbp('l00diff.pm', "blocksize C $blocksize @ $blockstart\n");
        l00httpd::dbp('l00diff.pm', "mxblocksize $mxblocksize @ $mxblockstart\n");
    }



    $oii = $mxblockstart;
    $nii = $OA[$oii];
    $mxblockstartNew = $nii;

    undef @diffout;
    $outlinks = '';

    # collect statistics
    $deleted = 0;
    $added = 0;
    $moved = 0;
    $same = 0;
    $lastact = '';
    $firstact = '';
    $anchor = 1;

    # print forward of largest matched block
    $hiding = 0;
    $hiding2 = 0;
    while (($oii <= $#OLD) || ($nii <= $#NEW)) {
        $hiding++;
        # prepare outputs
        ($oout, $nout, $ospc) = &l00http_diff_make_outline($oii, $nii, $width, $oldfile, $newfile);
        # print deleted
        if (($oii <= $#OLD) && ($OA[$oii] < 0)) {
            if ($lastact ne '<') {
                $lastact = '<';
                # make link to changes
                $_ = $oii + 1;
                $outlinks .= "<a href=\"#change$anchor\">delete($_)</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }

            push (@diffout, " $oout &lt;\n");
            $oii++;
            $deleted++;
            next;
        }
        # print added
        if (($nii <= $#NEW) && ($NA[$nii] < 0)) {
            if ($lastact ne '>') {
                $lastact = '>';
                # make link to changes
                $_ = $nii + 1;
                $outlinks .= "<a href=\"#change$anchor\">add[$_]</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }

            push (@diffout, " $ospc &gt;$nout\n");
            $nii++;
            $added++;
            next;
        }
        # print identical
        if (($oii <= $#OLD) && ($nii <= $#NEW) && ($OA[$oii] == $nii)) {
            if ($hide ne 'checked') {
                # print if not hiding
                if ($lastact ne '=') {
                    # make link to changes
                    $_ = $nii + 1;
                    $outlinks .= "<a href=\"#change$anchor\">same[$_]</a> ";
                    push (@diffout, "<a name=\"change$anchor\"></a>");
                    $anchor++;
                }
                push (@diffout, " $oout =$nout\n");
            } else {
                # print a note about hidden lines
                $hiding2++;
                if ($hiding2 != $hiding) {
                    $hiding2 = $hiding;
                    push (@diffout, sprintf ("%-${width}s%-${width}s--- same omitted ---\n", '-'x$width, '-'x$width));
                }
            }
            $lastact = '=';
            if ($firstact eq '') {
                $firstact = $lastact;
            }
            $oii++;
            $nii++;
            $same++;
            next;
        }
        # print moved block in NEW
        if ($NA[$nii] < $oii) {
            if ($lastact ne '[') {
                $lastact = '[';
                # make link to changes
                $_ = $nii + 1;
                $outlinks .= "<a href=\"#change$anchor\">move[$_]</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }
            $_ = sprintf ("(%d)", $NA[$nii] + 1);
            substr ($ospc, length ($ospc) - length ($_), length ($_)) = $_;
            push (@diffout, " $ospc [$nout\n");
            $nii++;
            $moved++;
            next;
        }
        # print moved block in OLD
        if ($OA[$oii] < $nii) {
            if ($lastact ne ']') {
                $lastact = ']';
                # make link to changes
                $_ = $oii + 1;
                $outlinks .= "<a href=\"#change$anchor\">move($_)</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }
            push (@diffout, sprintf (" %s ] (%d)\n", $oout, $OA[$oii] + 1));
            $oii++;
            next;
        }

        # fail safe
        if ($oii < $#OLD) {
            $oii++;
        }
        if ($nii < $#NEW) {
            $nii++;
        }
    }

    $oii = $mxblockstart - 1;
    $nii = $mxblockstartNew - 1;

    if ($debug >= 3) {
        l00httpd::dbp('l00diff.pm', "list backward from start of largest block\n");
        l00httpd::dbp('l00diff.pm', "oii $oii nii $nii\n");
    }

    # print backward from largest matched block
    $hiding = 0;
    $hiding2 = 0;
    $lastact = $firstact;
    #$outlinks = "backward debug " . $outlinks;

    while (($oii >= 0) && ($nii >= 0)) {
        $hiding++;
        # prepare outputs
        ($oout, $nout, $ospc) = &l00http_diff_make_outline($oii, $nii, $width, $oldfile, $newfile);
        # print deleted
        if (($oii >= 0) && ($OA[$oii] < 0)) {
            if ($lastact ne '<') {
                # make link to changes
                if ($lastact eq '>') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">1same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq ']') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '[') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = '<';
            }

            unshift (@diffout, " $oout &lt;\n");
            $oii--;
            $deleted++;
            next;
        }
        # print added
        if (($nii >= 0) && ($NA[$nii] < 0)) {
            if ($lastact ne '>') {
                # make link to changes
                if ($lastact eq '<') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">2same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '[') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq ']') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = '>';
            }

            unshift (@diffout, " $ospc &gt;$nout\n");
            $nii--;
            $added++;
            next;
        }
        # print identical
        if (($oii >= 0) && ($nii >= 0) && ($OA[$oii] == $nii)) {
            if ($hide ne 'checked') {
                # print if not hiding
                if ($lastact ne '=') {
                    # make link to changes
                    if ($lastact eq '>') {
                        if ($nii >= 0) {
                            $_ = $nii + 2;
                            $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                        }
                    } elsif ($lastact eq '<') {
                        if ($oii >= 0) {
                            $_ = $oii + 2;
                            $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                        }
                    } elsif ($lastact eq '[') {
                        if ($nii >= 0) {
                            $_ = $nii + 2;
                            $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                        }
                    } elsif ($lastact eq ']') {
                        if ($oii >= 0) {
                            $_ = $oii + 2;
                            $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                        }
                    }
                    unshift (@diffout, "<a name=\"change$anchor\"></a>");
                    $anchor++;
                    $lastact = '=';
                }

                unshift (@diffout, " $oout =$nout\n");
            } else {
                # print a note about hidden lines
                $hiding2++;
                if ($hiding2 != $hiding) {
                    $hiding2 = $hiding;
                    push (@diffout, sprintf ("%-${width}s%-${width}s--- same omitted ---\n", '-'x$width, '-'x$width));
                }
            }
            $lastact = '=';

            $oii--;
            $nii--;
            $same++;
            next;
        }
        # print moved block in NEW
        if ($NA[$nii] < $oii) {
            if ($lastact ne '[') {
                # make link to changes
                if ($lastact eq '>') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '<') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">3same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq ']') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = '[';
            }

            $_ = sprintf ("(%d)", $NA[$nii] + 1);
            substr ($ospc, length ($ospc) - length ($_), length ($_)) = $_;
            unshift (@diffout, " $ospc [$nout\n");
            $nii--;
            $moved++;
            next;
        }
        # print moved block in OLD
        if ($OA[$oii] > $nii) {
            if ($lastact ne ']') {
                # make link to changes
                if ($lastact eq '>') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '<') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">4same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '[') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = ']';
            }

            unshift (@diffout, sprintf (" %s ] (%d)\n", $oout, $OA[$oii] + 1));
            $oii--;
            next;
        }

        # fail safe
        if ($oii < 0) {
            $oii--;
        }
        if ($nii > 0) {
            $nii--;
        }
    }

    $outlinks = sprintf ("Deleted %4d lines\n" .
                         "Added   %4d lines\n" . 
                         "Moved   %4d lines\n" . 
                         "Same    %4d lines\n", 
                         $deleted, $added, $moved, $same) . 
                "</pre>Links to modified blocks, (old line#), [new line#]: " . $outlinks . "<pre>\n";

    $out = '';
    for ($ln = 0; $ln <= $#diffout; $ln++) {
        $out .= $diffout [$ln];
        if ($ln >= $maxline) {
            last;
        }
    }
    $outlinks . $out;
}

sub l00http_diff_compare {
    my ($ctrl, $sock, $width, $oldfile, $newfile, $hide, $maxline, $debug) = @_;
    my ($ln, $jj, $oii, $nii, $out, $nfor, $nptr);
    my ($text, $mode, $cnt, $debugbuf, $htmlout);

    $htmlout = '';
    $htmlout .= "<pre>\n";


    # A technique for isolating differences between files
    # Paul Heckel
    # http://documents.scribd.com/docs/10ro9oowpo1h81pgh1as.pdf

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

    #for ($ln = 0; $ln <= $#OLD; $ln++) {
    #    $htmlout .= "$ln: <  $OLD[$ln]\n";
    #}
    #for ($ln = 0; $ln <= $#NEW; $ln++) {
    #    $htmlout .= "$ln:  > $NEW[$ln]\n";
    #}


    # Index to $SYMBOL
    $OC   = 0;
    $NC   = 1;
    $OLNO = 2;
    $NLNO = 3;

    # Symbol table:
    # $SYMBOL{$text}[$OC]: Old counter: number of occurance of $text in OLD file
    # $SYMBOL{$text}[$NC]: New counter: number of occurance of $text in NEW file
    # $SYMBOL{$text}[$OLNO]: OLD file line number for $text
    # $SYMBOL{$text}[$NLNO]: NEW file line number for $text

    # OA: Old Array
    # $OA[$ln]: if >= 0: NEW file line number of unique and identical $text as $OLD[$ln]
    #           if == -1: all other cases

    # NA: New Array
    # $NA[$ln]: if >= 0: OLD file line number of unique and identical $text as $NEW[$ln]
    #           if == -1: all other cases

    undef %SYMBOL;
    # Pass 1
    if ($debug >= 1) {
        l00httpd::dbp('l00diff.pm', "Pass 1: Fill SYMBOL table with OLD file content\n");
    }
    for ($ln = 0; $ln <= $#OLD; $ln++) {
        # Examining current line $OLD[$ln]
        # Set OA old array (-1) to point to symbol table (by $SYMBOL{$OLD[$ln]})
        $OA[$ln] = -1;
        # update SYMBOL table
        if (!defined($SYMBOL{$OLD[$ln]})) {
            # Current line has not been seen before
            # Initialize symbol table to: 
            #   OC = 1
            #   NC = 0      # we haven't process NEW file so it must be zero
            #   OLNO = $ln  # current line is line $ln in OLD file
            $SYMBOL{$OLD[$ln]}[$OC] = 1;
            $SYMBOL{$OLD[$ln]}[$NC] = 0;
            $SYMBOL{$OLD[$ln]}[$OLNO] = $ln;
            $SYMBOL{$OLD[$ln]}[$NLNO] = -1;
        } else {
            $SYMBOL{$OLD[$ln]}[$OC]++;
            # as $oc > 1, OLNO is not meaningful
            $SYMBOL{$OLD[$ln]}[$OLNO] = -1;
        }
    }
    if ($debug >= 5) {
        for ($ln = 0; $ln <= $#OLD; $ln++) {
            l00httpd::dbp('l00diff.pm', "$ln: OC $SYMBOL{$OLD[$ln]}[$OC] OLNO $SYMBOL{$OLD[$ln]}[$OLNO] >$OLD[$ln]<\n");
        }
    }


    # Pass 2
    if ($debug >= 1) {
        l00httpd::dbp('l00diff.pm', "Pass 2: Fill SYMBOL table with NEW file content\n");
    }
    for ($ln = 0; $ln <= $#NEW; $ln++) {
        # Examining current line $NEW[$ln]
        # Set NA new array (-1) to point to symbol table (by $SYMBOL{$NEW[$ln]})
        $NA[$ln] = -1;
        # update SYMBOL table
        if (!defined($SYMBOL{$NEW[$ln]})) {
            # Current line has not been seen before
            # Initialize symbol table to: 
            #   OC = 1
            #   NC = 0      # we haven't process NEW file so it must be zero
            #   OLNO = $ln  # current line is line $ln in OLD file
            $SYMBOL{$NEW[$ln]}[$OC] = 0;
            $SYMBOL{$NEW[$ln]}[$NC] = 1;
            $SYMBOL{$NEW[$ln]}[$OLNO] = -2; # not relavent for NEW file
            $SYMBOL{$NEW[$ln]}[$NLNO] = $ln;
        } else {
            $SYMBOL{$NEW[$ln]}[$NC]++;
            if ($SYMBOL{$NEW[$ln]}[$NC] == 1) {
                # as $nc == 1, NLNO is NEW file line number
                $SYMBOL{$NEW[$ln]}[$NLNO] = $ln;
            } else {
                # as $nc > 1, NLNO is not meaningful
                $SYMBOL{$NEW[$ln]}[$NLNO] = -1;
            }
        }
    }
    if ($debug >= 5) {
        for ($ln = 0; $ln <= $#NEW; $ln++) {
            l00httpd::dbp('l00diff.pm', "$ln: NC $SYMBOL{$NEW[$ln]}[$NC] >$NEW[$ln]<\n");
        }
    }


    # Pass 3
    if ($debug >= 1) {
        l00httpd::dbp('l00diff.pm', "Pass 3: Establish match for unique lines\n");
    }
    foreach $text (keys %SYMBOL) {
        if (($SYMBOL{$text}[$OC] == 1) &&
            ($SYMBOL{$text}[$NC] == 1)) {
            # NA NEW array points to OLNO OLD line number
            $NA[$SYMBOL{$text}[$NLNO]] = $SYMBOL{$text}[$OLNO];
            # OA OLD array points to NLNO NEW line number
            $OA[$SYMBOL{$text}[$OLNO]] = $SYMBOL{$text}[$NLNO];
            if ($debug >= 5) {
                l00httpd::dbp('l00diff.pm', "NA $NA[$SYMBOL{$text}[$NLNO]] OA $OA[$SYMBOL{$text}[$OLNO]] >$text<\n");
            }
        }
    }

    # Pass 4
    if ($debug >= 1) {
        l00httpd::dbp('l00diff.pm', "Pass 4: Match non unique lines by context going forward\n");
    }
    for ($ln = 0; $ln < $#NEW; $ln++) { # skip last line which has no next
        # $ln is new line number
        # $jj is matching old line number
        $jj = $NA[$ln];
        if ($jj >= 0) {
            # There is a matching line in OLD file
            # Are the next lines in each matching?
            if ((defined($NEW[$ln + 1])) &&
                (defined($OLD[$jj + 1])) &&
                ($NEW[$ln + 1] eq $OLD[$jj + 1]) &&
                ($OA[$jj + 1] < 0) &&
                ($NA[$ln + 1] < 0)) {
                # yes
                $OA[$jj + 1] = $ln + 1;
                $NA[$ln + 1] = $jj + 1;
                if ($debug >= 5) {
                    $debugbuf = printf ("NA %d OA %d >%s<\n", $jj + 1, $ln + 1, $NEW[$ln + 1]);
                    l00httpd::dbp('l00diff.pm', $debugbuf);
                }
            }
        }
    }


    # Pass 5
    if ($debug >= 1) {
        l00httpd::dbp('l00diff.pm', "Pass 5: Match non unique lines by context going backword\n");
    }
    for ($ln = $#NEW; $ln > 0; $ln--) { # skip first line which has no previous
        # $ln is new line number
        # $jj is matching old line number
        $jj = $NA[$ln];
        if ($jj >= 0) {
            # There is a matching line in OLD file
            # Are the next lines in each matching?
            if (($NEW[$ln + 1] eq $OLD[$jj - 1]) &&
                ($OA[$jj - 1] < 0) &&
                ($NA[$ln - 1] < 0)) {
                # yes
                $OA[$jj - 1] = $ln - 1;
                $NA[$ln - 1] = $jj - 1;
                if ($debug >= 5) {
                    $debugbuf = printf ("NA %d OA %s >%s<\n", $jj - 1, $ln - 1, $NEW[$ln - 1]);
                    l00httpd::dbp('l00diff.pm', $debugbuf);
                }
            }
        }
    }

    # Pass 6
    if ($debug >= 1) {
        l00httpd::dbp('l00diff.pm', "Pass 6: Output results\n");
        $oii = 0;
        $nii = 0;
        $out = '';
        while (($oii <= $#OLD) || ($nii <= $#NEW)) {
            if ($oii <= $#OLD) {
                $_ = sprintf ("%3d: OA(%3d) %-${width}s", $oii + 1, substr($OA[$oii],0,$width), substr($OLD[$oii],0,$width));
                $oii++;
            } else {
                $_ = sprintf ("%3d: OA(%3d) %${width}s", $oii + 1, 0, ' ');
                s/./ /g;
            }
            $out .= $_;
            if ($nii <= $#NEW) {
                $_ = sprintf ("%3d: NA(%3d) %-${width}s", $nii + 1, substr($NA[$nii],0,$width), substr($NEW[$nii],0,$width));
                $nii++;
            } else {
                $_ = sprintf ("%3d: NA(%3d) %${width}s", $nii + 1, 0, ' ');
                s/./ /g;
            }
            $out .= $_;
            $out .= "\n";
        }
        foreach $_ (split ("\n", $out)) {
            l00httpd::dbp('l00diff.pm', "$_\n");
        }

        l00httpd::dbp('l00diff.pm', "--------------------------\n");

        $oii = 0;
        $nii = 0;
        $nfor = 0;
        $nptr = 0;
        while (($oii <= $#OLD) || ($nii <= $#NEW)) {
            # deleted
            if (($oii <= $#OLD) && ($OA[$oii] < 0)) {
                $oii++;
                next;
            }
            # added
            if (($nii <= $#NEW) && ($NA[$nii] < 0)) {
                $nii++;
                next;
            }
            # not deleted nor added, i.e. same or moved
            if (($oii <= $#OLD) && ($nii <= $#NEW)) {
                if ($OA[$oii] >= $nii) {
                    # 
                }
                $oii++;
                $nii++;
                next;
            }
            # OLD and NEW points to different lines
            # count OLD pointing forward

            $oii++;
            $nii++;
        }
    }

    $htmlout .= &l00http_diff_output ($width, $oldfile, $newfile, 
        $hide, $maxline, $debug);

    $htmlout .= "</pre>\n";

    $htmlout;
}

1;
