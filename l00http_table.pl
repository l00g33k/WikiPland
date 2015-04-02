use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Converting tab delimited data (e.g. copied from Excel)
# and making constant width for easy viewing with fixed
# width font (e.g. vi of programmer's editor)

my %config = (proc => "l00http_table_proc",
              desc => "l00http_table_desc");
my ($buffer, $pre, $tblhdr, $tbl, $post, @width, @cols, $ii);
my (@modcmds, $modadd, $modcopy, $moddel, $modrow, $mod, $modtab);
my ($exelog, $nocols, $norows, @rows, @keys, @order, $nolist);
my (@allkeys, $sortdebug, @tblbdy, $tblfilorg, $sortkeys);

$modadd  = "Add new column at A";
$moddel  = "Delete column A";;
$modcopy = "Copy column A to B";
$modrow  = "Append A empty row";
$modtab  = "Display tabs";
@modcmds = ("Reload from file", $modadd, $moddel, $modcopy, $modrow, $modtab);
$tblfilorg ='';
$sortkeys = '';
$nolist = '';

sub l00http_table_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "table: Tab to table converter";
}


#print "key$ii cols $cols[$ii] 
#order $order[$ii] key $keys[$ii]\n";
sub tablesort {
    my ($ret, $idx, @acols, @bcols, $tmp, $aval, $bval);

    $ret = 0;
    ($tmp, @acols) = split ('\|\|', $a);
    ($tmp, @bcols) = split ('\|\|', $b);
 
    if ($sortdebug >= 5) {
        print "sorting a>$a<\n";
        print "sorting b>$b<\n";
    }
    for ($idx = 0; $idx <= $#keys; $idx++) {
        $aval = "";
        if ($acols [$cols [$idx]] =~ /$keys[$idx]/) {
            $aval = $1;
        }
        $bval = "";
        if ($bcols [$cols [$idx]] =~ /$keys[$idx]/) {
            $bval = $1;
        }
        if ($order [$idx] eq "-") {
            $ret = $bval cmp $aval;
        } else {
            $ret = $aval cmp $bval;
        }
        # sort '_' last
        if (($aval =~ /^ *_ *$/) && !($bval =~ /^ *_ *$/)) {
            $ret = 1;
        }
        if (!($aval =~ /^ *_ *$/) && ($bval =~ /^ *_ *$/)) {
            $ret = -1;
        }
        if ($sortdebug >= 5) {
            print "sort$idx acol >$acols[$idx]< -> >$aval<\n";
            print "sort$idx bcol >$bcols[$idx]< -> >$bval<\n";
            print "sort$idx ret $ret key $keys[$idx]\n";
        }
        if ($ret != 0) {
            # found difference, skip lower order
            last;
        }
    }
    
    $ret; 
}

sub l00http_table_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $path, $multitbl, $fname);
    my ($filtered, $tblcol, $tblfiled, $tblnot, @tblfield);
    my ($dofilter, $dosort, $tblfil);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }
    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname table</title>" .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> \n";
        # create shell script for vi
        if (open (OUT, ">$ctrl->{'plpath'}l00http_cmdedit.sh")) {
            print OUT "vim $form->{'path'}\n";
            close (OUT);
        }
    } else {
        $form->{'path'} = "$ctrl->{'plpath'}l00_table.txt";
    }
    print $sock "<a href=\"#end\">Jump to end</a><hr>\n";

    if ((defined ($form->{'nolist'})) && ($form->{'nolist'} eq 'on')) {
        $nolist = 'checked';
    } else {
        $nolist = '';
    }

    $buffer = "";
    if (defined ($form->{'convert'})) {
       # only get from browser if 'convert'
        if ((defined ($form->{'buffer'})) &&
            ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0))) {
            # make backup
            #$buffer = "$ctrl->{'bbox'}mv $form->{'path'} $form->{'path'}.bak";
            #`$buffer`;
            # get from browser
            $buffer = $form->{'buffer'};
        }
    } else {
        # read from file
        if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
            if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                $buffer = &l00httpd::l00freadAll($ctrl);
            }
