use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Converting tab delimited data (e.g. copied from Excel)
# and making constant width for easy viewing with fixed
# width font (e.g. vi of programmer's editor)

my %config = (proc => "l00http_tableedit_proc2",
              desc => "l00http_tableedit_desc2");
my ($buffer, $pre, $tblhdr, $tbl, $post, @width, @cols, $ii);
my (@modcmds, $modadd, $modcopy, $moddel, $modrow, $mod, $modtab);
my ($exelog, $nocols, $norows, @rows, @keys, @order);
my (@allkeys, $sortdebug, @tblbdy, $rowsel);

$modadd  = "Add new column at A";
$moddel  = "Delete column A";;
$modcopy = "Copy column A to B";
$modrow  = "Append A empty row";
$modtab  = "Display tabs";
$rowsel = 0;
@modcmds = ("Reload from file", $modadd, $moddel, $modcopy, $modrow, $modtab);

sub l00http_tableedit_desc2 {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "tableedit: Insert table row";
}


#print "key$ii cols $cols[$ii] 
#order $order[$ii] key $keys[$ii]\n";
sub tablesort22 {
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

sub l00http_tableedit_proc2 {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $path, $multitbl);
    my (@linehdr, @linetgt, $newline, $edittbl, $tmp, $fname);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }

    if (defined ($form->{'next'})) {
        $rowsel = 0;
        if (defined ($form->{'lineno'}) &&
           (($form->{'lineno'} >= 0) && ($form->{'lineno'} <= 99))) {
            $rowsel = $form->{'lineno'};
        }
    }
    if (defined ($form->{'inc'})) {
        $form->{'next'} = 1;
        if (defined ($form->{'colsel'}) &&
           (($form->{'colsel'} >= 0) && ($form->{'colsel'} <= 99))) {
        } else {
            $form->{'colsel'} = 0;
        }
    }
    if (defined ($form->{'del'})) {
        $form->{'next'} = 1;
        if (defined ($form->{'colsel'}) &&
           (($form->{'colsel'} >= 0) && ($form->{'colsel'} <= 9999))) {
        } else {
            $form->{'colsel'} = 0;
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname tableedit</title>" .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> \n";
    } else {
        $form->{'path'} = "$ctrl->{'plpath'}l00_table.txt";
    }
    print $sock "<a href=\"#end\">Jump to end</a><hr>\n";

    $buffer = "";
    # read from file
    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
		if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
		}
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
        if ($line =~ /^\|\|[^|].*\|\| *$/) {
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
    if ($rowsel > $#alllines) {
        $rowsel = $#alllines;
    }
    if ($rowsel < 0) {
        $rowsel = 0;
    }

    # prepare to insert/replace line
    if (defined ($form->{'save'}) &&
        defined ($form->{'nocols'}) &&
        defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 2)) {
        $newline = '||';
        for ($lineno = 1; $lineno < $form->{'nocols'}; $lineno++) {
            if ((defined($form->{"col$lineno"})) &&
                (length($form->{"col$lineno"}) > 0)) {
                $newline .= $form->{"col$lineno"}."||";
            } else {
                $newline .= "_||";
            }
        }
        if ($form->{'mode'} eq 'insert') {
            splice(@alllines,$rowsel+1,0,$newline);
        } elsif ($form->{'mode'} eq 'insertb4') {
            splice(@alllines,$rowsel,0,$newline);
        } elsif ($form->{'mode'} eq 'edit') {
            $alllines[$rowsel] = $newline;
        }
    }

    foreach $line (@alllines) {
        $norows++;
        @cols = split ('\|\|', $line);
        if ($nocols <= $#cols) {
            $nocols = $#cols + 1;
        }
        for ($ii = 1; $ii <= $#cols; $ii++) {
            $cols[$ii] =~ s/^ +//g;
            $cols[$ii] =~ s/ +$//g;
            if ((!defined ($width [$ii])) || ($width [$ii] < length ($cols[$ii]))) {
                $width [$ii] = length ($cols[$ii]);
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

    # glue it together
    $buffer = $pre . $tbl . $post;

    if ($multitbl) {
        print $sock "<h1>Warning: multiple tables. Only the first table will be processed</h1>\n";
    }

    # if convert, save to file
    if ((defined ($form->{'save'}) &&
        (defined ($form->{'path'})) && 
        (length ($form->{'path'}) > 2))) {
        if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
        } else {
            &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 5);
        }
        &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        &l00httpd::l00fwriteBuf($ctrl, $buffer);
        &l00httpd::l00fwriteClose($ctrl);
    }

    # generate HTML buttons, etc.

    if (!defined ($form->{'next'})) {
        # 1st pass
        print $sock "<form action=\"/tableedit.htm\" method=\"post\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "<input type=\"hidden\" name=\"nocols\" value=\"$nocols\">\n";
        print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"next\" value=\"Next\">\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"radio\" name=\"mode\" value=\"edit\" checked>edit\n";
        print $sock "<input type=\"radio\" name=\"mode\" value=\"insert\">insert\n";
        print $sock "<input type=\"radio\" name=\"mode\" value=\"delete\">delete\n";
        print $sock "</td></tr>\n";
        print $sock "</table>\n";

        print $sock "<br>\n";
        $edittbl = '';
        $line = 0;
        foreach $_ (split ("\n", $tbl)) {
            @cols = split ('\|\|', $_);
            if ($line == 0) {
                # make top row with links to sort by column
                $edittbl .= "||sort table -&gt;||";
                for ($ii = 1; $ii <= $#cols; $ii++) {
#/table.pl?path=del.txt&sort=Sort&keys=4%2B
                    $_ = $ii - 1;
                    $edittbl .= "<a href=\"/table.htm?path=$form->{'path'}&sort=Sort&keys=$_%2B\">^</a>:";
                    $edittbl .= "<a href=\"/table.htm?path=$form->{'path'}&sort=Sort&keys=$_%2D\">v</a>||";
                }
                $edittbl .= "\n";
                # make top row with links to sort by column
#               $edittbl .= "||<input type=\"radio\" name=\"lineno\" value=\"$line\">$line||";
                $edittbl .= "||Row: ";
                $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=insertb4\">^</a>:";
                $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=edit\">E</a>:";
                $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=insert\">v</a>";
                $edittbl .= "<input type=\"radio\" name=\"lineno\" value=\"$line\">$line||";
                for ($ii = 1; $ii <= $#cols; $ii++) {
#/table.pl?path=del.txt&sort=Sort&keys=4%2D
                    $_ = $ii - 1;
                    $edittbl .= "$cols[$ii]||";
                }
                $edittbl .= "\n";
            } else {
                $edittbl .= "||Row: ";
                $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=insertb4\">^</a>:";
                $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=edit\">E</a>:";
                $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=insert\">v</a>";
                $edittbl .= "<input type=\"radio\" name=\"lineno\" value=\"$line\">$line||";
                for ($ii = 1; $ii <= $#cols; $ii++) {
                    $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=edit&colsel=$ii&inc=Insert\">&gt;</a>:";
                    $edittbl .= "<a href=\"/tableedit.htm?path=$form->{'path'}&next=Next&nocols=$nocols&lineno=$line&mode=edit&colsel=$ii&del=Delete\">&lt;</a>";
                    $edittbl .= "<br>";
                    $edittbl .= "$cols[$ii]||";
                }
                $edittbl .= "\n";
            }
            $line++;
        }
        print $sock &l00wikihtml::wikihtml ($ctrl, $ctrl->{'plpath'}, $edittbl, 0);

        print $sock "</form><hr>\n";
    } else {
        # 2nd pass
        # edit row
        print $sock "<form action=\"/tableedit.htm\" method=\"post\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "<input type=\"hidden\" name=\"nocols\" value=\"$nocols\">\n";
        print $sock "<input type=\"hidden\" name=\"mode\" value=\"$form->{'mode'}\">\n";
        print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
        print $sock "<tr><td>\n";
        print $sock "&nbsp;</td><td>\n";
        print $sock "<input type=\"submit\" name=\"back\" value=\"Back\">\n";
        print $sock "</td><td>\n";
        print $sock "Back to row selection\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "&nbsp;</td><td>\n";
        print $sock "<input type=\"submit\" name=\"save\" value=\"Save\">\n";
        print $sock "</td><td>\n";
        if ($form->{'mode'} eq 'insert') {
            print $sock "Inserting new row after $rowsel\n";
        } elsif ($form->{'mode'} eq 'insertb4') {
            print $sock "Inserting new row before $rowsel\n";
        } elsif ($form->{'mode'} eq 'edit') {
            print $sock "Editing row $rowsel\n";
        } else {
            print $sock "Not implemented\n";
        }
        print $sock "<br><input type=\"checkbox\" name=\"nobak\" checked>Do not backup. ";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "&nbsp;</td><td>\n";
        print $sock "Column:</td><td>\n";
        print $sock "<input type=\"submit\" name=\"inc\" value=\"Insert\">\n";
        print $sock "<input type=\"submit\" name=\"del\" value=\"Delete\">\n";
        print $sock "selected\n";
        print $sock "</td></tr>\n";

        @linehdr = split('\|\|', $alllines[0]); 
        if ($rowsel > 0) {
            @linetgt = split('\|\|', $alllines[$rowsel]); 
        }
        for ($lineno = 1; $lineno <= $#linehdr; $lineno++) {
            $_ = $linehdr[$lineno]; 
            print $sock "<tr><td>\n";
            s/\n//g;
            s/</&lt;/g;
            s/>/&gt;/g;
            if ($rowsel > 0) {
                if (defined ($form->{'inc'})) {
                    if ($lineno < $form->{'colsel'}) {
                        $line = $linetgt[$lineno]; 
                    } elsif ($lineno == $form->{'colsel'}) {
                        $line = '';
                    } else {
                        $line = $linetgt[$lineno - 1];
                    }
                } elsif (defined ($form->{'del'})) {
                    if ($lineno < $form->{'colsel'}) {
                        $line = $linetgt[$lineno]; 
                    } elsif ($lineno == $#linehdr) {
                        $line = '';
                    } else {
                        $line = $linetgt[$lineno + 1];
                    }
                } else {
                    $line = $linetgt[$lineno]; 
                }
            } else {
                $line = '';
            }
            $line =~ s/\n//g;
            $line =~s/</&lt;/g;
            $line =~s/>/&gt;/g;
            $line =~ s/^ *//g;
            $line =~ s/ *$//g;
            print $sock "<input type=\"radio\" name=\"colsel\" value=\"$lineno\">\n";
            # clean out URL
            s/\[(\[).+?\|(.+?\])\]/$1$2/g;
            print $sock "$lineno</td><td>$_";
            print $sock "</td><td>\n";
            print $sock "<input type=\"text\" size=\"16\" name=\"col$lineno\" value=\"$line\">";
            print $sock "</td></tr>\n";
        }
#   print $sock "<input type=\"submit\" name=\"convert\" value=\"Convert / Save\">\n";
#   print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";

        print $sock "</table><hr>\n";
        print $sock "</form>\n";
    }

    print $sock &l00wikihtml::wikihtml ($ctrl, $ctrl->{'plpath'}, $buffer, 0);

    # print raw ASCII texts
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

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
