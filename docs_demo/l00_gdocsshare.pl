my $form;
$form = $ctrl->{'FORM'};

$wget = '';
$wget .= "<form action=\"/do.htm\" method=\"get\">\n";
$wget .= "<input type=\"submit\" name=\"paste\" value=\"CB paste\">\n";
$wget .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
$wget .= "</form>\n";

#$wget .= "Arg1: full path to logcat file.<br>\n";
#$wget .= "Arg2: (blank) (all), a (all+color), b (filtered)<br>\n";

if (defined ($form->{'arg1'})) {
	$arg1 = $form->{'arg1'};
}
if (defined ($form->{'arg2'})) {
	$arg2 = $form->{'arg2'};
}
if (defined ($form->{'paste'})) {
    $arg1 = $ctrl->{'droid'}->getClipboard()->{'result'};
    print "From clipboard:\n$arg1\n";
    $wget .= "<hr><p>";
    #$wget .= "clipboard: $arg1<p>";
    if ($arg1 =~ m\content://.+?(/.+)\) {
        $wget .= "<a href=\"/launcher.htm?path=$1\">/launcher.pl?path=$1</a><p>";
        $wget .= "<a href=\"/view.htm?path=$1\">/view.pl?path=$1</a><p>";
        $wget .= "<a href=\"/ls.htm?path=$1\">/ls.pl?path=$1</a><p>";
        $wget .= "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=vi+$1\">clip 'vi $1'</a><p>";
        #/ls.htm?path=/sdcard/l00httpd/index.txt
    }
}


$wget .= "<hr><p>".
"Edit <a href=\"/edit.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";


print $sock $wget;

1;
