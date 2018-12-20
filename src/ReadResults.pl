#!/usr/bin/perl

use strict;
use warnings; no warnings 'uninitialized';
use File::Basename;
use Tie::File;

#############################################################################
# Subroutines for Reads Results                                             #
#############################################################################


# Global ARGVs
my $comName;
my $outFormat;
###
# Normal Functionality
my $linesCorrectlyTurned = 0;
my $totalAtoms           = 0;
my $flagStart            = 0;
# Sigma Pi
my @orbitals;
my $FirstOrbitalPosition;
# 0 means NBO was not done
my $NBOGood = 0;
# Core + Valence
my $Valencia;
my $Core;
my $TotalLewisOrbital;
# Lewis + Non-Lewis
my $TotalLewisAndNL;
# Lines no relevant information between each MO information
my $AmountofTrashLines = 54;
my $Pi                 = 0;
my $Sigma              = 0;	
###
#
my $outputName         = "ValuesICSS" ;
# Gaussian line position
my $atomStarts;
my $atomEND = -1;
my $tensorStarts;

###################################
# Subroutine: The .com files is not loaded into memory.
sub SetSpecialLinePosition {
	my ($file)     = @_;
	my $lineNumber = 0;
	#
	tie my @data, 'Tie::File', $file, memory=>4_000_000_000;
	# Set line numbers
	foreach my $line (@data){
		if( $line=~/Center/ && $line=~/Coordinates/ && $line=~/Angstroms/ ){
			$atomStarts = $lineNumber+3;
		}
		if( $line=~/Distance/ && $line=~/matrix/ && $line=~/angstroms/ ){
			$atomEND = $lineNumber - 1;
		} elsif( $line=~/Rotational/ && $line=~/GHZ/ && $atomEND == -1 ){
			$atomEND = $lineNumber - 1;
		}
		if( $line=~/SCF/ && $line=~/GIAO/ && $line=~/shielding/ && $line=~/tensor/ ){
			$tensorStarts = $lineNumber + 1;
			last;
		}
		$lineNumber++;
	}
	untie @data;
}
###################################
# Subroutine that sets NBO data information.
sub NBOAnalysisData{
	my ($file)     = @_;
	my $lineNumber = 0;
	open(GAUSSIAN , "$file");
	my $ValencePosition=0;
	my $numAllOrbitals;
	my $CorePosition;
	# Set line numbers
	foreach my $line (<GAUSSIAN>){
		if( $line=~/NATURAL/ && $line=~/CHEMICAL/ && $line=~/SHIELDING/ && $line=~/ANALYSIS/ ){
			$NBOGood = 1;  #1 means NBO was calculated
		}elsif( $line=~/Valence/ && $line=~/Lewis/ && $ValencePosition==0){
			$ValencePosition = $lineNumber;
			$CorePosition= $lineNumber -1;
		}elsif( $line=~/Rydberg/ && $line=~/non-Lewis/){
			$numAllOrbitals=$lineNumber - 4;
		} elsif( $line=~/Canonical/ && $line=~/MO/ && $line=~/contributions/ ){
			#push @OrbitalsPositionList, $lineNumber;
			$FirstOrbitalPosition=$lineNumber+3;
			last;
		}
		$lineNumber++;
	}
	close(GAUSSIAN); 

	tie my @data, 'Tie::File', $file, memory=>4_000_000_000;
	
	$Valencia=(split(/[^0-9]/,$data[$ValencePosition]))[-1] /2;
	$Core=(split(/[^0-9]/,$data[$CorePosition]))[-1] /2;
	$TotalLewisOrbital= $Valencia+ $Core;
	$TotalLewisAndNL=(split(" ",$data[$numAllOrbitals]))[0];
	chop($TotalLewisAndNL);
	untie @data;

}
###################################
# Subroutine for read output file ValuesICSS
sub ReadOutsSetInfo {
	my ($file, $SP) = @_;
	print "\t$file\n";
	open(COM, $file);
	my @data   = <COM>;
	close(COM);
	my %coordsComs;
	# Count atoms and points
	for (my $i = $atomStarts ; $i < $atomEND ; $i++) {
		my @coords    = split(" ",$data[$i]);
		if($coords[1]!=0 && $flagStart==0){ 
			$totalAtoms++;		
		} # es un atomo
		$coordsComs{$i-$atomStarts} = [@coords];
	}
	my $totalData;
	#
	my $aux   = 0;
	my $start;
	# special case with the first .com, we print system info
	$totalData = ($atomEND-$atomStarts);
	if( $flagStart == 0 ){
		$start = 0;
	}else{
		$start = $totalAtoms;
	}
	$flagStart = 1;
	####
	# Variable is used for PI information as well default information (SIGMAPI option chosen)
	my %tensor;
	my %tensorSig;
	# Get tensor information No Sigma Pi
	if($SP==0){
		for (my $i = $tensorStarts ; $i < $tensorStarts+($totalData*9) ; $i+=9) {
			chomp($data[$i]);
			my $Iso = (split(" ",$data[$i]))[4];
			my $Ani = (split(" ",$data[$i]))[7];
			my $XX  = (split(" ",$data[$i+1]))[1];
			my $YY  = (split(" ",$data[$i+2]))[3];
			my $XZ  = (split(" ",$data[$i+3]))[1];
			my $YZ  = (split(" ",$data[$i+3]))[3];
			my $ZZ  = (split(" ",$data[$i+3]))[5];
			# Orden de aparicion
			$tensor{$aux} = [($Iso,$Ani,$XX,$YY,$ZZ,$XZ,$YZ)];
			$aux++;
		}
	}elsif($NBOGood==1){
		#Sigma Pi get data
		# the "BigJump" is a variable number of lines wich separates MO information in file
		my $bigJump= ($TotalLewisOrbital*(($TotalLewisAndNL-$TotalLewisOrbital+1)+$TotalLewisAndNL))/2;
		# First orbital position
		my $ActualOrbitalLine=$FirstOrbitalPosition;
		my $next;
		for (my $i = 0; $i <$totalData; $i++) {
			my $newXXPi = 0;
			my $newYYPi = 0;
			my $newZZPi = 0;
			my $newXZPi = 0;
			my $newYZPi = 0;
			my $newIsoPi = 0;

			my $newXXSig = 0;
			my $newYYSig = 0;
			my $newZZSig = 0;
			my $newXZSig = 0;
			my $newYZSig = 0;
			my $newIsoSig = 0;

			foreach my $number (@orbitals){
				if($number < 0){			#Sigma
					my $Snumber = $number*(-1);
					if($Snumber <= $TotalLewisOrbital){
						my @tmp = split(' ',$data[$ActualOrbitalLine + $Snumber]);
						$newXXSig = $newXXSig + $tmp[1];
						$newYYSig = $newYYSig + $tmp[5];
						$newZZSig = $newZZSig + $tmp[9];
						$newXZSig = $newXZSig + $tmp[3];
						$newYZSig = $newYZSig + $tmp[6];

					}
				}else{
					if($number <= $TotalLewisOrbital){
						my @tmp=split(' ',$data[$ActualOrbitalLine + $number]);
						$newXXPi = $newXXPi + $tmp[1];
						$newYYPi = $newYYPi + $tmp[5];
						$newZZPi = $newZZPi + $tmp[9];
						$newXZPi = $newXZPi + $tmp[3];
						$newYZPi = $newYZPi + $tmp[6];
					}
				}
			}
			$newIsoPi = ($newXXPi + $newYYPi + $newZZPi)/3.0;
			$newIsoSig = ($newXXSig + $newYYSig + $newZZSig)/3.0;
			#print "XX PI $newXXPi / $Pi\n";
			$tensorSig{$i} = [($newIsoSig ,0 , $newXXSig, $newYYSig, $newZZSig, $newXZSig, $newYZSig)];		#hash with Sigma info
			$tensor{$i} = [($newIsoPi, 0, $newXXPi, $newYYPi, $newZZPi, $newXZPi, $newYZPi)];		# hash with Pi info
			my $firstLine = $ActualOrbitalLine;
			$next = $firstLine+($TotalLewisOrbital*2)+($bigJump*2)+$AmountofTrashLines;
			$ActualOrbitalLine = $next;
		}
	}
	#dump %tensor;
	undef @data;
	if($SP==0){
		open(NEWMESH, ">>$outputName.backup");	
	}else{
		open(NEWMESH, ">>$outputName\_PI.backup");	
		open(NEWMESH2, ">>$outputName\_SIGMA.backup");
	}
	for (my $i = $start; $i < $totalData; $i++) {
		if(${$coordsComs{$i}}[1] == 0){
			print NEWMESH "Bq\t";
			if($SP==1){	print NEWMESH2 "Bq\t"};
		}else{
			print NEWMESH "${$coordsComs{$i}}[1]\t";
			if($SP==1){	print NEWMESH2 "${$coordsComs{$i}}[1]\t";};
		}
		printf NEWMESH "%.6f\t",${$coordsComs{$i}}[3];	# X coord
		printf NEWMESH "%.6f\t",${$coordsComs{$i}}[4];	# Y coord
		printf NEWMESH "%.6f\t",${$coordsComs{$i}}[5];	# Z coord
		printf NEWMESH "%.6f\t",${$tensor{$i}}[0];		# Isotropic   chemical shift
		printf NEWMESH "%.6f\t",${$tensor{$i}}[1];		# Anisotropic chemical shift
		printf NEWMESH "%.6f\t",${$tensor{$i}}[2];		# Components XX
		printf NEWMESH "%.6f\t",${$tensor{$i}}[3];		# Components YY
		printf NEWMESH "%.6f\t",${$tensor{$i}}[4];		# Components ZZ
		printf NEWMESH "%.6f\t",${$tensor{$i}}[5];		# Components XZ
		printf NEWMESH "%.6f\n",${$tensor{$i}}[6];		# Components YZ
		if($SP==1){
			printf NEWMESH2 "%.6f\t",${$coordsComs{$i}}[3];	# X coord
			printf NEWMESH2 "%.6f\t",${$coordsComs{$i}}[4];	# Y coord
			printf NEWMESH2 "%.6f\t",${$coordsComs{$i}}[5];	# Z coord
			printf NEWMESH2 "%.6f\t",${$tensorSig{$i}}[0];	# Isotropic   chemical shift
			printf NEWMESH2 "%.6f\t",${$tensorSig{$i}}[1];	# Anisotropic chemical shift
			printf NEWMESH2 "%.6f\t",${$tensorSig{$i}}[2];	# Components XX
			printf NEWMESH2 "%.6f\t",${$tensorSig{$i}}[3];	# Components YY
			printf NEWMESH2 "%.6f\t",${$tensorSig{$i}}[4];	# Components ZZ
			printf NEWMESH2 "%.6f\t",${$tensorSig{$i}}[5];	# Components XZ
			printf NEWMESH2 "%.6f\n",${$tensorSig{$i}}[6];	# Components YZ
		}
	}
	close(NEWMESH);
	if($SP == 1){
		close(NEWMESH2);
	}
	undef %tensor;
	undef %tensorSig;
	undef %coordsComs;
}
###################################
# Subroutine for read the .out files
sub ReadMeshCOMS {
	my($SP, $orbitalsP)=@_;

	my @coms  = glob "$comName*.out";
	if( $#coms == -1 ) {
		@coms = glob "$comName*.log";
	}
	my $last  = pop @coms;
	my $first = shift @coms;
	
	###########
	if($SP==1){				#SigmaPi chosen
		@orbitals=@{$orbitalsP};
		NBOAnalysisData($first);
		if($NBOGood == 0){
			#NBO wasn't calculated;
			print "NBO wasn't correclty calculated, please delete all .out/.log files and try again\n";
			exit(2);
		}
		foreach my $num (@orbitals){		# Sum of Pi and Sigma Data
			if($num>0){
				$Pi++;
			}else{
				$Sigma++;
			}
		}
	}
	###########
	# get data information position from 1st .com output
	SetSpecialLinePosition($first);
	# get data.
	print "MESSAGE Reading ... \n";
	ReadOutsSetInfo($first, $SP);
	#all .com output data
	foreach my $com (@coms) {
		# print "escribiendo $com\n";
		NBOAnalysisData($com);
		SetSpecialLinePosition($com);
		ReadOutsSetInfo($com, $SP);		
	#	last;
	}
	$atomEND = -1;
	# last output could have a different number of lines, so data position is recalculated
	SetSpecialLinePosition($last);
	if($SP==1){NBOAnalysisData($last);}	
	ReadOutsSetInfo($last, $SP);
}
###################################
# Subroutine for Sigma-Pi orbitals
sub VerifySigmaPi{
	my($configFile)=@_;
	open(CONFIG, "$configFile");
	my ($SP,@orbitals);
	foreach my $line (<CONFIG>){
		chomp($line);
		if( $line=~/option/i){
			$SP=(split("=",$line))[-1];
		}
		if( $line=~/orbitals/){
			my $tmp=(split("=",$line))[-1];
			@orbitals=split(",",$tmp);
		}
	}
	return ($SP,\@orbitals);
}


###################################
# Call subroutines 
my $configFile = $ARGV[0];
$comName       = $ARGV[1];
#
my($SP, $orbitalsP) = VerifySigmaPi($configFile);
# If valuesICSS exists then all this script don't do anything
if(-e 'ValuesICSS.backup' && $SP==0){#
# -e 'ValuesICSS_PI.backup' || -e 'ValuesICSS_SIGMA.backup' ){
}else{
	ReadMeshCOMS($SP, $orbitalsP);
}
