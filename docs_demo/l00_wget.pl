
print $sock "wget<p>\n";

#--------------------------
$url = 'http://192.168.4.101:20338/myfriends.htm';

($hdr, $bdy) = &l00wget::wget ($ctrl, $url, "p:p", 0.4, 0.4);
print $sock "l00wget::wget ($ctrl, $url, \"p:p\");<p>\n";
print $sock "hdr " . length($hdr) . " bdy " . length($bdy) . "<p>\n";

print $sock "header:<p><pre>\n$hdr\n</pre><p>";
$bdy =~ s/</&lt/g;
$bdy =~ s/>/&gt/g;
print $sock "body:<p><pre>\n$bdy\n</pre><p>";
