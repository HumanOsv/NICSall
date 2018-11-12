#!/usr/bin/perl

#
# Write code: 
#             Diego Inostrosa & Osvaldo Yañez Osses
# E-Mail    : 
#             dinostro92@gmail.com & osvyanezosses@gmail.com


use strict;
use warnings; no warnings 'uninitialized';
use Benchmark;
use List::Util qw( min max );
use Math::Trig;
use Cwd qw(abs_path);
use File::Basename;
#
# install: 
# sudo cpan Time::HiRes
# sudo cpan Test::Most
# sudo cpan Sub::Exporter::Simple
# sudo cpan Array::Split
use Array::Split qw( split_into );
#
# install: sudo cpan Parallel::ForkManager
use Parallel::ForkManager;

# Numero de colas para correr en 
# paralelo (Ej: Si mandas un calculo de 4 procesadores y tu 
#               computador es de 16, por lo tanto son 4 colas 
#                puesto que 4*4 = 16)
my $numero_colas      = 4;
my $gaussian_version  = "g09";
# Local = 0 y queue = 1
my $local_cluster     = 1;

# # # 
# Check cluster send jobs
#my $queue        = "all.q";
#my $queue        = "Aztlan";
my $exec_bin_g09      = "Gaussian09.d01";
# 
my $max_numb_conver   = 3;
# Numero de procesos
my $nprocess          = 100;
#
my $NumPtsTotal       = 0;
#
my $Numb_total_sup_atom;
#
my $cylinderCase      = -1;
my $cylinderAreaThick = 0.5;  # half thick, real thickness is value * 2
my @systemdata        = ();
#
my @files_Calc        = ();
#
my %Atomic_number = ( '89'  => 'Ac', '13'  => 'Al', '95'  => 'Am', '51'  => 'Sb',	
	                  '18'  => 'Ar', '33'  => 'As', '85'  => 'At', '16'  => 'S',  
					  '56'  => 'Ba', '4'   => 'Be', '97'  => 'Bk', '83'  => 'Bi',	
                      '107' => 'Bh', '5'   => 'B', 	'35'  => 'Br', '48'  => 'Cd',	
	                  '20'  => 'Ca', '98'  => 'Cf',	'6'   => 'C',  '58'  => 'Ce',	
	                  '55'  => 'Cs', '17'  => 'Cl',	'27'  => 'Co', '29'  => 'Cu',	
	                  '24'  => 'Cr', '96'  => 'Cm', '110' => 'Ds', '66'  => 'Dy',
	                  '105' => 'Db', '99'  => 'Es', '68'  => 'Er', '21'  => 'Sc',	
	                  '50'  => 'Sn', '38'  => 'Sr', '63'  => 'Eu', '100' => 'Fm',	
	                  '9'   => 'F',  '15'  => 'P',  '87'  => 'Fr', '64'  => 'Gd',	
	                  '31'  => 'Ga', '32'  => 'Ge', '72'  => 'Hf', '108' => 'Hs',	
                      '2'   => 'He', '1'   => 'H',  '26'  => 'Fe', '67'  => 'Ho',	
					  '49'  => 'In', '53'  => 'I',  '77'  => 'Ir', '70'  => 'Yb',
					  '39'  => 'Y',  '36'  => 'Kr', '57'  => 'La', '103' => 'Lr',	
					  '3'   => 'Li', '71'  => 'Lu', '12'  => 'Mg', '25'  => 'Mn',	
                      '109' => 'Mt', '101' => 'Md', '80'  => 'Hg', '42'  => 'Mo',	
					  '60'  => 'Nd', '10'  => 'Ne', '93'  => 'Np', '41'  => 'Nb',	
					  '28'  => 'Ni', '7'   => 'N',  '102' => 'No', '79'  => 'Au',	
					  '76'  => 'Os', '8'   => 'O', 	'46'  => 'Pd', '47'  => 'Ag',	
					  '78'  => 'Pt', '82'  => 'Pb',	'94'  => 'Pu', '84'  => 'Po',	
					  '19'  => 'K',  '59'  => 'Pr', '61'  => 'Pm', '91'  => 'Pa',	
					  '88'  => 'Ra', '86'  => 'Rn', '75'  => 'Re', '45'  => 'Rh',	
					  '37'  => 'Rb', '44'  => 'Ru', '104' => 'Rf', '62'  => 'Sm',
					  '106' => 'Sg', '34'  => 'Se', '14'  => 'Si', '11'  => 'Na',
					  '81'  => 'Tl', '73'  => 'Ta', '43'  => 'Tc', '52'  => 'Te',	
					  '65'  => 'Tb', '22'  => 'Ti', '90'  => 'Th', '69'  => 'Tm',	
					  '112' => 'Uub','116' => 'Uuh','111' => 'Uuu','118' => 'Uuo',	
					  '115' => 'Uup','114' => 'Uuq','117' => 'Uus','113' => 'Uut',
					  '92'  => 'U',  '23'  => 'V',  '74'  => 'W',  '54'  => 'Xe',
                      '30'  => 'Zn', '40'  => 'Zr' );
			
