! $Id: general.f90 13605 2010-04-08 16:35:53Z Bourdin.KIS $

module General

!  Module with general utility subroutines
!  (Used for example in Sub and Mpicomm)

  use Cparam
  use Messages

  implicit none

  private

  public :: safe_character_assign,safe_character_append, chn
  public :: random_seed_wrapper
  public :: random_number_wrapper, random_gen, normal_deviate
  public :: parse_filename

  public :: setup_mm_nn
  public :: find_index_range

  public :: spline,tridag,pendag,complex_phase,erfcc

  include 'record_types.h'

  interface random_number_wrapper   ! Overload this function
    module procedure random_number_wrapper_0
    module procedure random_number_wrapper_1
    module procedure random_number_wrapper_3
  endinterface

  interface safe_character_append   ! Overload this function
    module procedure safe_character_append_2
    module procedure safe_character_append_3 ! add more if you like..
  endinterface
!
!  state and default generator of random numbers
!
  integer, save, dimension(mseed) :: rstate=0
  character (len=labellen) :: random_gen='min_std'

  contains
!***********************************************************************
    subroutine setup_mm_nn()
!
!  Produce index-array for the sequence of points to be worked through:
!  Before the communication has been completed, the nghost=3 layers next
!  to the processor boundary (m1, m2, n1, or n2) cannot be used yet.
!  In the mean time we can calculate the interior points sufficiently far
!  away from the boundary points. Here we calculate the order in which
!  m and n are executed. At one point, necessary(imn)=.true., which is
!  the moment when all communication must be completed.
!
      use Cparam
      use Cdata, only: mm,nn,imn_array,necessary,lroot
!
      integer :: imn,m,n
      integer :: min_m1i_m2,max_m2i_m1
!
!  For non-parallel runs simply go through m and n from bottom left to to right.
!
      imn_array=0
      if (ncpus==1) then
        imn=1
        necessary(1)=.true.
        do n=n1,n2
          do m=m1,m2
            mm(imn)=m
            nn(imn)=n
            imn_array(m,n)=imn
            imn=imn+1
          enddo
        enddo
      else
        imn=1
        do n=n1i+2,n2i-2
          do m=m1i+2,m2i-2
            if (imn_array(m,n) == 0) then
              mm(imn)=m
              nn(imn)=n
              imn_array(m,n)=imn
              imn=imn+1
            endif
          enddo
        enddo
        necessary(imn)=.true.
!
!  do the upper stripe in the n-direction
!
        do n=max(n2i-1,n1+1),n2
          do m=m1i+2,m2i-2
            if (imn_array(m,n) == 0) then
              mm(imn)=m
              nn(imn)=n
              imn_array(m,n)=imn
              imn=imn+1
            endif
          enddo
        enddo
!
!  do the lower stripe in the n-direction
!
        do n=n1,min(n1i+1,n2)
          do m=m1i+2,m2i-2
            if (imn_array(m,n) == 0) then
              mm(imn)=m
              nn(imn)=n
              imn_array(m,n)=imn
              imn=imn+1
            endif
          enddo
        enddo
!
!  left and right hand boxes
!  NOTE: need to have min(m1i,m2) instead of just m1i, and max(m2i,m1)
!  instead of just m2i, to make sure the case ny=1 works ok, and
!  also that the same m is not set in both loops.
!  ALSO: need to make sure the second loop starts not before the
!  first one ends; therefore max_m2i_m1+1=max(m2i,min_m1i_m2+1).
!
        min_m1i_m2=min(m1i+1,m2)
        max_m2i_m1=max(m2i-1,min_m1i_m2+1)
!
        do n=n1,n2
          do m=m1,min_m1i_m2
            if (imn_array(m,n) == 0) then
              mm(imn)=m
              nn(imn)=n
              imn_array(m,n)=imn
              imn=imn+1
            endif
          enddo
          do m=max_m2i_m1,m2
            if (imn_array(m,n) == 0) then
              mm(imn)=m
              nn(imn)=n
              imn_array(m,n)=imn
              imn=imn+1
            endif
          enddo
        enddo
      endif
!
!  Debugging output to be analysed with $PENCIL_HOME/utils/check-mm-nn.
!  Uncommenting manually, since we can't use ip here (as it is not yet
!  read from run.in).
!
      if (.false.) then
        if (lroot) then
          do imn=1,ny*nz
            if (necessary(imn)) write(*,'(A)') '==MM==NN==> Necessary'
            write(*,'(A,I5,I5)') '==MM==NN==> m,n= ', mm(imn), nn(imn)
          enddo
        endif
      endif
