!  -*-f90-*-  (for emacs)    vim:set filetype=fortran:  (for vim)
!  cparam.inc
!
! This file was automatically generated by mkcparam, so think twice before
! you modify it.
!
! It is included by cparam.f90 and defines some constants based on the
! settings in Makefile.local
!

integer, parameter :: mvar=4, maux=0
integer, parameter :: maux_com=0
integer, parameter :: mglobal=0
integer, parameter :: mscratch=0
integer, parameter :: mpvar=0
integer, parameter :: ndustspec=1
integer, parameter :: nchemspec=1
logical, parameter :: lmdvar=.false., lmice=.false.

integer, parameter :: npar=1

integer, parameter :: mpar_loc=npar
integer, parameter :: npar_mig=1
integer, parameter :: npar_species=1
integer, parameter :: nspar=1
integer, parameter :: npar_stalk=0
integer, parameter :: nbrickx=1
integer, parameter :: nbricky=1
integer, parameter :: nbrickz=1
integer, parameter :: nblockmax=1
logical, parameter :: lparticles_blocks = .false.
integer, parameter :: nghost = 3
logical, parameter :: linitial_condition = .false.
logical, parameter :: lborder_profiles = .false.
logical, parameter :: lsignal = .false.
logical, parameter :: lhyperresistivity_strict=.false.
logical, parameter :: lhyperviscosity_strict=.false.
logical, parameter :: lparticles_stalker=.false.
logical, parameter :: lparticles_collisions = .false.
logical, parameter :: lparticles_viscosity = .false.
logical, parameter :: lparticles_nbody=.false.
logical, parameter :: lparticles_selfgravity=.false.
logical, parameter :: lparticles_number=.false.
logical, parameter :: lparticles_spin=.false.
logical, parameter :: lparticles_radius=.false.
logical, parameter :: lparticles=.false.
logical, parameter :: ltestflow = .false.
logical, parameter :: ltestfield = .false.
logical, parameter :: ltestscalar = .false.
logical, parameter :: lcosmicrayflux = .false.
logical, parameter :: lcosmicray = .false.
logical, parameter :: lspecial = .false.
logical, parameter :: ldustdensity = .false.
logical, parameter :: ldustvelocity = .false.
logical, parameter :: lchemistry = .false.
logical, parameter :: lpolymer = .false.
logical, parameter :: llorenz_gauge = .false.
logical, parameter :: lmagnetic = .false.
logical, parameter :: ltemperature = .false.
logical, parameter :: lentropy = .false.
logical, parameter :: linterstellar = .false.
logical, parameter :: lpoisson=.false.
logical, parameter :: ldensity_anelastic = .false.
logical, parameter :: ldensity = .true.
logical, parameter :: lhydro_kinematic = .false.
logical, parameter :: lhydro = .true.
logical, parameter :: lshock = .false.
logical, parameter :: lviscosity = .true.