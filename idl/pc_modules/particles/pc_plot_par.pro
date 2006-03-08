;
;  $Id: pc_plot_par.pro,v 1.11 2006-03-08 13:59:53 ajohan Exp $
;
pro pc_plot_par, xx, x=x, y=y, z=z, com=com, pos=pos, ps=ps, color=color, $
    filename=filename, imgdir=imgdir, datadir=datadir, quiet=quiet

default, x, 0
default, y, 0
default, z, 0
default, com, 0
default, pos, [0.1,0.1,0.9,0.9]
default, ps, 0
default, color, 0
default, filename, 'particles.eps'
default, imgdir, '.'
default, datadir, './data/'
default, quiet, 0

if (n_elements(x) ne 1) then begin
  nx=n_elements(x) & ny=n_elements(y) & nz=n_elements(z)
  x0=x[0] & x1=x[nx-1]
  y0=y[0] & y1=y[ny-1]
  z0=z[0] & z1=x[nz-1]
endif else begin
  pc_read_dim, obj=dim, datadir=datadir, /quiet
  pc_read_param, obj=par, datadir=datadir, /quiet
  nx=dim.nxgrid & ny=dim.nygrid & nz=dim.nzgrid
  x0=par.xyz0[0] & x1=x0+par.Lxyz[0]
  y0=par.xyz0[1] & y1=y0+par.Lxyz[1]
  z0=par.xyz0[2] & z1=z0+par.Lxyz[2]
endelse

if (com eq 1) then begin
  x0=x0+mean(xx[*,0]) & x1=x1+mean(xx[*,0])
  y0=y0+mean(xx[*,1]) & y1=y1+mean(xx[*,1])
  z0=z0+mean(xx[*,2]) & z1=z1+mean(xx[*,2])
endif

if ( (nx ne 1) and (ny ne 1) and (nz ne 1) ) then begin
  thick=3
  !p.charsize=2.0
  xsize=14.0
  ysize=11.0
endif else begin
  thick=3
  !p.charsize=1.0
  xsize=12.0
  ysize=12.0
endelse

if (ps) then begin
  set_plot, 'ps'
  device, /encapsulated, color=color, xsize=xsize, ysize=ysize, $
      font_size=11, filename=imgdir+'/'+filename
endif else begin
  thick=1
endelse

!p.charthick=thick & !p.thick=thick
!x.thick=thick & !y.thick=thick & !z.thick=thick

if (color) then loadct, 12
frame_color=100
par_color=200

if ( (nx ne 1) and (ny ne 1) and (nz ne 1) ) then begin

  surface,  [[0.0,0.0,0.0],[0.0,0.0,0.0]], col=frame_color, $
      xrange=[x0,x1], yrange=[y0,y1], zrange=[z0,z1], $
      xstyle=1, ystyle=1, zstyle=1, /save, /nodata, pos=pos
  axis, xaxis=1, x0, y1, z1, /t3d, xtickformat='noticknames_aj',col=frame_color
  axis, xaxis=1, x0, y1, z0, /t3d, xtickformat='noticknames_aj',col=frame_color
  axis, yaxis=1, x1, y0, z0, /t3d, ytickformat='noticknames_aj',col=frame_color
  axis, yaxis=1, x1, y0, z1, /t3d, ytickformat='noticknames_aj',col=frame_color
  axis, zaxis=0, x1, y1, z0, /t3d, ztickformat='noticknames_aj',col=frame_color
  axis, zaxis=0, x1, y0, z0, /t3d, ztickformat='noticknames_aj',col=frame_color

  plots, xx[*,0], xx[*,1], xx[*,2], psym=3, col=par_color, /t3d

  axis, zaxis=1, x0, y0, z0, /t3d, ztickformat='noticknames_aj',col=frame_color
  axis, yaxis=0, x0, y0, z1, /t3d, ytickformat='noticknames_aj',col=frame_color
  axis, xaxis=0, x0, y0, z1, /t3d, xtickformat='noticknames_aj',col=frame_color
 
endif else if ( (nx ne 1) and (ny ne 1) and (nz eq 1) ) then begin
  
  plot, xx[*,0], xrange=[x0,x1], yrange=[y0,y1], /nodata
  plots, xx[*,0], xx[*,1], psym=3
 
endif else if ( (nx ne 1) and (ny eq 1) and (nz ne 1) ) then begin
  
  plot, xx[*,0], xrange=[x0,x1], yrange=[z0,z1], /nodata
  plots, xx[*,0], xx[*,2], psym=3

endif else if ( (nx eq 1) and (ny ne 1) and (nz ne 1) ) then begin
  
  plot, xx[*,0], xrange=[y0,y1], yrange=[z0,z1], /nodata
  plots, xx[*,1], xx[*,2], psym=3

endif

if (ps) then begin
  if (not quiet) then print, 'pc_plot_par: writing '+imgdir+'/'+filename
  device, /close
  set_plot, 'x'
endif

end
