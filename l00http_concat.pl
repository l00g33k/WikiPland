use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($key, $val);
my %config = (proc => "l00http_concat_proc",
              desc => "l00http_concat_desc");


sub l00http_concat_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "concat: Create a new RAM file by concatenate a list of files";
}

sub l00http_concat_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($httphdr, $cnt, $files, $bytes, $buf);


    # create HTTP and HTML headers
    $httphdr = "$ctrl->{'httphead'}$ctrl->{'htmlhead'}$ctrl->{'htmlttl'}$ctrl->{'htmlhead2'}";
    $httphdr .= "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'}<a href=\"#end\">end</a> -\n";
    if (defined ($form->{'path'})) {
        $httphdr .= "Path: <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    }
    print $sock "$httphdr<br>\n";


    print $sock "<form action=\"/concat.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"submit\" name=\"submit\" value=\"Concat\"></td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "</form><p>\n";


    if (defined($form->{'path'}) &&
        &l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $files = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, 'l00://concat.txt');
        $cnt = 0;
        $bytes = 0;
        print $sock "View: <a href=\"/view.htm?path=l00://concat.txt\">l00://concat.txt</a><p>Processing $form->{'path'}:<br>\n";
        # extract filenames
        print $sock "<pre>\n";
        foreach $_ (split("\n", $files)) {
            if (/^ *\d+ \d+\/\d+\/\d+ \d+:\d+:\d+ (.+)/) {
                $_ = $1;
            }
            if (&l00httpd::l00freadOpen($ctrl, $_)) {
                $cnt++;
                print $sock "$cnt: $_\n";
                $buf = &l00httpd::l00freadAll($ctrl);
                $bytes += length($buf);
                &l00httpd::l00fwriteBuf($ctrl, $buf);
                &l00httpd::l00fwriteBuf($ctrl, "\n");
            }
        }
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "<a name=\"end\"></a></pre>Processed $cnt files, $bytes bytes<p><a href=\"#top\">top</a><p>\n";
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
