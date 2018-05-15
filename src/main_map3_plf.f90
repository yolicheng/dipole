program map3_plf

! Try to find type III symmetric periodic orbit, so instead of looking at the first and second returns to the starting axis, we have to look at another 
! for example, we take I.C. on axis to be (x0, 0, 0, +vy)
! and we look at the first crossing at y-axis (0, yf, vxf, vyf), if we have vyf=0, we are saved 

! By applying the symmetry of the system, we take initial grid with points y=0 and vx=0 and treat vy as a function of (h, x, y=0, vx=0)
! we only need to discretise the component x, with x \in [-0.62, 0.62]

!  --- data saved in ./dat/map3_plf/  subfolder 

!  1. cur.dat         -- the original orbit of the 2D torus 
!  2. curve.dat         -- the invariant curve obtained by Poincare map 
! 
use dp_mod
use pi_mod 
use poinc_mod
use plf_mod 
!use po_plf_mod
implicit none

integer, parameter  ::  ndim   = 4,  & ! for lf
                        npvar  = 6, &  !42 for variational matrix, 6 for state vector 
                        npoinc = 2000  
! Local Variables
integer       ::  debug, i, k
real(kind=dp) ::  beta0 

! eigenvalues and eigenvectors around the equilibria                 
real(kind=dp) ::  dlf(ndim, ndim), wr(ndim), wi(ndim), vr(ndim, ndim) 


! Poincare map 
integer       :: ind0, dir0, imax0, ispro, ind_free, fmap_pro, fmap_retro 
!                ind will be the Poincare section, ind_free will be the free parameter left
!                first we take ind=2, ind_free = 1 to detect p.o. symmetric w.r.t. x-axis
!                then we take ind=1, ind_free = 2 to detect p.o. symmetric w.r.t. y-axis
! 
real(kind=dp) :: p00,  tmax0, xmax0, cj0 
character(len=70) :: fnpro, fnretro

! Po 
integer ::  ispo 
real(kind=dp) ::  y0(ndim-2),   TP, yf(ndim), dg(1,1), cj  

! curve
integer :: ftorus,foball, ind_curv, isv, ispc, ispl, np
real(kind=dp) :: pvi(ndim), pvf(ndim), cj_i, tf, hminim, xstep, x0!, tf_total
character(len=70) :: fntorus, fncurve 

! for fft_ob 
integer           ::  istol, nfmax, nsm,  nitmax, isfour 
real(kind=dp)     ::  tolres,  tolfc 

! take eq1  in planar normal case as an example, type center X saddle  equilibria
! with beta = 1.d0, there is resonance when beta is around 1, avoid this for the moment 
debug = 0

call init_plf     ! to assign the value of  eq 

! TODO: the value of beta matters! at this moment, we take beta=2 
beta0 = 2.d0   ! use 2 to check, but 1 is better?  
!print*, 'Input the value of beta (n/w_c):'
!read*, beta0 
call init_beta(beta0)   
     
print*, 'check,  beta',  beta0 

call gr_cjplf(eq, cj)
print*, 'check energy! ', cj, eq

! -- the energy level we r taking, smaller than the one at the equilibria, so we have a 
! closed UFO 
! for x ----
 cj0 = cj + 0.05d0
 print*, 'cj0 =', cj0; read*
 
! cj0 = 3.8270713160552936          ! the one the continutation stops 
 
! cj0 = 3.8270713160552936 - 1.d-5  ! the one there is no intersection? 
 
! cj0 = 3.8270713160552936 + 1.d-3  ! the one with 2 periodic orbits 
   
!! try another one, where the continuation stops 
!  cj0 =  3.8270713125978135    ! 3.8270713125975111
!! 
!!! try a even smaller one 
!! cj0 =  3.8270713125978135 - 1.d-5
! 
! ! for continuation of Type 2 p.o. 
!!  cj0 =  1.9970714282989488 -  1.d0 !5.d-1 !- 1.d-6    
!  cj0 = 1.9924776554107650
read*

    
! -- the real units-----
print*, 'runit(km), tunit(s), vuint(km/s): ', runit, tunit, vunit

! Jacobi matrix of the lorentz force with respective to the state 
call dflrtz2(eq, dlf)

