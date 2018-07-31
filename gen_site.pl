#! /usr/bin/perl -w
use warnings;
use strict;
use File::Glob;
use Config::Simple;
# Written by:   (John Leary)[git@jleary.cc]
# Date Created: 28 Jul 2018
# Version:      30 Jul 2018
# Dependencies: pandoc, perl, Config::Simple, and rsync

## Config
my $basedir = "$ENV{'HOME'}/Documents/Site";
my $srcdir  = "$basedir/src";
my $outdir  = "$basedir/out";
my $incdir  = "$basedir/inc";
my $config  = new Config::Simple("$basedir/remote.cfg");
my $srvurl  = $config->param("remote");
my %tabmap  = (
                'index.md'    => 'home',
                'posts/'      => 'posts',
                'resume/'     => 'resume',
            );
my $year    = (localtime)[5] + 1900;

## Processing
my %subs=(
    '-g'=>[\&gen_site,$srcdir],
    '-p'=>[\&push    ,undef  ],
    '-n'=>[\&new     ,undef  ],
    '-?'=>[\&help    ,undef  ],
);

my $arg = (defined $ARGV[0] && $subs{$ARGV[0]}) ? $ARGV[0]:'-?'; 
$subs{$arg}->[0]($subs{$arg}->[1]);

sub gen_site{
    return if $_[0] =~ /\.git$/;
    (my $newdir = $_[0]) =~ s/$srcdir/$outdir/g;
    print "Make Dir: $newdir\n";
    mkdir $newdir;
    my $args = '';
    if(-e $_[0]."/.login"){
        $args = '-V login=login';
        print "Handling Login Directory: $_[0]\n";
    }
    foreach(<"$_[0]*">){
        print "Recursing On Directory: $_\n" and &gen_site("$_/") and next if(-d $_);
        (my $file = $_) =~ s/$srcdir/$outdir/g;
        $_ =~ /^$srcdir\/(index\.md|posts\/|resume\/)/g;
        my $tab = 'none';
        $tab  = $tabmap{$1} if defined $1;
        $file =~ s/\.md$/.html/g;
        if($_ =~ /\.(md|html)$/){
            print "Processing: $_ -> $file\n";
            #Possible log hash of file skip here unless md file or template changes
            print `pandoc -s --template=$incdir/template.html $args -V year=$year -V tab=$tab -i $_ -o $file`;
        }
    }
}

sub push{
    chdir $srcdir  or die "Could not chdir into $srcdir\n";
    print "Commit & Publish y/N: ";
    print "Exiting...\n" and exit if(<STDIN>!~ /^[Y|y]/);
    print "Commiting Source to Git\n",;
    #`git commit -a -m "Automatic site update"`;
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
    mkdir "$outdir/media/$name" or die "Could not creat post: $srcdir/media/$name";
}

sub help{
     print <<HELP;
    -g: generates site
    -p: pushes site
    -n: new post
    -?: shows this dialog
HELP
}
