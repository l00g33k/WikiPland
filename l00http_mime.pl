use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_mime_proc",
              desc => "l00http_mime_desc");
my ($buffer, $lastbuf);
$lastbuf = '';


sub l00http_mime_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "mime: Simple blogger: must be invoked through ls.pl file view";
}

sub l00http_mime_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $path, $buforg, $buforgpre, $fname);
    my ($output, $keys, $key, $space);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname blog</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> <a href=\"#end\">Jump to end</a><br>\n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> %BLOG:key%:<br>\n";
    } else {
        print $sock "%BLOG:key% quick save link:<br>\n";
    }
    if (defined ($form->{'pastesave'})) {
        $_ = $ctrl->{'droid'}->getClipboard()->{'result'};
        print $sock "<hr>$_<hr>\n";
    }

    $buffer = '';

    # do funny tricks to switch log style
    if (defined ($form->{'logstyle'})) {
    }

    print $sock "<form action=\"/blog.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"set\" value=\"Set\">\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"><br>\n";
    print $sock "Header: <input type=\"text\" size=\"16\" name=\"header\" value=\"$form->{'header'}\">\n";
    print $sock "</form>\n";

    print $sock "<hr><a name=\"end\"></a>";
    print $sock "<a href=\"#__top__\">top</a>\n";
    print $sock "<br>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
