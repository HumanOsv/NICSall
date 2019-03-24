#!/usr/bin/perl

use strict;
use warnings; no warnings 'uninitialized';
use File::Basename;
use Tie::File;

use Data::Dump qw(dump ddx);
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
my @OrbUbicationList;
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
	#tie my @data, 'Tie::File', $file, memory=>4_000_000_000;
	open(GAUSSIAN, $file);
	# Set line numbers
	$atomEND = -1;
	foreach my $line (<GAUSSIAN>){
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
	close(GAUSSIAN);
}
###################################
# Subroutine that sets NBO data information.
sub NBOAnalysisData{
	my ($file)     = @_;
	print "archivo es: $file \n";
	my $lineNumber = 0;
	open(GAUSSIAN , $file);
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
			push @OrbUbicationList, $FirstOrbitalPosition;
			#last;
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
sub SaveSPDataToFile {
	my ($file) = @_;
	my $ActualOrbitalLine=$FirstOrbitalPosition;

	open(COM, $file);
	my @data   = <COM>;
	close(COM);

	open(SAVE,">>SP.all");

	my %coordsComs;
	if($flagStart ==0){
		print SAVE "$TotalLewisOrbital\n";
		for (my $i = $atomStarts ; $i < $atomEND ; $i++) {
			my @coords    = split(" ",$data[$i]);
			if($coords[1]!=0 && $flagStart==0){ 
				$totalAtoms++;		
			} # es un atomo
			$coordsComs{$i-$atomStarts} = [@coords];

		}
		my $llaves =  keys %coordsComs;
		for (my $i = 0; $i < $llaves; $i++) {
			print SAVE "COORDINATES\n";
			print SAVE ${$coordsComs{$i}}[1],"\t";
			print SAVE ${$coordsComs{$i}}[3],"\t";
			print SAVE ${$coordsComs{$i}}[4],"\t";
			print SAVE ${$coordsComs{$i}}[5],"\n";

			foreach my $number (-4 .. $TotalLewisOrbital+2){
				print SAVE $data[$OrbUbicationList[$i*2] + $number];
			}
			print SAVE "\n";
		}
	}else{
		for (my $i = $atomStarts + $totalAtoms; $i < $atomEND ; $i++) {
			my @coords    = split(" ",$data[$i]);
			$coordsComs{$i-$atomStarts} = [@coords];
		}
		my $llaves = keys %coordsComs;
		for (my $i = $totalAtoms; $i < $llaves + $totalAtoms; $i++) {
			print SAVE "COORDINATES\n";
			print SAVE ${$coordsComs{$i}}[1],"\t";
			print SAVE ${$coordsComs{$i}}[3],"\t";
			print SAVE ${$coordsComs{$i}}[4],"\t";
			print SAVE ${$coordsComs{$i}}[5],"\n";

			foreach my $number (-4 .. $TotalLewisOrbital+2){
				print SAVE $data[$OrbUbicationList[$i*2] + $number];
			}
			print SAVE "\n";
		}
	}
	$flagStart = 1;
	undef @OrbUbicationList;
	print SAVE "FINIT\n";


}
sub ReadSPsSetInfo {
	open(COM, "SP.all");
	my @data   = <COM>;
	close(COM);

	$TotalLewisOrbital = $data[0];
	open(NEWMESH, ">$outputName\_PI.backup");	
	open(NEWMESH2, ">$outputName\_SIGMA.backup");
	
	#  ( ($a_1=~/type_graph/gi ) ){
	for (my $i = 1; $i < $#data; $i++) {
		if($data[$i]=~/COORDINATES/){  #coordenadas
			#print "Cordenadas: ";
			my @tmp = split(" ",$data[$i+1]);
			#dump @tmp;
			if($tmp[0] == 0){
				print NEWMESH "Bq\t";
				print NEWMESH2 "Bq\t";
			}else{
				print NEWMESH "$tmp[0]\t";
				print NEWMESH2 "$tmp[0]\t";
			}
			print NEWMESH "$tmp[1]\t$tmp[2]\t$tmp[3]\t";
			print NEWMESH2 "$tmp[1]\t$tmp[2]\t$tmp[3]\t";
			#TERMINAMOS ESCRIBIR COORDENADAS
			my $orbitalStarts = $i + 6;

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
						my @tmp = split(' ',$data[$orbitalStarts + $Snumber]);
						$newXXSig = $newXXSig + $tmp[1];
						$newYYSig = $newYYSig + $tmp[5];
						$newZZSig = $newZZSig + $tmp[9];
						$newXZSig = $newXZSig + $tmp[3];
						$newYZSig = $newYZSig + $tmp[6];

					}
				}else{
					if($number <= $TotalLewisOrbital){
						my @tmp=split(' ',$data[$orbitalStarts + $number]);
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

			printf NEWMESH "%.6f\t",$newIsoPi;	# Isotropic   chemical shift
			printf NEWMESH "---\t",;	# Anisotropic chemical shift
			printf NEWMESH "%.6f\t",$newXXPi;	# Components XX
			printf NEWMESH "%.6f\t",$newYYPi;	# Components YY
			printf NEWMESH "%.6f\t",$newZZPi;	# Components ZZ
			printf NEWMESH "%.6f\t",$newXZPi;	# Components XZ
			printf NEWMESH "%.6f\n",$newYZPi;	# Components YZ

			printf NEWMESH2 "%.6f\t",$newIsoSig;	# Isotropic   chemical shift
			printf NEWMESH2 "---\t",;	# Anisotropic chemical shift
			printf NEWMESH2 "%.6f\t",$newXXSig;	# Components XX
			printf NEWMESH2 "%.6f\t",$newYYSig;	# Components YY
			printf NEWMESH2 "%.6f\t",$newZZSig;	# Components ZZ
			printf NEWMESH2 "%.6f\t",$newXZSig;	# Components XZ
			printf NEWMESH2 "%.6f\n",$newYZSig;	# Components YZ
		}
	}
	close(NEWMESH2);
	close(NEWMESH);
	undef @data;
}
###################################
# Subroutine for read output file ValuesICSS
sub ReadOutsSetInfo {
	my ($file) = @_;
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
	# Get tensor information No Sigma Pi
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
	#dump %tensor;
	undef @data;

	open(NEWMESH, ">>$outputName.backup");	
	for (my $i = $start; $i < $totalData; $i++) {
		if(${$coordsComs{$i}}[1] == 0){
			print NEWMESH "Bq\t";
		}else{
			print NEWMESH "${$coordsComs{$i}}[1]\t";
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
	}
	close(NEWMESH);

	undef %tensor;
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
	#my $first = shift @coms;
	#my $last  = pop @coms;
	

	if($SP==1){	#se procede a leer la info
		@orbitals=@{$orbitalsP};
		foreach my $num (@orbitals){		# Sum of Pi and Sigma Data
			if($num>0){
				$Pi++;
			}else{
				$Sigma++;
			}
		}
		if(-e 'SP.all'){
			print "Data written in SP.all\t Reading...\n";
			ReadSPsSetInfo();
		}else{
			foreach my $com (@coms) {
				# print "escribiendo $com\n";
				NBOAnalysisData($com);
				SetSpecialLinePosition($com);
				#ReadOutsSetInfo($com, $SP);
				SaveSPDataToFile($com);		
				if($NBOGood == 0){
					#NBO wasn't calculated;
					print "NBO wasn't correclty calculated, please delete all .out/.log files and try again\n";
					exit(2);
				}
			}
		}
		ReadSPsSetInfo();
	}else{
		foreach my $com (@coms) {
			# print "escribiendo $com\n";
			$atomEND = -1;
			SetSpecialLinePosition($com);
			ReadOutsSetInfo($com);		
		}
	}
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
	close(CONFIG);
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
