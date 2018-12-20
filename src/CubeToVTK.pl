#!/usr/bin/perl

use strict;
use warnings; 

#############################################################################
# Subroutines to change .cube format to .vtk format                         #
#############################################################################



###################################
# Subroutine for convert bohr to angstrom
sub convert_bohr_armstrong {
    my $s     = shift;
    my $multi = $s*0.529177249;
    return $multi;
}
###################################
# Subroutine for change .cube format to .vtk format
sub convert_cube_vtk {
    my ($file) = @_;
    my @lines;
    #
    (my $without_extension_1 = $file) =~ s/\.[^.]+$//;
    open (CUBE, "$file");
    @lines = <CUBE>;
    close (CUBE);
    #
    my ($natom,$origen_x,$origen_y,$origen_z) = split(" ",$lines[2]);
    $origen_x = convert_bohr_armstrong($origen_x);
    $origen_y = convert_bohr_armstrong($origen_y);
    $origen_z = convert_bohr_armstrong($origen_z);
    #
    my($NX,$sx1,$sx2,$sx3) = split(" ",$lines[3]);
    my($NY,$sy1,$sy2,$sy3) = split(" ",$lines[4]);
    my($NZ,$sz1,$sz2,$sz3) = split(" ",$lines[5]);
    #
    my $spacingX = convert_bohr_armstrong($sx1);
    my $spacingY = convert_bohr_armstrong($sy2);
    my $spacingZ = convert_bohr_armstrong($sz3);
    # spacing es lines [3, 4 & 5]
    my $pos = 6 + $natom;
    # marks the cycle
    my $x = 0;
    my $y = 0;
    my $z = 0;
    my $listX = ();
    my $listY = ();
    my $listZ = ();
    #
    open (TEST,">test.tmp");
    for (my $i = $pos ; $i <= $#lines ; $i++) {
        if($lines[$i] eq "\n"){
        #
        }else{
            chomp($lines[$i]);
            my @density_line = split(" ",$lines[$i]);
            #
            while($#density_line!=-1) {
                if( $z < $NZ && $y < $NY ) {
                    my $point = shift(@density_line);
                    print TEST "$x.$y.$z = ",$point,"\n";
                    $z++;
                } elsif ( $y < $NY ) {
                    $y++;
                    $z = 0;
                } elsif ($x<$NX){
                    $x++;
                    $y = 0;
                    $z = 0;
                }           
            }
        }
    }
    close(TEST);
    #
    my @coordintes_unsorted = ();
    open (DATA,"test.tmp");
    @lines         = ();
    @lines         = <DATA>;
    my @ubications = ();
    close (DATA);
    #
    my $posX = $NY * $NZ;
    my $posY = $NZ;
    #
    my $key   = 0;
    my $data11 = "";
    #
    open(DATA2,">test2.tmp");
    #
    OUTER:for ( my $z = 0 ; $z < $NZ ; $z++ ) {
        for ( my $y = 0 ; $y < $NY ; $y++ ) {
            for ( my $x = 0 ; $x < $NX ; $x++ ) {
                $key = ($posX*$x) + ($posY*$y) + $z;
                #print "key es  $key , $posX, $posY\n";
                $data11 = $lines[$key];
                print DATA2 "data1=$data11";
            }
        }
    }
    close(DATA2);
    #
    open(DATA3,"test2.tmp");
    @lines = ();
    @lines = <DATA3>;
    unlink "test.tmp";
    #
    open(VTK,">$without_extension_1.vtk");
    my $towrite = "";
    my $aux     = 0;
    my $aux2    = 0;
    #
    print VTK "# vtk DataFile Version 3.0\n";
    print VTK "$without_extension_1 vkfile_converted\n";
    print VTK "ASCII\n";
    print VTK "DATASET STRUCTURED_POINTS\n";
    chomp ($NZ);
    print VTK "DIMENSIONS $NX $NY $NZ\n";
    print VTK "ORIGIN $origen_x $origen_y $origen_z\n";
    print VTK "SPACING $spacingX $spacingY $spacingZ\n";
    print VTK "POINT_DATA ",$NX*$NY*$NZ,"\n";
    print VTK "SCALARS scalars float 1\n";
    print VTK "LOOKUP_TABLE default\n";
    # # Cordinates:
    for (my $i = 0; $i <= $#lines; $i++) {
        my $point = (split( "=" , $lines[$i]))[-1];
        chomp($point);
        $aux++;
        $aux2++;
        $towrite = $towrite.$point;
        if ($aux2 < ($NX*$NY)) {
            if ($aux < $NX) {
                $towrite = $towrite." ";
            } else {
                $towrite = $towrite." \n";
                print VTK "$towrite";
                $towrite ="";
                $aux     =0;
            }
        } else {
            $towrite = $towrite." \n\n ";
            print VTK "$towrite";   
            $aux2    = 0;
            $aux     = 0;
            $towrite = "";
        }
    }
    #
    close(DATA3);
    close(VTK);
    unlink "test2.tmp";
}


###################################
# Call subroutines 
if($#ARGV==-1){
	print "Usage: $0 [Cube-File]\n";
	exit(1);
}
my $file = $ARGV[0];
print "MESSAGE Convert .cube to .vtk\n";
convert_cube_vtk ("$file");
