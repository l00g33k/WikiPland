use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_srcdoc_proc",
              desc => "l00http_srcdoc_desc");
my ($editwd, $editht, $editsz, $root, $filter);
my ($hostpath, $contextln, $blklineno, $level);
$hostpath = "c:\\x\\";
$editsz = 0;
$editwd = 320;
$editht = 7;
$contextln = 0;
$blklineno = 0;
$root = '';
$filter = '\.c$|||\.cpp$|||\.h$';
$level = 3;

sub l00http_srcdoc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "srcdoc: source documentation helper";
}

sub l00http_srcdoc_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $blkbuf, $tgtline, $tgtln);
    my ($pname, $fname, $comment, $buffer, @buf, $tmp, $tmp2, $lnno, $uri, $ii, $cmd, $lasthdrlvl);
    my ($gethdr, $html, $title, $body, $level, $tgtfile, $tgttext);
    my ($tlevel, $tfullpath, $tlnnohi);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
	print $sock "<a href=\"#__toc__\">toc</a>\n";

    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        print $sock " Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
    }
    print $sock "<br>\n";


    # insert notes
    if (defined ($form->{'Save'}) && defined ($form->{'insertlnno'})) {
        $title = '';
        if (defined ($form->{'title'})) {
            $title = $form->{'title'};
        }
        $body = '';
        if (defined ($form->{'body'})) {
            $body = $form->{'body'};
        }
        $level = 1;
        if (defined ($form->{'level'})) {
            $level = $form->{'level'};
        }
        $tgtfile = '(unknown)';
		if (&l00httpd::l00freadOpen($ctrl, "l00://~find_hilite.txt")) {
			if ($_ = &l00httpd::l00freadLine($ctrl)) {
				$tgtfile = $_;
			}
			if ($_ = &l00httpd::l00freadLine($ctrl)) {
				$tgtfile .= "    $_";
			}
		}

        if (open (IN, "<$form->{'path'}")) {
            $lnno = 0;
            $buffer = '';
            for ($ii = 0; $ii < $form->{'insertlnno'}; $ii++) {
                $buffer .= <IN>;
            }
            $buffer .= '=' x $level . $title . '=' x $level . "\n";
            $buffer .= $tgtfile;
            $buffer .= "$body\n";
            while (<IN>) {
                $buffer .= $_;
            }
            close (IN);
            if (open (OU, ">$form->{'path'}")) {
                print OU $buffer;
                close (OU);
            }
        }
    }


    $buffer = '';
    @buf = ();
    if (open (IN, "<$form->{'path'}")) {
        $lnno = 0;
        $root = '';
        $lasthdrlvl = 1;
        while (<IN>) {
            $lnno++;
            if (/^(=+)/) {
                $buffer .= "\n__SRCDOC__$lnno\n";
            }
            $buffer .= $_;
            push(@buf, $_);
        }
        $buffer .= "\n__SRCDOC__$lnno\n";
        close (IN);
    }
    ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;


    if (defined ($form->{'generate'})) {
        l00httpd::dbp($config{'desc'}, "generate outputs ${fname}_index.html in $pname\n"), if ($ctrl->{'debug'} >= 1);
        $html = '';
        $tfullpath = '';
        for ($ii = 0; $ii <= $#buf; $ii++) {
            if (($buf[$ii] =~ /^=+/) && ($tfullpath ne '')) {
                l00httpd::dbp($config{'desc'}, "INSERT target level $tlevel line $tlnnohi in file $tfullpath\n"), if ($ctrl->{'debug'} >= 1);
                $html .= "SRCDOC::${tlevel}::${tfullpath}::${tlnnohi}\n";
                $tfullpath = '';
            }
            $html .= $buf[$ii];
            if (($tmp) = $buf[$ii] =~ /^(=+)/) {
                $tlevel = length($tmp);
                l00httpd::dbp($config{'desc'}, "this line ^= x $tlevel\n"), if ($ctrl->{'debug'} >= 1);
                if (($tfullpath, $tlnnohi) = $buf[$ii + 1] =~ /^(.+)::(\d+) */) {
                    l00httpd::dbp($config{'desc'}, "next line target level $tlevel line $tlnnohi in file $tfullpath\n"), if ($ctrl->{'debug'} >= 1);
                    if (!-f $tfullpath) {
                        l00httpd::dbp($config{'desc'}, "target file not found\n"), if ($ctrl->{'debug'} >= 1);
                        $tfullpath = '';
                    }
                }
            }
        }
        if ($tfullpath ne '') {
            l00httpd::dbp($config{'desc'}, "INSERT target level $tlevel line $tlnnohi in file $tfullpath\n"), if ($ctrl->{'debug'} >= 1);
            $html .= "SRCDOC::${tlevel}::${tfullpath}::${tlnnohi}\n";
            $tfullpath = '';
        }
        if (open(OU, ">$pname${fname}_index.html")) {
            print OU $html;
            close(OU);
        }
    }


    $html = &l00wikihtml::wikihtml ($ctrl, $pname, $buffer, 2);
    $buffer = "<br>\n";
    $buffer .= "<form action=\"/srcdoc.htm\" method=\"get\">\n";
    $buffer .= "<input type=\"submit\" name=\"refresh\" value=\"R&#818;efresh\" accesskey=\"r\">\n";
    $buffer .= "<input type=\"submit\" name=\"generate\" value=\"G&#818;enerate\" accesskey=\"g\">\n";
    $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    $buffer .= "</form>\n";
    foreach $_ (split("\n", $html)) {
        if (/^__SRCDOC__(\d+)/) {
           #$buffer .= "SRCDOC FORM:$1\n";
            if (defined ($form->{'insertlnno'}) && ($form->{'insertlnno'} eq "$1")) {
                if (&l00httpd::l00freadOpen($ctrl, "l00://~find_hilite.txt")) {
                    $tgtfile = &l00httpd::l00freadLine($ctrl);
                    $tgttext = &l00httpd::l00freadLine($ctrl);
                }
               #$buffer .= "INSERT NOTES HERE $form->{'update'}<br>\n";
                $buffer .= "<form action=\"/srcdoc.htm\" method=\"post\">\n";
                $buffer .= "<input type=\"submit\" name=\"Save\" value=\"Save notes here $1\">\n";
                $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                $buffer .= "<input type=\"hidden\" name=\"insertlnno\" value=\"$1\">\n";
                $buffer .= "<input type=\"checkbox\" name=\"pair\">Calling/Return From pair\n";
                $buffer .= "Level: ";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"1\" accesskey=\"1\" checked>1&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"2\" accesskey=\"2\">2&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"3\" accesskey=\"3\">3&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"4\" accesskey=\"4\">4&#818;\n";
                $buffer .= "<input type=\"radio\" name=\"level\" value=\"5\" accesskey=\"5\">5&#818;\n";
                $buffer .= "<p>Title:<br><input type=\"text\" size=\"100\" name=\"title\" value=\"Title\" accesskey=\"t\">\n";
                $buffer .= "<p>Target file: $tgtfile\n\n";
                $buffer .= "    <pre>$tgttext</pre>\n";
                $buffer .= "<p>Description:<br><textarea name=\"body\" cols=\"100\" rows=\"10\" accesskey=\"e\">desc</textarea>\n";
                $buffer .= "</form>\n";
            } else {
                $buffer .= "<form action=\"/srcdoc.htm\" method=\"get\">\n";
                $buffer .= "<input type=\"submit\" name=\"showform\" value=\"Show form here $1\">\n";
                $buffer .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
                $buffer .= "<input type=\"hidden\" name=\"insertlnno\" value=\"$1\">\n";
                $buffer .= "</form>\n";
            }
        } else {
            $buffer .= "$_";
        }
    }
    print $sock "$buffer";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
