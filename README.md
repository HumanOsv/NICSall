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

    • FileName.xyz        : XYZ cartesian coordinates format .xyz
    
    • Config.in              : The NICSall input file
    
    • NICSall.pl             : The executables files for NMR parameters
          |_ GraphMaker.pl   
          |_ CubeToVTK.pl    
          |_ ReadResults.pl  
    

Now use the following commands to execute this program:

    user$ setsid perl NICSall.pl Config.in >out.log

After a successful run of the program, several output files named as: ValuesICSS.backup and will be generated in Resources directory with the following files: BOX.vmd, FileName.cube, FileName.vti and FileName.vtk.

	ValuesICSS.backup       : Final c
	./Resources
	     |_ BOX.vmd         :  
	     |_ FileName.cube   : 
	     |_ FileName.vti    : 
	     |_ FileName.vtk    : 
		
**3)	Input File**

The main input file named as Config.in, contains all necessary parameters for calculate the Nucleus-Independent Chemical Shifts (NICS).

Coordenadas cartesianas en formato xyz 

    coords = FileName.xyz

Calidad grid y componente del calculo Total
Ejemplo: quality = 0.2 

    quality = 0.2

Opcion para calcular Shielding (0) o separacion sigma pi (1)
    
    option = 1

Orbitales para realizar la separacion sigma pi ( N° orbitals > 3)

    orbitals = 20,21,22,23,-19,-18,-24,-25

Componente a calcular (1=Isotropy, 2=Anisotropy, 3=Component XX, 4=Component YY, 5=Component ZZ, 6=FiPC, 7=Scan, 8=FiPC+Scan & 9=SPST)
    
    type_graph = 5

The size of the box (in Angstroms) length, width, and height. AUTOMATON build an automatic box.

    box_size = 

Software mopac and gaussian (mopac/gaussian/lammps)

    software = gaussian

*Configuring the program for chemistry packages*

The number of processors to use in the run (the value may be used to create the input file) # and memory to be used in GB.

    core_mem = 8,8

The charge and multiplicity of the candidate.

    charge_multi = 0,1

keywords for gaussian, mopac, or lammps

*Gaussian*

    header = B3lyp/6-31g*

A model potential be substituted for the core electrons (https://bse.pnl.gov/bse/portal).

    pseudopotentials
    ...
    ...
    pseudopotentials

General Note: Respect the spaces of separation between the symbol "=".

    Correct : software = gaussian
    Wrong   : software=gaussian
	
	
