#!/usr/bin/env perl

use strict;
use warnings;

use Carp;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Slice;
use Bio::EnsEMBL::DBSQL::SliceAdaptor;

# Maybe not using any of the packages below
#use LWP::UserAgent;
#use Set::Object;
#use IntervalTree;
#use List::Util;
#use JSON;
#use HTTP::Tiny;
#use Data::Dumper;
#
#use Getopt::Long;


# TO DO - has to use Ensembl Core API rather than REST API, I think

# my $usageMessage = "Usage: $0 <in-gene-list-file> <out-bed-file>\n";
my $usageMessage = "Usage: $0 <in-coord>\n";
if(@ARGV != 1){
  die $usageMessage;
}

my $inChromCoord = $ARGV[0];

print "Processing ${inChromCoord}\n";

my ($inChrom, $inCoord) = split(/:/, $inChromCoord);
my ($inStart, $inEnd) = split(/-/, $inCoord);

print "Chromosome: $inChrom\n";
print "start: $inStart end: $inEnd\n";

# my @enspIDs = getEnsemblProteinIDFromContent($responseContent, $geneName, $id);

my $registry = "Bio::EnsEMBL::Registry";

$registry->load_registry_from_db(
    -host => "ensembldb.ensembl.org", # alternatively "useastdb.ensembl.org"
    -user => "anonymous"
);

my $slice_adaptor = $registry -> get_adaptor("Human", "Core", "Slice");
# Get the slice for requested coordinates
# my $slice = $slice_adaptor->fetch_by_region("chromosome", $inChrom, $inStart, $inEnd);
my $slice = $slice_adaptor -> fetch_by_region("chromosome", $inChrom, $inStart, $inEnd, 1, "GRCh38");

# WVN 5/7/20 Borrowed code to see what we get from this
# The method coord_system() returns a Bio::EnsEMBL::CoordSystem object
my $coord_sys  = $slice->coord_system()->name();
my $cs_version = $slice->coord_system()->version();
my $seq_region = $slice->seq_region_name();
my $start      = $slice->start();
my $end        = $slice->end();
my $strand     = $slice->strand();

# The example code actually ends up getting a coordinate system with name
# "chromosome" (got confused...)
# Version is GRCh38
print "Slice - coord sys: $coord_sys coord sys version: $cs_version seq_region: $seq_region $start-$end ($strand)\n";


# Need to use "Transform" method somehow
# Or "Project" ???
# Decided to use "Project" since it is the most general
# GRCh38
foreach my $segment(@{$slice -> project("chromosome", "GRCh37")}){
# foreach my $segment(@{$slice -> project("chromosome")}){
  my $segSlice = $segment -> to_Slice();
  my $segSliceCS = $segSlice -> coord_system() -> name();
  my $segSliceCSVersion = $segSlice -> coord_system() -> version();
  my $segSliceRegion = $segSlice -> seq_region_name();
  my $segSliceStart = $segSlice -> start();
  my $segSliceEnd = $segSlice -> end();
  my $segSliceStrand     = $segSlice -> strand();
  print "Transformed segment slice - coord sys: $segSliceCS coord sys version: $segSliceCSVersion seq_region: $segSliceRegion $segSliceStart-$segSliceEnd ($segSliceStrand)\n";
}

exit 0;
