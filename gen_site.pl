#! /usr/bin/perl -w
use warnings;
use strict;
use File::Glob;

# Written by: (John Leary)[git@jleary.cc]
# Version:    28 Jul, 2018
# Dependencies: pandoc, perl, and rsync

## Config
my $basedir = '/home/jleary/Documents/Site';
my $srcdir  = "$basedir/src";
my $outdir  = "$basedir/out";
my $incdir  = "$basedir/inc";
my $srvurl  = "/tmp/test";
my %tabmap  = (
                'index.md'    => 'home',
                'posts/'      => 'posts',
                'resume/'     => 'resume',
            );

## Processing
my %subs=(
    '-g'=>[\&gen_site,$srcdir],
    '-p'=>[\&push,],
    '-?'=>[\&help,],
);

my $arg = (defined $ARGV[0] && $subs{$ARGV[0]}) ? $ARGV[0]:'-?'; 
$subs{$arg}->[0]($subs{$arg}->[1]);

sub gen_site{
    return if $_[0] =~ /\.git$/;
    print "Change Dir: $_[0]\n";
    chdir $_[0];
    (my $newdir = $_[0]) =~ s/$srcdir/$outdir/g;
    print "Make Dir: $newdir\n";
    mkdir $newdir;
    foreach(<"$_[0]*">){
        print "Recursing On Directory: $_\n" and &gen_site("$_/") and next if(-d $_);
        (my $file = $_) =~ s/$srcdir/$outdir/g;
        $_ =~ /^$srcdir\/(index\.md|posts\/|resume\/)/g;
        my $tab = 'none';
        $tab = $tabmap{$1} if defined $1;
        $file =~ s/\.md$/.html/g;
        if($_ =~ /\.md$/){
            print "Processing $_ -> $file\n";
            print `pandoc -s --template=$incdir/template.html -V tab=$tab -i $_ -o $file`;
        }
    }
}

sub push{
    (chdir $srcdir and print "Commit & Publish y/N: ") or die "Could not chdir into $srcdir\n";
    print "Exiting...\n" and exit if(<STDIN>!~ /^[Y|y]/);
    print "Commiting Source to Git\n",;#`git commit -a -m "Automatic site update";git push`;
    print "Pushing Site\n",`rsync -a $outdir/ $srvurl `;
}

sub help{
     print <<HELP;
    -g: generates site
    -p: pushes site
    -?: shows this dialog
HELP
}