#           if (open (IN, "<$form->{'path'}")) {
#               # http://www.perlmonks.org/?node_id=1952
#               local $/ = undef;
#               $buffer = <IN>;
#               close (IN);
#           }
        }
    }

    # convert tabs
    $buffer =~ s/\r//g;
    @alllines = split ("\n", $buffer);
    $buffer = "";
    foreach $line (@alllines) {
        if ($line =~ /\t/) {
            $line =~ s/\t/||/g;
            $line = "||$line||";
        }
        $buffer .= "$line\n";
    }

    # extract texts before and after table 
    $pre = '';
    $tbl = '';
    $post = '';
    $buffer =~ s/\r//g;
    $buffer =~ s/\|\| *\|\|/\|\|_\|\|/g;  # take care of empty cell (|||| -> ||_||)
    $multitbl = 0;
    @alllines = split ("\n", $buffer);
    foreach $line (@alllines) {
        if ($line =~ /^\|\|[^|].*\|\|$/) {
            # seeing table
            if ($post ne '') {
                $multitbl = 1;
                $post .= $line . "\n";
            } else {
                $tbl .= $line . "\n";
            }
        } else {
            if ($tbl eq '') {
                $pre .= $line . "\n";
            } else {
                $post .= $line . "\n";
            }
        }
    }

    # find maximun column width
    undef @width;
    $width [0] = "";
    $nocols = 0;
    $norows = 0;
    # find max width
    @alllines = split ("\n", $tbl);
    foreach $line (@alllines) {
        $norows++;
        @cols = split ('\|\|', $line);
        if ($nocols <= $#cols) {
            $nocols = $#cols + 1;
        }
        for ($ii = 1; $ii <= $#cols; $ii++) {
            $cols[$ii] =~ s/^ +//g;
            $cols[$ii] =~ s/ +$//g;
            if ((!defined ($width [$ii])) || ($width [$ii] <= length ($cols[$ii]))) {
                # allow a space for the widest entry
                $width [$ii] = length ($cols[$ii]) + 1;
            }
        }
    }
    #$nocols--;
    # make same width
    $tbl = "";
    foreach $line (@alllines) {
        @cols = split ('\|\|', $line);
        for ($ii = 1; $ii <= $#cols; $ii++) {
            if (!defined ($cols[$ii])) {
                $cols[$ii] = "";
            }
            $cols[$ii] =~ s/^ +//g;
            $cols[$ii] =~ s/ +$//g;
            if (length ($cols[$ii]) < $width [$ii]) {
                $cols [$ii] .= " " x ($width [$ii] - length ($cols[$ii]));
            }
        }
        for ($ii = $#cols + 1; $ii < $nocols; $ii++) {
            $cols [$ii] .= "_" . " " x ($width [$ii] - 1);
        }
        $tbl .= join ("||", @cols) . "||\n";;
    }

    $exelog = "Nothing executed";
    
    # execute...
    if (defined ($form->{'method'})) {
        if ($form->{'method'} eq $modtab) {
            $exelog = "Tab delimited";
            $tbl =~ s/\|\|/\t/g;
            $tbl =~ s/^\t//gm;
            $tbl =~ s/\t$//gm;
        } elsif (!defined ($form->{'Avalue'}) ||
            ($form->{'Avalue'} =~ /^ *$/) ||
            !($form->{'Avalue'} =~ /^ *[0-9]+ *$/) |
            ($form->{'Avalue'} < 0) ||
            ($form->{'Avalue'} > $nocols)) {
            $exelog = "Invalid A value";
        } elsif ($form->{'method'} eq $modadd) {
            $exelog = "Added column $form->{'Avalue'}. Not saved, use 'Convert / Save'";
            $buffer = $tbl;
            $tbl = "";
            foreach $line (split("\n",$buffer)) {
                ($buffer, @cols) = split ('\|\|', $line);
                $buffer = "||";
                for ($ii = 0; $ii < $nocols; $ii++) {
                    if ($ii < $form->{'Avalue'}) {
                        $buffer .= $cols [$ii] . "||";
                    } else {
                        if ($ii == $form->{'Avalue'}) {
                            $buffer .= "_||";
                        }
                        #    $buffer .= ".||";
                        $buffer .= $cols [$ii] . "||";
                    }
                }
                if ($form->{'Avalue'} == $nocols) {
                    $buffer .= "_||";
                }
                $tbl .= "$buffer\n";
            }
        } elsif ($form->{'method'} eq $modcopy) {
            $exelog = "Copied from column $form->{'Avalue'} to $form->{'Bvalue'}. Not saved, use 'Convert / Save'";
            if (defined ($form->{'Bvalue'}) &&
                !($form->{'Bvalue'} =~ /^ *$/) ||
                ($form->{'Bvalue'} =~ /^ *[0-9]+ *$/) &&
                ($form->{'Bvalue'} >= 0) &&
                ($form->{'Bvalue'} < $nocols)) {
                $buffer = $tbl;
                $tbl = "";
                foreach $line (split("\n",$buffer)) {
                    ($buffer, @cols) = split ('\|\|', $line);
                    $cols [$form->{'Bvalue'}] = $cols [$form->{'Avalue'}];
                    $tbl .= "||".join ("||", @cols)."||\n";
                }
            } else {
                $exelog = "Invalid B value";
            }
        } elsif ($form->{'method'} eq $modrow) {
            for (1..$form->{'Avalue'}) {
                $tbl .= "||";
                $tbl .= "_||" x $nocols;
                $tbl .= "\n";
            }
        } elsif ($form->{'method'} eq $moddel) {
            $exelog = "Deleted column $form->{'Avalue'}. Not saved, use 'Convert / Save'";
            $buffer = $tbl;
            $tbl = "";
            foreach $line (split("\n",$buffer)) {
                ($buffer, @cols) = split ('\|\|', $line);
                $buffer = "||";
                for ($ii = 0; $ii < $nocols; $ii++) {
                    if ($ii != $form->{'Avalue'}) {
                        # don't coply deleted column
                        if (defined($cols [$ii])) {
                            $buffer .= $cols [$ii] . "||";
                        }
                    }
                }
                $tbl .= "$buffer\n";
            }
        } else {
            $exelog = "Unknown command";
        }
    }

    # sort
    $filtered = 0;
    if (defined ($form->{'sort'})) {
        if ((defined ($form->{'keys'}) && (length ($form->{'keys'}) > 0) && (!($form->{'keys'} =~ /^ *$/)))) {
            $dosort = 1;
        } else {
            $dosort = 0;
        }
        if ((defined ($form->{'filter'}) && (length ($form->{'filter'}) > 0) && (!($form->{'filter'} =~ /^ *$/)))) {
            $dofilter = 1;
        } else {
            $dofilter = 0;
        }
        if ($dosort) {
            $sortkeys = $form->{'keys'};
            @allkeys = split ('\|\|', $sortkeys);
            if ($ctrl->{'debug'} >= 3) {
                print "keys >>$sortkeys<<\n";
                foreach $buffer (@allkeys) {
                    print "key >$buffer<\n";
                }
            }
            $ii = 0;
            undef @keys;
            foreach $buffer (@allkeys) {
                if ($buffer =~ /^(\d+)([+-]*):(.+)$/) {
                    # 2-:tag:(.+)||
                    $cols [$ii] = $1;
                    $order [$ii] = $2;
                    $keys [$ii] = $3;
                } elsif ($buffer =~ /^(\d+)([+-]*)$/) {
                    # 2-||
                    $cols [$ii] = $1;
                    $order [$ii] = $2;
                    $keys [$ii] = "(.*)";
                } else {
                    $cols [$ii] = $ii;
                    $order [$ii] = "";
                    $keys [$ii] = $buffer;
                    # $ii (.*)
                }
                if (!($keys [$ii] =~ /\(.+\)/)) {
                    $keys [$ii] .= "(.*)";
                }
                if ($ctrl->{'debug'} >= 4) {
                    print "key$ii cols $cols[$ii] order $order[$ii] key $keys[$ii]\n";
                }
                $ii++;
            }
            $sortdebug = $ctrl->{'debug'};
            ($tblhdr, @tblbdy) = split("\n",$tbl);
            @rows = sort tablesort @tblbdy;
            $tbl = "$tblhdr\n" . join ("\n", @rows) . "\n";
        }

        if ($dofilter) {
            $tblfilorg = $form->{'filter'};
            l00httpd::dbp($config{'desc'}, "filter = $tblfilorg\n");
            $tblfil = $tblfilorg;
            if ($tblfil =~ /^!!/) {
                $tblnot = 1;
                substr ($tblfil, 0, 2) = '';
            } else {
                $tblnot = 0;
            }
            if (($tblcol, $tblfil) = $tblfil =~ /(\d+)\|\|(.+)/) {
                $tblcol++;  # there is one extra count
                l00httpd::dbp($config{'desc'}, "(tblcol, tblfil) = ($tblcol, $tblfil)\n");
                $filtered = 1;

                ($tblhdr, @tblbdy) = split("\n",$tbl);
                @rows = sort tablesort @tblbdy;
                $tblfiled = "$tblhdr\n";
                foreach $_ (@rows) {
                    @tblfield = split ('\|\|', $_);
                    if ($tblnot) {
                        # skip matching
                        if ($tblfield[$tblcol] =~ /$tblfil/) {
                            next;
                        }
                    } else {
                        # skip not matching
                        if (!($tblfield[$tblcol] =~ /$tblfil/)) {
                            next;
                        }
                    }
                    $tblfiled .= "$_\n";
                }
                $tblfiled .= "\n";
            }
        }
    }

    # glue it together
    $buffer = $pre . $tbl . $post;

    if ($multitbl) {
        print $sock "<h1>Warning: multiple tables. Only the first table will be processed</h1>\n";
    }
    if ($filtered) {
        $tblfiled = $pre . $tblfiled . $post;
        print $sock &l00wikihtml::wikihtml ($ctrl, $ctrl->{'plpath'}, $tblfiled, 0);
    } else {
        print $sock &l00wikihtml::wikihtml ($ctrl, $ctrl->{'plpath'}, $buffer, 0);
    }

    # if convert, save to file
    if ((defined ($form->{'convert'}) &&
        (defined ($form->{'path'})) && 
        (length ($form->{'path'}) > 0))) {
        if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
        } else {
            &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 5);
        }
        &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        &l00httpd::l00fwriteBuf($ctrl, $buffer);
        if (&l00httpd::l00fwriteClose($ctrl)) {
            print $sock "Unable to write '$form->{'path'}'<p>\n";
        }
