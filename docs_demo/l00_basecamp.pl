
use l00wikihtml;

my $form, $fname;
$form = $ctrl->{'FORM'};

if (defined ($form->{'arg1'})) {
    $fname = $form->{'arg1'};
}

if (defined ($fname)) {
    print $sock "Processing '$fname'\n";
    if (open (IN, "<$fname")) {
        print $sock "<pre>\n";
        while (<IN>) {
            print $sock $_;
        }
        print $sock "</pre>\n";
        close (IN);
    } else {
        print $sock "Failed to open '$fname'\n";
    }
} else {
    print $sock "Enter full path and filename in 'Arg1' below\n";
}

