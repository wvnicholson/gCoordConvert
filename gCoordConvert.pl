#!/usr/bin/env perl

use strict;
use warnings;

use Carp;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Slice;
use Bio::EnsEMBL::DBSQL::SliceAdaptor;

my $usageMessage = "Usage: $0 <in-coord>\n";
if(@ARGV != 1){
  die $usageMessage;
}

my $inChromCoord = $ARGV[0];

print "Processing ${inChromCoord}\n";

my ($inChrom, $inCoord) = split(/:/, $inChromCoord);
my ($inStart, $inEnd) = split(/-/, $inCoord);

my $registry = "Bio::EnsEMBL::Registry";

$registry->load_registry_from_db(
    -host => "ensembldb.ensembl.org", # alternatively "useastdb.ensembl.org"
    -user => "anonymous"
);

my $slice_adaptor = $registry -> get_adaptor("Human", "Core", "Slice");

# Get the slice for requested coordinates
my $slice = $slice_adaptor -> fetch_by_region("chromosome", $inChrom, $inStart, $inEnd, 1, "GRCh38");

# WVN 5/7/20 Borrowed code to see what we get from this
# The method coord_system() returns a Bio::EnsEMBL::CoordSystem object
my $csVersion = $slice -> coord_system() -> version();
my $seqRegion = $slice -> seq_region_name();
my $start      = $slice -> start();
my $end        = $slice -> end();

# The example code gets a "chromosome" coordinate system
# whether it is GRCh37, GRCh38, whatever is the version.
# Version is GRCh38
print "Starting coordinates for $csVersion: chromosome $seqRegion from $start to $end\n\n";

# Decided to use "Project" since it is the most general for converting between coordinate system
foreach my $segment(@{$slice -> project("chromosome", "GRCh37")}){
  my $segSlice = $segment -> to_Slice();
  my $segSliceRegion = $segSlice -> seq_region_name();
  if($segSliceRegion ne $seqRegion){ # Skip instances of segment coordinates transforming to a different region
    next;
  }
  my $segSliceCSVersion = $segSlice -> coord_system() -> version();
  my $segSliceStart = $segSlice -> start();
  my $segSliceEnd = $segSlice -> end();
  my $segSliceStrand     = $segSlice -> strand();
  print "Transformed segment slice coordinates for $segSliceCSVersion: chromosome $segSliceRegion from $segSliceStart to $segSliceEnd; strand $segSliceStrand\n";
}

exit 0;