###################################
# Distributed Jobs
sub distribute {
    my ($n, $array) = @_;
	#
    my @parts;
    my $i = 0;
    foreach my $elem (@$array) {
        push @{ $parts[$i++ % $n] }, $elem;
    };
    return \@parts;
}
###################################
# Parallel processing
sub parallel_cpu_local {
	#
	my ($info_file,$file_one,$count,$option)  = @_;
	my @tmp_arr                               = @{$info_file};
	#
	my $slrm = "Lanz-tmp_$count.sh";
	open (SLURMFILE, ">$slrm");
	#
	print SLURMFILE "#!/bin/bash \n";
	print SLURMFILE "\n";
	#
	if ( $option == 0 ) {
		foreach my $i (@tmp_arr) {
			(my $without_ext = $i) =~ s/\.[^.]+$//;
			print SLURMFILE "$gaussian_version $without_ext.com 2>error.tmp\n";
		}
	} else {
		print SLURMFILE "$gaussian_version $file_one.com 2>error.tmp\n";	
	}
	#
	close (SLURMFILE);
	#
	system ("bash $slrm &");
}
###################################
# delete repeat data
sub uniq {
	my %seen;
	grep !$seen{$_}++, @_;
}
###################################
# Verification jobs
sub verification_of_termination {
	my ($info_array) = @_;
	my @Secuencias   = @{$info_array};
	#
	my $boolean = 2;
	#
	foreach my $a_1 (@Secuencias){
		# Normal termination
		if ( ($a_1=~/Normal/gi ) && ($a_1=~/termination/gi ) ){
			$boolean = 1;
		}
		# Error termination
		if ( ($a_1=~/Error/gi ) && ($a_1=~/termination/gi ) ){
			$boolean = 0;
		}
		# traceback not available
		if ( ($a_1=~/traceback/gi ) ){
			$boolean = 0;
		}
	}
	return $boolean;
}
###################################
# Summit jobs
sub submit_queue { 
	my ($arrayInputs,$queue,$exec_bin_g09,$option_lanz,$ncpus) = @_;
	#
	my @files  = @{$arrayInputs}; 
	# numero de atomos
	my $number_paral     = ($numero_colas - 1);
	#
	my @name_files       = ();
	my @report_structure = ();
	#
	my %Info_files_dir   = ();
	my @array_keys       = ();
	#
	my @total_files_qm   = ();
	#
	print "\nMESSAGE Send Jobs\n";
	#
	for (my $i = 0; $i < scalar(@files) ; $i++) {
		#
		(my $without_ext = $files[$i]) =~ s/\.[^.]+$//;
		#
		my $id               = sprintf("%06d",$i);
		$Info_files_dir{$id} = $files[$i];
		push (@array_keys,$id);
		push (@total_files_qm,$files[$i]);
		#
		if ($option_lanz == 1) {
			my $env_a = `$exec_bin_g09 $without_ext $without_ext.com $ncpus $queue`;
		}
	}
	#
	# # # # 
	# Cluster Slurm
	#
	if ($option_lanz == 0) {
		my @arrfile = ();
		my $arr     = distribute($number_paral,\@files);
		my @loarr   = @{$arr};
		my $div     = int ( scalar (@files) / $number_paral);		
		for (my $i = 0; $i < scalar (@loarr) ; $i++) {
			my @tmp_arr = ();
			for (my $j = 0; $j <= $div ; $j++) {
				push (@tmp_arr,$loarr[$i][$j]);
				push (@arrfile,$loarr[$i][$j]);
			}
			#slurm_cluster (\@tmp_arr,"NOFILE",$i,0);
			#PBS_cluster (\@tmp_arr,"NOFILE",$i,0);
			parallel_cpu_local (\@tmp_arr,"NOFILE",$i,0);
		}
		my @delete_arr    = ();
		my @element_files = ();
		foreach my $i (@files) {
			foreach my $j (@arrfile) {
				if ( ($i=~/$j/gi ) ){
					#print "$j\n";
					push (@element_files,$j);
					@delete_arr = ();
				} else {
					push (@delete_arr,$i);
				}
			}
		}
		my @filtered   = uniq(@delete_arr);
		my $data_value = scalar (@loarr);
		#slurm_cluster (\@filtered,"NOFILE",$data_value,0);
		#PBS_cluster (\@filtered,"NOFILE",$data_value,0);
		parallel_cpu_local (\@filtered,"NOFILE",$data_value,0);
		foreach my $i (@filtered) {
			push (@element_files,$i);
		}
		if ( ( scalar (@files) ) != ( scalar (@element_files) ) ) { print "Problem Number Files Slurm, PBS & Local\n"; exit;}
	}
	#
	#
	#
	# # # # # # # # # # #
	my $count = 0;
	while ( $count < 1 ) {
		while (my ($key, $value) = each %Info_files_dir) {
			my %Info_count_files = ();
			my %Info_NImag_files = ();
			#
			my $input_file = $value;
			############# 		
			# Main
			(my $without_extension = $input_file) =~ s/\.[^.]+$//;
			if( ( -e "$without_extension.out" ) || ( -e "$without_extension.log" ) ) {
				my @Secuencias   = ();
				if( -e "$without_extension.out" ) {
					sleep(2);
					@Secuencias      = read_file ("$without_extension.out");
				}
				if( -e "$without_extension.log" ) {
					sleep(2);
					@Secuencias      = read_file ("$without_extension.log");
				}
				#
				my $option       = verification_of_termination(\@Secuencias);
				# # # # # # # # # # # # #
				# Error termination
				if ( $option == 0 ) {
					#print "Error Termination -> File: $input_file\n";	
					my $energy = 0;
					my $total_coords;
					my $deci   = 0;
					#
					push (@name_files,$without_extension); 
					foreach my $element( @name_files ) {
						++$Info_count_files{$element};
					}
					if ( $Info_count_files{$without_extension} > $max_numb_conver ) {
						push (@report_structure,$Info_files_dir{$key});
						delete $Info_files_dir{$key};
						$deci = 1;
					}
					#
					if ( $deci == 0 ) {
						# funcion
						if( -e "$without_extension.chk" ){ unlink ("$without_extension.chk");}
						if( -e "$without_extension.out" ){ unlink ("$without_extension.out");}
						if( -e "$without_extension.log" ){ unlink ("$without_extension.log");}
						#
						my @empty_arr = ();
						if ($option_lanz == 0) {
							#slurm_cluster (\@empty_arr,$without_extension,100,1);
							#PBS_cluster (\@empty_arr,$without_extension,100,1);
							parallel_cpu_local (\@empty_arr,$without_extension,100,1);
						} else {
							my $env_b = `$exec_bin_g09 $without_extension $without_extension.com $ncpus $queue`;
						}
					}				
				}		
				# # # # # # # # # # # # #
				# Normal termination
				if ( $option == 1 ) { #-----
					#print "Normal Termination -> File : $input_file\n";
					delete $Info_files_dir{$key};
				}	#-----	
			}
		}
		if (!%Info_files_dir) {
			print "MESSAGE Normal Termination Jobs\n";
			$count = 1;
		}
	}
	return @report_structure;
}			
###################################
# Drawing a box around a molecule 			
sub box_molecule {
	my ($coordsmin, $coordsmax) = @_;
	#
	my $minx = @$coordsmin[0];
	my $maxx = @$coordsmax[0];
	my $miny = @$coordsmin[1];
	my $maxy = @$coordsmax[1];
	my $minz = @$coordsmin[2];
	my $maxz = @$coordsmax[2];
	# raw the lines
	
	my $filename = 'BOX.vmd';
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";	
	print $fh "draw delete all\n";
	print $fh "draw materials off\n";
	print $fh "draw color 1\n";
	#
	print $fh "draw line \"$minx $miny $minz\" \"$maxx $miny $minz\" \n";
	print $fh "draw line \"$minx $miny $minz\" \"$minx $maxy $minz\" \n";
	print $fh "draw line \"$minx $miny $minz\" \"$minx $miny $maxz\" \n";
	#
	print $fh "draw line \"$maxx $miny $minz\" \"$maxx $maxy $minz\" \n";
	print $fh "draw line \"$maxx $miny $minz\" \"$maxx $miny $maxz\" \n";
	#
	print $fh "draw line \"$minx $maxy $minz\" \"$maxx $maxy $minz\" \n";
	print $fh "draw line \"$minx $maxy $minz\" \"$minx $maxy $maxz\" \n";
	#
	print $fh "draw line \"$minx $miny $maxz\" \"$maxx $miny $maxz\" \n";
	print $fh "draw line \"$minx $miny $maxz\" \"$minx $maxy $maxz\" \n";
	#
	print $fh "draw line \"$maxx $maxy $maxz\" \"$maxx $maxy $minz\" \n";
	print $fh "draw line \"$maxx $maxy $maxz\" \"$minx $maxy $maxz\" \n";
	print $fh "draw line \"$maxx $maxy $maxz\" \"$maxx $miny $maxz\" \n";
	close $fh;
}					 
###################################
# Grid information for discrete space
sub grid_information_generator{
	my ($length_side_box_x,$length_side_box_y,$length_side_box_z,$cell_size_w) = @_;
	#
	my $total_number_of_cell_x = ( $length_side_box_x / $cell_size_w );
	my $total_number_of_cell_y = ( $length_side_box_y / $cell_size_w );
	my $total_number_of_cell_z = ( $length_side_box_z / $cell_size_w );
	#
	my $neg_points_x = int ($total_number_of_cell_x / -2);
	my $neg_points_y = int ($total_number_of_cell_y / -2);
	my $neg_points_z = int ($total_number_of_cell_z / -2);
	#
	if($length_side_box_x == 0){
		$neg_points_x           = 0;
		$total_number_of_cell_x = 1;	
	}
	if($length_side_box_y == 0){
		$neg_points_y           = 0;	
		$total_number_of_cell_y = 1;
	}
	if($length_side_box_z == 0){
		$neg_points_z           = 0;	
		$total_number_of_cell_z = 1;
	}
	@systemdata=(($neg_points_x*$cell_size_w),
	             ($neg_points_y*$cell_size_w),
				 ($neg_points_z*$cell_size_w),
				 $cell_size_w,
				 int($total_number_of_cell_x + 1),
				 int($total_number_of_cell_y + 1),
				 int($total_number_of_cell_z + 1));
}
###################################
# Construct Discrete Search Space Cube
sub Construct_Discrete_Search_Space_Cube {
	my ($length_side_box_x,$length_side_box_y,$length_side_box_z,$cell_size_w) = @_;
	#
	my $max_coord_x = $length_side_box_x;
	my $max_coord_y = $length_side_box_y;
	my $max_coord_z = $length_side_box_z;
	#
	my $cell_center = 0; 
	#
	my $total_number_of_cell_x = ( $max_coord_x / $cell_size_w );
	my $total_number_of_cell_y = ( $max_coord_y / $cell_size_w );
	my $total_number_of_cell_z = ( $max_coord_z / $cell_size_w );
	#
	#my @discretized_search_space = ();
	#
	my $pm = Parallel::ForkManager->new($nprocess);
	my %HashOrder;		# Hash to sort child process results
	$pm->run_on_finish(sub {
						my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $string_coords) = @_;
							my @string_array = split ( /\n/, $$string_coords );
							my @tmp;
							foreach (@string_array) {
								push @tmp, $_;
								#push (@discretized_search_space,$_);
							}
							$HashOrder{$pid}=\@tmp;
						});	
	# Dividimos el numero de puntos
	my $div_points_x = ($total_number_of_cell_x / 2);
	my $div_points_y = ($total_number_of_cell_y / 2);
	my $div_points_z = ($total_number_of_cell_z / 2);
	#
	my $neg_points_x = int ($div_points_x * -1);
	my $pos_points_x = int ($div_points_x);
	
	my $neg_points_y = int ($div_points_y * -1);
	my $pos_points_y = int ($div_points_y);

	my $neg_points_z = int ($div_points_z * -1);
	my $pos_points_z = int ($div_points_z);	
	if($length_side_box_x==0){
		$neg_points_x=$pos_points_x=0;
		$total_number_of_cell_x=1;	
	}
	if($length_side_box_y==0){
		$neg_points_y=$pos_points_y=0;	
		$total_number_of_cell_y=1;
	}
	if($length_side_box_z==0){
		$neg_points_z=$pos_points_z=0;	
		$total_number_of_cell_z=1;
	}
	#print "$total_number_of_cell_x\t$total_number_of_cell_y\t$total_number_of_cell_z\n";
	@systemdata=(($neg_points_x*$cell_size_w),
					($neg_points_y*$cell_size_w),
					($neg_points_z*$cell_size_w),
					$cell_size_w,
					int($total_number_of_cell_x +1),
					int($total_number_of_cell_y +1),
					int($total_number_of_cell_z +1));
	#
	#print @systemdata;
	for (my $x=$neg_points_x; $x <= $pos_points_x; $x++) {
		$pm->start and next;
		# All children process havee their own random.
		srand();
		my $string_coords;		
		for (my $y=$neg_points_y; $y <= $pos_points_y; $y++) { 
			for (my $z=$neg_points_z; $z <= $pos_points_z; $z++) { 
			#for (my $z= 0; $z < $pos_points_z; $z++) { 	
				my $coord_x = ( ( $x * $cell_size_w ) + $cell_center );
				my $coord_y = ( ( $y * $cell_size_w ) + $cell_center );
				my $coord_z = ( ( $z * $cell_size_w ) + $cell_center );
				#
				my $c_x = sprintf '%.6f', $coord_x;
				my $c_y = sprintf '%.6f', $coord_y;	
				my $c_z = sprintf '%.6f', $coord_z;
				#aqui se verifica la distancia al espacio cilindrico
				# Cylinder
				if($cylinderCase != -1){
					my $medition = Euclidean_distance($c_x, $c_y, $c_z, 0, 0, $c_z);
					if($medition <= ($cylinderCase + $cylinderAreaThick +($cell_size_w)) && $medition >= ($cylinderCase - $cylinderAreaThick- ($cell_size_w))){
						$string_coords.= "$c_x\t$c_y\t$c_z\n";
					}
				# Box normal
				}else{		
					$string_coords.= "$c_x\t$c_y\t$c_z\n";
				}
			}
		}
		$pm->finish(0,\$string_coords);
	}
	$pm->wait_all_children;	
	my @sorted_discretized_search_space;

	my @myPids= keys %HashOrder;
	my @sortedPids= sort { $a <=> $b} @myPids;
	foreach my $llaves (@sortedPids){
		push @sorted_discretized_search_space, @{$HashOrder{$llaves}};
	}
	return \@sorted_discretized_search_space;
}					
###################################
# Read files
sub read_file {
	# filename
	my ($input_file) = @_;
	my @array        = ();
	# open file
	open(FILE, "<", $input_file ) || die "Can't open $input_file: $!";
	while (my $row = <FILE>) {
		chomp($row);
		push (@array,$row);
	}
	close (FILE);
	# return array	
	return @array;
}
###################################
# Join string
sub string_tmp {
	my ($array_input) = @_;
	#
	my $concat_string;
	for ( my $i=2 ; $i < scalar (@{$array_input}); $i++) {
		$concat_string.="@$array_input[$i] ";
	}
	return $concat_string;
}
###################################
# Euclidean distance between points
sub Euclidean_distance {
	# array coords basin 1 and basin 2
	my ($p1,$p2,$p3, $axis_x, $axis_y, $axis_z) = @_;
	# variables
	my $x1 = $axis_x;
	my $y1 = $axis_y;
	my $z1 = $axis_z;
	# measure distance between two point
	my $dist = sqrt(
					($x1-$p1)**2 +
					($y1-$p2)**2 +
					($z1-$p3)**2
					); 
	return $dist;
}
###################################
# Reference file
sub format_xyz {
	my ($input_file) = @_;
	#
	my @array_coord = ();
	#
	my $tam = scalar (@{$input_file});
	for ( my $i = 2 ; $i < $tam ; $i = $i + 1 ){
		if ( length(@$input_file[$i]) > 2) { 
			my @array_tabs  = split (/\s+/,@$input_file[$i]);
			my $radii_val;
			if ( exists $Atomic_number{$array_tabs[0]} ) {
				# exists
				$radii_val = $Atomic_number{$array_tabs[0]};
			} else {
				# not exists
				$radii_val = $array_tabs[0] ;
			}
			my $strong = "$radii_val\t$array_tabs[1]\t$array_tabs[2]\t$array_tabs[3]";
			push (@array_coord,$strong);
		}
	}
	return @array_coord;
}			
###################################
# Print info terminal
sub Print_info_grid {
	my ($cell_size_w,$Num_total_Bq,$discretized_search_space_3D_init,
	    $discretized_search_space_3D_end,$NumPtsTotal,$Num_multi_arrays,$orbit,$option_nbo) = @_;
	#
	my @tmp_init = ();
	@tmp_init    = split (/\s+/,$discretized_search_space_3D_init);
	my @tmp_end  = ();
	@tmp_end     = split (/\s+/,$discretized_search_space_3D_end);
	#
	box_molecule (\@tmp_init,\@tmp_end);
	#
	my @print_orbit = @{$orbit};
	#
	my $side_x = abs ($tmp_init[0]) + abs ($tmp_end[0]);
	my $side_y = abs ($tmp_init[1]) + abs ($tmp_end[1]);
	my $side_z = abs ($tmp_init[2]) + abs ($tmp_end[2]);
	#	
	my $sum_x = ($side_x / $cell_size_w) + 1;
	my $sum_y = ($side_y / $cell_size_w) + 1;
	my $sum_z = ($side_z / $cell_size_w) + 1;
	#
	print "Grid spacing               = $cell_size_w "."A"."\n";
	print "Box dimensions     (X*Y*Z) = $side_x * $side_y * $side_z    "."A"."^3\n";
	print "Initial coordinate (X,Y,Z) = $discretized_search_space_3D_init "."A"."\n";
	print "Ending  coordinate (X,Y,Z) = $discretized_search_space_3D_end    "."A"."\n";
	print "Total points               = $NumPtsTotal\n";
	print "Number of points (X,Y,Z)   = $sum_x   $sum_y   $sum_z\n";
	print "Number of Bq per file      = $Num_total_Bq\n";
	print "Number of files            = $Num_multi_arrays\n";
	#
	if ( $option_nbo == 1 ) {
		print "Orbitals (sigma-pi)        = ";
		my $tmpstring;
		foreach (@print_orbit) {
			$tmpstring.="$_,";
		}
		chop ($tmpstring);
		print "$tmpstring\n";
	}
	#
	return ($side_x,$side_y,$side_z,$sum_x,$sum_y,$sum_z);
}
###################################
# Print logo
sub print_logo {
	print "        \n";	
	print "          _   _ _____ _____  _____       _ _         \n";
	print "         | \\ | |_   _/  __ \\/  ___|     | | |      \n";
	print "         |  \\| | | | | /  \\/\\ `--.  __ _| | |     \n";
	print "         | . ` | | | | |     `--. \\/ _` | | |       \n";
	print "         | |\\  |_| |_| \\__/\\/\\__/ / (_| | | |    \n";
	print "         \\_| \\_/\\___/ \\____/\\____/ \\__,_|_|_|  \n";
	print "         \n";
	print "                     TiznadoLab\n";
	print "        \n";
	my $datestring = localtime();
	print "              $datestring\n\n";
}
#sub print_logo {
#	print "\n";	
#	print "                                    _                      \n";
#	print "/'\\_/`\\                            ( )_                    \n";
#	print "|     |   _ _    __    ___     __  | ,_) _   _   ___ ___   \n";
#	print "| (_) | /'_` ) /'_ `\\/' _ `\\ /'__`\\| |  ( ) ( )/' _ ` _ `\\ \n";
#	print "| | | |( (_| |( (_) || ( ) |(  ___/| |_ | (_) || ( ) ( ) | \n";
#	print "(_) (_)`\\__,_)`\\__  |(_) (_)`\\____)`\\__)`\\___/'(_) (_) (_) \n";
#	print "              ( )_) |                                      \n";
#	print "               \\___/'                                      \n";
#	print "                                                           \n";
#	print "                     TiznadoLab\n";
#	print "\n";
#	my $datestring = localtime();
#	print "              $datestring\n\n";
#}
###################################
# Keywords Errors
sub errors_config {
	my ($data) = @_;
	my $bolean = 1;
	if ( ( @$data[0]  =~/coords/gi )           ){ } else { print "ERROR Correct Keywords: coords\n";            $bolean = 0;};
	if ( ( @$data[1]  =~/quality/gi )          ){ } else { print "ERROR Correct Keywords: quality\n";           $bolean = 0;};
	if ( ( @$data[2]  =~/option/gi )           ){ } else { print "ERROR Correct Keywords: option\n";            $bolean = 0;};
	if ( ( @$data[3]  =~/box_size/gi )         ){ } else { print "ERROR Correct Keywords: box_size\n";          $bolean = 0;};
	if ( ( @$data[4]  =~/core_mem/gi )         ){ } else { print "ERROR Correct Keywords: core_mem\n";          $bolean = 0;};
	if ( ( @$data[5]  =~/charge_multi/gi)      ){ } else { print "ERROR Correct Keywords: charge_multi\n";      $bolean = 0;};
	if ( ( @$data[6]  =~/header/gi)            ){ } else { print "ERROR Correct Keywords: header\n";            $bolean = 0;};
	if ( ( @$data[7]  =~/software/gi)          ){ } else { print "ERROR Correct Keywords: software\n";          $bolean = 0;};
	if ( ( @$data[8]  =~/type_graph/gi)        ){ } else { print "ERROR Correct Keywords: type_graph\n";        $bolean = 0;};
	if ( ( @$data[9]  =~/pseudopotentials/gi)  ){ } else { print "ERROR Correct Keywords: pseudopotentials\n";  $bolean = 0;};
	if ( ( @$data[10] =~/orbitals/gi)          ){ } else { print "ERROR Correct Keywords: orbitals\n";          $bolean = 0;};
	return $bolean;
}
###################################
# Input software gaussian 
sub G03Input {
	#
	my ($filebase,$Header,$ncpus,$mem,$Charge,$Multiplicity,$coordsMM,$iteration,$Info_pseudo,$option_nbo,$option_pseudo) = @_;
	#
	my @pseu_total = @{$Info_pseudo};
	#
	my $Number_file = sprintf '%.4d',$iteration;
	my $G03Input    = "$filebase$Number_file.com";
	#
	open (COMFILE, ">$G03Input");
	#print COMFILE "%chk=$filebase.chk\n";
	if ( $ncpus > 0 ) {
		print COMFILE "%NProc=$ncpus\n";
	}	
	(my $word_nospaces = $mem) =~ s/\s//g;
	print COMFILE "%mem=$word_nospaces"."GB\n";
	#
	if ( ($option_nbo == 0) && ($option_pseudo == 0) ) {
		print COMFILE "#p $Header nosymm nmr(PrintEigenVectors) geom=Connectivity \n";
	}
	if ( ($option_nbo == 1) && ($option_pseudo == 0)) {
		print COMFILE "#p $Header nosymm nmr(PrintEigenVectors) geom=Connectivity pop=nbo6read \n";
	}
	if ( ($option_nbo == 0) && ($option_pseudo == 1) ) {
		print COMFILE "#p $Header pseudo=read nosymm nmr(PrintEigenVectors) geom=Connectivity \n";	
	}
	if ( ($option_nbo == 1) && ($option_pseudo == 1) ) {
		print COMFILE "#p $Header pseudo=read nosymm nmr(PrintEigenVectors) geom=Connectivity pop=nbo6read \n";
	}
	#
	print COMFILE "\nMagnetum job $iteration\n";
	print COMFILE "\n";
	print COMFILE "$Charge $Multiplicity\n";
	foreach my $coords (@{$coordsMM}) {
		chomp ($coords);
		print COMFILE "$coords\n";
	}
	print COMFILE "\n";
	for ( my $i = 1 ; $i <= scalar (@{$coordsMM}); $i++) {
		print COMFILE "\t$i\n";
	}
	# pseudopotentials
	if ( ($option_pseudo == 1) ) {
		print COMFILE "\n";
		foreach my $line (@pseu_total) {
			print COMFILE "$line\n";
		}
	}
	# nbo orbitals
	if ( ($option_nbo == 1) ) {
		print COMFILE "\n";
		print COMFILE "\$NBO NCS=0.0  XYZ MO  \$END\n";
	}
	print COMFILE "\n";
	close COMFILE;
	#
	return $G03Input;
}

