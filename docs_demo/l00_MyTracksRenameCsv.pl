if (!defined($ctrl->{'FORM'}->{'arg1'})) {
    print $sock "This do script renames exported MyTracks .csv filename to the first timestamp.<p>\n";
    print $sock "Enter full path to the directory containing the .csv files in 'Arg1'. Make sure to end in '/'. Then click 'Do more'<p>\n";
} else {
    $curdir = $ctrl->{'FORM'}->{'arg1'};

    print $sock "Renaming .csv in $curdir to first timestamp in file<p>\n";

    if (opendir (DIR, $curdir)) {
        print $sock "<pre>\n";
        # read in all filenames into an array
        @allfiles = readdir (DIR);
        foreach $file (@allfiles) {
            if ((-f "$curdir$file") && ($file =~ /\.csv$/)) {
                # for all .csv files
                # print $sock "$curdir$file\n";
                if (!($file =~ /\d\d\d\d-\d\d-\d\dT\d\d_\d\d_\d\d\.\d+Z/)) {
                    # not already using timestamp filename
                    if (open(IN, "<$curdir$file")) {
                        $stamp = '';
                        # scan for first timestamp
                        while (<IN>) {
                            #"1","1","48.865405","2.332933","94.0","","24","0","2015-08-22T08:25:36.486Z","","",""
                            # look for ',"2015-08-22T08:25:36.486Z",'
                            if (($stamp eq '') && (/,"(\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ)",/)) {
                                # found it
                                $stamp = $1;
                                $stamp =~ s/:/_/g;
                            }
                        }
                        close(IN);
                        if ($stamp ne '') {
                            # if found timestamp, rename it
                            print $sock "Rename $file to $stamp.csv\n";
                            rename("$curdir$file", "$curdir$stamp.csv");
                        }
                    }
                }
            }
        }
        print $sock "</pre>\n";
        closedir (DIR);
    }
}

