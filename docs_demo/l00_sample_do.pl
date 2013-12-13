
my $form;
$form = $ctrl->{'FORM'};

$wget = '';
$wget .= "<form action=\"/do.htm\" method=\"get\">\n";
$wget .= "<input type=\"submit\" name=\"paste\" value=\"CB paste\">\n";
$wget .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
$wget .= "</form>\n";

#$wget .= "Arg1: full path to logcat file.<br>\n";
#$wget .= "Arg2: (blank) (all), a (all+color), b (filtered)<br>\n";

# retrieve parameters
if (defined ($form->{'arg1'})) {
	$arg1 = $form->{'arg1'};
}
if (defined ($form->{'arg2'})) {
	$arg2 = $form->{'arg2'};
}

if (defined ($form->{'paste'})) {
    if ($ctrl{'os'} eq 'and') {
        # get from clipboard
        $arg1 = $ctrl->{'droid'}->getClipboard()->{'result'};
        $wget .= "$arg1<br><hr><p>";
    } else {
        $wget .= "no clipboard on non Android<br><hr><p>";
    }
}


$wget .= "<hr><p>".
"Edit <a href=\"/edit.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";


print $sock $wget;

1;
