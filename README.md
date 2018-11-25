# NICSall

We introduce a Nuclear independent chemical shielding (NICS) algorithm implemented in the new **NICSall** program.

# Getting Started

**1)	Prerequisites**

NICSall is written in Perl. The program has only been tested on Linux, so it can’t be guaranteed to run on other operating systems.

This topic lists library and software that must be installed prior to installing NICSall.

-Install CPAN modules (http://www.cpan.org/modules/INSTALL.html or https://egoleo.wordpress.com/2008/05/19/how-to-install-perl-modules-through-cpan-on-ubuntu-hardy-server/)

    user$ sudo cpan install Array::Split
      
    user$ sudo cpan install Parallel::ForkManager

-Install External softwares

  •	ADF (https://www.scm.com/)

  •	Gaussian (http://gaussian.com/)

  •	Orca (https://orcaforum.cec.mpg.de/)

  •	NBO for Gaussian to perform Sigma-Pi separation (http://nbo6.chem.wisc.edu/webnbo_css.htm) 
  
  

**2)	Running NICSall**

The NICSall program works through the command line interface using very simple instructions. NICSall program interfaces with a computational program in the background, thus the program to be used has to be available. The program allows NMR parameters using standard electronic structure theory methods to be performed using a wide variety of external quantum chemistry programs including Gaussian, ADF (work in progress) and Orca (work in progress).

To download the NICSall you need Git installed on your computer. If Git is installed use the following command to download the NICSall: 

    user$ git clone https://github.com/HumanOsv/NICSall.git

    user$ cd ./NICSall

The following necessary files should appear in the working directory:

    • FileName.xyz         : XYZ cartesian coordinates format .xyz
    
    • Config.in            : The NICSall input file
    
    • NICSall.pl           : The executables files for NMR parameters
       ./src/
          |_ GraphMaker.pl  : Build the ValuesICSS.backup files with all NMR parameters
          |_ CubeToVTK.pl   : Change cube format to VTK formst 
          |_ ReadResults.pl : Read all the NMR parameters obtained by Gaussian software and extract them to be saved   
    

Now use the following commands to execute this program:

    user$ perl NICSall.pl Config.in > out.log

alternatively, the user can set NICSall to run in the background using:

    user$ nohup perl NICSall.pl Config.in > out.log

or: 

    user$ setsid perl NICSall.pl Config.in > out.log

After a successful run of the program, several output files named as: ValuesICSS.backup and will be generated in Resources directory with the following files: BOX.vmd, FileName.cube, FileName(Pos|Neg).vti, FileName.vtk, Filename_SCANS.txt and Filename_FiPC.txt.

	out.log			   : Output file from NICSall software
	ValuesICSS.backup          : File contains the main 
	./Resources
	     |_ BOX.vmd            : The size of the box (in Angstroms) length, width, and height. (vmd -e BOX.vmd) 
	     |_ FileName.cube      : The cube file describes volumetric data as well as atom positions. 
	     |_ FileName_Pos.vti   : The Induced Magnetic Field (VTI File Format, Positive Vectors)
	     |_ Filename_Neg.vti   : The Induced Magnetic Field (VTI File Format, Negative Vectors)
	     |_ FileName.vtk       : The Induced Magnetic Field (VTK File Format, Isolines) 
	     |_ Filename_SCANS.txt : Scan-NICS values computed along the axis perpendicular to the molecular plane
	     |_ Filename_FiPC.txt  : FiPC-NICS is computing NICS profiles along the axis perpendicular to the molecular plane
	     |_ Filename_SPST.txt  : Symmetry Properties of the Shielding Tensor (SPST) profiles along the axis perpendicular to the 
	                             molecular plane
		
*NOTE: Files Format*

   ValuesICSS.backup
   
    Column   Description
       1         Type of Atom 
     2,3,4       Cartesian Coords
       5         Isotropy
       6         Anisotropy
       7         Component XX
       8         Component YY
       9         Component ZZ
      10         Component XZ
      11         Component YZ
           
   Filename_SCANS.txt
   
    Column   Description
       1         Type of Atom       
       2         Z axis coord
       3         Component ZZ
       4         Isotropy
       5         Anisotropy
       
   Filename_FiPC.txt
   
    Column   Description
       1         Type of Atom       
       2         Z axis coord
       3         Component XX
       4         Component YY
       5         Component ZZ
       6         In-Plane
       7         Out-Plane
       
   Filename_SPST.txt
   
    Column   Description
				
		
**3)	Input File**

NICSall needs an input file, Config.in, that contains all the necessary parameters for a correct calculation. Each variable is 
explained below.


*a)* The XYZ file cartesian coordinates format is a chemical file format (https://openbabel.org/docs/dev/FileFormats/XYZ_cartesian_coordinates_format.html).

    coords = FileName.xyz

*NOTE: For a better analysis it's recommended that all the molecular rings must be placed in the XY plane, in such a way that the external magnetic field is on the Z axis.*


*b)* Quality grid of NICS parameters.

    quality = 0.2

*NOTE: For efficiency consideration, the default quality of grid data is 0.4*


*c)* The size of the box (in Angstroms) length, width, and height. NICSall build an automatic box.

    box_size = 


*NOTE: The value "0" in any parameter (length, width or height) will make a plane. Two "0" in the parameters will build a line*


*d)* Choose NMR chemical shieldings (0) or Sigma-Pi separation (1)
    
    option = 0


*e)* Orbitals to perform Sigma-Pi separation 

    orbitals = 20,21,22,23,-19,-18,-24,-25

*NOTE: The Sigma and Pi orbitals correspond to Negative and Positive values.*


*f)* Nuclear independent chemical shielding (NICS) functions.
    
    type_graph = 1,2,5,8

*NOTE: NICS and related properties.*
 
    1 = Isotropy
   
    2 = Anisotropy
   
    3 = Component XX
   
    4 = Component YY
   
    5 = Component ZZ
   
    6 = FiPC-NICS
   
    7 = Scan-NICS
   
    8 = FiPC-NICS & Scan-NICS
   
    9 = Symmetry Properties of the Shielding Tensor (SPST)


*g)* Software gaussian (gaussian)

    software = gaussian

*Configuring the program for chemistry packages*


*h)* The number of processors to use in the run (the value may be used to create the input file) and memory to be used in GB.

    core_mem = 8,8


*i)* The charge and multiplicity of the candidate.

    charge_multi = 0,1


*j)* keywords for gaussian

*Gaussian*

    header = B3lyp/6-31g*


*k)* A model potential be substituted for the core electrons (https://bse.pnl.gov/bse/portal).

    pseudopotentials
    ... Inputa data ...
    pseudopotentials


**General Note: Respect the spaces of separation between the symbol "=".**

    Correct : software = gaussian
    Wrong   : software=gaussian
	
	
