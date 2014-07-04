
use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple bookmark


my %config = (proc => "l00http_ctags_proc",
              desc => "l00http_ctags_desc");

my ($lvl, $out);

sub l00http_ctags_recurse {
    my ($sock, $dir, $name, $filefrom) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
	my ($file, $partpath, $line, $line4);

    $lvl++;

    if ($lvl < 20) {
        if (opendir (DIR, $dir)) {
            foreach $file (readdir (DIR)) {
      	        if ($file =~ /^\.+$/) {
			        next;
                }
      	        if (!($file =~ /\.cpp$/) &&
                    !($file =~ /\.c$/) &&
                    !($file =~ /\.h$/)) {
			        next;
                }
                if ($file eq $filefrom) {
                    # don't print self
                    next;
                }
      	        if (-d $dir.$file) {
                    &l00http_tree_list ($sock, "$dir$file/");
                } else {
                    if (open (IN, "<$dir$file")) {
                        $partpath = $dir.$file;
                        $partpath =~ s/^$dir//;
                        $line = 0;
                        while (<IN>) {
                            chop;
                            $line++;
                            if (/$name/) {
                                s/($name)/<strong>$1<\/strong>/g;
                                $line4 = sprintf ("%4d", $line);
                                $out .= "    <a href=\"/view.htm?path=$dir$file&lineno=on&hilite=$line#line$line\">$partpath</a>($line4): $_\n";

                            }
                        }
                        close (IN);
                    }
                }
            }
            closedir (DIR);
        }
    }
    $lvl--;
}


sub l00http_ctags_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    # Descriptions to be displayed in the list of modules table
    "ctags: viewer";
}

sub l00http_ctags_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $dir, $name, $file);

    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>ctags viewer</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a href=\"#__end__\">Jump to end</a><hr>\n";


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        $dir = $path;
        $dir =~ s/[^\/]+$//;
    } else {
        $path = '';
        $dir = '';
    }

    print $sock "tags can be an edited version of the tags files by ctags<br>\n";
    print $sock "tags: <a href=\"/ls.htm&path=$path\">$path</a><br>\n";

    print $sock "<form action=\"/ctags.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"display\" value=\"Display\">\n";
    print $sock "tags: <input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"></td>\n";
    print $sock "</form>\n";

    if (open (TAG, "<$path")) {
        print $sock "<pre>\n";
        $lvl = 0;
        while (<TAG>) {
            chop;
            if (/^!/) {
                next;
            }
            if (($name, $file) = split ("\t", $_)) {
                $out = '';
                &l00http_ctags_recurse ($sock, $dir, $name, $file);
                if ($out ne '') {
                    print $sock "\n$name &lt;- $file\n\n$out";
                }
            }
        }
        close (TAG);
        print $sock "</pre>\n";
    }

    print $sock "<hr><a name=\"end\"></a>\n";
    print $sock "<a href=\"#__top__\">Jump to top</a>\n";

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
