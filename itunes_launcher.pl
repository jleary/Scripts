#!/usr/bin/perl -w
use strict;
use warnings;

my $file ='';

if (defined $ARGV[0]){
    $file = $ARGV[0];
    $file =~ s/\ / /g;
    $file =~ s/\//\\/g;
    $file = '"Z:' . $file . '"';
    print $file , "\n";
}

my $procs = `pgrep -f iTunes.exe`;
$procs    =~ s/\Q$$//g;

system("env WINEPREFIX='/home/jleary/.wine_iTunes_10_32_prod' WINEARCH=win32 wine '/home/jleary/.wine_iTunes_10_32_prod/dosdevices/c:/Program Files/iTunes/iTunes.exe' $file &");

print "Already running: $procs\npid: $$\n" and exit if $procs !~ /^\s*$/;

my $track = 0;
while(<STDIN>){
    if($_=~/OverviewActive/){
        my $ps = `pgrep -fl iTunes.exe`;
        exit(0) if($ps eq '');
        $track = 1;
        next;
    }
    if($track == 1 && $_=~/boolean true/){
        print `env WINEPREFIX='/home/jleary/.wine_iTunes_10_32_prod' WINEARCH=win32 wine '/home/jleary/.wine_iTunes_10_32_prod/dosdevices/c:/Program Files/iTunes/iTunes.exe' `;
        $track = 0;
    }else{
        $track = 0;
    }
}
