#==========================================================
# svisual_iv_2d.tcl -- reverse I-V extraction for the 2D structure (copy of svisual_iv_vis.tcl)
# Only change: current per um of depth is divided by the window width @Wwin@ before the
# 1 mm^2 scaling, so IR15_nA includes the edge (perimeter) leakage of a Wwin-wide stripe.
# DOE: IR15_nA  = |I| at V_R = 15 V, scaled to the junction area
#      BV10uA_V = V_R where |I| reaches 10 uA (scaled), -1 if not reached
# CSV: <project dir>/n<node>_iv.csv  (raw sim units)
#==========================================================

set Aum2 [expr {1e6/@Wwin@}]     ;# 1 mm^2 divided by the window width [um]

# current file of the upstream sdevice node (tool label assumed "sdevice")
set ds [load_file "@plot|sdevice@"]
set p  [create_plot -1d]
set iv [create_curve -plot $p -dataset $ds \
          -axisX "Anode InnerVoltage" -axisY "Anode TotalCurrent"]

set xs [get_curve_data $iv -plot $p -axisX]
set ys [get_curve_data $iv -plot $p -axisY]

# ---- leakage at V_R = 15 V
set i15 [probe_curve $iv -valueX -15.0]
puts "DOE: IR15_nA [format %.4g [expr {abs($i15)*$Aum2*1e9}]]"

# ---- breakdown: first crossing of 10 uA (log interpolation between points)
set Ith [expr {10e-6/$Aum2}]
set bv -1
set xp ""; set yp ""
foreach xv $xs yv $ys {
  set ya [expr {abs($yv)}]
  if {$ya >= $Ith} {
    if {$xp ne "" && $yp > 0 && $ya > 0} {
      set f [expr {(log($Ith)-log($yp))/(log($ya)-log($yp))}]
      set bv [expr {abs($xp + $f*($xv-$xp))}]
    } else {
      set bv [expr {abs($xv)}]
    }
    break
  }
  set xp $xv; set yp $ya
}
puts "DOE: BV10uA_V [format %.3f $bv]"
puts "DOE: Vmax_V [format %.2f [expr {abs([lindex $xs end])}]]"

# ---- full curve -> CSV
set fname "@pwd@/n@node@_iv.csv"
set fid [open $fname w]
puts $fid "Anode InnerVoltage,Anode TotalCurrent"
foreach xv $xs yv $ys { puts $fid "$xv,$yv" }
close $fid
puts "I-V curve written: $fname ([llength $xs] points)"
