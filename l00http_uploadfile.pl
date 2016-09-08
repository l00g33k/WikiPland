use strict;
use warnings;
use l00backup;
use l00crc32;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_uploadfile_proc",
              desc => "l00http_uploadfile_desc");


sub l00http_uploadfile_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "uploadfile: Upload file to the server";
}

sub l00http_uploadfile_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $fname);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if (defined($form->{'path'})) {
        $path = $form->{'path'};
        # drop any path
        $path =~ s/([\/\\])[^\/\\]+$/$1/;
    } else {
        if ($ctrl->{'os'} eq 'and') {
            $path = '/sdcard/z/';
        } elsif ($ctrl->{'os'} eq 'win') {
            $path = 'c:/z/';
        } elsif ($ctrl->{'os'} eq 'lin') {
            $path = '/home/z/';
        } elsif ($ctrl->{'os'} eq 'tmx') {
            # termux on Android
            $path = '/sdcard/z/';
        } else {
            $path = '/z/';
        }
    }
    $form->{'path'} = $path;

    print $sock "<a href=\"/uploadfile.htm\">uploadfile.htm</a><p>\n";

    if (defined($form->{'payload'})) {
        $fname = $form->{'filename'};
        $fname =~ s/^.+[\/\\]([^\/\\]+)$/$1/;
        $path .= $fname;
        if (-f "$path") {
            # backup
            &l00backup::backupfile ($ctrl, $path, 1, 5);
        }
        if (length($form->{'payload'}) < 100000) { 
            $_ = &l00crc32::crc32($form->{'payload'});
        } else {
            $_ = 0;
        }
#        open(DBG2,">$path");
#        binmode(DBG2);
#        print DBG2 $form->{'payload'};
#        close(DBG2);
        &l00httpd::l00fwriteOpen($ctrl, $path);
        &l00httpd::l00fwriteBuf($ctrl, $form->{'payload'});
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "<p>Saved '$fname' to '$path'<br>\n";
        print $sock sprintf("Size = %d bytes<br>CRC32 = 0x%08x<br>\n", length($form->{'payload'}), $_);
        print $sock "<a href =\"/ls.htm?path=$path\">$fname</a>\n";
        print $sock "<a href =\"/view.htm?path=$path\">view</a>\n";
        print $sock "<a href =\"/launcher.htm?path=$path\">launcher</a><p>\n";
    }

    print $sock "<form action=\"/uploadfile.htm\" method=\"post\" enctype=\"multipart/form-data\">\n";

    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"upload\" value=\"Upload to\">\n";
    print $sock "<input type=\"text\" size=\"20\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input id=\"myfile\" name=\"myfile\" type=\"file\">\n";
    print $sock "</td></tr>\n";

    print $sock "</table><br>\n";
    print $sock "</form>\n";

    print $sock "WARNING: Be certain you intend to overwrite target file. Under unknown conditions, target directory may be lost. You are warned.<p>\n".

    print $sock "Note: The directory part of the 'Upload to' field is used as the destination direction. ".
        "The filename is taken from the file being uploaded. If only directory is given, it must end in '/' or '\'. Pick a file in launcher and only the directory part will be kept<p>\n";

    print $sock "Note: Tested uploading 45 MBytes file to Android phone<p>\n".

    print $sock "<a name=\"end\"></a>";
    print $sock "<a href=\"#top\">top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
