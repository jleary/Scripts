#! /usr/bin/perl -w
use warnings;
use strict;
use File::Glob;

# Written by (John Leary)[git@jleary.cc]
# Standardizes/Fixes Markdown Headings Recursively

my $basedir = '/home/jleary/Notes/';
&refactor($basedir);

sub refactor{
    return if $_[0] =~ /\.git$/;
    print "CHDIR: $_[0]\n";
    chdir $_[0];
    (my $outdir = $_[0]) =~ s/$basedir/\/tmp\/Refactor\//g;
    print "MKDIR: $outdir\n";
    mkdir $outdir;
    foreach(<"$_[0]*">){
        my $file = $_;
        print "Checking $_\n";
        (my $file = $_) =~ s/$basedir/\/tmp\/Refactor\//g;
        print "Recursing On Directory: $_\n" and &refactor("$_/") if(-d $_);
        if($_ =~ /\.md$/){
            print "Refactoring $_ -> $file\n";
            open(READ, '<',$_) or die "READ ERROR\n";
            open(WRITE, '+>',$file) or die "WRITE ERROR $!\n";
            my $live = $_;
            while(<READ>){
                my $out = $_;
                #$out    =~ s/^(#*)/$1 /g if $_ =~/^#/g;
                $out    =~ s/^(#*)\s*/$1 /g if $_ =~/^#/g;
                print WRITE $out;
            }
            close READ;
            close WRITE;
            print `cat $file > $live`; #Added when satisfied with result
        }

    }
}
