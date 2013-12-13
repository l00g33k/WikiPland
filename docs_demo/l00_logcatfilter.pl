
my $form;
$form = $ctrl->{'FORM'};

#$arg1 = '';
#$arg2 = 200;
if (defined ($form->{'arg1'})) {
	$arg1 = $form->{'arg1'};
}
if (defined ($form->{'arg2'})) {
	$arg2 = $form->{'arg2'};
}
if (defined ($form->{'paste'})) {
    $arg1 = $ctrl->{'droid'}->getClipboard()->{'result'};
    print "From clipboard:\n$arg1\n";
}


#<font style="color:black;background-color:gray">more words</font>
#<font style="color:black;background-color:silver">more words</font>
#<font style="color:black;background-color:yellow">more words</font>
#<font style="color:black;background-color:lime">more words</font>
#<font style="color:black;background-color:aqua">more words</font>
#<font style="color:black;background-color:fuchsia">more words</font>
#<font style="color:black;background-color:red">more words</font>
#<font style="color:black;background-color:olive">more words</font>
#<font style="color:black;background-color:teal">more words</font>
#<font style="color:black;background-color:green">more words</font>
#<font style="color:white;background-color:blue">more words</font>
#<font style="color:white;background-color:maroon">more words</font>
#<font style="color:white;background-color:navy">more words</font>
@highlight = (
    "<font style=\"color:black;background-color:yellow\">",
    "<font style=\"color:black;background-color:gray\">",
    "<font style=\"color:black;background-color:silver\">",
    "<font style=\"color:black;background-color:lime\">",
    "<font style=\"color:black;background-color:aqua\">",
    "<font style=\"color:black;background-color:fuchsia\">",
    "<font style=\"color:black;background-color:red\">",
    "<font style=\"color:black;background-color:olive\">",
    "<font style=\"color:black;background-color:teal\">",
    "<font style=\"color:black;background-color:green\">",
    "<font style=\"color:white;background-color:blue\">",
    "<font style=\"color:white;background-color:maroon\">",
    "<font style=\"color:white;background-color:navy\">"
);


$wget = '';


@filter = (
    "\\\): Preparing: ",
    "\\\): Waiting for prepare",
    "\\\): connect\\\(\\\) redirect http status error",
    "\\\): error \\\(1, -1004\\\)",
    "\\\): onError\\\(1, -1004\\\)",
    "\\\): info\\\/warning \\\(1, 902\\\)",
    "\\\): Prepared/",
    "is not localhost"
);


if (($arg2 ne 'a') && ($arg2 ne 'b')) {
    $jmp = 1;
    $wget .= "<a name=\"jmp_0\"></a><a href=\"#jmp_1\">jump to first highlight</a>\n";
}

$cnt = 0;
$wget .= "<pre>\n";
if (open (IN, "<$arg1")) {
    while (<IN>) {
        $cnt++;
        $found = 0;
        foreach $fil (@filter) {
            if (/$fil/) {
                $found = 1;
            }
        }
        if ($arg2 eq 'a') {
            $wget .= sprintf ("%05d: ", $cnt)."$_";
        } elsif ($arg2 eq 'b') {
            if ($found) {
                s/\r//;
                s/\n//;
				if (/error/i) {
                    $wget .= $highlight [0];
                    $tmp = sprintf ("%05d", $cnt);
                    $wget .= "$tmp: $_";
                    $wget .= "</font>\n";
                } else {
                    $wget .= sprintf ("%05d: ", $cnt)."$_\n";
                }
            }
        } else {
            if ($found) {
                $wget .= "<a name=\"jmp_$jmp\"></a>";
                s/\r//;
                s/\n//;
                $wget .= $highlight [0];
                $wget .= "<a name=\"jmp_$jmp\"></a>";
                $tmp = sprintf ("%05d", $cnt);
                $jmpl = $jmp - 1;
                $jmpn = $jmp + 1;
                $wget .= "<a href=\"#jmp_$jmpl\">$tmp</a> : <a href=\"#jmp_$jmpn\">$_</a>";
                $wget .= "</font>\n";
                $jmp++;
            } else {
                $wget .= sprintf ("%05d: ", $cnt)."$_";
            }
        }
    }
    close (IN);
} else {
    $wget .= "Unable to open: $arg1<p>";
}
$wget .= "</pre>\n";
$wget .= "<a href=\"#jmp_$jmpl\">jump to last highlight</a>\n";




$wget .= "<hr><p>";
$wget .= "Found $cnt lines in $arg1<p>";
$wget .= "<hr><p>".
"Edit <a href=\"/edit.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n".
"View <a href=\"/view.htm?path=$arg1\">$arg1</a><br>\n";


$wget .= "<form action=\"/do.htm\" method=\"get\">\n";
$wget .= "<input type=\"submit\" name=\"paste\" value=\"CB paste\">\n";
$wget .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
$wget .= "</form>\n";

$wget .= "Arg1: full path to logcat file.<br>\n";
$wget .= "Arg2: (blank) (all), a (all+color), b (filtered)<br>\n";

print $sock $wget;

1;