print*, 'Check DG in the planar case: ' 
do i = 1, ndim 
  write(*,'(4f18.8)') dlf(i,:) 
enddo
print*; read* 

call eigrg(dlf, ndim,1, wr,wi, vr)
print*, 'Check if we have a center X center X saddle equilibria:' 
print*; read* 

! Take initial point on the x-axis, with velocity perpendicular to x-axis, and compute the P.O. 
! by Poincare map with the section as y=0, take vy as a function of f(cj, x, y=0, vx)
! so we have 2 dimension of freedom (x, vx )


!! ---------- Computation -----------------------------
! For poincare map limitation 
xmax0 =  2.d0  !
tmax0 =  4.d1 ! 

! Poincare section:  y=0  
ind_free  = 1       ! 1: x (or 2: y) component
ind0  = 3-ind_free  ! 2: y (or 1: x) component 

p00   = 0.d0        ! rough guess, by observing directly at the plot of the tori  
dir0  = 0           ! no requirement in the direction, just compute the first turn 
imax0 = 1           ! consider every intersection, and choose by the direction of velocity

!subroutine init_poinc( ind0, p00, dir0, imax0, tmax0, xmax0, ndim0, h00) 
call init_poinc(ind0, p00, dir0, imax0, tmax0, xmax0, ndim, cj0)
  
! instead of refining for po orbit, we just take a lot of points on x-axis, and do the poincare section 
! observe the first and second return to the Poincare section to see if there exist p.o. 
! ** NOTE *** 
! Definition of prograde and retrograde orbit 

! Prograde: The normal to orbit is the same with the normal to the chief's orbit around the Earth 
! retrograde: .... the contrary 

! ** Criteria **
! Since we have the symmetry about the origin in '+t' time sense, once we have (x, y, vx, vy)
! as a solution, we will have also (-x, -y, -vx, -vy), so we only need to study the first qudrant (x>0, y>0)
 
! we take initial point on x-axis with an initial velocity perpendicular to x-axis, (x0, 0, 0, vy0), with x0>0
! and check the first return to x-axis(y=0 section), take vy0>0. 

! We could have two kinds of p.o.,   
! -- 1. one is prograde,  so xf < x0 after half revolution. 

! -- 2. one is retrograde, so xf > x0 after half revolution 

! Now we have to make clear if it is necessary to study also the case when vy0 < 0  
! for the above two kinds of p.o.s
! -- 1. if xf > 0 for all the grids, there is no need to take vy0 < 0, since for every point (x0>0, vy0<0), its first return to y=0 section 
!       corresponds to a point (xf > 0, vyf > 0) 
! -- 2. if xf < 0, we obtain a p.o. symmetric w.r.t. to both x-axis and y-axis, which ends up with a circle. 

fmap_pro   = 25;    fmap_retro   = 52; 

if(ind_free == 1) then  ! for x axis
  write(fnpro,  fmt='(a)')  './dat/map3_plf/map_pro_x.dat'
  write(fnretro,fmt='(a)')  './dat/map3_plf/map_retro_x.dat'
  
elseif(ind_free == 2) then ! for y axis
  write(fnpro,  fmt='(a)')  './dat/map3_plf/map_pro_y.dat'
  write(fnretro,fmt='(a)')  './dat/map3_plf/map_retro_y.dat'
endif  

open(fmap_pro, file = fnpro, access ='append',status = 'replace')
write(fmap_pro, *)  ' # Poincare map:  t      (x y  vx vy )   h'

open(fmap_retro, file = fnretro  , access ='append',status = 'replace' )
write(fmap_retro, *)  ' #  Poincare map:  t      (x y  vx vy )   h'


!open(fmap_pro, file = './dat/map3_plf/map_pro.dat', access ='append',status = 'replace')
!write(fmap_pro, *)  ' # Poincare map:  t      (x y  vx vy )   h'

!open(fmap_retro, file = './dat/map3_plf/map_retro.dat'  , access ='append',status = 'replace' )
!write(fmap_retro, *)  ' #  Poincare map:  t      (x y  vx vy )   h'


!ftorus = 21;  fntorus    =  './dat/map3_plf/torusall.dat'
!open(ftorus  ,file = fntorus, access ='append',  status = 'replace' )
!write(ftorus ,*)  ' # Original  tori: t      (x y  vx vy )   h'

