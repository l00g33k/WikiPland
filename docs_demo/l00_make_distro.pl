my $form;
$form = $ctrl->{'FORM'};

my (@list, $lvl, $partial, $nofile);

sub l00_make_distro_tree {
    my ($sock, $path) = @_;

    $lvl++;

    if ($lvl < 20) {
        if (opendir (DIR, $path)) {
            foreach $file (readdir (DIR)) {
      	        if (($file =~ /^\.+$/) || 
                    ($file =~ /^\.git/) || 
                    ($file =~ /\.bak$/) || 
                    ($file =~ /\.log$/) || 
                    ($file =~ /\.scc$/)) {
                    next;
                }
      	        if (-d $path.$file) {
                    &l00_make_distro_tree ($sock, "$path$file/");
                } else {
                    push (@list, $path.$file);
                }
            }
        }
    }
    $lvl--;
}


$wget = '';


$arg1 = '';
$arg2 = '';
# retrieve parameters
if (defined ($form->{'arg1'})) {
	$arg1 = $form->{'arg1'};
}
if (defined ($form->{'arg2'})) {
	$arg2 = $form->{'arg2'};
}

$wget .= "Arg1: full path to /sdcard/sl4a/scripts/l00httpd/<br>\n";
$wget .= "Arg2: full path to /sdcard/tmp/l00httpd.distro<br>\n";
$wget .= "<a href=\"/view.htm?path=$arg2\">/view.pl?path=$arg2</a><br>\n";

if (($arg1 ne '') && ($arg2 ne '')) {
    undef @list;
    $lvl = 0;
    &l00_make_distro_tree ($sock, $arg1);

    open (OU, ">$arg2");

    print OU "__END__\n";
    $restdest = '/sdcard/al/del/insttest/';
    print OU "DEST?$restdest?\n";

    print $sock "<pre>";
    print $sock "Restore dest: $restdest\n";
    $cnt = 0;
    $nofile = 0;
    foreach $file (@list) {
if ($nofile++ > 8) {
#last;
}
        $partial = $file;
        $partial =~ s /^.+\/l00httpd\///;
        print $sock "Storing file $cnt: $partial\n";
        if (open (SRC, "<$file")) {
            print OU "FILE?$partial?\n";
            close (SRC);
            open (SRC, "<$file");
            while (<SRC>) {
                print OU;
            }
            close (SRC);
            print OU "FILEEND?\n";
        }


        $cnt++;
    }
    print $sock "</pre>";
    close (OU);
}


$wget .= "<hr><p>".
"Edit <a href=\"/edit.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";


print $sock $wget;

1;
