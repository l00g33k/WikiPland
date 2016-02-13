use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_treesize_proc",
              desc => "l00http_treesize_desc");

my $calctreesize = '';

sub l00http_treesize_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "treesize: Calculate directory tree size";
}

sub l00http_treesize_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($pname, $fname, @alllines, $lineno, $buffer, $line, $ii, $level);
    my ($table, $format, $size, $pathname, $path, $name, %dirsize, %treesize);
    my ($ttlbytes, $ttldirs, %sort, $dirslash, $sizecomma);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if (defined ($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
        print $sock " <a href=\"/ls.htm?path=$form->{'path'}&editline=on\">Edit line link</a>\n";
    }
    print $sock "<br>\n";

    if (defined($form->{'treesize'}) && ($form->{'treesize'} eq 'on')) {
        $calctreesize = 'checked';
    } else {
        $calctreesize = '';
    }

    print $sock "<form action=\"/treesize.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"color\" value=\"Calculate\"> \n";
    print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<input type=\"checkbox\" name=\"treesize\" $calctreesize>Calculate tree size\n";
    print $sock "</form>\n";


    if (defined ($form->{'path'})) {
        print $sock "<p><pre>\n";
        $buffer = '';
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
        }
        $buffer =~ s/\r//g;
        @alllines = split ("\n", $buffer);
        $lineno = 0;
        $format = '?';
        foreach $line (@alllines) {
            if (!($line =~ /^\|\|/)) {
                next;
            }
            if ($format eq '3') {
                ($size, $pathname) = $line =~ /^ *\|\| +(\d+) +\|\| +\w+ +\|\| +(.+) +\|\| *$/;
            } elsif ($format eq '2') {
                ($size, $pathname) = $line =~ /^ *\|\| +(\d+) +\|\| +(.+) +\|\| *$/;
            } else {
                @_ = split ('\|\|', $line);
                if ($#_ == 2) {
                    $format = '2';
                    ($size, $pathname) = $line =~ /^ *\|\| +(\d+) +\|\| +(.+) +\|\| *$/;
                } else {
                    $format = '3';
                    ($size, $pathname) = $line =~ /^ *\|\| +(\d+) +\|\| +\w+ +\|\| +(.+) +\|\| *$/;
                }
                ($dirslash) = $pathname =~ /([\/\\])/;
            }
            ($path, $name) = $pathname =~ /^(.+[\/\\])([^\/\\]+)$/;
            #print $sock "($size, $path, $name)\n";
            if (defined($dirsize{$path})) {
                $dirsize{$path} += $size;
            } else {
                $dirsize{$path} = $size;
            }
            
            #printf $sock ("%s\n", $line);
            $lineno++;
        }

        print $sock "</pre>\n";

        $table = "\n|| # || Directories || #Bytes ||\n";
        $ttlbytes = 0;
        $ttldirs = 0;
        if ($calctreesize ne 'checked') {
            foreach $path (sort keys %dirsize) {
                if (defined($sort{$dirsize{$path}})) {
                    $sort{$dirsize{$path}} .= "||$path";
                } else {
                    $sort{$dirsize{$path}} = "$path";
                }
            }

            foreach $size (sort {$a - $b} keys %sort) {
                $sizecomma = $size;
                $sizecomma =~ s/(\d\d\d)$/,$1/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/,+/,/g;
                $sizecomma =~ s/^,+//g;
                foreach $path (split('\|\|', $sort{$size})) {
                    $ttldirs++;
                    $ttlbytes += $size;
                    $table .= "|| $ttldirs || $path || $sizecomma ||\n";
                }
            }
        } else {
            # print parsed rule table
            foreach $path (sort keys %dirsize) {
                $size = $dirsize{$path};
                $ttldirs++;
                $ttlbytes += $size;
                @_ = split($dirslash, $path);
                for ($level = 0; $level <= $#_; $level++) {
                    $_ = '';
                    for ($ii = 0; $ii <= $level; $ii++) {
                        $_ .= "@_[$ii]$dirslash";
                    }
                    if (defined($treesize{$_})) {
                        $treesize{$_} += $size;
                    } else {
                        $treesize{$_} = $size;
                    }
                }
            }

            foreach $path (sort keys %treesize) {
                if (defined($sort{$treesize{$path}})) {
                    $sort{$treesize{$path}} .= "||$path";
                } else {
                    $sort{$treesize{$path}} = "$path";
                }
            }

            foreach $size (sort {$a - $b} keys %sort) {
                $sizecomma = $size;
                $sizecomma =~ s/(\d\d\d)$/,$1/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/(\d\d\d),/,$1,/;
                $sizecomma =~ s/,+/,/g;
                $sizecomma =~ s/^,+//g;
                foreach $path (split('\|\|', $sort{$size})) {
                    $table .= "|| $ttldirs || $path || $sizecomma ||\n";
                }
            }
        }
        $table .= "* There are $ttldirs directories and $ttlbytes bytes\n";
        print $sock &l00wikihtml::wikihtml ($ctrl, "", $table, 0);

        print $sock "<hr><a name=\"end\"></a>";
        print $sock "<a href=\"#top\">top</a>\n";
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
