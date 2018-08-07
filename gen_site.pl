#! /usr/bin/perl -w
use warnings;
use strict;
use File::Glob;
use Config::Simple;
# Written by:   (John Leary)[git@jleary.cc]
# Date Created: 28 Jul 2018
# Version:      03 Aug 2018
# Dependencies: pandoc, perl, Config::Simple, and rsync

## Config
### I'm probably going to regret this
### but I added multi site support.
my $site    = defined $ARGV[1]? '/'.$ARGV[1] :  '';
my $config  = new Config::Simple("$ENV{'HOME'}/Site$site/site.cfg") or die "Could not open site.cfg";
my $basedir = "$ENV{'HOME'}/Site";
my $srcdir  = "$basedir/src";
my $outdir  = "$basedir/out";
my $incdir  = "$basedir/inc";
my $srvurl  = $config->param("remote");
my $prefix  = $config->param("prefix");
my %tabmap  = %{$config->get_block('tabs')};

my $year    = (localtime)[5] + 1900;
my $regex   =''; #tab regex
($regex .= "$_|") foreach keys %tabmap;
$regex   =~s#\/#\\/#g; 
chop($regex);

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
        $_ =~ /^$srcdir\/($regex).*/g;
        my $tab = 'none';
        $tab  =  $tabmap{$1} if defined $1;
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
    if($config->param("usegit") =~ /^(True|true)/){
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
    chdir $srcdir and `git add "$srcdir/posts/$name.md"` if lc($config->param('usegit')) eq 'true'; 
    mkdir "$outdir/media/posts/$name" or die "Could not creat post: $srcdir/media/posts/$name";
}

sub view{
    print "Open Url: http://localhost:8000\n";
    system("mini_httpd -p 8000 -d $outdir -h localhost 2>&1 > /dev/null &");
    print "Press [enter] to stop server: ";
    my $a = <STDIN>;
    `killall mini_httpd`;
}

sub help{
     print <<HELP;
    -g: generates site
    -p: pushes site
    -n: new post
    -v: serves site on port 8080 (with mini_httpd)
    -?: shows this dialog
HELP
}
