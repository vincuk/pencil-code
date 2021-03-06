! $Id$
!
!  This module takes care of stirring of particles.
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lparticles_stirring=.false.
!
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
!
!***************************************************************
module Particles_stirring
!
  use Cparam
  use Cdata
  use General, only: keep_compiler_quiet
  use Particles_cdata
!
  implicit none
!
  include 'particles_stirring.h'
!
  contains
!***********************************************************************
    subroutine particle_stirring(fp,ineargrid)
!
!  30-dec-10/anders+michiel: dummy
!
      real, dimension (mpar_loc,mparray) :: fp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      call keep_compiler_quiet(fp)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine particle_stirring
!***********************************************************************
    subroutine read_particles_stir_run_pars(unit,iostat)
!
!  30-dec-10/anders+michiel: dummy
!
      include 'unit.h'
      integer, intent(inout), optional :: iostat
!
      call keep_compiler_quiet(unit)
      if (present(iostat)) call keep_compiler_quiet(iostat)
!
    endsubroutine read_particles_stir_run_pars
!***********************************************************************
    subroutine write_particles_stir_run_pars(unit)
!
!  30-dec-10/anders+michiel: dummy
!
      integer, intent(in) :: unit
!
      call keep_compiler_quiet(unit)
!
    endsubroutine write_particles_stir_run_pars
!***********************************************************************
endmodule Particles_stirring
