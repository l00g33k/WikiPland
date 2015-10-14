$rhc = 'l00://rhc.htm';
print $sock "Polling history: <a href=\"/view.htm?path=$rhc\">$rhc</a><p>\n";
#--------------------------
$url = "http://wikipland-l00g33k.rhcloud.com/httpd.htm&extra=$ctrl->{'machine'}";

($hdr, $bdy) = &l00wget::wget ($url);

$out = '';
if (&l00httpd::l00freadOpen($ctrl, $rhc)) {
    $out = &l00httpd::l00freadAll($ctrl);
}

$rst = "$ctrl->{'now_string'} hdr " . length($hdr) . " bdy " . length($bdy) . " ";
foreach $_ (split("\n", $bdy)) {
    if ((/connected to the WikiPland running/) ||
       (/Server IP: /)) {
       s/<.+?>//g;
       print $sock $_;
       $rst .= $_;
    }
}

$rst =~ s/connected to the WikiPland running //;
print $sock $rst;

&l00httpd::l00fwriteOpen($ctrl, $rhc);
&l00httpd::l00fwriteBuf($ctrl, "$rst  \n$out");
&l00httpd::l00fwriteClose($ctrl);

#print $sock "header:<p><pre>\n$hdr\n</pre><p>";
#$bdy =~ s/</&lt/g;
#$bdy =~ s/>/&gt/g;
#print $sock "body:<p><pre>\n$bdy\n</pre><p>";