# # # # # # # # # # # # # # # # # #
# MAIN
#
print_logo();
# Funcion para el tiempo de ejecucion del programa
my $tiempo_inicial = new Benchmark;
#
my ($file_name,$queue) = @ARGV;
if (not defined $file_name) {
	die "\nNICSall must be run with:\n\nUsage:\n\tNICSall [configure-file]\n\n\n";
	exit(1);
}
if (not defined $queue) {
	die "\n Especifique cola de calculo (all.q, Aztlan, Mictlan, campos) \n";
	exit(1);
}
#
# read and parse files
my @data           = read_file($file_name);
#
my @arrays_errors  = ();
#
my $without_extension;
# data parse
my $cart;
my $quality;
my $option;
# data parse
my $Box;
my @Box_dimensions = ();
my ($Box_x,$Box_y,$Box_z);
my $option_box;
#
my $Submit_guff;
my @Submit_parameters = ();
my $ncpus;
my $mem;
#
my $charge_multi;
my @charge_multi_parameters = ();
my $Charge; 
my $Multiplicity;
#
my $header;
my $software;
my $type_graphic;
#
my $count_lines  = 0;
my @pseudo_lines = ();
my @Info_pseudo  = ();
my $option_pseudo;
#
my @Orbitales       = ();
my $Num_of_Orbitals = 0;
my @neg_orbit       = ();
my @pos_orbit       = ();
#
foreach my $a_1 (@data){
	# Convert 
#	$a_1 =~ tr/a-z/A-Z/;
#	$a_1 =~ tr/A-Z/a-z/;
	#
	if ( ($a_1=~/#/gi ) ){
	#	print "$a_1\n";
	} else {
		if ( ($a_1=~/coords/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);		
			# Identify empty string
			if (!defined($tmp[2])) {			
				print "ERROR cartesian file name empty\n\n";
				exit;
			} else {
				$cart = $tmp[2];
				($without_extension = $cart) =~ s/\.[^.]+$//;
			}	
			#
			$arrays_errors[0] = "coords";
		}
		#
		if ( ($a_1=~/quality/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {
				# Datos MultiWFN
				# Grid menor = 0.2
				# Grid medio = 0.1
				# Grid mayot = 0.07
				$quality = 0.2;
			} else {
				$quality = $tmp[2];
			}
			#
			$arrays_errors[1] = "quality";			
		}
		#
		if ( ($a_1=~/option/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {
				# default option 0
				$option = 0;
			} else {
				$option = $tmp[2];
			}
			#
			$arrays_errors[2] = "option";			
		}
		#
		if ( ($a_1=~/box_size/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string			
			if (!defined($tmp[2])) {
				print "MESSAGE Automatic size box\n";
				$option_box = 0;
			} else {
				my $var_tmp = string_tmp (\@tmp);
				$Box = $var_tmp;
				@Box_dimensions = split(/,/, $Box);
				$Box_x = $Box_dimensions[0];
				$Box_y = $Box_dimensions[1];
				$Box_z = $Box_dimensions[2];
				$option_box = 1;
			}
			#
			$arrays_errors[3] = "box_size";			
		}		
		#
		if ( ($a_1=~/core_mem/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {
				# default cpus 1 and memory 1GB
				$ncpus             = 1;
				$mem               = 1;
			} else {
				my $var_tmp        = string_tmp (\@tmp);
				$Submit_guff       = $var_tmp;
				@Submit_parameters = split(/,/, $Submit_guff);
				$ncpus             = $Submit_parameters[0];
				$mem               = $Submit_parameters[1];
			}
			#
			$arrays_errors[4] = "core_mem";			
		}
		#
		if ( ($a_1=~/charge_multi/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {
				# default multiplicity 1 and charge 0
				$Charge       = 0; 
				$Multiplicity = 1;
			} else {
				my $var_tmp   = string_tmp (\@tmp);
				$charge_multi = $var_tmp;
				@charge_multi_parameters = split(/,/, $charge_multi);
				$Charge       = $charge_multi_parameters[0]; 
				$Multiplicity = $charge_multi_parameters[1];
			}
			#
			$arrays_errors[5] = "charge_multi";			
		}
		#
		if ( ($a_1=~/header/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {
				print "ERROR theory level empty \n\n";
				exit;
			} else {
				my $var_tmp = string_tmp (\@tmp);			
				$header     = $var_tmp;
			}
			#
			$arrays_errors[6] = "header";			
		}
		#
		if ( ($a_1=~/software/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {
				print "ERROR software empty \n\n";
				exit;
			} else {			
				$software = $tmp[2];
			}
			#
			$arrays_errors[7] = "software";			
		}
		#
		if ( ($a_1=~/type_graph/gi ) ){
			my @tmp = ();
			@tmp    = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {
				print "ERROR type graphic empty \n\n";
				exit;
			} else {			
				$type_graphic = $tmp[2];
			}
			#
			$arrays_errors[8] = "type_graph";
		}
		#
		if ( ($a_1=~/pseudopotentials/gi ) ){
			push (@pseudo_lines,$count_lines);
			#
			$arrays_errors[9] = "pseudopotentials";
		}
		#
		if ( ($a_1=~/orbitals/gi ) ){
			my @tmp          = ();
			@tmp             = split (/\s+/,$a_1);
			# Identify empty string
			if (!defined($tmp[2])) {		
			} else {
				my $var_tmp      = string_tmp (\@tmp);
				@Orbitales       = split(/,/, $var_tmp);
				$Num_of_Orbitals = scalar (@Orbitales);
			}
			#
			$arrays_errors[10] = "orbitals";
		}
		#
#		if( ($a_1=~/cylinder_radii/gi) ){
#			my @tmp 			 = ();
#			if (!defined($tmp[2])) {
#				$cylinderCase = -1;
#			}else{
#				@tmp 				 = split(/\s+/, $a_1);
#				$cylinderCase= $tmp[2];
#			}
#		}
		#
#		if( ($a_1=~/cylinder_thickness/gi) ){
#			my @tmp 			 = ();
#			@tmp 				 = split(/\s+/, $a_1);
#			$cylinderAreaThick= $tmp[2];
#		}
	}
	$count_lines++;
}
#
#
if ( $option > 1 ) {
	print "ERROR Choose option 0 (Shielding) or 1 (Sigma-Pi separation)\n\n";
	exit (1);
}
if ( $option == 0 ) {
	$Numb_total_sup_atom = 7000;
	print "MESSAGE Choose Magnetic Shielding \n";
} else {
	$Numb_total_sup_atom = 250;
	print "MESSAGE Choose Sigma-pi Separation\n";
}
#
#
if ( ($option == 1) && ($Num_of_Orbitals < 4) ) {
	print "ERROR orbitals empty or N orbitals > 3 \n\n";
	exit (1);
}
# Toma valores unicos del los obitales sin repetir
my @Uniq_orbit   = uniq(@Orbitales);
my @Orbital_sort = sort {$a <=> $b} @Uniq_orbit;
foreach my $count_orbit (@Orbital_sort) {
	if ( $count_orbit < 0) {
		push (@neg_orbit,$count_orbit);
	} else {
		push (@pos_orbit,$count_orbit);
	}
}
#
# Save info pseudopotentials
my @pseu_empty = ();
foreach my $lines (($pseudo_lines[0]+1)..($pseudo_lines[1]-1)) {
	push (@Info_pseudo,$data[$lines]);
	if ($data[$lines] =~/^$/) {
	} else {
		push (@pseu_empty,$data[$lines]);
	}
}
if ( scalar (@pseu_empty) < 4 ) {
	$option_pseudo = 0;
} else {
	$option_pseudo = 1;
}
#
# Inputs for Gaussian, Orca y ADF
my $option_software;
if (($software=~/gaussian/gi )) {
	$option_software = 0;
	print "MESSAGE Choose software Gaussian\n";
} elsif (($software=~/orca/gi )) {
	$option_software = 1;
	print "MESSAGE Choose software Orca\n";
} elsif (($software=~/adf/gi )) {
	$option_software = 2;
	print "MESSAGE Choose software ADF\n";	
} else {
	print "ERROR Choose software Gaussian, Orca or ADF\n\n";
	exit (1);
}
#
#
# Measure (1=Isotropic, 2=Anisotropic, 3=Component XX, 4=Component YY & 5=Component ZZ,
#          6=FiPC, 7=scans, 8= (FiPC & scan) & & 9=SPST)
if ( $type_graphic == 1 ) {
	print "MESSAGE Choose type graphic Isotropy\n";
} elsif ( $type_graphic == 2 ) {
	print "MESSAGE Choose type graphic Anisotropy\n";
} elsif ( $type_graphic == 3 ) {
	print "MESSAGE Choose type graphic Component XX\n";
} elsif ( $type_graphic == 4 ) {
	print "MESSAGE Choose type graphic Component YY\n";
} elsif ( $type_graphic == 5 ) {
	print "MESSAGE Choose type graphic Component ZZ\n";
} elsif ( $type_graphic == 6 ) {
	print "MESSAGE Choose type graphic FIPC\n";
} elsif ( $type_graphic == 7 ) {
	print "MESSAGE Choose type graphic Scan\n";
} elsif ( $type_graphic == 8 ) {
	print "MESSAGE Choose type graphic FIPC & Scan\n";
} elsif ( $type_graphic == 9 ) {
	print "MESSAGE Choose type graphic Symmetry Properties of the Shielding Tensor\n";
} else {
	print "ERROR Please choose type graphic (1=Isotropy,2=Anisotropy,3=Component XX,4=Component YY,\n";
	print "                                  5=Component ZZ,6=FiPC,7=Scan,8=(FiPC & Scan) & 9=SPST)\n\n";
	exit (1);
}
#
#
if (!defined($arrays_errors[0]))  { $arrays_errors[0]  = "NO"; }
if (!defined($arrays_errors[1]))  { $arrays_errors[1]  = "NO"; }
if (!defined($arrays_errors[2]))  { $arrays_errors[2]  = "NO"; }
if (!defined($arrays_errors[3]))  { $arrays_errors[3]  = "NO"; }
if (!defined($arrays_errors[4]))  { $arrays_errors[4]  = "NO"; }
if (!defined($arrays_errors[5]))  { $arrays_errors[5]  = "NO"; }
if (!defined($arrays_errors[6]))  { $arrays_errors[6]  = "NO"; }
if (!defined($arrays_errors[7]))  { $arrays_errors[7]  = "NO"; }
if (!defined($arrays_errors[8]))  { $arrays_errors[8]  = "NO"; }
if (!defined($arrays_errors[9]))  { $arrays_errors[9]  = "NO"; }
if (!defined($arrays_errors[10])) { $arrays_errors[10] = "NO"; }
my $bolean = errors_config (\@arrays_errors);
if ( $bolean == 0) { exit; }
#
my $filebase = "Magneto";
# # # # # # # # # # # #	
# read file format xyz
my $file_ext_xyz = $cart;
my @data_file    = read_file ($file_ext_xyz);
my @coords_file  = format_xyz (\@data_file);
my @file_axis_x  = ();
my @file_axis_y  = ();
my @file_axis_z  = ();  
foreach my $data_coords (@coords_file) {
	my @Cartesians              = split '\s+', $data_coords;
	my ($Atom_label, @orig_xyz) = @Cartesians;
	#
	push (@file_axis_x,$orig_xyz[0]);
	push (@file_axis_y,$orig_xyz[1]);
	push (@file_axis_z,$orig_xyz[2]);
}
# # # # # # # # # 
# Automatic box
if ($option_box == 0) {
	#
	my $min_x = min @file_axis_x;
	my $max_x = max @file_axis_x;
	#
	my $min_y = min @file_axis_y;
	my $max_y = max @file_axis_y;
	#
	my $min_z = min @file_axis_z;
	my $max_z = max @file_axis_z;
	#
	my $range = Euclidean_distance ($min_x,$min_y,$min_z,$max_x,$max_y,$max_z);
	#
	my $Delta_side = 0;
	my $side_x     = sprintf '%.6f',($max_x + ($range + $Delta_side));
	my $side_y     = sprintf '%.6f',($max_y + ($range + $Delta_side));
	my $side_z     = sprintf '%.6f',($max_z + ($range + $Delta_side));
	#
	$Box_x = $side_x;
	$Box_y = $side_y;
	$Box_z = $side_z;
}

my @discretized_search_space_3D = ();
my @arrayrefs                   = ();
my $Num_total_Bq                = 0;
my $numberofarrays              = 0;
my $Numb_Atoms                  = 0;
#
my ($side_grid_x,$side_grid_y,$side_grid_z)    = 0;
my ($num_points_x,$num_points_y,$num_points_z) = 0;
#
if ( -e "ValuesICSS.backup") {
	# Generate iso-chemical shielding surfaces (ICSS)
	print "MESSAGE File ValuesCSS.backup exists, ignoring data recopilation\n";
} else {
	my $com_log_boolean = 0;
	my @coms_out = glob "$filebase*.out";
	my @coms_log = glob "$filebase*.log";
	if( scalar (@coms_out) > 0 ) {
		print "MESSAGE Data written all .out in ValuesICSS.backup\n";
		$com_log_boolean = 1;
		grid_information_generator($Box_x,$Box_y,$Box_z,$quality);
	}
	if( scalar (@coms_log) > 0 ) {
		print "MESSAGE Data written all .log in ValuesICSS.backup\n";
		grid_information_generator($Box_x,$Box_y,$Box_z,$quality);
		$com_log_boolean = 1;
	}
	#$com_log_boolean = 0;
	if ($com_log_boolean == 0) {
		@discretized_search_space_3D    = @{Construct_Discrete_Search_Space_Cube ($Box_x,$Box_y,$Box_z,$quality)};
		my $tiempo_medio = new Benchmark;
		my $tiempo_grid  = timediff($tiempo_medio, $tiempo_inicial);
		print "MESSAGE Construct discrete search space is done  ",timestr($tiempo_grid),"\n\n"; 
		#
		$NumPtsTotal     = scalar (@discretized_search_space_3D);
		$Numb_Atoms      = scalar (@coords_file);
		#
		my $Total_Data   = $NumPtsTotal + $Numb_Atoms;
		$Num_total_Bq    = $Numb_total_sup_atom - $Numb_Atoms;
		#
		$numberofarrays      = int ($NumPtsTotal/$Num_total_Bq);
		@arrayrefs           = split_into($numberofarrays,@discretized_search_space_3D); 
		my $Num_multi_arrays = scalar (@arrayrefs);
		#
		($side_grid_x,$side_grid_y,$side_grid_z,
		$num_points_x,$num_points_y,$num_points_z) = Print_info_grid ($quality,scalar(@{$arrayrefs[0]}),$discretized_search_space_3D[0],
																	$discretized_search_space_3D[-1],$NumPtsTotal,$Num_multi_arrays,\@Orbital_sort,$option);

		for ( my $i = 0 ; $i < $Num_multi_arrays ; $i = $i + 1 ){
			my @tmp_arr = ();
			my $Total_Gaus_Data = scalar(@{$arrayrefs[$i]}) + $Numb_Atoms;
			foreach my $points (@coords_file) {
				push (@tmp_arr,$points);
			}
			foreach my $lol (@{$arrayrefs[$i]}) {
				my $str_tmp = "Bq   $lol\n";
				push (@tmp_arr,$str_tmp);		
			}
			# software gaussian
			my $G03Input = G03Input ($filebase,$header,$ncpus,$mem,$Charge,$Multiplicity,\@tmp_arr,$i,\@Info_pseudo,$option,$option_pseudo);
			push (@files_Calc,$G03Input);
			#
		}
		# submit jobs
		# exit(1);
		if (1) {
			my @files_error = submit_queue (\@files_Calc,$queue,$exec_bin_g09,$local_cluster,$ncpus);
			if ( scalar (@files_error) > 0) { 
				print "MESSAGE Error Termination in output files\n";
				my $count_f = 0;
				foreach my $out_file (@files_error) {
					print "$count_f\t$out_file\n";
					$count_f++;
				}
				#
				#
				# Delete files Lanz and input .com
				my @Lanz       = glob "Lanz*.sh";
				if( scalar (@Lanz) > 0 ) {
				        unlink glob "Lanz*.sh";
				}
				my @input_com  = glob "Magneto*.com";
				if( scalar (@input_com) > 0 ) {
			        	unlink glob "Magneto*.com";
				}
				unlink ("error.tmp");
				exit(1);
			}
		}
	}
}
#
#
my $root       = dirname(abs_path($0));
my $readScript ="$root/src/ReadResults.pl";
my $cubeScript ="$root/src/GraphMaker.pl" ;
my $vtkScript  ="$root/src/CubeToVTK.pl"  ;
#
#
# Call ReadResults.pl
my $return = system("$readScript $file_name $filebase");
if($return == 512){ # little catch if $readscript finds a error.
	exit(1);
}

my @backup= glob "*.backup";
foreach my $filesBackup(@backup){
	open(VALUES, ">>$filesBackup");
	if(defined($systemdata[0])){
		printf  VALUES "@systemdata\n";
	}	
	close(VALUES);
}
# Call GraphMaker.pl
system("$cubeScript $file_name");
# Call CubeToVTK.pl
# Convert .vtk to .cube
my @cube_out = glob "*.cube";
foreach my $cube (@cube_out){
	system("perl $vtkScript $cube");
}
system("mkdir -p Resources >/dev/null");
if( scalar (@cube_out) > 0 ) {
	system("mv BOX.vmd *.cube *.vtk *.vti ./Resources/. 2>/dev/null");
} else {
	system("mv BOX.vmd *.txt ./Resources/. 2>/dev/null");
}
#
#
# Delete files Lanz and input .com
my @Lanz       = glob "Lanz*.sh";
if( scalar (@Lanz) > 0 ) {
	unlink glob "Lanz*.sh";
}
my @input_com  = glob "Magneto*.com";
if( scalar (@input_com) > 0 ) {
	unlink glob "Magneto*.com";
}
#
#
my $tiempo_final  = new Benchmark;
my $tiempo_total  = timediff($tiempo_final, $tiempo_inicial);
print "\n\tExecution Time: ",timestr($tiempo_total),"\n";
print "\n";
exit;