#==========================================================
# sdevice_ir15_des.cmd -- reverse I-V 0 -> 15 V, SWB version of the team deck
# (sentaurus/iter03/sdevice_ir_15v_luyiming.cmd: same Physics / Math / Solve, only the File
#  section uses SWB placeholders). Works for the 1D and the 2D SDE node.
# 2D: the final Plot file (@tdrdat@, at -15 V) holds the ElectricField map -> look at the
#     P+ window corners for field crowding. Currents are A per um of depth.
#==========================================================

File {
  Grid    = "@tdr@"
  Current = "@plot@"
  Plot    = "@tdrdat@"
  Output  = "@log@"
}

Electrode {
  { Name="Anode"   Voltage=0.0 }
  { Name="Cathode" Voltage=0.0 }
}

Physics {
  Temperature=298.15
  AreaFactor=1
  Fermi
  Mobility( DopingDependence HighFieldSaturation )
  Recombination( SRH(DopingDependence) Auger
                 Band2Band(Model=NonlocalPath)
                 Avalanche(GradQuasiFermi) )
  EffectiveIntrinsicDensity( OldSlotboom )
}

Plot { Doping SpaceCharge Potential ElectricField eDensity hDensity
       eAvalancheGeneration hAvalancheGeneration Band2BandGeneration }

Math {
  Extrapolate RelErrControl Digits=7 Iterations=80 Notdamped=100
  AvalDerivatives
}

Solve {
  Coupled(Iterations=100) { Poisson }
  Coupled { Poisson Electron Hole }
  Quasistationary(
    InitialStep=0.005 Increment=1.4 Decrement=2
    MinStep=1e-7 MaxStep=0.05
    Goal { Name="Anode" Voltage=-15.0 }
  ) { Coupled { Poisson Electron Hole } }
}