!
    endsubroutine setup_mm_nn
!***********************************************************************
    subroutine random_number_wrapper_0(a)
!
!  Fills a with a random number calculated with one of the generators
!  available with random_gen
!
      real :: a
      real, dimension(1) :: b
!
      intent(out) :: a
!
!     b = a                     ! not needed unless numbers are non-Markovian
!
      call random_number_wrapper(b)
      a = b(1)
!
    endsubroutine random_number_wrapper_0
!***********************************************************************
    subroutine random_number_wrapper_1(a)
!
!  Fills a with an array of random numbers calculated with one of the
!  generators available with random_gen
!
      use Cdata, only: lroot
!
      real, dimension(:) :: a
      integer :: i
!
      intent(out) :: a
!
      select case (random_gen)
!
      case ('system')
        call random_number(a)
      case ('min_std')
        do i=1,size(a,1)
          a(i)=ran0(rstate(1))
        enddo
      case ('nr_f90')
        do i=1,size(a,1)
          a(i)=mars_ran()
        enddo
      case default
        if (lroot) print*, 'No such random number generator: ', random_gen
        STOP 1                ! Return nonzero exit status

     endselect
!
    endsubroutine random_number_wrapper_1
!***********************************************************************
    subroutine random_number_wrapper_3(a)
!
!  Fills a with a matrix of random numbers calculated with one of the
!  generators available with random_gen
!
      use Cdata, only: lroot
!
      real, dimension(:,:,:) :: a
      integer :: i,j,k
!
      intent(out) :: a
!
      select case (random_gen)
!
      case ('system')
        call random_number(a)
      case ('min_std')
        do i=1,size(a,1); do j=1,size(a,2); do k=1,size(a,3)
          a(i,j,k)=ran0(rstate(1))
        enddo; enddo; enddo
      case ('nr_f90')
        do i=1,size(a,1); do j=1,size(a,2); do k=1,size(a,3)
          a(i,j,k)=mars_ran()
        enddo; enddo; enddo
      case default
        if (lroot) print*, 'No such random number generator: ', random_gen
        STOP 1                ! Return nonzero exit status

      endselect
!
    endsubroutine random_number_wrapper_3
!***********************************************************************
    subroutine normal_deviate(a)
!
!  Return a normal deviate (Gaussian random number, mean=0, var=1) by means
!  of the "Ratio-of-uniforms" method
!
!  28-jul-08/kapelrud: coded
!
      real,intent(out) :: a
!
      real :: u,v,x,y,q
      logical :: lloop
!
      lloop=.true.
      do while(lloop)
        call random_number_wrapper_0(u)
        call random_number_wrapper_0(v)
        v=1.7156*(v-0.5)
        x=u-0.449871
        y=abs(v)+0.386595
        q=x**2+y*(0.19600*y-0.25472*x)
        lloop=q>0.27597
        if (lloop) &
          lloop=(q>0.27846).or.(v**2>-4.0*log(u)*u**2)
      enddo
!
      a=v/u
!      
    endsubroutine normal_deviate
!***********************************************************************
    subroutine random_seed_wrapper(size,put,get)
!
!  mimics the f90 random_seed routine
!
      real :: dummy
      integer, optional, dimension(:) :: put,get
      integer, optional :: size
      integer :: nseed
!
      select case (random_gen)
!
      case ('system')
        call random_seed(SIZE=nseed)
        if (present(size)) size=nseed
        if (present(get))  call random_seed(GET=get(1:nseed))
        if (present(put))  call random_seed(PUT=put(1:nseed))
      case ('min_std')
        nseed=1
        if (present(size)) size=nseed
        if (present(get))  get=rstate(1)
        if (present(put))  rstate(1)=put(1)
      case default ! 'nr_f90'
        nseed=2
        if (present(size)) size=nseed
        if (present(get)) then
          get(1:nseed)=rstate(1:nseed)
        endif
        if (present(put)) then
          if (put(2)==0) then   ! state cannot be result from previous
                                ! call, so initialize
            dummy = mars_ran(put(1))
          else
            rstate(1:nseed)=put(1:nseed)
          endif
        endif
      endselect
!
    endsubroutine random_seed_wrapper
!***********************************************************************
    function ran0(dummy)
!
!  The 'Minimal Standard' random number generator
!  by Lewis, Goodman and Miller.
!
!  28.08.02/nils: Adapted from Numerical Recipes
!
      integer, parameter :: ia=16807,im=2147483647,iq=127773,ir=2836, &
           mask=123459876
      real, parameter :: am=1./im
      real :: ran0
      integer :: dummy,k
