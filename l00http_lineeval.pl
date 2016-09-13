use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

my ($fil, $eval);
$fil = '.';
$eval = 'print $sock $_';

my %config = (proc => "l00http_lineeval_proc",
              desc => "l00http_lineeval_desc");


sub l00http_lineeval_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "lineeval: Eval expression on selected lines in file";
}

sub l00http_lineeval_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($dolncnt, $dorst, $newfile, $oldfile);
    my ($last, $this, $next);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>lineeval</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a name=\"__top__\"></a>";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
    }
    print $sock "<a href=\"#__end__\">Jump to end</a><br>\n";

    print $sock "<form action=\"/lineeval.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"run\" value=\"Run\"></td>\n";
    print $sock "    </tr>\n";
    print $sock "    <tr>\n";
    print $sock "        <td>Path: <input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "    </tr>\n";
    print $sock "    <tr>\n";
    print $sock "        <td>Filter: <input type=\"text\" size=\"10\" name=\"fil\" value=\"$fil\"></td>\n";
    print $sock "    </tr>\n";
    print $sock "    <tr>\n";
    print $sock "        <td>Eval: <input type=\"text\" size=\"10\" name=\"eval\" value=\"$eval\"></td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    if ((defined ($form->{'path'})) && 
        (defined ($form->{'run'}))) {
        if (defined ($form->{'fil'})) {
            $fil = $form->{'fil'};
        }

        if (defined ($form->{'eval'})) {
            $eval = $form->{'eval'};
        }

        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $dolncnt = -1;
            $oldfile = '';

            print $sock "<pre>\n";

            $dolncnt = 0;
            $newfile = '';
            undef $last;
            undef $this;
            undef $next;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $dolncnt++;
                s/\n//g;
                s/\r//g;
                if (!defined ($next)) {
                    $next = $_;
                } elsif (!defined ($this)) {
                    $this = $next;
                    $next = $_;
#                   $newfile .= &txtdopl ($sock, $ctrl, $dolncnt - 1, $last, $this, $next) . "\n";
                    $newfile .= "$_\n";
                } else {
                    $last = $this;
                    $this = $next;
                    $next = $_;
#                   $newfile .= &txtdopl ($sock, $ctrl, $dolncnt - 1, $last, $this, $next) . "\n";
                    $newfile .= "$_\n";
                }
            }
#           $newfile .= &txtdopl ($sock, $ctrl, $dolncnt - 1, $this, $next, undef) . "\n";
            $newfile .= "$_\n";
            if ($newfile ne $oldfile) {
                # write new file only if changed
#               &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
#&l00httpd::l00fwriteOpen($ctrl, $fname);
#               open (OU, ">$form->{'path'}");
#&l00httpd::l00fwriteBuf($ctrl, $buf);
#               print OU $newfile;
#&l00httpd::l00fwriteClose($ctrl);
#               close (OU);
            }
            print $sock "</pre>\n";
        }
    }

    if ((defined ($form->{'run'})) && (defined ($form->{'path'}))) {
        if (open (IN, "<$form->{'path'}")) {
            print $sock "<hr><pre>\n";
            while (<IN>) {
                print $sock "$_";
            }
            print $sock "</pre>\n";
            close (IN);
        }
    }
    print $sock "<a href=\"#__top__\">Jump to top</a>\n";
    print $sock "<a name=\"__end__\"></a><br>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
