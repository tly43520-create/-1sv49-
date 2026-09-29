#==========================================================
# svisual_vis.tcl  -- batch C-V extraction (v2)
# SWB flow: sde -> sdevice -> svisual  (one svisual node per sdevice node)
# 1) DOE values written into the SWB table
# 2) full C-V curve written to <project dir>/n<node>_cv.csv
#    (get_curve_data + plain Tcl file output; replaces export_variables)
# Units: c(a,a) in F per um of device depth
#==========================================================

set ds [load_file "@acplot|sdevice@"]

set p  [create_plot -1d]
set cv [create_curve -plot $p -dataset $ds -axisX "v(a)" -axisY "c(a,a)"]

# ---- checkpoints first, so the SWB table is filled even if export fails
foreach vr {1 3 5 8} {
  set c($vr) [probe_curve $cv -valueX [expr {-1.0*$vr}]]
  puts "DOE: C${vr}V [format %.4e $c($vr)]"
}
puts "DOE: Ratio18 [format %.3f [expr {$c(1)/$c(8)}]]"

# ---- full curve -> CSV in the project directory
set xs [get_curve_data $cv -plot $p -axisX]
set ys [get_curve_data $cv -plot $p -axisY]
set fname "@pwd@/n@node@_cv.csv"
set fid [open $fname w]
puts $fid "v(a),c(a,a)"
foreach xv $xs yv $ys {
  puts $fid "$xv,$yv"
}
close $fid
puts "C-V curve written: $fname ([llength $xs] points)"
