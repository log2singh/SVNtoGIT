package SBEAMS::Proteomics::SpecViewer;

###############################################################################
# Program     : SBEAMS::Proteomics::SpecViewer
# Author      : Luis Mendoza <lmendoza (at) systemsbiology dot org>
# $Id$
#
# Description : Contains utilities to display spectra in the Lorikeet viewer
#
# SBEAMS is Copyright (C) 2000-2011 Institute for Systems Biology
# This program is governed by the terms of the GNU General Public License (GPL)
# version 2 as published by the Free Software Foundation.  It is provided
# WITHOUT ANY WARRANTY.  See the full description of GPL terms in the
# LICENSE file distributed with this software.
#
###############################################################################


use strict;
use vars qw($sbeams
           );

use SBEAMS::Connection::DBConnector;
use SBEAMS::Connection::Settings;
use SBEAMS::Connection::TableInfo;

use SBEAMS::Proteomics::AminoAcidModifications;


###############################################################################
# Constructor
###############################################################################
sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    return($self);
}



###############################################################################
# convertMods
#   returns a string of lorikeet-ready mods based on input peptide sequence
###############################################################################
sub convertMods { 
#    my $self = shift;
    my %args = @_;

    my $sequence = $args{'modified_sequence'} || '';

    my $AAmodifications = new SBEAMS::Proteomics::AminoAcidModifications;
    my %supported_modifications = %{$AAmodifications->{supported_modifications}};

    my $mass_type = 'monoisotopic';

    my $modstring = "[ ";

    while ($sequence =~ /\[/) {
	my $index = $-[0];
	if ($sequence =~ /([A-Znc]\[\d+\])/) {
	    my $mod = $1;
	    my $aa = substr($mod,0,1);

	    my $mass_diff = $supported_modifications{$mass_type}->{$mod};
	    if (defined($mass_diff)) {
		$modstring .= "{index: $index, modMass: $mass_diff, aminoAcid: \"$aa\"}, ";
		$sequence =~ s/[A-Znc]\[\d+\]/$aa/;
	    } else {
		print STDERR "ERROR: Mass modification $mod is not supported yet\n";
		return(undef);
	    }
	} else {
	    print STDERR "ERROR: Unresolved mass modification in '$sequence'\n";
	    return(undef);
	}
    }

    #### Remove n-term and c-term notation
    $sequence =~ s/[nc]//g;
    
    #### Fail if imprecise AA's are present
    return(undef) if ($sequence =~ /[BZX]/);

    $modstring .= " ]";

    return ($sequence, $modstring);
}


###############################################################################
# generateSpectrum
#   returns a string of lorikeet spectrum code
###############################################################################
sub generateSpectrum { 
    my $self = shift;
    my %args = @_;

    my $charge   = $args{'charge'};
    my $showA    = $args{'a_ions'} || '[0,0,0]';
    my $showB    = $args{'b_ions'} || '[1,1,0]';
    my $showC    = $args{'c_ions'} || '[0,0,0]';
    my $showX    = $args{'x_ions'} || '[0,0,0]';
    my $showY    = $args{'y_ions'} || '[1,1,0]';
    my $showZ    = $args{'z_ions'} || '[0,0,0]';
    my $scanNum  = $args{'scan'} || '0';
    my $fileName = $args{'name'} || '';
    my $modified_sequence = $args{'modified_sequence'};
    my $precursorMz = $args{'precursor_mass'};

    my $spectrum_aref = $args{'spectrum'};

    my ($sequence,$mods) = &convertMods(modified_sequence => $modified_sequence);


    my $lorikeet_resources = "$HTML_BASE_DIR/usr/javascript/lorikeet";

    my $lorikeet_html = qq%
	<!--[if IE]><script language="javascript" type="text/javascript" src="$lorikeet_resources/js/excanvas.min.js"></script><![endif]-->
	<script type="text/javascript" src="$lorikeet_resources/js/jquery.min.js"></script>
	<script type="text/javascript" src="$lorikeet_resources/js/jquery-ui.min.js"></script>
	<script type="text/javascript" src="$lorikeet_resources/js/jquery.flot.js"></script>
	<script type="text/javascript" src="$lorikeet_resources/js/jquery.flot.selection.js"></script>
	<script type="text/javascript" src="$lorikeet_resources/js/specview.js"></script>
	<script type="text/javascript" src="$lorikeet_resources/js/peptide.js"></script>
	<script type="text/javascript" src="$lorikeet_resources/js/aminoacid.js"></script>
	<script type="text/javascript" src="$lorikeet_resources/js/ion.js"></script>
	<link REL="stylesheet" TYPE="text/css" HREF="$lorikeet_resources/css/lorikeet.css">

	<div id="lorikeet"></div>

	<script type="text/javascript">
	\$(document).ready(function () {

	    \$("#lorikeet").specview({"sequence":sequence,
				      "scanNum":scanNum,
				      "charge":charge,
				      "precursorMz":precursorMz,
				      "fileName":fileName,
				      "showA":showA,
				      "showB":showB,
				      "showC":showC,
				      "showX":showX,
				      "showY":showY,
				      "showZ":showZ,
				      "variableMods":variableMods,
				      "peaks":ms2peaks});
	});

    var showA = $showA;
    var showB = $showB;
    var showC = $showC;
    var showX = $showX;
    var showY = $showY;
    var showZ = $showZ;
    var charge = $charge;
    var scanNum = $scanNum;
    var fileName = "$fileName";
    var sequence = "$sequence";
    var precursorMz = $precursorMz;
    var variableMods = $mods;
    %;

    $lorikeet_html .= "var ms2peaks = [";
    for my $ar_ref (@{$spectrum_aref}) {
	my $mz = $ar_ref->[0];	
	my $in = $ar_ref->[1];
	$lorikeet_html .= "[$mz,$in],\n";
    }
    $lorikeet_html .= "];\n";

    $lorikeet_html .= "</script>\n";


    return $lorikeet_html;
}


###############################################################################

1;

__END__
###############################################################################
###############################################################################
###############################################################################

=head1 NAME

SBEAMS::Proteomics::SpecViewer

=head1 SYNOPSIS

  Methods to dispay spectra in Lorikeet Viewer (+others?)

    use SBEAMS::Proteomics::SpecViewer;


=head1 DESCRIPTION

    This module is new.  More info to come...someday.

=head1 METHODS

=item B<generateSpectrum()>

    Generate spectrum code (mostly javascript)

=item B<convertMods()>

    Returns a string of lorikeet-ready mods based on input peptide sequence

=head1 AUTHOR

Luis Mendoza <lmendoza (at) systemsbiology dot org>

=head1 SEE ALSO

perl(1).

=cut