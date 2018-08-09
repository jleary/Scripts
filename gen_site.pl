#! /usr/bin/perl -w
use warnings;
use strict;
use File::Glob;
use Config::Tiny;
use Browser::Open qw(open_browser);
# Written by:   (John Leary)[git@jleary.cc]
# Date Created: 28 Jul 2018
# Version:      08 Aug 2018
# Dependencies: pandoc, perl, Config::Tiny,Browser::Open, and rsync
# Deb Packages: pandoc, perl, libconfig-tiny-perl,libbrowser-open-perl, rsync

my $site    = defined $ARGV[1]? '/'.$ARGV[1] :  '';
my $cfg     = Config::Tiny->read("$ENV{'HOME'}/Site$site/site.cfg") or die "Could not open site.cfg";

## Constants
my $basedir = "$ENV{'HOME'}/Site";
my $srcdir  = "$basedir/src";
my $outdir  = "$basedir/out";
my $incdir  = "$basedir/inc";
## Settings Defined in cfg
my $srvurl  = $cfg->{_}->{"remote"} or die "remote not defined in site.cfg";
my $prefix  = $cfg->{_}->{"prefix"} or die "prefix not defined in site.cfg";
my $tabmap  = $cfg->{'tabmap'}      or die "[tabmap] not specified in site.cfg";
my $secure  = $cfg->{'secure'};

my %subs=(
    '-g'=>[\&gen_site,$srcdir],
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
    if($srcdir eq $_[0]){
        $year    = (localtime)[5] + 1900;
        $regex   =''; #tab regex
        ($regex .= "$_|") foreach keys %{$tabmap};
        $regex   =~s#\/#\\/#g; 
        chop($regex);
    }else{
        (undef,$regex,$year) = @_;
    }
    return if $_[0] =~ /\.git$/;
    (my $newdir = $_[0]) =~ s/$srcdir/$outdir/g;
    print "Make Dir: $newdir\n";
    mkdir $newdir;
    foreach(<"$_[0]*">){
        print "Recursing On Directory: $_\n" and &gen_site("$_/",$regex,$year) and next if(-d $_);
        (my $file = $_) =~ s/$srcdir/$outdir/g;
        $_ =~ /^$srcdir\/($regex).*/g;
        my $tab = 'none';
        my $args = '';
        if(defined $1){
            $tab  =  $tabmap->{$1};# if defined $1;
            $args = '-V login=login' if (defined $secure->{$1} && $secure->{$1} eq 'true');
        }
        $file =~ s/\.md$/.html/g;
        if($_ =~ /\.(md|html)$/){
            print "Processing: $_ -> $file\n";
            #Possible log hash of file skip here unless md file or template changes
            print `pandoc -s --template=$incdir/template.html $args -T $prefix -V year=$year -V lang=en -V tab=$tab -i $_ -o $file`;
        }
    }
}

sub push{
    chdir $srcdir  or die "Could not chdir into $srcdir\n";
    print "Commit & Publish y/N: ";
    print "Exiting...\n" and exit if(<STDIN>!~ /^[Y|y]/);
    if(defined $cfg->{_}->{"usegit"} && $cfg->{_}->{"usegit"} eq 'true'){
        print "Commiting Source to Git\n",;
        print `git commit -a -m "Automatic site update on push"`;
    }
    print "Pushing Site\n";
    print `rsync -avz --progress -e "ssh" $outdir/ $srvurl`;
}

sub new{
    stat $srcdir or die "Could not stat $srcdir\n";
    stat $outdir or die "Could not stat $outdir\n";
    my $name = '';
    while($name eq ''){
        print "What would you like to name the post (CTRL-C To Exit): ";
        $name = <STDIN>;
        chomp($name);
        $name = '' if $name eq 'index';
    }
    open(NEW,"+>","$srcdir/posts/$name.md") or die "Could not create post: $name.md\n";
    close NEW;
    if (defined $cfg->{_}->{"usegit"} && lc($cfg->{_}->{"usegit"}) eq 'true'){
        chdir $srcdir;
        print `git add "$srcdir/posts/$name.md"` ; 
    }
    mkdir "$outdir/media/posts/$name" or die "Could not creat post: $srcdir/media/posts/$name";
}

sub view{
    print "Open Url: http://localhost:8000\n";
    system("mini_httpd -p 8000 -d $outdir -h localhost 2>&1 > /dev/null &");
#    system("xdg-open http://localhost:8000");
    open_browser('http://localhost:8000');
    print "Press [enter] to stop server: ";
    my $a = <STDIN>;
    `killall mini_httpd`;
}

sub help{
     print <<HELP;
    -g: generates site
    -p: pushes site
    -n: new post
    -v: serves site on port 8000 (with mini_httpd)
    -?: shows this dialog
HELP
}
