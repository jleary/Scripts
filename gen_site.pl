#! /usr/bin/perl -w
use warnings;
use strict;
use File::Glob;
use Config::Tiny;
use Browser::Open qw(open_browser);
# Written by:   (John Leary)[git@jleary.cc]
# Date Created: 28 Jul 2018
# Version:      08 Aug 2018
# Dependencies: pandoc, perl, Config::Tiny, Browser::Open, and rsync
# Deb Packages: pandoc, perl, libconfig-tiny-perl, libbrowser-open-perl, rsync
# Todo:
##    - make fully platform agnostic (replace mini_httpd,deal w/ paths),
##    - replace recursion with loop and stack

my $site    = defined $ARGV[1]? '/'. $ARGV[1] :  '';

## Constants
my $BASEDIR = "$ENV{'HOME'}/Site$site";
my $SRCDIR  = "$BASEDIR/src";
my $OUTDIR  = "$BASEDIR/out";
my $INCDIR  = "$BASEDIR/inc";

&init() and exit if $ARGV[0] eq '-i'; 

## Required Settings
my $cfg     = Config::Tiny->read("$ENV{'HOME'}/Site$site/site.cfg") or die "Could not open site.cfg";
die "remote not defined in site.cfg" if !defined $cfg->{_}->{'remote'};
die "prefix not defined in site.cfg" if !defined $cfg->{_}->{'prefix'};
die "tabmap not defined in site.cfg" if !defined $cfg->{'tabmap'};

my %subs=(
    '-g'=>[\&gen_site,$SRCDIR],
    '-p'=>[\&push    ,undef  ],
    '-n'=>[\&new     ,undef  ],
    '-v'=>[\&view    ,undef  ],
    '-?'=>[\&help    ,undef  ],
);

my $arg = (defined $ARGV[0] && $subs{$ARGV[0]}) ? $ARGV[0]:'-?'; 
$subs{$arg}->[0]($subs{$arg}->[1]);

## Functions

sub gen_site{
    (my $regex, my $year);
    if($SRCDIR eq $_[0]){ #Base condition
        $year    = (localtime)[5] + 1900;
        $regex   =''; #tab regex
        ($regex .= "$_|") foreach keys %{$cfg->{'tabmap'}};
        $regex   =~s#(\/|\.)#\\$1#g; 
        chop($regex);
    }else{
        (undef,$regex,$year) = @_;
    }
    return if $_[0] =~ /\.git$/;
    (my $newdir = $_[0]) =~ s/$SRCDIR/$OUTDIR/g;
    print "Make Dir: $newdir\n";
    mkdir $newdir;
    foreach(<"$_[0]*">){
        print "Recursing On Directory: $_\n" and &gen_site("$_/",$regex,$year) and next if(-d $_);
        (my $file = $_) =~ s/$SRCDIR/$OUTDIR/g;
        $_ =~ /^$SRCDIR\/($regex).*/g;
        my $tab = 'none';
        my $login = '';
        if(defined $1){
            $tab   =  $cfg->{'tabmap'}->{$1};# if defined $1;
            $login = '-V login=login' if (defined $cfg->{'secure'}->{$1} && $cfg->{'secure'}->{$1} eq 'true');
        }
        $file =~ s/\.md$/.html/g;
        if($_ =~ /\.(md|html)$/){
            print "Processing: $_ -> $file\n";
            print `pandoc -s --template=$INCDIR/template.html $login -T "$cfg->{_}->{'prefix'}" -V year=$year -V lang=en -V tab=$tab -i $_ -o $file`;
        }
    }
}

sub push{
    chdir $SRCDIR  or die "Could not chdir into $SRCDIR\n";
    print "Commit & Publish y/N: ";
    print "Exiting...\n" and exit if(<STDIN>!~ /^[Y|y]/);
    if(defined $cfg->{_}->{"usegit"} && lc($cfg->{_}->{"usegit"}) eq 'true'){
        print "Commiting Source to Git\n",;
        print `git commit -a -m "Automatic site update on push"`;
    }
    print "Pushing Site\n";
    print `rsync -avz --progress -e "ssh" $OUTDIR/ $cfg->{_}->{"remote"}`;
}

sub new{
    stat $SRCDIR or die "Could not stat $SRCDIR\n";
    stat $OUTDIR or die "Could not stat $OUTDIR\n";
    my $name = '';
    while($name eq ''){
        print "What would you like to name the post (CTRL-C To Exit): ";
        $name = <STDIN>;
        chomp($name);
        $name = '' if $name eq 'index';
    }
    open(NEW,"+>","$SRCDIR/posts/$name.md") or die "Could not create post: $name.md\n";
    close NEW;
    if (defined $cfg->{_}->{"usegit"} && lc($cfg->{_}->{"usegit"}) eq 'true'){
        chdir $SRCDIR;
        print `git add "$SRCDIR/posts/$name.md"` ; 
    }
    mkdir "$OUTDIR/media/posts/$name" or die "Could not creat post: $SRCDIR/media/posts/$name";
}

sub init{
    print "Directory exists... Exiting.\n" and exit if (-d $BASEDIR);
    print "Make Dir: base directory\n"     and mkdir $BASEDIR         or die "Could not create base directory";
    print "Make Dir: source directory\n"   and mkdir $SRCDIR          or die "Could not create source directory";
    print "Make Dir: posts directory\n"    and mkdir "$SRCDIR/posts"  or die "Could not create source directory";
    print "Make Dir: output directory\n"   and mkdir $OUTDIR          or die "Could not create output directory";
    print "Make Dir: includes directory\n" and mkdir $INCDIR          or die "Could not create includes directory";
    print "Write File: template.html\n"    and `pandoc -D html > $INCDIR/template.html`;
    print "Write File: site.cfg\n" and open(my $sc, '>', "$BASEDIR/site.cfg") or die "Could not open site.cfg for writing.";
    print $sc <<EOF;
;remote   = username\@rsync.example.com
;prefix   = Title Of Site
;usegit   = false ; whether or not you want to perform a git commit on the directory
;[tabmap]
;;file location mapped to tab name
;index.md    = home
;login/      = login
;[secure]
;;list of login tab keys
;;login/     = true
EOF
    close $sc;

}
sub view{
    print "Open Url: http://localhost:8000\n";
    system("mini_httpd -p 8000 -d $OUTDIR -h localhost 2>&1 > /dev/null &");
    open_browser('http://localhost:8000');
    print "Press [enter] to stop server: ";
    my $a = <STDIN>;
    `killall mini_httpd`;
}

sub help{
     print <<HELP;
    -i: initializes a site
    -g: generates site
    -p: pushes site
    -n: new post
    -v: serves site on port 8000 (with mini_httpd)
    -?: shows this dialog
HELP
}
