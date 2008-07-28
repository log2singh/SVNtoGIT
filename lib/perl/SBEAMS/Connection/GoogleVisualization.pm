###############################################################################
# $Id: $
#
# Description :  Wrapper for Google Visualizations
#
# SBEAMS is Copyright (C) 2000-2008 Institute for Systems Biology
# This program is governed by the terms of the GNU General Public License (GPL)
# version 2 as published by the Free Software Foundation.  It is provided
# WITHOUT ANY WARRANTY.  See the full description of GPL terms in the
# LICENSE file distributed with this software.
#
###############################################################################

package SBEAMS::Connection::GoogleVisualization;
use strict;

use SBEAMS::Connection;
use SBEAMS::Connection::Log;

use POSIX;

my $log = SBEAMS::Connection::Log->new();
my $sbeams = SBEAMS::Connection->new();

##### Public Methods ###########################################################

#+
# Constructor method.
#
sub new {
  my $class = shift;
  my $this = {
		           '_packages' => {},
							 '_callbacks' => [],
							 '_functions' => [],
							 '_charts' => 0,
							 '_tables' => 0,
               @_
             };
  bless $this, $class;
  return $this;
}

sub setDrawBarChart {
  # Get passed args
	my $self = shift;
	my %args = @_;

  # Required!
	for my $arg ( qw( samples data_types headings ) ) {
	  unless ( $args{$arg} ) {
			$log->error( "Missing required option $arg");
			return undef;
		}
	  unless ( ref $args{$arg} eq 'ARRAY' ) {
			$log->error( "Required option $arg must be an ARRAY, not " . ref $args{$arg} );
			return undef;
		}
	}
	if ( scalar( @{$args{headings}} ) != scalar( @{$args{data_types}} ) ) {
    $log->error( "Headings and data type arrays must have same size" );
    return undef;
	}

	# Set defaults
	$args{show_table} ||= 0;
	my $height = $args{height} || 0;
	my $width = $args{width} || 800;


  # Tally information
	$self->{_packages}->{barchart}++; 
	$self->{'_charts'}++;
	if( $args{show_table} ) {
  	$self->{_packages}->{table}++; 
	}

  # set script vars
  my $chart = 'chart' . $self->{'_charts'}; 
  my $table = 'table' . $self->{'_tables'}; 
  # Just want the div name for now...
  my $chart_div = $chart . '_div'; 
  my $table_div = $table . '_div'; 
  my $chart_fx = 'draw_' . $chart; 
  my $table_fx = 'draw_' . $table; 

	my $table_script = 

  push @{$self->{'_callbacks'}}, $chart_fx;

  my $n_rows = scalar( @{$args{samples}} );

	my $fx = <<"  END";
  function $chart_fx() {
    var data = new google.visualization.DataTable();
  END
	for ( my $i = 0; $i <= $#{$args{headings}}; $i++ ) {
    $fx .= " data.addColumn('$args{data_types}->[$i]', '$args{headings}->[$i]');\n";
	}
	$fx .= " data.addRows( $n_rows );\n"; 
  my $sample_cnt = 0;
  my $sample_list = '';
	for my $s ( @{$args{samples}} ) {
    my $posn = 0;
		for my $c ( @$s ) {
	    # caller requested labels be truncated (will affect table too!)
		  if ( $args{truncate_labels} && !$posn ) {
			  $c = $sbeams->truncateString( string => $c, len => $args{truncate_labels} );
	    }
			if ( $args{data_types}->[$posn] eq 'number' ) {
    		$sample_list .= " data.setValue($sample_cnt, $posn, $c );\n";
			} else {
    		$sample_list .= " data.setValue($sample_cnt, $posn, '$c' );\n";
			}
			$posn++;
		}
		$sample_cnt++;
	}
	$height = $height || 50 + $n_rows * 16;
#	, title: 'Experiment Contribution'});

  my $table_js = '';
	if( $args{show_table} ) {
    $table_js =<<"    END";
    var table = new google.visualization.Table(document.getElementById('$table_div'));
    table.draw(data, {showRowNumber: true});
    END
	}


  $fx .=<<"  END";
  $sample_list
  $table_js
  var chart = new google.visualization.BarChart(document.getElementById('$chart_div'));
  chart.draw(data, {width: $width, height: $height, is3D: true } );
  }
  END

  push @{$self->{'_functions'}}, $fx;

	# Put divs into markup for return to caller
  $chart_div = '<DIV id="' . $chart . '_div' . '"></DIV>'; 
  $table_div = '<DIV id="' . $table . '_div' . '"></DIV>'; 
  
	if ( $args{show_table} ) {
		if ( wantarray ) {
			return ( $chart_div, $table_div );
		}
		return( "$chart_div\n$table_div" );
	}
	return $chart_div;

}


#+
# To be called last!
#-
sub getHeaderInfo {
	my $self = shift;
	my %args = @_;
	my $pkgs = '';
	my $sep = '';
	for my $p ( keys( %{$self->{'_packages'}} ) ) {
		$pkgs .= $sep . '"' . $p . '"'; 
		$sep = ', ';
	}
	my $callbacks = '';
	for my $callback ( @{$self->{'_callbacks'}} ) {
		$callbacks .= "google.setOnLoadCallback($callback);";
	}
	my $functions = '';
	for my $function ( @{$self->{'_functions'}} ) {
		$functions .= "$function\n";
	}

  my $header_info =<<"  END_SCRIPT";
  <script type="text/javascript" src="https://www.google.com/jsapi"></script>
  <script type="text/javascript">
    google.load("visualization", "1", {packages:[$pkgs]});
		$callbacks
		$functions
  </script>
  END_SCRIPT

  return $header_info;
}

1;

