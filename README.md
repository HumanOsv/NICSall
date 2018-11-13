# NICSall

We introduce a structural search algorithm implemented in the new **NICSall** program.

# Getting Started

**1)	Prerequisites**

NICSall is written in Perl. The program has only been tested on Linux, so it can’t be guaranteed to run on other operating systems.

This topic lists library and software that must be installed prior to installing NICSall.

-Install CPAN modules (http://www.cpan.org/modules/INSTALL.html or https://egoleo.wordpress.com/2008/05/19/how-to-install-perl-modules-through-cpan-on-ubuntu-hardy-server/)

    user$ sudo cpan Array::Split
      
    user$ sudo cpan Parallel::ForkManager

-Install External softwares

  •	ADF (https://www.scm.com/)

  •	Gaussian (http://gaussian.com/)

  •	Orca (https://orcaforum.cec.mpg.de/)
  

**2)	Running NICSall**

The program does not have a graphical user interface, it has a command line interface that is very simple to use with some instruction. NICSall program interfaces with a computational program in the background, thus the program to be used has to be available. The program allows NMR parameters using standard electronic structure theory methods to be performed using a wide variety of external quantum chemistry programs including Gaussian, ADF (work in progress) and Orca (work in progress).

To download the NICSall you need Git installed on your computer. If Git is installed use the following command to download the NICSall: 

    user$ git clone https://github.com/HumanOsv/NICSall.git

    user$ cd ./NICSall

The following necessary files should appear in the working directory:

    • FileName.xyz         : XYZ cartesian coordinates format .xyz
    
    • Config.in            : The NICSall input file
    
    • NICSall.pl           : The executables files for NMR parameters
       ./src/
          |_ GraphMaker.pl   
          |_ CubeToVTK.pl    
          |_ ReadResults.pl  
    

Now use the following commands to execute this program:

    user$ setsid perl NICSall.pl Config.in >out.log

After a successful run of the program, several output files named as: ValuesICSS.backup and will be generated in Resources directory with the following files: BOX.vmd, FileName.cube, FileName.vti, FileName.vtk, Filename_SCANS.txt and Filename_FiPC.txt.

	ValuesICSS.backup          : Final c
	./Resources
	     |_ BOX.vmd            :  
	     |_ FileName.cube      : 
	     |_ FileName.vti       : 
	     |_ FileName.vtk       : 
	     |_ Filename_SCANS.txt :
	     |_ Filename_FiPC.txt  :
		
**3)	Input File**

The main input file named as Config.in, contains all necessary parameters for calculate the NICS parameters.

The XYZ file cartesian coordinates format is a chemical file format (https://openbabel.org/docs/dev/FileFormats/XYZ_cartesian_coordinates_format.html).

    coords = FileName.xyz

*NOTE: For a better analysis it's recommended that all the molecular rings must be placed in the XY plane, in such a way that the external magnetic field is on the Z axis.*

Quality grid of NICS parameters.

    quality = 0.2

*NOTE: For efficiency consideration, the default quality of grid data is 0.4*

Choose NMR chemical shieldings (0) or Sigma-Pi separation (1)
    
    option = 0

Orbitals to perform Sigma-Pi separation 

    orbitals = 20,21,22,23,-19,-18,-24,-25

*NOTE: The Sigma and Pi orbitals correspond to Negative and Positive values.*

The size of the box (in Angstroms) length, width, and height. NICSall build an automatic box.

    box_size = 

Software gaussian (gaussian)

    software = gaussian

*Configuring the program for chemistry packages*

The number of processors to use in the run (the value may be used to create the input file) # and memory to be used in GB.

    core_mem = 8,8

The charge and multiplicity of the candidate.

    charge_multi = 0,1

keywords for gaussian

*Gaussian*

    header = B3lyp/6-31g*

A model potential be substituted for the core electrons (https://bse.pnl.gov/bse/portal).

    pseudopotentials
    ... Inputa data ...
    pseudopotentials

Nuclear independent chemical shielding (NICS) functions.
    
    type_graph = 1,2,5,8

*NOTE: NICS and related properties.*
 
    1 = Isotropy
   
    2 = Anisotropy
   
    3 = Component XX
   
    4 = Component YY
   
    5 = Component ZZ
   
    6 = FiPC
   
    7 = Scan
   
    8 = FiPC & Scan
   
    9 = Symmetry Properties of the Shielding Tensor (SPST)

**General Note: Respect the spaces of separation between the symbol "=".**

    Correct : software = gaussian
    Wrong   : software=gaussian
	
	
