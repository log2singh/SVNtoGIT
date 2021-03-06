#!/usr/local/bin/perl -w

###############################################################################
# Program     : misc_db_fix.pl
# Author      : Eric Deutsch <edeutsch@systemsbiology.org>
# $Id$
#
# Description : This script performs miscellaneous data fixing tasks
###############################################################################


###############################################################################
# Generic SBEAMS setup for all the needed modules and objects
###############################################################################
use strict;
use Getopt::Long;
use FindBin;

use lib qw (../perl ../../perl);
use vars qw ($sbeams $sbeamsMOD $q
             $PROG_NAME $USAGE %OPTIONS $QUIET $VERBOSE $DEBUG $DATABASE
	     $TESTONLY
             $current_contact_id $current_username
	     $fav_codon_frequency
            );

#### Set up SBEAMS core module
use SBEAMS::Connection;
use SBEAMS::Connection::Settings;
use SBEAMS::Connection::Tables;

use SBEAMS::Proteomics;
use SBEAMS::Proteomics::Settings;
use SBEAMS::Proteomics::Tables;

$sbeams = SBEAMS::Connection->new();
$sbeamsMOD = SBEAMS::Proteomics->new();
$sbeamsMOD->setSBEAMS($sbeams);


###############################################################################
# Set program name and usage banner for command like use
###############################################################################
$PROG_NAME = $FindBin::Script;
$USAGE = <<EOU;
Usage: $PROG_NAME [OPTIONS]
Options:
  --verbose n          Set verbosity level.  default is 0
  --quiet              Set flag to print nothing at all except errors
  --debug n            Set debug flag
  --testonly           If set, rows in the database are not changed or added
  --fix_search_batch_data_location    Apply various rules to repair
                       data_location in the search_batch table
                       the biosequence_name
  --show_data_location Show the data locations of the specified search_batches

 e.g.:  $PROG_NAME --fix_search_batch_data_location

EOU


#### Process options
unless (GetOptions(\%OPTIONS,"verbose:s","quiet","debug:s","testonly",
  "fix_search_batch_data_location","show_data_location:s",
  )) {
  print "$USAGE";
  exit;
}

$VERBOSE = $OPTIONS{"verbose"} || 0;
$QUIET = $OPTIONS{"quiet"} || 0;
$DEBUG = $OPTIONS{"debug"} || 0;
$TESTONLY = $OPTIONS{"testonly"} || 0;
if ($DEBUG) {
  print "Options settings:\n";
  print "  VERBOSE = $VERBOSE\n";
  print "  QUIET = $QUIET\n";
  print "  DEBUG = $DEBUG\n";
  print "  TESTONLY = $TESTONLY\n";
}


###############################################################################
# Set Global Variables and execute main()
###############################################################################
main();
exit(0);


###############################################################################
# Main Program:
#
# Call $sbeams->Authenticate() and exit if it fails or continue if it works.
###############################################################################
sub main {

  #### Do the SBEAMS authentication and exit if a username is not returned
  exit unless ($current_username = $sbeams->Authenticate(
    work_group=>'Proteomics_admin',
  ));


  $sbeams->printPageHeader() unless ($QUIET);
  handleRequest();
  $sbeams->printPageFooter() unless ($QUIET);


} # end main



###############################################################################
# handleRequest
###############################################################################
sub handleRequest { 
  my %args = @_;


  #### Define standard variables
  my ($i,$element,$key,$value,$line,$result,$sql);


  #### Set the command-line options
  my $fix_search_batch_data_location =
    $OPTIONS{"fix_search_batch_data_location"} || '';
  my $show_data_location =
    $OPTIONS{"show_data_location"} || '';


  #### Print out the header
  unless ($QUIET) {
    $sbeams->printUserContext();
    print "\n";
  }


  if ($fix_search_batch_data_location) {
    print "Fixing search_batch data_locations...\n";
    fix_search_batch_data_location();
  }

  elsif ($show_data_location) {
    print "Showing search_batch data_locations...\n";
    show_data_location(search_batch_ids => $show_data_location);
  }

  else {
    print $USAGE;
  }


  return;

} # end handleRequest



###############################################################################
# fix_search_batch_data_location
###############################################################################
sub fix_search_batch_data_location {
  my %args = @_;
  my $SUB_NAME = 'fix_search_batch_data_location';


  #### Get information about this biosequence_set_id from database
  my $sql = "
          SELECT search_batch_id,data_location
            FROM $TBPR_SEARCH_BATCH
  ";
  my %rows = $sbeams->selectTwoColumnHash($sql);


  #### Loop over all results
  while (my ($search_batch_id,$data_location) = each %rows) {

    my $need_update = 0;
    my $orig_data_location = $data_location;

    #### Check to see if the prefix needs fixing
    if ($data_location  =~ m~/net/db/projects/proteomics/data~) {
      $data_location  =~ s~/net/db/projects/proteomics/data~/data3/sbeams/archive~;
      $need_update = 1;
    }


    #### Check to see if a name needs fixing
    if ($data_location  =~ m~erich/~) {
      $data_location  =~ s~erich/~ebrunner/~;
      $need_update = 1;
    }


    #### Check to see if a name needs fixing
    if ($data_location  =~ m~priska/~) {
      $data_location  =~ s~priska/~phaller/~;
      $need_update = 1;
    }


    if ($need_update) {
      print "$orig_data_location ==> $data_location\n";

      my %rowdata = (data_location=>$data_location);

      #### INSERT/UPDATE the row
      my $result = $sbeams->updateOrInsertRow(
					      update=>1,
					      table_name=>$TBPR_SEARCH_BATCH,
					      rowdata_ref=>\%rowdata,
					      PK=>'search_batch_id',
					      PK_value => $search_batch_id,
					      verbose=>$VERBOSE,
					      testonly=>$TESTONLY,
					     );

    } else {
      print "$orig_data_location OK\n";
    }

  }


}



###############################################################################
# show_data_location
###############################################################################
sub show_data_location {
  my %args = @_;
  my $SUB_NAME = 'show_data_location';

  my $search_batch_ids = $args{"search_batch_ids"} || 0;

  #### Get information about this biosequence_set_id from database
  my $sql = "
          SELECT search_batch_id,data_location
            FROM $TBPR_SEARCH_BATCH
           WHERE search_batch_id IN ( $search_batch_ids )
  ";
  my %rows = $sbeams->selectTwoColumnHash($sql);


  #### Loop over all results
  while (my ($search_batch_id,$data_location) = each %rows) {

    $data_location = "/sbeams/archive/$data_location"
      unless ($data_location =~ /^\//);

    my $model_file = "$data_location/interact-prob-data.model";

    $model_file =~ s/^\/data3//;

    if ( -e $model_file) {
      print "$model_file\n";
    } elsif ( -e "$model_file.txt" ) {
      print "$model_file.txt\n";
    } else {
      $model_file =~ s/-prob-/-/;

      if ( -e $model_file) {
	print "$model_file\n";
      } elsif ( -e "$model_file.txt" ) {
	print "$model_file.txt\n";
      } else {
	print "Missing $model_file\n";
      }
    }


  }


}



