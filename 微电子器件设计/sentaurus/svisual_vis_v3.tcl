#==========================================================
# svisual_vis.tcl  -- batch C-V + Q + doping extraction (v3)
# SWB flow: sde -> sdevice -> svisual  (one svisual node per sdevice node)
# 1) DOE values written into the SWB table: C1V C3V C5V C8V Ratio18 (as v2) + Q1V
# 2) <project dir>/n<node>_cv.csv  : v(a), c(a,a), a(a,a)   (3 columns)
# 3) <project dir>/n<node>_dop.csv : Y, DopingConcentration  (vertical cut at x = 0.5 um)
# Method for every export: create_curve + get_curve_data (as v2; export_variables with
# "v(a) c(a,a)" wrote nothing in v1).
# Units: c(a,a) F/um, a(a,a) S/um (per um of device depth); Y um; doping cm^-3 (net, P < 0)
# Manual refs: sd §3.4 (Y = A + j*w*C, a(i,j) = conductance, in the .plt as a(d,g));
#              sv §6.3/6.4 (create_cutline -type x -at, create_curve -axisX Y, get_curve_data)
# UNVERIFIED: the "@tdrdat|sdevice@" placeholder (same pattern as @acplot|sdevice@).
#==========================================================

set f_ac 1.0e6
set pi   3.14159265358979

set ds [load_file "@acplot|sdevice@"]
set p  [create_plot -1d]
set cv [create_curve -plot $p -dataset $ds -axisX "v(a)" -axisY "c(a,a)"]

# ---- checkpoints first, so the SWB table is filled even if an export fails
foreach vr {1 3 5 8} {
  set c($vr) [probe_curve $cv -valueX [expr {-1.0*$vr}]]
  puts "DOE: C${vr}V [format %.4e $c($vr)]"
}
puts "DOE: Ratio18 [format %.3f [expr {$c(1)/$c(8)}]]"

# ---- conductance a(a,a) -> Q = 2*pi*f*C/G ; skipped (no crash) if the name differs
set haveG 1
if {[catch {set gv [create_curve -plot $p -dataset $ds -axisX "v(a)" -axisY "a(a,a)"]} err]} {
  puts "WARNING: a(a,a) not found ($err) -> CSV has 2 columns, no Q"
  set haveG 0
} else {
  set g1 [probe_curve $gv -valueX -1.0]
  puts "DOE: Q1V [format %.1f [expr {2*$pi*$f_ac*$c(1)/abs($g1)}]]"
}

# ---- full curve -> CSV
set xs [get_curve_data $cv -plot $p -axisX]
set ys [get_curve_data $cv -plot $p -axisY]
set fname "@pwd@/n@node@_cv.csv"
set fid [open $fname w]
if {$haveG} {
  set gs [get_curve_data $gv -plot $p -axisY]
  puts $fid "v(a),c(a,a),a(a,a)"
  foreach xv $xs yv $ys gvv $gs { puts $fid "$xv,$yv,$gvv" }
} else {
  puts $fid "v(a),c(a,a)"
  foreach xv $xs yv $ys { puts $fid "$xv,$yv" }
}
close $fid
puts "C-V curve written: $fname ([llength $xs] points)"

# ---- doping along depth (bias-independent; taken from the sdevice plot file)
if {[catch {
  set dd [load_file "@tdrdat|sdevice@"]
  set p2 [create_plot -dataset $dd]
  set cut [create_cutline -plot $p2 -type x -at 0.5]
  set p3 [create_plot -1d]
  set dc [create_curve -plot $p3 -dataset $cut -axisX Y -axisY DopingConcentration]
  set ys2 [get_curve_data $dc -plot $p3 -axisX]
  set ns2 [get_curve_data $dc -plot $p3 -axisY]
  set fname2 "@pwd@/n@node@_dop.csv"
  set fid2 [open $fname2 w]
  puts $fid2 "Y,DopingConcentration"
  foreach yv $ys2 nv $ns2 { puts $fid2 "$yv,$nv" }
  close $fid2
  puts "Doping cut written: $fname2 ([llength $ys2] points)"
} err]} {
  puts "WARNING: doping cut skipped ($err). Export it by hand: 1D cut at x=0.5, Y vs DopingConcentration."
}
