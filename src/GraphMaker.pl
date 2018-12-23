#!/usr/bin/perl

use strict;
use warnings; no warnings 'uninitialized';


#############################################################################
# Subroutines for build .cube and .vti format                               #
#############################################################################


my $datFile;
############
my $atomTotal =  0;
my $Xl        = -1;
my $Yl        = -1;
my $Zl        = -1;
my $delta;
my $del_x;
my $del_y;
my $del_z;
my $NumPts;
my $NX;
my $NY;
my $NZ;
my $origen_x;
my $origen_y;
my $origen_z;
my $out;
my @type;
my $option;

###################################
# Delete whitespaces from Strings
sub trim { 
	my $s = shift; 
	$s =~ s/^\s+|\s+$//g; 
	return $s 
}
###################################
# Subroutine for convert bohr to angstrom
sub convert_armstrong_to_bohr { 
	my $s     = shift; 
	my $multi = $s/0.529177249; 
	return $multi;
}
###################################
# Read data .com
sub ReadDatGetInfo {
	my($same1, $same2, $ori1, $ori2, $datFile)=@_;
	#tie my @meshdata, 'Tie::File', $datFile;
	#
	open(VALUES, "$datFile");
	my @meshdata = <VALUES>;
	close(VALUES);
	#
	my %magicalLines;
	my $aux      = 0;
	foreach my $data (@meshdata){
		my @information=split(" ",$data);
		# print "$information[$same1]\n";
		if($information[$same1]==$ori1 && $information[$same2]==$ori2 && $information[0] eq "Bq"){
			# print "$information[0]\t$information[1]\t$information[2]\t$information[3]\n";
			$magicalLines{$aux}=[@information];
			$aux++;
		}elsif($information[0] ne "Bq"){
			$magicalLines{$aux}=[@information];
			$aux++;
		}
	}
	undef @meshdata;
	return %magicalLines;
}
###################################
# Measure other Tesors 
sub OtherTensors {
	# this calculate sigma(av), delta, nu from page 201 of "The Shieldign Tensor, Part I: Unterstading its Symmetry Properties".
	# taking xx, yy, zz from data like 11, 22, 33
	my($outputName, $datFile)=@_;
	my %magicalLines = ReadDatGetInfo(1,2,0, 0,$datFile);
	my $total        = keys %magicalLines;
	open (SPST, ">$outputName.txt");
	print SPST "Type\taxis(z)\tXX\tYY\tZZ\tsigma(av)\tdelta\tnu\n\n";
	foreach my $id (0..$total-1){
		# Diagonal Tensor Simetrico.
		my $DIxx  = ${$magicalLines{$id}}[6];
		my $DIyy  = ${$magicalLines{$id}}[7];
		my $DIzz  = ${$magicalLines{$id}}[8];
		#
		my $Tav   = ($DIxx + $DIyy + $DIzz)/3;
		my $delta = $DIzz - $Tav;
		my $nu    = ($DIyy - $DIxx) * $delta;
		#
		print  SPST "${$magicalLines{$id}}[0]\t";			# type of atom
		printf SPST ("%.3f\t",${$magicalLines{$id}}[3]);	# Z coordinate
		#
		printf SPST ("%.3f\t",$DIxx);						# XX gaussian copy
		printf SPST ("%.3f\t",$DIyy);						# YY gaussian copy
		printf SPST ("%.3f\t",$DIzz);						# ZZ gaussian copy
		#
		printf SPST ("%.3f\t",$Tav);						# tensor or sigma(av)
		printf SPST ("%.3f\t",$delta);						# delta
		printf SPST ("%.3f\t",$nu);							# nu
		print SPST "\n";
	}
	close(SPST);
}
###################################
# Write files
sub CalculatePropiertiesAndWrite {
	#
	# Simulando que SIEMPRE es eje Z en 0 Angstrom
	my($type, $outputName, $datFile)=@_;
	my %magicalLines;
	my $outputShow;
	my $PrintC;
	my $PrintCC;
	#
	%magicalLines = ReadDatGetInfo(1,2,0, 0,$datFile);
	$outputShow   = 3;
	$PrintC       = "axis(z)";
	$PrintCC      = "ZZ";
	#
	my $total     = keys %magicalLines;
	#
	if($total!=0){
		# Wirte file 
		open(FIPC, ">$outputName.txt");
		if( $type == 1 ){
			print FIPC "Type\t$PrintC\tXX\tYY\tZZ\tIn-Plane\tOut-Plane\n\n";
		}elsif( $type == 2 ){
			print FIPC "Type\t$PrintC\t$PrintCC\tIso\tAni\n\n";
		}else{
			print FIPC "Type\t$PrintC\tXX\tYY\tZZ\tIso\tIn-Plane\tOut-Plane\tAni\n\n";
		}
		#
		foreach my $id (0..$total-1){
			my $newXX = ${$magicalLines{$id}}[6]*(-1);
			my $newYY = ${$magicalLines{$id}}[7]*(-1);
			my $newZZ = ${$magicalLines{$id}}[8]*(-1);
			my $inplane;
			my $outplane;
			$inplane  = ($newZZ+$newYY)/3;
			$outplane = $newXX/3;
			print  FIPC "${$magicalLines{$id}}[0]\t";
			printf FIPC ("%.3f\t",${$magicalLines{$id}}[$outputShow]);
			if( $type == 1 ){
				printf FIPC ("%.3f\t",$newXX);
				printf FIPC ("%.3f\t",$newYY);
				printf FIPC ("%.3f\t",$newZZ);
				printf FIPC ("%.3f\t",$inplane);
				printf FIPC ("%.3f\n",$outplane);
			}elsif( $type == 2 ){
				printf FIPC ("%.3f\t",${$magicalLines{$id}}[$outputShow+5]*(-1));
				printf FIPC ("%.3f\t",${$magicalLines{$id}}[4]);
				printf FIPC ("%.3f\n",${$magicalLines{$id}}[5]);
			}else{
				printf FIPC ("%.3f\t",$newXX);
				printf FIPC ("%.3f\t",$newYY);
				printf FIPC ("%.3f\t",$newZZ);
				printf FIPC ("%.3f\t",${$magicalLines{$id}}[4]);
				printf FIPC ("%.3f\t",$inplane);
				printf FIPC ("%.3f\t",$outplane);
				printf FIPC ("%.3f\n",${$magicalLines{$id}}[5]);
			}
		}
		close(FIPC);
	}
}
###################################
# Parameters of outputfiles 
sub GetParamOFDat {
	#tie my @meshdata, 'Tie::File', $datFile;
	my($datFile)=@_;
	open(OUT, "$datFile");
	my @meshdata=<OUT>;
	close(OUT);
	#
	foreach my $x (@meshdata) {
		my @tmp = split(" ",$x);
		# atoms are over and now Bq data starts
		if($tmp[0] eq "Bq"){	
			last;
		}
		$atomTotal++;
	}
	# Last line of .backup file has: "X Y Z delta NumX NumY NumZ". 
	# Meaning x,y,z coordinates of origin (corner); separation between points Angstron; 
	# and number of points in each axis.
	my @meshSizeData  = split(" ",$meshdata[-1]);
	#
	$origen_x = $meshSizeData[0];
	$origen_y = $meshSizeData[1];
	$origen_z = $meshSizeData[2];
	$del_x = $del_y = $del_z = $delta  = $meshSizeData[3];
	$Xl = $meshSizeData[4];
	$Yl = $meshSizeData[5];
	$Zl = $meshSizeData[6];
	$NumPts = $Xl * $Yl * $Zl;

	if($Xl==1){
		$del_x = 0;
	}
	if($Yl==1){
		$del_y = 0;
	}
	if($Zl==1){
		$del_z = 0;
	}	
}
###################################
# Build file .vti format
sub CreateVTIFileHeader {
	my($outputName, $id) = @_;
	open (VTI,">$outputName\_$id.vti");
	print VTI "<?xml version=\"1.0\"?>\n";
	print VTI "<VTKFile type=\"ImageData\" version=\"0.1\" byte_order=\"LittleEndian\">\n";
	print VTI "\t<ImageData WholeExtent=\"";
	print VTI " 0 ".($Xl-1);
	print VTI " 0 ".($Yl-1);
	print VTI " 0 ".($Zl-1)."\"";
	print VTI " Origin=\"";
	print VTI "$origen_x $origen_y $origen_z\"";
	print VTI " Spacing=\"";
	print VTI "$del_x $del_y $del_z\">\n";	
	print VTI "\t<Piece Extent=\"";
	print VTI " 0 ".($Xl-1);
	print VTI " 0 ".($Yl-1);
	print VTI " 0 ".($Zl-1)."\">\n";
	print VTI "\t<PointData Scalars=\"scalars\">\n";
	print VTI "\t<DataArray Name=\"vectors\" type=\"Float64\" NumberOfComponents=\"3\" Format=\"ascii\">\n";
	close(VTI);
}
###################################
# Build file in .cube format
sub CreateCubeFile {
	my($valueToWrite, $outputName, $datFile) = @_;
	#
	open(DATA,"$datFile");
	my @meshdata = <DATA>;
	close(DATA);
	#
	CreateVTIFileHeader($outputName,"Pos1");
	CreateVTIFileHeader($outputName,"Neg1");
	# CUBE header information here
	open(CUBE, ">$outputName.cube");
	print CUBE "Cube File generated by Magnetum\n";
	print CUBE "\tTotally\t$NumPts grid points\n";
	print CUBE "\t$atomTotal\t",	convert_armstrong_to_bohr($origen_x),"\t",
								convert_armstrong_to_bohr($origen_y),"\t",
								convert_armstrong_to_bohr($origen_z),"\n";
	printf CUBE ("\t$Xl\t%.6f\t0.000000\t0.000000\n",convert_armstrong_to_bohr($delta));
	printf CUBE ("\t$Yl\t0.000000\t%.6f\t0.000000\n",convert_armstrong_to_bohr($delta));
	printf CUBE ("\t$Zl\t0.000000\t0.000000\t%.6f\n",convert_armstrong_to_bohr($delta));
	# atom data in bohr here
	for (my $i = 0 ; $i < $atomTotal ; $i++) {
		my @tmp = split(" ",$meshdata[$i]);
		printf CUBE ("$tmp[0]\t$tmp[0].0\t%.6f\t%.6f\t%.6f\n",convert_armstrong_to_bohr($tmp[1]),
												convert_armstrong_to_bohr($tmp[2]),
												convert_armstrong_to_bohr($tmp[3]))
	}
	#
	open(VTIPOS,">>$outputName\_Pos1.vti");
	open(VTINEG,">>$outputName\_Neg1.vti");
	#
	my $aux = $atomTotal;
	# CUBE Information here
	for (my $i = 0; $i < $Xl; $i++) {
		for (my $j = 0; $j < $Yl; $j++) {
			my $flag=1;
			my $written = 0;
			for (my $k = 0; $k < $Zl; $k++) {
				my @tmp = split(" ",$meshdata[$aux]);
				# use bignum;
				my $legalX= sprintf "%.6f",($i*$delta)+$origen_x;
				my $legalY= sprintf "%.6f",($j*$delta)+$origen_y;
				my $legalZ= sprintf "%.6f",($k*$delta)+$origen_z;

				$flag=1;
				my $vx=0;
	    		my $vy=0;
	    		my $vz=0;
				if( $legalX == $tmp[1] && $legalY == $tmp[2] && $legalZ == $tmp[3]){
					my $tmpvalue = $tmp[$valueToWrite];
					if($tmpvalue > 0){
             			printf CUBE (" %.5e",($tmpvalue)*(-1));
					}elsif($tmpvalue < 0){
						printf CUBE ("  %.5e",($tmpvalue)*(-1));	
          			}else{
          				print CUBE "  0.00000e+00";
          			}
   					$written++;
					$aux++;
					# Control VTI
					$vx = $tmp[-2]*(-1);
					$vy = $tmp[-1]*(-1);
					$vz = $tmp[-3]*(-1);
					# En caso los vectores se vean muy peqeuños jugar con esta variable
					my $module= sqrt(($vx**2) + ($vy**2) + ($vz**2));
					if($vz > 0){ 					#Pos values here
						print VTIPOS "\t\t$vx\t$vy\t$vz\n";
						print VTINEG "\t\t0.0000\t0.0000\t0.0000\n";
					}else{							#Neg values here (and 0)
						print VTIPOS "\t\t0.0000\t0.0000\t0.0000\n";
						print VTINEG "\t\t$vx\t$vy\t$vz\n";
					}
				}else{
					print CUBE "  0.00000e+00\t";
				}
				if($written%6 == 0){
					print CUBE "\n";
					$flag=0;
					$written=0;
				}
			}
			if($flag!=0){
				print CUBE "\n";
			}
		}
		my $pcent = (($i+1)*100/$Xl);
		printf "Writting %.2f%s of cube\n",$pcent, '%';
	}
	close(VTIPOS);
	close(VTINEG);
	printf "MESSAGE Writting vti file\n";
	RectifyVTI("$outputName\_Pos1.vti","$outputName\_Pos.vti");
	RectifyVTI("$outputName\_Neg1.vti","$outputName\_Neg.vti");
	close(CUBE);
}
###################################
# Verify the .vti file
sub RectifyVTI {
	my ($vtiFile, $newName)=@_;
	#
	my $posX = $Yl * $Zl;
    my $posY = $Zl;
    my $header = 6; 
	open(VTI, "$vtiFile");
	my @line = <VTI>;
	close(VTI);
	open(LEGAL, ">$newName");
	foreach my $i (1..$header){
		print LEGAL "$line[$i]";
	}
	for (my $z = 0; $z < $Zl; $z++) {
		for (my $y = 0; $y < $Yl; $y++) {
			for (my $x = 0; $x < $Xl; $x++) {
				# Locate and transfer information
				my $key = ($posX*$x) + ($posY*$y) + $z + $header;
				print LEGAL "$line[$key]";
			}
		}
	}
	print LEGAL "\n\t</DataArray>\n\t</PointData>\n\t\t</Piece>\n\t</ImageData>\n</VTKFile>\n";
	close(LEGAL);
	unlink $vtiFile;
}
###################################
# Config variables
sub SetVariables {
	my($configFile)=@_;
	open(CONFIG, "$configFile");
	my ($outputName, $tmp);
	foreach my $line (<CONFIG>){
		chomp($line);
		if( $line=~/coords/i    ) {
			$outputName=(split("=",$line))[-1];
		}
		if( $line=~/type_graph/i) {
			$tmp=(split("=",$line))[-1];
			@type=split(",",$tmp);
		}
		if ( $line=~/option/i   ) {
			$option=(split("=",$line))[-1];
		}
	}
	return ($outputName);
}
###################################
# This function sets the variables to print in the .cube, .vtk & .vti files
sub Starts {
	my($datFile, $surname, $outputName)=@_;
	GetParamOFDat($datFile);

	foreach my $type (@type){
		my $OutPutFilesNMR;
		if($type==1){
			$OutPutFilesNMR=$outputName.$surname."_ISO";
		}elsif($type==2){
			$OutPutFilesNMR=$outputName.$surname."_ANI";
		}elsif($type==3){
			$OutPutFilesNMR=$outputName.$surname."_XX";
		}elsif($type==4){
			$OutPutFilesNMR=$outputName.$surname."_YY";
		}elsif($type==5){
			$OutPutFilesNMR=$outputName.$surname."_ZZ";
		}elsif($type==6){
			$OutPutFilesNMR=$outputName.$surname."_FiPC";
		}elsif($type==7){
			$OutPutFilesNMR=$outputName.$surname."_Scans";
		}elsif($type==8){
			$OutPutFilesNMR=$outputName.$surname."_FS";
		}elsif($type==9){
			$OutPutFilesNMR=$outputName.$surname."_SPST";
		}
		#
		if($type==6){
			print "MESSAGE Creating FiPC file\n";
			CalculatePropiertiesAndWrite(1,$OutPutFilesNMR,$datFile);
		}elsif($type==7){
			#SCAN
			print "MESSAGE Creating Scans file\n";
			CalculatePropiertiesAndWrite(2,$OutPutFilesNMR,$datFile);
		}elsif($type==8){
			print "MESSAGE Creating FiPC and Scans file\n";
			CalculatePropiertiesAndWrite(3,$OutPutFilesNMR,$datFile);
		}elsif($type==9){
			print "MESSAGE Creating Symmetry Properties of the Shielding Tensor file\n";
			OtherTensors($OutPutFilesNMR,$datFile);
			#CalculatePropiertiesAndWrite($outputName,$datFile);
		}else{
			print "MESSAGE Creating Isotropic, Anisotropic & Component (XX,YY,ZZ) file\n";
			CreateCubeFile(($type+3), $OutPutFilesNMR,$datFile);
		}
	}
}
###################################
# Call subroutines 
my $configFile= $ARGV[0];
(my $basename)=SetVariables($configFile);
(my $outputName = $basename) =~ s/\.[^.]+$//;
$outputName=trim($outputName);
#
# print "COSAS:  @type\n";
if($option==0){
	$datFile="ValuesICSS.backup";
	Starts($datFile,"",$outputName);
}else{
	$datFile="ValuesICSS_SIGMA.backup";
	Starts($datFile,"SIG",$outputName);
	# Resets the global variables, necesary for SigmaPi calculation
	$atomTotal=0;
	$Xl=-1;
	$Yl=-1;
	$Zl=-1;
	$datFile="ValuesICSS_PI.backup";
	Starts($datFile,"PI",$outputName);
}
