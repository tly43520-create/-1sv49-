#==========================================================
# svisual_vis.tcl  -- sweep01 batch C-V extraction
# SWB flow: sde -> sdevice -> svisual  (one svisual node per sdevice node)
# Writes: DOE values into the SWB table + full C-V curve as CSV per node
# Units: c(a,a) in F per um of depth (quasi-1D, width 1 um -> F per um^2)
#        multiply by 1e18 to get pF for a 1 mm^2 junction
#==========================================================

# AC output of the upstream sdevice node (tool label assumed "sdevice")
set ds [load_file "@acplot|sdevice@"]

set p  [create_plot -1d]
set cv [create_curve -plot $p -dataset $ds -axisX "v(a)" -axisY "c(a,a)"]

# full curve for archive / local-n analysis
export_variables {v(a) c(a,a)} -dataset $ds -filename "n@node@_cv.csv" -overwrite

# checkpoints: anode voltage = -VR
foreach vr {1 3 5 8} {
  set c($vr) [probe_curve $cv -valueX [expr {-1.0*$vr}]]
  puts "DOE: C${vr}V [format %.4e $c($vr)]"
}
puts "DOE: Ratio18 [format %.3f [expr {$c(1)/$c(8)}]]"
