#==========================================================
# cv_des.cmd  -- iter00: 1 MHz small-signal C-V of practice varactor
# Mesh from practice_dvs.cmd -> practice_msh.tdr
# Reverse bias: anode swept 0 -> -15 V, cathode grounded
# Output capacitance c(a,a) is per um of device depth (2D default = 1 um)
# All paths absolute; can be run from any directory
#==========================================================

Device DIODE {
  Electrode {
    { Name="Anode"   Voltage=0.0 }
    { Name="Cathode" Voltage=0.0 }
  }
  File {
    Grid    = "/home/wzc/STDB/1sv/practice_msh.tdr"
    Plot    = "/home/wzc/STDB/1sv/cv_des.tdr"
    Current = "/home/wzc/STDB/1sv/cv_des.plt"
  }
  Physics {
    Mobility( DopingDep HighFieldSaturation )
    EffectiveIntrinsicDensity( oldSlotboom )
  }
}

File {
  Output    = "/home/wzc/STDB/1sv/cv_log"
  ACExtract = "/home/wzc/STDB/1sv/cv_ac_des.plt"
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
