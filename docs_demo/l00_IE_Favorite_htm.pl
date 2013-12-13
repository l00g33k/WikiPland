
use l00wikihtml;

my $form, $fname;
$form = $ctrl->{'FORM'};

if (defined ($form->{'arg1'})) {
    $fname = $form->{'arg1'};
}


if (defined ($fname)) {
    if (open (IN, "<$fname")) {
        $outbuf = "%TOC%\n";
        $print = 0;
        while (<IN>) {
            #    <DT><H3 FOLDED ADD_DATE="1263251165">Links</H3>
            if (/^( +)<DT><H3.*?>(.+)<\/H3>/) {
                $lvl = length ($1);
                $lvl = '=' x (0 + int ($lvl / 4));
                $outbuf .= "$lvl$2$lvl\n";
            }
            #   <DT><A HREF="https://ieonline.microsoft.com/#ieslice" ADD_DATE="1308550525" LAST_VISIT="1308550525" 
            #   LAST_MODIFIED="1308550526" FEEDURL="https://ieonline.microsoft.com/#ieslice" 
            #   WEBSLICE="true" ISLIVEPREVIEW="true" PREVIEWSIZE="320x240" ICON_URI="https://ieonline.microsoft.com/favicon.ico" 
            #   >Suggested Sites</A>
            if (/<DT>(<A HREF=.+<\/A>)/) {
                $outbuf .= "* $1\n";
            }
        }
        close (IN);
        print $sock &l00wikihtml::wikihtml ($ctrl, "", $outbuf, 0);
    }
} else {
    print $sock "Enter full path and filename in 'Arg1' below\n";
}
print $sock "Displays IE9 Favorites<br>\n";