#       if (open (OUT, ">$form->{'path'}")) {
#           # http://www.perlmonks.org/?node_id=1952
#           print OUT $buffer;
#           close (OUT);
#       } else {
#           print $sock "Unable to write '$form->{'path'}'<p>\n";
#       }
    }

        
    # generate HTML buttons, etc.
    print $sock "<hr><a name=\"end\"></a>\n";

    if ($nolist ne 'checked') {
        # convert
        print $sock "<form action=\"/table.htm\" method=\"post\">\n";
        print $sock "<textarea name=\"buffer\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$buffer</textarea>\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"convert\" value=\"Convert / Save\">\n";
        print $sock "<input type=\"checkbox\" name=\"nobak\" checked>Do not backup\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "</form>\n";
        print $sock "</td><td>\n";

        # cancel
        print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"cancel\" value=\"Cancel\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "</form>\n";
        print $sock "</td></tr>\n";
        print $sock "</table><hr>\n";

        print $sock "Execution log: $exelog<p>\n";
    }
    
    # editing column
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<form action=\"/table.htm\" method=\"get\">\n";
    print $sock "<select name=\"method\">\n";
    foreach $mod (@modcmds) {
        print $sock "  <option value=\"$mod\">$mod</option>\n";
    }
    print $sock "</select>\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<input type=\"submit\" name=\"execute\" value=\"Execute\">\n";
    print $sock "</td></tr><tr><td>\n";
    print $sock "A: <input type=\"text\" size=\"3\" name=\"Avalue\">\n";
    print $sock "</td><td>\n";
    print $sock "B: <input type=\"text\" size=\"3\" name=\"Bvalue\">\n";
    print $sock "</form>\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";

    # sort 
    print $sock "<form action=\"/table.htm\" method=\"get\">\n";
    print $sock "<br>Sort key: 1-:hdr(\\d+)||3<br><table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<input type=\"submit\" name=\"sort\" value=\"Sort\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"20\" name=\"keys\" value=\"$sortkeys\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Filter\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"20\" name=\"filter\" value=\"$tblfilorg\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"nolist\" $nolist>No listing\n";
    print $sock "</td><td>\n";
    print $sock "Filter affects only display. !!col#||regex\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    if (defined ($form->{'path'})) {
        print $sock "<br><a href=\"/tableedit.htm?path=$form->{'path'}\">tableedit</a>: table row editor\n";
    }

    # print raw ASCII texts
    if ($nolist ne 'checked') {
        print $sock "<pre>\n";
        $lineno = 1;
        $buffer =~ s/\r//g;
        @alllines = split ("\n", $buffer);
        foreach $line (@alllines) {
            $line =~ s/\n//g;
            $line =~ s/</&lt;/g;
            $line =~ s/>/&gt;/g;
            print $sock sprintf ("%04d: ", $lineno++) . "$line\n";
        }
        print $sock "</pre>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
