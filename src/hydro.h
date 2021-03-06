!  -*-f90-*-  (for emacs)    vim:set filetype=fortran:  (for vim)
  private
!
! functions
  public :: register_hydro, initialize_hydro
  public :: read_hydro_init_pars, write_hydro_init_pars
  public :: read_hydro_run_pars,  write_hydro_run_pars
  public :: rprint_hydro
  public :: get_slices_hydro
  public :: init_uu, duu_dt, calc_lhydro_pars, calc_pencils_hydro
  public :: time_integrals_hydro
  public :: pencil_criteria_hydro, pencil_interdep_hydro
  public :: calc_mflow, remove_mean_momenta, impose_velocity_ceiling
  public :: hydro_clean_up
  public :: traceless_strain, coriolis_cartesian
  public :: kinematic_random_phase
  public :: hydro_before_boundary
  public :: expand_shands_hydro
  public :: calc_means_hydro
!
! WL: SHOULDN'T BE PUBLIC!
!
  public :: uumx,        lcalc_uumeanx
  public :: uumz, guumz, lcalc_uumeanz, lupw_uu
  public :: uumxy, uumxz, lcalc_uumeanxy, lcalc_uumeanxz
  public :: ampl_fcont_uu