!
      dummy=ieor(dummy,mask)
      k=dummy/iq
      dummy=ia*(dummy-k*iq)-ir*k
      if (dummy.lt.0) dummy=dummy+im
      ran0=am*dummy
      dummy=ieor(dummy,mask)
!
    endfunction ran0

!***********************************************************************
    function mars_ran(init)
!
! 26-sep-02/wolf: Implemented, following `Numerical Recipes for F90'
!                 ran() routine
!
! "Minimal" random number generator of Park and Miller, combined
! with a Marsaglia shift sequence, with a period of supposedly
! ~ 3.1x10^18.
! Returns a uniform random number in (0, 1).
! Call with (INIT=ival) to initialize.
!
      implicit none
!
      real :: mars_ran
      real, save :: am=impossible    ! will be constant on a given platform
      integer, optional, intent(in) :: init
      integer, parameter :: ia=16807,im=2147483647,iq=127773,ir=2836
      integer :: k,init1=1812   ! default value
      logical, save :: first_call=.true.
!
!ajwm This doesn't appear to always get set!
      if (first_call) then
        am=nearest(1.0,-1.0)/im
        first_call=.false.
      endif
      if (present(init) .or. rstate(1)==0 .or. rstate(2)<=0) then
        !
        ! initialize
        !
        if (present(init)) init1 = init
        am=nearest(1.0,-1.0)/im
        rstate(1)=ieor(777755555,abs(init1))
        rstate(2)=ior(ieor(888889999,abs(init1)),1)
      endif
      !
      ! Marsaglia shift sequence with period 2^32-1
      !
      rstate(1)=ieor(rstate(1),ishft(rstate(1),13))
      rstate(1)=ieor(rstate(1),ishft(rstate(1),-17))
      rstate(1)=ieor(rstate(1),ishft(rstate(1),5))
      !
      ! Park-Miller sequence by Schrage's method, period 2^31-2
      !
      k=rstate(2)/iq
      rstate(2)=ia*(rstate(2)-k*iq)-ir*k
      if (rstate(2) < 0) rstate(2)=rstate(2)+im
      !
      ! combine the two generators with masking to ensure nonzero value
      !
      mars_ran=am*ior(iand(im,ieor(rstate(1),rstate(2))),1)
!
    endfunction mars_ran
!***********************************************************************
    function ran(iseed1)
!
!  (More or less) original routine from `Numerical Recipes in F90'. Not
!  sure we are allowed to distribute this
!
! 28-aug-02/wolf: Adapted from Numerical Recipes
!
      implicit none
!
      integer, parameter :: ikind=kind(888889999)
      integer(ikind), intent(inout) :: iseed1
      real :: ran
!
      ! "Minimal" random number generator of Park and Miller combined
      ! with a Marsaglia shift sequence. Returns a uniform random deviate
      ! between 0.0 and 1.0 (exclusive of the endpoint values). This fully
      ! portable, scalar generator has the "traditional" (not Fortran 90)
      ! calling sequence with a random deviate as the returned function
      ! value: call with iseed1 a negative integer to initialize;
      ! thereafter, do not alter iseed1 except to reinitialize. The period
      ! of this generator is about 3.1x10^18.

      real, save :: am
      integer(ikind), parameter :: ia=16807,im=2147483647,iq=127773,ir=2836
      integer(ikind), save      :: ix=-1,iy=-1,k

      if (iseed1 <= 0 .or. iy < 0) then   ! Initialize.
        am=nearest(1.0,-1.0)/im
        iy=ior(ieor(888889999,abs(iseed1)),1)
        ix=ieor(777755555,abs(iseed1))
        iseed1=abs(iseed1)+1   ! Set iseed1 positive.
      endif
      ix=ieor(ix,ishft(ix,13))   ! Marsaglia shift sequence with period 2^32-1.
      ix=ieor(ix,ishft(ix,-17))
      ix=ieor(ix,ishft(ix,5))
      k=iy/iq   ! Park-Miller sequence by Schrage's method,
      iy=ia*(iy-k*iq)-ir*k   ! period 231 - 2.
      if (iy < 0) iy=iy+im
      ran=am*ior(iand(im,ieor(ix,iy)),1)   ! Combine the two generators with
                                           ! masking to ensure nonzero value.
    endfunction ran
!***********************************************************************
    subroutine chn(n,ch,label)
