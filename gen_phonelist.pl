#!/usr/bin/perl
#
# *** MANAGED BY PUPPET - DO NOT EDIT DIRECTLY! ***
#
# Dale Wellman
# 6/10/2014
#
# Script to parse active directory users and build wiki phone list
#

use Getopt::Std;
use Net::LDAP;
use Net::LDAP::Control::Sort;
use MediaWiki::API;

getopts('do:s:');

# Set debug
if( $opt_d )
{
	$DEBUG = 1;
	$WIKIPAGE = "Phone_List_Test";
}
if( ! $opt_o || ! $opt_s)
{
	USAGE();
	exit 1;
}

$OU             = $opt_o;
$WIKISECTION    = $opt_s;

# Read in conf file for ignore extensions and always include extensions
do "/data/tools/gen_phonelist.$OU" || die $@ ;

$PRINTVERSION	= "/data/www/html/wiki.company.com/phonelist.html";

# LDAP statics
$ADSERVER	= "ad.company.local";
$SEARCHOU	= "ou=$OU,dc=company,dc=local";
$SEARCHUSER	= "CN=Query Account,CN=Users,DC=company,DC=local";
$SEARCHPASS	= "<changeme123>";
#$SEARCHATTRS	= "sn, givenname, telephonenumber, info";
$SEARCHFILTER	= "telephonenumber=*";

# Wiki statics
$WIKISERVER	= "wiki.company.com";
$WIKIAPI	= "https://wiki.company.com/wiki/api.php";
$WIKIUSER	= "someuser";
$WIKIPASS	= "<changeme123>";
if( ! $WIKIPAGE ) { $WIKIPAGE = "Phone_List"; }

# write print friendly version
open( FS, ">$PRINTVERSION") || die "$@";

# Create connection
DEBUG( "Connecting to $ADSERVER...\n" );
my $ldap = Net::LDAP->new ( "$ADSERVER" ) or die "$@";

# Bind to AD
DEBUG( "Binding to $ADSERVER with $SEARCHUSER...\n" );
$ldap->bind( "$SEARCHUSER", password => "$SEARCHPASS" ) or die "$@";

#
# This controls how we sort the incoming LDAP search from AD.  Not critical, it
# just makes the initial wiki page a little cleaner.  We are sorting by first name
# below.
#
my $sort_control = Net::LDAP::Control::Sort->new( 
	order => "givenname"
);

# Perform search on telephonenumber attribute
DEBUG( "Searching $SEARCHOU, filter $SEARCHFILTER for attrs $SEARCHATTRS...\n" );
my $results = $ldap->search ( 
	base	=> "$SEARCHOU",
	attrs	=> "$SEARCHATTRS",
	filter	=> "$SEARCHFILTER",
	control	=> [ $sort_control ],
);

my @lines = "\n[http://wiki.company.com/phonelist.html Printer Friendly Version]\n" ;

push( @lines, $TABLE_HEADER );

# Loop through results and build wiki table
DEBUG( "Building phone list...\n" );
my $count = $results->count;
my $midcount = int( ($count + $#STATIC_EXTENSIONS - 1) / 2 );
print FS '<html>
<STYLE type="text/css"> TABLE  { border: solid black; empty-cells: show }</STYLE>
<table width=800><tr><td width=400><table border=1 width=400>
			<tr><th>Name</th> <th>Ext</th> <th>Notes</th></tr>
'; 

for( my $i=0; $i<$count; $i++)
{
	my $entry = $results->entry($i);

	# Skip entry if extension is in the IGNORE_EXT variable
	my $tele = $entry->get_value('telephonenumber');
	next if( $IGNORE_EXT{$tele} ); 

	my $name = $entry->get_value('givenname') . " " . $entry->get_value('sn');
	my $printerline = "<tr><td> " . $name . "</td><td>" . 
		$entry->get_value('telephonenumber') . "</td><td>" .
		$entry->get_value('info') . "</td></tr>\n";
	print FS $printerline;
	my $line = "| " . $entry->get_value('givenname') . "||" . 
		$entry->get_value('sn') . "||" .
		$entry->get_value('telephonenumber') . "||" .
		$entry->get_value('department') . "||" .
		$entry->get_value('info') . "\n";
	DEBUG( "Adding: $line" );
	push( @lines, $line );
	if( $i == $midcount )
	{
		print FS "</table></td><td width=400 valign=top><table border=1 width=400>
				<tr><th>Name</th> <th>Ext</th> <th>Notes</th></tr>\n";
	}
	push( @lines, "|-\n" );
}

# This whole routine just makes the config file cleaner.  Uses multidimentional perl
# array in conf file.
my $i=0;
DEBUG( "Adding static extensions to list...\n" );
for my $array (@STATIC_EXTENSIONS)
{
	my $j=0;
	my $line = "| ";
	print FS "<tr>"; 
	for my $cell (@$array)
	{
		$line = $line . $STATIC_EXTENSIONS[$i][$j];
		#
		#  this is gross but it works for now
		#
		print FS "<td> $STATIC_EXTENSIONS[$i][$j] </td>"; 
		next if $j == 2;
		$line = $line . "||||"; 
		$j++;
	}
	print FS "</tr>"; 
	$line = $line . "\n";
	DEBUG( "Adding: $line" );
	$line = $line . "|-\n";
	push(@lines, $line);
	$i++;
}

push(@lines, $TABLE_FOOTER);
print FS "</td></tr></table></td></tr></table></html>\n";
close FS;


# Logout of AD
$ldap->unbind;

## DEBUG
#foreach $l (@lines)
#{
#	print $l;
#}

my $mw = MediaWiki::API->new( 
	{ api_url => "$WIKIAPI" }
);

$mw->login( {
	lgname => "$WIKIUSER", 
	lgpassword => "$WIKIPASS" 
} ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

# Add section title from config file
unshift( @lines, "$SECTION_TITLE" );

my $ref = $mw->get_page( { title => $WIKIPAGE } );
unless ( $ref->{missing} ) {
  my $timestamp = $ref->{timestamp};
  $mw->edit( {
	action => 'edit',
	title => $WIKIPAGE,
	basetimestamp => $timestamp,
	section => "$WIKISECTION",  # Edit which section number
	text => "@lines",
  } ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
}
DEBUG( "mw->edit finished...\n" );



sub DEBUG
{
	print STDERR "DEBUG: " . "@_" if $DEBUG;
}

sub USAGE
{
	print "Usage: \t$0 -o \"AD OU to search\" -s \"Wiki section to update\" [-d debug]\n";
}

