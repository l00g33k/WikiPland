
$fnamewidth = 100;
$ttlght = 20;
$svght = 16;

sub filecoverage {
    my ($fname, $noln, @marks) = @_;
    my ($ii);

    &l00httpd::l00fwriteOpen($ctrl, "l00://$fname.svg");

    &l00httpd::l00fwriteBuf($ctrl, "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");
    $_ = $noln + $fnamewidth;
    &l00httpd::l00fwriteBuf($ctrl, "<svg width=\"${_}px\" height=\"${ttlght}px\" viewBox=\"0 0 $_ $ttlght\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">\n");

    &l00httpd::l00fwriteBuf($ctrl, "<text x=\"0\" y=\"$svght\" font-size=\"20\" fill=\"Black\">$fname</text>\n");

    for ($ii = 0; $ii < $noln; $ii++) {
        for ($mark = 0; $mark <= $#marks; $mark++) {
            if ($marks[$mark] >= $ii) {
                last;
            }
        }
        if ($mark & 1) {
            $color = 'yellow';
        } else {
            $color = 'silver';
        }
        $_ = $ii + $fnamewidth;
        &l00httpd::l00fwriteBuf($ctrl, "<line x1=\"$_\" y1=\"0\" x2=\"$_\" y2=\"$svght\" stroke=\"$color\" stroke-width=\"1\" />\n");
    }

    &l00httpd::l00fwriteBuf($ctrl, "\n");

    &l00httpd::l00fwriteBuf($ctrl, "</svg>\n");
    &l00httpd::l00fwriteClose($ctrl);

    print $sock "<br><img src=\"/ls.htm?path=l00://$fname.svg\">\n";
}


print $sock "<p>\n";
&filecoverage("a.cpp", 4000, (100, 200, 300, 320));
&filecoverage("b.cpp", 400, (100, 200, 300, 320));
