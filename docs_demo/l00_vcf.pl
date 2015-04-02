print $sock "<p>Opening $ctrl->{'FORM'}->{'arg1'}<br>\n";

if (open(IN, "<$ctrl->{'FORM'}->{'arg1'}")) {
    $fixtext = '';
    $cnt = 0;
    undef %vcard;
    undef %vcardflds;
    undef %vcardN;
    undef %utf;
    while (<IN>) {
        s/\r//;
        s/\n//;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/&/&amp;/g;
        $fixtext .= "$_\n";
        if (/^BEGIN:VCARD/) {
            # new entry
            $cnt++;
        } elsif (/^END:VCARD/) {
        } else {
            if (($fldnam, $flddat) = /(.+):(.+)/) {
                if ($fldnam =~ /CHARSET=UTF-8/) {
                    $utf{$flddat} = $flddat;
                    $utf{$flddat} =~ s/=([a-fA-F0-9]{2})/pack("C", hex($1))/seg;
                }
                $vcardflds{$fldnam}++;
                $vcard{"${cnt}:::$fldnam"} = $flddat;
            }
            if ($fldnam eq 'N') {
                $vcardN{$flddat} = $cnt;
            }
        }
    }
    print $sock "Found $cnt records. List field names:<p>\n";
    print $sock "<pre>\n";
    $table = '||';
    foreach $key (sort keys %vcardflds) {
        $table .= "$key||";
        print $sock "$key\n";
    }
    $table .= "\n";


    for(1..$cnt) {
    #foreach $name (sort keys %vcardN) {
        #$_ = $vcardN{$name};
        $table .= "||";
        foreach $key (sort keys %vcardflds) {
            $tmp = "${_}:::$key";
            #$table .= "$tmp||";
            if (defined($vcard{$tmp})) {
                $table .= "$vcard{$tmp}||";
            } else {
                $table .= " ||";
            }
        }
        $table .= "\n";
    }
    #print $sock $table;
    print $sock "</pre>\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $table, 0);

    print $sock "<p>Translating UTF-8 to readable (not translating so you can re-import to contact):<br>\n";
    $table = "||Translated||Original||\n";
    foreach $_ (sort keys %utf) {
        $table .= "||$utf{$_}||$_||\n";
    }
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $table, 0);

    #print $sock "<pre>\n$fixtext</pre>\n";
    close (IN);
}

1;