! -- discard at this moment--- take too much time to write the data of the orbit, take ispl = 0
foball = 24
open(foball, file = './dat/map3_plf/oball.dat', access ='append',  status = 'replace' )
write(foball ,*)  ' # the orbit by poinc: t      (x y  vx vy )   h'


ispl = 0

!np = 4000  ! for the first two returns 
np = 10 ! for the poincare map of the phase space ...

if(ind_free == 1) then  ! for x>0
! x0 = 6.3d-1  
  x0 = 7.2d-1 
else                    ! for y>0 
 x0 = 4.58d-1  
 x0 = 1.d0
!  x0 = 20.d-1
endif   
!debug =1 

xstep = x0 / np
 
do  i = 1, np, 1
  pvi = 0.d0           ! y  = 0  ! vx = 0 
  
  
  ! so we only need to study x>0? 
  x0  =  i * xstep   ! x
  if( dabs(x0) < 1.d-5 ) cycle
  
  
  ! TODO:  debug.  we fail to reach to the poincare section when x0 = 0.519 
!   pvi(1) = 0.519d0  ! for debug 
  
!  pvi(1) = y0(1) - 3.d-2 * ind_curv ! x
!  pvi(1) = -0.60740924112296302d0
!  pvi = (/ 0.56784837604607341 ,      -1.1119702540638688E-022,   8.7175931844212136E-003 , 0.33555563012250067/)
  
  pvi(ind_free) = x0 
  
  x0 = 0.6d0
  pvi(1) = x0    !x0
  pvi(3) = 1.d-1 ! vx
  
  call cj2v_plf(pvi, cj0, ind+2, isv)
  if(isv == 0 ) then 
    print*, pvi 
    
    ! TODO: in fact, if we only take the positive half axis, we coulde exit once we detect isv==0
!   exit
    cycle
  endif  
  
  
  open(100, file='./dat/map_plf/po_ob3.dat', status='old', access='append')
  call plob(pvi, 0.d0, 4.d1, ndim, 1, 100, 1, gr_plf, gr_cjplf,  pvf) 
  
  stop 
    
  ! check the energy
  call gr_cjplf(pvi, cj_i)
  if (debug == 1) print*, 'State of initial point: ', pvi, 'cj = ', cj_i, 'dcj', dabs(cj_i-cj0) ; ! read*
  
  ! compute 2 intersections with y=0 plane, to detect periodic orbit
  ispro = 0
  do k = 1, npoinc, 1
  
!   subroutine poinc(sti, ndim, nvar, ispl, fob, tf,stf, hminim, ispc, deriv, gr_cj) 
    call poinc(pvi, ndim, ndim, ispl, foball, tf, pvf, hminim, ispc, gr_plf, gr_cjplf)

    if(ispc == 0) exit 
    
    ! check the energy 
    call gr_cjplf(pvf, cj_i)
    
    ! determine the sense of orbit by the first return to Poincare section
    if( k == 1 ) then 
      if(ind_free == 1)  then  ! check the evolution of x-component
        if(pvf(ind_free) < pvi(ind_free)) ispro = 1
        
      elseif (ind_free == 2) then ! check the evolution of y-component
        if(pvf(ind_free) > pvi(ind_free)) ispro = 1
      endif   
    endif 
    
    if( ispro == 1)  then
!      print*, 'Detect prograde orbit!'; read*
      write(fmap_pro, *)    tf, pvf, cj_i
    else 
      write(fmap_retro, *)  tf, pvf, cj_i
    endif 
    
    if(debug == 1) then 
       print*, 'i,k, ispro', i, k, ispro;  read* 
    endif    
    
    
    if (debug == 1) then 
      print*, k, '-th return to Poincare section!'
      write(*, *) k, tf, pvf, cj_i;  print*;  read*
    endif 
    
    pvi = pvf  ! as the new start point 
  enddo 
  
  if( ispro == 1)  then
    write(fmap_pro, *) ! to seperate difference initial points 
  else 
    write(fmap_retro, *) ! to seperate difference initial points 
  endif   
  
  if(ispl == 1)  write(foball, *) ! just to separate different orbits
 
enddo 

 close(fmap_pro); close(fmap_retro)
 stop 
 
 
end 
 


