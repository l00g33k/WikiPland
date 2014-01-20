print $sock "Opening $ctrl->{'FORM'}->{'arg1'}<br>\n";

$_ = pack("C30",0x53,0x6B,0xC3,0xAD,0x69,0x2D,0x6A,0x65,0x6E,0x6E,0x79);
print $sock "$_<br>\n";
$_ = pack("C30",0x53,0x6B,0xC3,0xAD,0x69,0x2D,0x6A,0x65,0x6E,0x6E,0x79);
print $sock "$_<br>\n";
$_ = pack("C30",0x53,0x68,0xC3,0xAD,0x68,0x6F,0x26,0x44,0x65,0x6E,0x6E,0x69);
print $sock "$_<br>\n";
$_ = pack("C30",0x53,0x68,0xC3,0xAD,0x68,0x6F,0x26,0x44,0x65,0x6E,0x6E,0x69);
print $sock "$_<br>\n";

#=53=68=C3=AD=68=6F=26=44=65=6E=6E=69
#=53=6B=C3=AD=69=2D=6A=65=6E=6E=79
#=53=6B=C3=AD=69=2D=6A=65=6E=6E=79
#=53=68=C3=AD=68=6F=26=44=65=6E=6E=69

if (open(IN, "<$ctrl->{'FORM'}->{'arg1'}")) {
    print $sock "<pre>\n";
    $_ = <IN>;
    s/\r//;
    s/\n//;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/&/&amp;/g;
    @hdr = split("\t", $_);
    while (<IN>) {
        s/\r//;
        s/\n//;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/&/&amp;/g;
        @fld = split("\t", $_);
        print $sock "BEGIN:VCARD\n";
        for($ii = 0; $ii <= $#fld; $ii++) {
            if (length($fld[$ii]) > 0) {
                print $sock "$hdr[$ii]:$fld[$ii]\n";
            }
        }
        print $sock "END:VCARD\n";
    }
    print $sock "</pre>\n";

    close (IN);
}

1;