!
!  make a character out of a number
!  take care of numbers that have less than 4 digits
!  30-sep-97/axel: coded
!
      character (len=5) :: ch
      character (len=*), optional :: label
      integer :: n
!
      intent(in) :: n,label
      intent(out) :: ch
!
      ch='     '
      if (n<0) stop 'chn: lt1'
      if (n<10) then
        write(ch(1:1),'(i1)') n
      elseif (n<100) then
        write(ch(1:2),'(i2)') n
      elseif (n<1000) then
        write(ch(1:3),'(i3)') n
      elseif (n<10000) then
        write(ch(1:4),'(i4)') n
      elseif (n<100000) then
        write(ch(1:5),'(i5)') n
      else
        if (present(label)) print*, 'CHN: <', label, '>'
        print*,'CHN: n=',n
        stop "CHN: n too large"
      endif
!
    endsubroutine chn
!***********************************************************************
    subroutine chk_time(label,time1,time2)
!
      integer :: time1,time2,count_rate
      character (len=*) :: label
!
!  prints time in seconds
!
      call system_clock(count=time2,count_rate=count_rate)
      print*,"chk_time: ",label,(time2-time1)/real(count_rate)
      time1=time2
!
    endsubroutine chk_time
!***********************************************************************
    subroutine parse_filename(filename,dirpart,filepart)
!
!  Split full pathname of a file into directory part and local filename part.
!
!  02-apr-04/wolf: coded
!
      character (len=*) :: filename,dirpart,filepart
      integer :: i
!
      intent(in)  :: filename
      intent(out) :: dirpart,filepart
!
      i = index(filename,'/',BACK=.true.) ! search last slash
      if (i>0) then
        call safe_character_assign(dirpart,filename(1:i-1))
        call safe_character_assign(filepart,trim(filename(i+1:)))
      else
        call safe_character_assign(dirpart,'.')
        call safe_character_assign(filepart,trim(filename))
      endif

    endsubroutine parse_filename
!***********************************************************************
    subroutine safe_character_assign(dest,src)
!
!  Do character string assignement with check against overflow
!
!  08-oct-02/tony: coded
!  25-oct-02/axel: added tag in output to give name of routine
!
      character (len=*), intent(in):: src
      character (len=*), intent(inout):: dest
      integer :: destLen, srcLen

      destLen = len(dest)
      srcLen = len(src)

      if (destLen<srcLen) then
         print *, "safe_character_assign: ", &
              "RUNTIME ERROR: FORCED STRING TRUNCATION WHEN ASSIGNING '" &
               //src//"' to '"//dest//"'"
         dest=src(1:destLen)
      else
         dest=src
      endif

    endsubroutine safe_character_assign
!***********************************************************************
    subroutine safe_character_append_2(str1,str2)
!
!  08-oct-02/wolf: coded
!
      character (len=*), intent(inout):: str1
      character (len=*), intent(in):: str2
