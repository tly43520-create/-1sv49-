#==========================================================
# svisual_vis_2d.tcl -- C-V + Q + doping cut for the 2D structure (sde2D_param_dvs.cmd)
# Same method as svisual_vis_v3.tcl (create_curve + probe_curve + get_curve_data), plus:
#  - DOE values normalised by the window width @Wwin@ -> pF @ 1 mm^2 INCLUDING the edge term
#    (C1V_pF ... C8V_pF), raw c(a,a) per um of depth kept as C1V_raw ...
#  - doping cut through the window centre x = 5 + Wwin/2 (x = 0.5 would be under the oxide)
# Area/edge split afterwards: matlab/compare_2D_1D.m with the Wwin 20 and 40 CSVs.
#==========================================================

set Wwin @Wwin@
set xcut [expr {5.0 + $Wwin/2.0}]
set f_ac 1.0e6
set pi   3.14159265358979

set ds [load_file "@acplot|sdevice@"]
set p  [create_plot -1d]
set cv [create_curve -plot $p -dataset $ds -axisX "v(a)" -axisY "c(a,a)"]

foreach vr {1 3 5 8} {
  set c($vr) [probe_curve $cv -valueX [expr {-1.0*$vr}]]
  puts "DOE: C${vr}V_raw [format %.4e $c($vr)]"
  puts "DOE: C${vr}V_pF [format %.2f [expr {$c($vr)/$Wwin*1e18}]]"
}
puts "DOE: Ratio18 [format %.3f [expr {$c(1)/$c(8)}]]"

set haveG 1
if {[catch {set gv [create_curve -plot $p -dataset $ds -axisX "v(a)" -axisY "a(a,a)"]} err]} {
  puts "WARNING: a(a,a) not found ($err) -> CSV has 2 columns, no Q"
  set haveG 0
} else {
  set g1 [probe_curve $gv -valueX -1.0]
  puts "DOE: Q1V [format %.1f [expr {2*$pi*$f_ac*$c(1)/abs($g1)}]]"
}

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
puts "C-V curve written: $fname ([llength $xs] points, Wwin = $Wwin um)"

if {[catch {
  set dd [load_file "@tdrdat|sdevice@"]
  set p2 [create_plot -dataset $dd]
  set cut [create_cutline -plot $p2 -type x -at $xcut]
  set p3 [create_plot -1d]
  set dc [create_curve -plot $p3 -dataset $cut -axisX Y -axisY DopingConcentration]
  set ys2 [get_curve_data $dc -plot $p3 -axisX]
  set ns2 [get_curve_data $dc -plot $p3 -axisY]
  set fname2 "@pwd@/n@node@_dop.csv"
  set fid2 [open $fname2 w]
  puts $fid2 "Y,DopingConcentration"
  foreach yv $ys2 nv $ns2 { puts $fid2 "$yv,$nv" }
  close $fid2
  puts "Doping cut at x = $xcut written: $fname2"
} err]} {
  puts "WARNING: doping cut skipped ($err). Export by hand: 1D cut at x = $xcut, Y vs DopingConcentration."
}
