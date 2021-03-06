package SBEAMS::Cytometry::Tables;

###############################################################################
# Program     : SBEAMS::Cytometry::Tables
# Author      : Eric Deutsch <edeutsch@systemsbiology.org>
# $Id$
#
# Description : This is part of the SBEAMS::Cytometry module which provides
#               a level of abstraction to the database tables.
#
###############################################################################


use strict;

use SBEAMS::Connection::Settings;


use vars qw(@ISA @EXPORT 
    $TB_ORGANISM
    $TBCY_QUERY_OPTION

    $TBCY_FCS_RUN
    $TBCY_MEASURED_PARAMETERS
    $TBCY_FCS_RUN_PARAMETERS
    $TBCY_SORT_ENTITY	    
    $TBCY_TISSUE_TYPE
    $TBCY_SORT_TYPE
    $TBCY_CYTOMETRY_SAMPLE
    
    $TBCY_BIOSEQUENCE
    $TBCY_BIOSEQUENCE_SET
);


require Exporter;
@ISA = qw (Exporter);

@EXPORT = qw (
    $TB_ORGANISM
    $TBCY_QUERY_OPTION

    $TBCY_FCS_RUN
    $TBCY_MEASURED_PARAMETERS
    $TBCY_FCS_RUN_PARAMETERS
    $TBCY_SORT_ENTITY
    $TBCY_TISSUE_TYPE
    $TBCY_SORT_TYPE
    $TBCY_CYTOMETRY_SAMPLE
    
    $TBCY_BIOSEQUENCE
    $TBCY_BIOSEQUENCE_SET
  
);


#### Get the appropriate database prefixes for the SBEAMS core and this module
my $core = $DBPREFIX{Core};
my $mod = $DBPREFIX{Cytometry};

$TB_ORGANISM                = "${core}organism";
$TBCY_QUERY_OPTION          = "${mod}query_option";

$TBCY_FCS_RUN               = "${mod}fcs_run";
$TBCY_MEASURED_PARAMETERS   = "${mod}measured_parameters";
$TBCY_FCS_RUN_PARAMETERS  = "${mod}fcs_run_parameters";  
$TBCY_SORT_ENTITY = "${mod}sort_entity";
$TBCY_TISSUE_TYPE = "${mod}tissue_type";
$TBCY_SORT_TYPE =  "${mod}sort_type";
$TBCY_CYTOMETRY_SAMPLE = "${mod}cytometry_sample";
$TBCY_BIOSEQUENCE = "${mod}biosequence";
$TBCY_BIOSEQUENCE_SET = "${mod}biosequence_set";

# Modules must return true
1;
