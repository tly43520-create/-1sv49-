#==========================================================
# sdevice_iv_des.cmd -- reverse I-V: leakage at 15 V + avalanche breakdown
# Quasi-1D varactor (same SDE node as the C-V flow)
# Based on sd tutorial section 11 (BVmethods): avalanche GradQuasiFermi,
# AvalDerivatives, BreakCriteria on contact current.
# Units: currents in A per um of device depth (quasi-1D: A/um^2)
#   datasheet 10 uA @ 1 mm^2  -> 1e-11 A/um
#   datasheet 50 nA @ 1 mm^2  -> 5e-14 A/um
#==========================================================

File {
  Grid    = "@tdr@"
  Plot    = "@tdrdat@"
  Current = "@plot@"
  Output  = "@log@"
}

Electrode {
  { Name="Anode"   Voltage=0.0 }
  { Name="Cathode" Voltage=0.0 }
}

Physics {
  EffectiveIntrinsicDensity( OldSlotboom )
  Mobility(
    DopingDep
    HighFieldSaturation( GradQuasiFermi )
  )
  Recombination(
    SRH( DopingDep )
    Avalanche( GradQuasiFermi )
  )
  Fermi
}

Plot {
  eDensity hDensity
  ElectricField Potential SpaceCharge
  Doping DonorConcentration AcceptorConcentration
}

CurrentPlot {
  ElectricField( Maximum(Semiconductor Coordinates) )
  ImpactIonization( Integrate(Semiconductor) )
}

Math {
  Extrapolate
  Iterations=20
  Notdamped=100
  RelErrControl
  AvalDerivatives
  Method=Blocked
  SubMethod=ParDiSo
  # stop at 1e-9 A/um (= 1 mA for 1 mm^2), well past the 10 uA criterion
  BreakCriteria{ Current(Contact="Anode" AbsVal=1e-9) }
}

Solve {
  Coupled(Iterations=100){ Poisson }
  Coupled{ Poisson Electron Hole }

  # reverse sweep: anode 0 -> -60 V (max step 0.005*60 = 0.3 V)
  Quasistationary(
    InitialStep=1e-4 Increment=1.41
    MinStep=1e-7 MaxStep=0.005
    Goal{ Name="Anode" Voltage=-60.0 }
  ){ Coupled{ Poisson Electron Hole } }
}
