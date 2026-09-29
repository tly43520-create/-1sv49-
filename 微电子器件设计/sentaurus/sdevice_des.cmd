#==========================================================
# sdevice_des.cmd  -- SWB version, iter00: 1 MHz small-signal C-V
# Mesh: taken from the upstream SDE node (n<NR>_msh.tdr)
# Reverse bias: anode swept 0 -> -15 V, cathode grounded
# Output capacitance c(a,a) is per um of device depth (2D default = 1 um)
#==========================================================

Device DIODE {
  Electrode {
    { Name="Anode"   Voltage=0.0 }
    { Name="Cathode" Voltage=0.0 }
  }
  File {
    Grid    = "@tdr@"
    Plot    = "@tdrdat@"
    Current = "@plot@"
  }
  Physics {
    Mobility( DopingDep HighFieldSaturation )
    EffectiveIntrinsicDensity( oldSlotboom )
  }
}

File {
  Output    = "@log@"
  ACExtract = "@acplot@"
}

Plot {
  eDensity hDensity
  ElectricField Potential SpaceCharge
  Doping DonorConcentration AcceptorConcentration
}

System {
  DIODE d1 ( "Anode"=a "Cathode"=c )
  Vsource_pset va (a 0) { dc = 0.0 }
  Vsource_pset vc (c 0) { dc = 0.0 }
}

Math {
  Extrapolate
  RelErrControl
  Digits=4
  Notdamped=50
  Iterations=12
  Method=Blocked
  SubMethod=ParDiSo
}

Solve {
  NewCurrentPrefix="init_"
  Coupled(Iterations=100){ Poisson }
  Coupled{ Poisson Electron Hole }

  NewCurrentPrefix=""
  Quasistationary (
    InitialStep=0.01 Increment=1.3
    MaxStep=0.05 MinStep=1e-5
    Goal { Parameter=va.dc Voltage=-15.0 }
  ){ ACCoupled (
       StartFrequency=1e6 EndFrequency=1e6 NumberOfPoints=1 Decade
       Node(a c) Exclude(va vc)
       ACCompute ( Time = ( Range = (0 1) Intervals = 150 ) )
     ){ Poisson Electron Hole }
  }
}
