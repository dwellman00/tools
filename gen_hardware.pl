#!/usr/bin/perl
#
# *** MANAGED BY PUPPET - DO NOT EDIT DIRECTLY! ***
#
# Dale Wellman
# 8/31/2014
#
# Script to pull data in from Racktables to MediaWiki pages
#

use Getopt::Std;
use MediaWiki::API;
use DBI;

# Getopts
#	- d: debug output, also sets wiki title to Server_Hardware_Test
#	- o: send output to stdout instead of wiki
#	- s: takes wiki section number to update as argument
#	- t: takes wiki section title as argument
#	- T: takes wiki page name as argument
#
getopts('dos:t:i:T:');

# Print to stdout
if( $opt_o )
{
	$OUT = 1;
}
# Required arguments
if( ! $opt_t || ! $opt_i || ! $opt_T )
{
	USAGE();
	exit 1;
}

$WIKIPAGE	= $opt_T;

# Set debug
#  - must be set after opt_t to override option
if( $opt_d )
{
	$DEBUG = 1;
	$WIKIPAGE = "Server_Hardware_Test";
}

###
# Sets the object type to search for in the racktables DB.
###
$TAGID		= $opt_i;
if( $WIKIPAGE eq "Printers" ) {
  $SQLFILE	= "/data/tools/gen_printers.sql";
} else {
  $SQLFILE	= "/data/tools/gen_hardware.sql";
}

$DATE 		= localtime();

###
# Wiki statics
###
$WIKISERVER	= "it-wiki.company.com";
$WIKIAPI	= "https://it-wiki.company.com/wiki/api.php";
$WIKIUSER	= "someuser";
# *** Not the best security to store password here.  need to revisit.
$WIKIPASS	= "<changeme123>";
if( $opt_s ) { $WIKISECTION = $opt_s; } else { $WIKISECTION = 1; }
if( ! $WIKIPAGE ) { $WIKIPAGE = "Server_Hardware"; }

$SECTION_TITLE = "== $opt_t ==\n\n";

###
# Syntax for start of wiki table
###
if( $WIKIPAGE eq "Server_Hardware" )
{
  $TABLE_HEADER = "{| class=\"wikitable sortable\"\n!'''Device Name'''!!'''Console'''!!'''Tag'''!!'''Device Type'''!!'''Serial No'''!!'''SW Version'''||'''Support End Date'''||'''Type'''!!'''Model'''!!'''Comment'''!!'''Rack'''\n|-\n";
} elsif( $WIKIPAGE eq "Printers" ) {
  $TABLE_HEADER = "{| class=\"wikitable sortable\"\n!'''Device Name'''!!'''Console'''!!'''IDS ID#'''!!'''Toner'''!!'''Tag'''!!'''Device Type'''!!'''Serial No'''!!'''SW Version'''||'''Support End Date'''||'''Type'''!!'''Model'''!!'''Comment'''!!'''Rack'''\n|-\n";
} else {
  $TABLE_HEADER = "{| class=\"wikitable sortable\"\n!'''Device Name'''!!'''Tag'''!!'''Device Type'''!!'''Serial No'''!!'''SW Version'''||'''Support End Date'''||'''Type'''!!'''Model'''!!'''Comment'''!!'''Rack'''\n|-\n";
}

###
# close the wiki table
###
$TABLE_FOOTER = "|}\n\n[[Category:Hardware]]\n<span style='font-size:50%'>Auto-created by $0 on $DATE</span>";

###
# Racktables DB info
###
my $db = "racktables";
my $dbuser = "rackuser";
my $dbpass = "<changeme123>";

###
# Load in the sql file to run
###
open(my $SQL_FH, "<", "$SQLFILE") or die "Can't open sql file: $!\n";
local $/ = undef;
my $sql = <$SQL_FH>;
close $SQL_FH;

###
# Replace variable in SQL file with perl static variable
###
$sql =~ s/\$TAGID/$TAGID/g;

###
# Connect to database
###
my $dbh = DBI->connect("DBI:mysql:database=$db;host=racktables",$dbuser,$dbpass,{'RaiseError' => 1});

my $sth = $dbh->prepare($sql);
$sth->execute();

###
# Begin formating wiki update.  Starts with table header info.
###
push( @wikilines, $TABLE_HEADER );

###
# Build wiki table line entry from database query output
###
while( my @dbrow = $sth->fetchrow_array() )
{
  my $line =  "| ";
  ###
  #  The first two arguments in the SQL are reformated to create a link to the racktables object
  #  entry.  Entry 0 is host or device name.  Entry 1 is the object_id.
  ###
  $id = $dbrow[1];
  $line = $line . "[https://racktables.company.com/index.php\?page=object\&tab=default\&object_id=$id ";
  $host = $dbrow[0];
  $line = $line .  "$host]";
  if( $dbrow[2] )
  {
    $console = "[http://" . $dbrow[2] . " " . $dbrow[2] . "]";
  } else {
    $console = "";
  }
  #
  # If running for Server_Hardware or Printers, we want the second column in the wiki to be a link
  # to the console or web mgmt interface
  # 
  if( $WIKIPAGE eq "Server_Hardware" || $WIKIPAGE eq "Printers" )
  {
    $line = $line . "||" . $console;
  }
  splice( @dbrow, 0, 1 );  # Once used we remove them from the array
  splice( @dbrow, 0, 1 );  # Once used we remove them from the array
  splice( @dbrow, 0, 1 );  # Once used we remove them from the array
  foreach( @dbrow )
  {
    my $record = $_;
    ###
    # Racktables uses special strings for formatting.  Which we get rid of here.
    ###
    if( $record =~ /\%GPASS\%/ ) { $record =~ s/\%GPASS\%/ /; } 
    if( $_ =~ /\[\[/ )
    {
	my @split_record = split(/\|/, $record);
	$split_record[0] =~ s/\[\[//;
	$record = $split_record[0];
    }
    $line = $line . "||" . $record;
  }
  $line = $line . "\n|-\n";
  DEBUG( "$line" );
  push( @wikilines, $line );
}


$sth->finish();
$dbh->disconnect();

if( $OUT )
{
	print "@wikilines\n";
	exit 0;
}

my $mw = MediaWiki::API->new(
	{ api_url => "$WIKIAPI" }
);

# Sets the credentials to log into apache AuthBasic 
$mw->{ua}->credentials(
	'it-wiki.company.com:443',
	'IT User',
	'someuser',
	'<changeme123>'
);

$mw->login( {
	lgname => "$WIKIUSER",
	lgpassword => "$WIKIPASS"
} ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

# Add section title from config file
unshift( @wikilines, "$SECTION_TITLE" );

push( @wikilines, $TABLE_FOOTER );

my $ref = $mw->get_page( { title => $WIKIPAGE } );
unless ( $ref->{missing} ) {
  my $timestamp = $ref->{timestamp};
  $mw->edit( {
	action => 'edit',
	title => $WIKIPAGE,
	basetimestamp => $timestamp,
	section => "$WIKISECTION",  # Edit which section number
	text => "@wikilines",
  } ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
}
DEBUG( "mw->edit finished...\n" );


sub DEBUG
{
        print STDERR "DEBUG: " . "@_" if $DEBUG;
}

sub USAGE
{
        print "Usage: \t$0 [-T Wiki Page Title][-i tagid][-t Section Title]\n\tOptional:  [-d debug][-o output to stdout][-s section number, default: 1]\n";
}