!
      call safe_character_assign(str1, trim(str1) // str2)
!
    endsubroutine safe_character_append_2
!***********************************************************************
    subroutine safe_character_append_3(str1,str2,str3)
!
!  08-oct-02/wolf: coded
!
      character (len=*), intent(inout):: str1
      character (len=*), intent(in):: str2,str3
!
      call safe_character_assign(str1, trim(str1) // trim(str2) // trim(str3))
!
    endsubroutine safe_character_append_3
!***********************************************************************
    subroutine input_array(file,a,dimx,dimy,dimz,dimv)
!
!  Generalized form of input, allows specifying dimension
!  27-sep-03/axel: coded
!
      character (len=*) :: file
      integer :: dimx,dimy,dimz,dimv
      real, dimension (dimx,dimy,dimz,dimv) :: a
!
      open(1,FILE=file,FORM='unformatted')
      read(1) a
      close(1)
!
    endsubroutine input_array
!***********************************************************************
    subroutine find_index_range(aa,naa,aa1,aa2,ii1,ii2)
!
!  find index range (ii1,ii2) such that aa
!
!   9-mar-08/axel: coded
!
      use Cparam, only: nghost
!
      integer :: naa,ii,ii1,ii2
      real, dimension (naa) :: aa
      real :: aa1,aa2
!
      intent(in)  :: aa,naa,aa1,aa2
      intent(out) :: ii1,ii2
!
!  if not extent in this direction, set indices to interior values
!
      if (naa==2*nghost+1) then
        ii1=nghost+1
        ii2=nghost+1
        goto 99
      endif
!
!  find lower index
!
      ii1=naa
      do ii=1,naa
        if (aa(ii)>=aa1) then
          ii1=ii
          goto 10
        endif
      enddo
!
!  find upper index
!
10    ii2=1
      do ii=naa,1,-1
        if (aa(ii)<=aa2) then
          ii2=ii
          goto 99
        endif
      enddo
!
99    continue
    endsubroutine find_index_range
!***********************************************************************
    function spline_derivative(z,f)
!
!  computes derivative of a given function using spline interpolation
!
!  01-apr-03/tobi: originally coded by Aake Nordlund
!
      implicit none
      real, dimension(:) :: z
      real, dimension(:), intent(in) :: f
      real, dimension(size(z)) :: w1,w2,w3
      real, dimension(size(z)) :: d,spline_derivative
      real :: c
      integer :: mz,k

      mz=size(z)

      w1(1)=1./(z(2)-z(1))**2
      w3(1)=-1./(z(3)-z(2))**2
      w2(1)=w1(1)+w3(1)
      d(1)=2.*((f(2)-f(1))/(z(2)-z(1))**3 &
                  -(f(3)-f(2))/(z(3)-z(2))**3)
!
! interior points
!
      w1(2:mz-1)=1./(z(2:mz-1)-z(1:mz-2))
      w3(2:mz-1)=1./(z(3:mz)-z(2:mz-1))
      w2(2:mz-1)=2.*(w1(2:mz-1)+w3(2:mz-1))

      d(2:mz-1)=3.*(w3(2:mz-1)**2*(f(3:mz)-f(2:mz-1)) &
           +w1(2:mz-1)**2*(f(2:mz-1)-f(1:mz-2)))

!
! last point
!
      w1(mz)=1./(z(mz-1)-z(mz-2))**2
      w3(mz)=-1./(z(mz)-z(mz-1))**2
      w2(mz)=w1(mz)+w3(mz)
      d(mz)=2.*((f(mz-1)-f(mz-2))/(z(mz-1)-z(mz-2))**3 &
           -(f(mz)-f(mz-1))/(z(mz)-z(mz-1))**3)
!
! eliminate at first point
!
      c=-w3(1)/w3(2)
      w1(1)=w1(1)+c*w1(2)
      w2(1)=w2(1)+c*w2(2)
      d(1)=d(1)+c*d(2)
      w3(1)=w2(1)
      w2(1)=w1(1)
!
! eliminate at last point
!
      c=-w1(mz)/w1(mz-1)
      w2(mz)=w2(mz)+c*w2(mz-1)
      w3(mz)=w3(mz)+c*w3(mz-1)
      d(mz)=d(mz)+c*d(mz-1)
      w1(mz)=w2(mz)
      w2(mz)=w3(mz)
!
! eliminate subdiagonal
!
      do k=2,mz
         c=-w1(k)/w2(k-1)
         w2(k)=w2(k)+c*w3(k-1)
         d(k)=d(k)+c*d(k-1)
      enddo
!
! backsubstitute
!
      d(mz)=d(mz)/w2(mz)
      do k=mz-1,1,-1
         d(k)=(d(k)-w3(k)*d(k+1))/w2(k)
      enddo

      spline_derivative=d
    endfunction spline_derivative
!***********************************************************************
    function spline_derivative_double(z,f)
!
!  computes derivative of a given function using spline interpolation
!
!  01-apr-03/tobi: originally coded by Aake Nordlund
!  11-apr-03/axel: double precision version
!
      implicit none
      real, dimension(:) :: z
      double precision, dimension(:), intent(in) :: f
      double precision, dimension(size(z)) :: w1,w2,w3
      double precision, dimension(size(z)) :: d,spline_derivative_double
      double precision :: c
      integer :: mz,k

      mz=size(z)

      w1(1)=1./(z(2)-z(1))**2
      w3(1)=-1./(z(3)-z(2))**2
      w2(1)=w1(1)+w3(1)
      d(1)=2.*((f(2)-f(1))/(z(2)-z(1))**3 &
                  -(f(3)-f(2))/(z(3)-z(2))**3)
!
! interior points
!
      w1(2:mz-1)=1./(z(2:mz-1)-z(1:mz-2))
      w3(2:mz-1)=1./(z(3:mz)-z(2:mz-1))
      w2(2:mz-1)=2.*(w1(2:mz-1)+w3(2:mz-1))

      d(2:mz-1)=3.*(w3(2:mz-1)**2*(f(3:mz)-f(2:mz-1)) &
           +w1(2:mz-1)**2*(f(2:mz-1)-f(1:mz-2)))

!
! last point
!
      w1(mz)=1./(z(mz-1)-z(mz-2))**2
      w3(mz)=-1./(z(mz)-z(mz-1))**2
      w2(mz)=w1(mz)+w3(mz)
      d(mz)=2.*((f(mz-1)-f(mz-2))/(z(mz-1)-z(mz-2))**3 &
           -(f(mz)-f(mz-1))/(z(mz)-z(mz-1))**3)
!
! eliminate at first point
!
      c=-w3(1)/w3(2)
      w1(1)=w1(1)+c*w1(2)
      w2(1)=w2(1)+c*w2(2)
      d(1)=d(1)+c*d(2)
      w3(1)=w2(1)
      w2(1)=w1(1)
!
! eliminate at last point
!
      c=-w1(mz)/w1(mz-1)
      w2(mz)=w2(mz)+c*w2(mz-1)
      w3(mz)=w3(mz)+c*w3(mz-1)
      d(mz)=d(mz)+c*d(mz-1)
      w1(mz)=w2(mz)
      w2(mz)=w3(mz)
!
! eliminate subdiagonal
!
      do k=2,mz
         c=-w1(k)/w2(k-1)
         w2(k)=w2(k)+c*w3(k-1)
         d(k)=d(k)+c*d(k-1)
      enddo
!
! backsubstitute
!
      d(mz)=d(mz)/w2(mz)
      do k=mz-1,1,-1
         d(k)=(d(k)-w3(k)*d(k+1))/w2(k)
      enddo

      spline_derivative_double=d
    endfunction spline_derivative_double
!***********************************************************************
    function spline_integral(z,f,q0)
!
!  computes integral of a given function using spline interpolation
!
!  01-apr-03/tobi: originally coded by Aake Nordlund
!
      implicit none
      real, dimension(:) :: z
      real, dimension(:) :: f
      real, dimension(size(z)) :: df,dz
      real, dimension(size(z)) :: q,spline_integral
      real, optional :: q0
      integer :: mz,k

      mz=size(z)

      q(1)=0.
      if (present(q0)) q(1)=q0
      df=spline_derivative(z,f)
      dz(2:mz)=z(2:mz)-z(1:mz-1)

      q(2:mz)=.5*dz(2:mz)*(f(1:mz-1)+f(2:mz)) &
              +(1./12.)*dz(2:mz)**2*(df(1:mz-1)-df(2:mz))

      do k=2,mz
         q(k)=q(k)+q(k-1)
      enddo

      spline_integral=q
    endfunction spline_integral
!***********************************************************************
    function spline_integral_double(z,f,q0)
!
!  computes integral of a given function using spline interpolation
!
!  01-apr-03/tobi: originally coded by Aake Nordlund
!  11-apr-03/axel: double precision version
!
      implicit none
      real, dimension(:) :: z
      double precision, dimension(:) :: f
      real, dimension(size(z)) :: dz
      double precision, dimension(size(z)) :: df
      double precision, dimension(size(z)) :: q,spline_integral_double
      double precision, optional :: q0
      integer :: mz,k

      mz=size(z)

      q(1)=0.
      if (present(q0)) q(1)=q0
      df=spline_derivative_double(z,f)
      dz(2:mz)=z(2:mz)-z(1:mz-1)

      q(2:mz)=.5*dz(2:mz)*(f(1:mz-1)+f(2:mz)) &
              +(1./12.)*dz(2:mz)**2*(df(1:mz-1)-df(2:mz))

      do k=2,mz
         q(k)=q(k)+q(k-1)
      enddo

      spline_integral_double=q
    endfunction spline_integral_double
!***********************************************************************
    subroutine tridag(a,b,c,r,u,err)
!
!  Solves tridiagonal system.
!
!  01-apr-03/tobi: from numerical recipes
!
      implicit none
      real, dimension(:), intent(in) :: a,b,c,r
      real, dimension(:), intent(out) :: u
      real, dimension(size(b)) :: gam
      logical, intent(out), optional :: err
      integer :: n,j
      real :: bet
!
      if (present(err)) err=.false.
      n=size(b)
      bet=b(1)
      if (bet==0.0) then
        print*,'tridag: Error at code stage 1'
        if (present(err)) err=.true.
        return
      endif
!
      u(1)=r(1)/bet
      do j=2,n
        gam(j)=c(j-1)/bet
        bet=b(j)-a(j)*gam(j)
        if (bet==0.0) then
          print*,'tridag: Error at code stage 2'
          if (present(err)) err=.true.
          return
        endif
        u(j)=(r(j)-a(j)*u(j-1))/bet
      enddo
!
      do j=n-1,1,-1
        u(j)=u(j)-gam(j+1)*u(j+1)
      enddo
!
    endsubroutine tridag
!***********************************************************************
    subroutine tridag_double(a,b,c,r,u,err)
!
!  Solves tridiagonal system.
!
!  01-apr-03/tobi: from numerical recipes
!  11-apr-03/axel: double precision version
!
      implicit none
      double precision, dimension(:), intent(in) :: a,b,c,r
      double precision, dimension(:), intent(out) :: u
      double precision, dimension(size(b)) :: gam
      logical, intent(out), optional :: err
      integer :: n,j
      double precision :: bet
!
      if (present(err)) err=.false.
      n=size(b)
      bet=b(1)
      if (bet==0.0) then
        print*,'tridag_double: Error at code stage 1'
        if (present(err)) err=.true.
        return
      endif
!
      u(1)=r(1)/bet
      do j=2,n
        gam(j)=c(j-1)/bet
        bet=b(j)-a(j)*gam(j)
        if (bet==0.0) then
          print*,'tridag_double: Error at code stage 2'
          if (present(err)) err=.true.
          return
        endif
        u(j)=(r(j)-a(j)*u(j-1))/bet
      enddo
      do j=n-1,1,-1
        u(j)=u(j)-gam(j+1)*u(j+1)
      enddo
!
    endsubroutine tridag_double
!***********************************************************************
    subroutine pendag (m,a,b,c,d,e,r)
!
!  Solve pentadiagonal system of M linear equations.
!  A,B,C,D,E are the diagonals (A:subsub, B:sub, C:main, etc.).
!  R is the rhs on input and contains the solution on output
!
!  01-apr-00/John Crowe (Newcastle): written
!
implicit none

integer :: i,m
real :: x
real, dimension (m) :: a,b,c,d,e,r

! eliminate sub-diagonals

   x    = b(2)/c(1)
   c(2) = c(2)-d(1)*x
   d(2) = d(2)-e(1)*x
   r(2) = r(2)-r(1)*x

do i=3,m-1,1

   x    = a(i)/c(i-2)
   b(i) = b(i)-d(i-2)*x
   c(i) = c(i)-e(i-2)*x
   r(i) = r(i)-r(i-2)*x

   x    = b(i)/c(i-1)
   c(i) = c(i)-d(i-1)*x
   d(i) = d(i)-e(i-1)*x
   r(i) = r(i)-r(i-1)*x

end do

   x    = a(m)/c(m-2)
   b(m) = b(m)-d(m-2)*x
   c(m) = c(m)-e(m-2)*x
   r(m) = r(m)-r(m-2)*x

   x    = b(m)/c(m-1)
   c(m) = c(m)-d(m-1)*x
   r(m) = r(m)-r(m-1)*x


! eliminate super-diagonals

   r(m-1) = r(m-1) - d(m-1)*r(m)/c(m)

do i = m-2 , 1 , -1

   r(i)   = r(i) - d(i)*r(i+1)/c(i+1) - e(i)*r(i+2)/c(i+2)

end do

! reduce c's to unity, leaving the answers in r

do i = 1 , m , 1
 
   r(i) = r(i) / c(i)

end do

    endsubroutine pendag
!***********************************************************************
    subroutine spline(arrx,arry,x2,S,psize1,psize2,err)
!
!  Interpolates in x2 a natural cubic spline with knots defined by the 1d
!  arrays arrx and arry
!
!  25-mar-05/wlad : coded
!
      integer, intent(in) :: psize1,psize2
      integer :: i,j,ct1,ct2
      real, dimension (psize1) :: arrx,arry,h,h1,a,b,d,sol
      real, dimension (psize2) :: x2,S
      real :: fac=0.1666666
      logical, intent(out), optional :: err

      intent(in)  :: arrx,arry,x2
      intent(out) :: S

      if (present(err)) err=.false.
      ct1 = psize1
      ct2 = psize2
!
! Short-circuit if there is only 1 knot
!
      if (ct1 == 1) then
        S = arry(1)
        return
      endif
!
! Breaks if x is not monotonically increasing
!
      do i=1,ct1-1
        if (arrx(i+1).le.arrx(i)) then
          print*,'spline x:y in x2:y2 : vector x is not monotonically increasing'
          if (present(err)) err=.true.
          return
        endif
      enddo
!
! step h
!
      h(1:ct1-1) = arrx(2:ct1) - arrx(1:ct1-1)
      h(ct1) = h(ct1-1)
      h1=1./h
!
! coefficients for tridiagonal system
!
      a(2:ct1) = h(1:ct1-1)
      a(1) = a(2)
!
      b(2:ct1) = 2*(h(1:ct1-1) + h(2:ct1))
      b(1) = b(2)
!
      !c = h
!
      d(2:ct1-1) = 6*((arry(3:ct1) - arry(2:ct1-1))*h1(2:ct1-1) - (arry(2:ct1-1) - arry(1:ct1-2))*h1(1:ct1-2))
      d(1) = 0. ; d(ct1) = 0.
!
      call tridag(a,b,h,d,sol)
!
! interpolation formula
!
      do j=1,ct2
         do i=1,ct1-1
!
            if ((x2(j).ge.arrx(i)).and.(x2(j).le.arrx(i+1))) then
!
! substitute 1/6. by 0.1666666 to avoid divisions 
!
               S(j) = (fac*h1(i)) * (sol(i+1)*(x2(j)-arrx(i))**3 + sol(i)*(arrx(i+1) - x2(j))**3)  + &
                    (x2(j) - arrx(i))*(arry(i+1)*h1(i) - h(i)*sol(i+1)*fac)                          + &
                    (arrx(i+1) - x2(j))*(arry(i)*h1(i) - h(i)*sol(i)*fac)
            endif
!
         enddo
!
! use border values beyond this interval - should perhaps allow for linear
! interpolation
!
         if (x2(j).le.arrx(1)) then
           S(j) = arry(1)
         elseif (x2(j).ge.arrx(ct1)) then
           S(j) = arry(ct1)
         endif
       enddo
!
    endsubroutine spline
!*****************************************************************************
    function complex_phase(z)
!
!  takes complex number and returns Theta where
!  z = A*exp(i*theta)
!
!  17-may-06/anders+jeff: coded
!
      use Cdata, only: pi
!
      real :: c,re,im,complex_phase
      complex :: z
!
      c=abs(z)
      re=real(z)
      im=aimag(z)
! I
  if ( (re .ge. 0.0) .and. (im .ge. 0.0) ) complex_phase =      asin(im/c)
! II
  if ( (re .lt. 0.0) .and. (im .ge. 0.0) ) complex_phase =   pi-asin(im/c)
! III
  if ( (re .lt. 0.0) .and. (im .lt. 0.0) ) complex_phase =   pi-asin(im/c)
! IV
  if ( (re .ge. 0.0) .and. (im .lt. 0.0) ) complex_phase = 2*pi+asin(im/c)
!
   endfunction complex_phase
!*****************************************************************************
    function erfcc(x)
!  nr routine.
!  12-jul-2005/joishi: added, translated syntax to f90, and pencilized
!  21-jul-2006/joishi: generalized.
       real :: x(:)
       real,dimension(size(x)) :: erfcc,t,z


      z=abs(x)
      t=1./(1.+0.5*z)
      erfcc=t*exp(-z*z-1.26551223+t*(1.00002368+t*(.37409196+t* &
            (.09678418+t*(-.18628806+t*(.27886807+t*(-1.13520398+t*  &
            (1.48851587+t*(-.82215223+t*.17087277)))))))))
      where (x.lt.0.) erfcc=2.-erfcc
      return
    endfunction erfcc
!*****************************************************************************
    subroutine cyclic(a,b,c,alpha,beta,r,x,n)
!
! 08-Sep-07/gastine+dintrans: coded from numerical recipes.
! Inversion of a tridiagonal matrix with periodic BC (alpha and beta
! coefficients in the left and right corners). Used in the ADI scheme
! of the implicit_physics module.
! Note: this subroutine is using twice the tridag one written above by tobi.
!
      implicit none
!
      real, dimension(n) :: a,b,c,r,x,bb,u,z
      real    :: alpha,beta,gamma,fact      
      integer :: i,n
!
      if (n <= 2) stop "cyclic in the general module: n too small"
      gamma=-b(1)
      bb(1)=b(1)-gamma
      bb(n)=b(n)-alpha*beta/gamma
      do i=2,n-1
        bb(i)=b(i)
      enddo
      call tridag(a,bb,c,r,x)
      u(1)=gamma
      u(n)=alpha
      do i=2,n-1
        u(i)=0.
      enddo
      call tridag(a,bb,c,u,z)
      fact=(x(1)+beta*x(n)/gamma)/(1.+z(1)+beta*z(n)/gamma)
      do i=1,n
        x(i)=x(i)-fact*z(i)
      enddo
!
      return
    endsubroutine cyclic
!*****************************************************************************
endmodule General
