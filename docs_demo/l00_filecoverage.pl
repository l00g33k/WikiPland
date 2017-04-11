# paints horizontal bars with colorings

$fnamewidth = 20;
$ttlght = 20;
$svght = 16;

# '<<notperlcode;' makes the following block into a string to be ignored.
<<notperlcode;
#sample input file
fnamewidth:36

file:fileA
length:50
mark:yellow:0-50
end:

file:fileB
length:50
mark:green:0-50
end:

file:fileC
length:50
mark:cyan:0-50
end:

file:fileD
length:50
mark:gray:0-50
end:

file:fileE
length:50
mark:lime:0-50
end:

file:fileF
length:50
mark:fuchsia:0-50
end:

file:fileG
length:50
mark:olive:0-50
end:

file:fileH
length:50
mark:aqua:0-50
end:

file:fileI
length:50
mark:red:0-50
end:

file:program.cpp
length:1456
mark:olive:59-1456
end:

notperlcode

sub filecoverage {
    my ($fname, $noln, @marks) = @_;
    my ($ii, $line, $color);
    #print $sock "filecoverage($fname, $noln, @marks)\n";

    &l00httpd::l00fwriteOpen($ctrl, "l00://$fname.svg");

    &l00httpd::l00fwriteBuf($ctrl, "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");
    $_ = $noln;
    &l00httpd::l00fwriteBuf($ctrl, "<svg width=\"${_}px\" height=\"${ttlght}px\" viewBox=\"0 0 $_ $ttlght\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">\n");

    #&l00httpd::l00fwriteBuf($ctrl, "<text x=\"0\" y=\"$svght\" font-size=\"20\" fill=\"Black\">$fname</text>\n");

    for ($ii = 0; $ii < $noln; $ii++) {
        for ($mark = 0; $mark <= $#marks; $mark++) {
            ($line) = $marks[$mark] =~ /(\d+)/;
            if ($line >= $ii) {
                last;
            }
        }
        if ($mark & 1) {
            if (!(($color) = $marks[$mark] =~ /\d+:(.+)/)) {
                $color = 'yellow';
            }
        } else {
            $color = 'silver';
        }
        $_ = $ii;
        &l00httpd::l00fwriteBuf($ctrl, "<line x1=\"$_\" y1=\"0\" x2=\"$_\" y2=\"$svght\" stroke=\"$color\" stroke-width=\"1\" />\n");
    }

    &l00httpd::l00fwriteBuf($ctrl, "\n");

    &l00httpd::l00fwriteBuf($ctrl, "</svg>\n");
    &l00httpd::l00fwriteClose($ctrl);

    printf $sock ("%${fnamewidth}s <img src=\"/ls.htm?path=l00://$fname.svg\">\n", $fname);
}



if (defined($ctrl->{'FORM'}->{'arg1'})) {
    print $sock "<br>Reading '$ctrl->{'FORM'}->{'arg1'}'<br>\n";
    print $sock "<pre>\n";
    if (&l00httpd::l00freadOpen($ctrl, $ctrl->{'FORM'}->{'arg1'})) {
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/\n//;
            s/\r//;
            #file:program.cpp
            #length:1000
            #mark:yellow:10-20
            #end:
            if (/^file:(.+)/) {
                $file = $1;
            }
            if (/^length:(.+)/) {
                $length = $1;
                undef @markers;
            }
            #mark:yellow:10-20
            if (($color, $start, $end) = /^mark:(.+?):(\d+)-(\d+)/) {
                push (@markers, "$start");
                push (@markers, "$end:$color");
            }
            if (/^end:/) {
                &filecoverage($file, $length, @markers);
            }
            if (/^fnamewidth:(-*\d+)/) {
                $fnamewidth = $1;
            }
        }
    }
    print $sock "</pre>\n";
} else {
    print $sock "<pre>\n";
    &filecoverage("a.cpp", 1400, ('300', '400:red', '700', '720:yellow'));
    &filecoverage("b.cpp", 400, '100', '200:green');
    print $sock "</pre>\n";
}

