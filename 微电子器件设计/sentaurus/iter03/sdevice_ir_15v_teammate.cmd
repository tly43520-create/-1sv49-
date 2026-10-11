# 1SV149 反向漏电流 IR 仿真：阳极由 0 V 扫至 -15 V，阴极接地。
# File 指定输入网格及仿真输出文件。
File {
  # 读取正式设计的几何、掺杂、材料和电极网格。
  Grid    = "mesh_msh.tdr"
  # 保存各偏压步的接触电压和电流；IR 从此文件提取。
  Current = "ir_15v.plt"
  # 保存末态的电场、载流子等空间分布。
  Plot    = "ir_15v_fields.tdr"
  # 保存求解器和收敛过程日志。
  Output  = "ir_15v.log"
}
# Electrode 给出接触初始电压；扫描目标另在 Solve 中设置。
Electrode {
  # 阳极初始 0 V，随后被扫描至 -15 V。
  { Name="Anode" Voltage=0.0 }
  # 阴极始终为 0 V，作为电压参考端。
  { Name="Cathode" Voltage=0.0 }
}
# Physics 选择电流和强场计算使用的物理模型。
Physics {
  # 与手册 25 °C 测试条件一致：25 °C = 298.15 K。
  Temperature=298.15
  # 求解器内不放大二维电流；整片电流的面积换算放在后处理。
  AreaFactor=1
  # 使用费米-狄拉克统计，适用于重掺杂区。
  Fermi
  # 考虑掺杂相关迁移率以及高场速度饱和。
  Mobility( DopingDependence HighFieldSaturation )
  # SRH(DopingDependence) 为掺杂相关的陷阱辅助产生/复合，Auger 为俄歇复合。
  # Band2Band(Model=NonlocalPath) 计算非局域带间隧穿。
  # Avalanche(GradQuasiFermi) 以准费米势梯度为驱动力计算碰撞电离。
  Recombination( SRH(DopingDependence) Auger
                 Band2Band(Model=NonlocalPath)
                 Avalanche(GradQuasiFermi) )
  # OldSlotboom 禁带变窄模型修正重掺杂区的有效本征载流子浓度。
  EffectiveIntrinsicDensity( OldSlotboom )
}
# Plot 指定写入 ir_15v_fields.tdr 的空间分布：净掺杂、空间电荷、静电势、电场、
# 电子/空穴浓度、电子/空穴雪崩产生率和带间隧穿产生率。
Plot { Doping SpaceCharge Potential ElectricField eDensity hDensity
       eAvalancheGeneration hAvalancheGeneration Band2BandGeneration }
# Math 控制数值收敛，不更改器件结构与掺杂。
Math {
  # Extrapolate 沿扫描外推上一解；RelErrControl 使用相对误差判据；
  # Digits=7 收紧误差目标；Iterations=80 是每步牛顿迭代上限；
  # Notdamped=100 允许前 100 次牛顿迭代中残差范数暂时增大。
  Extrapolate RelErrControl Digits=7 Iterations=80 Notdamped=100
  # 将雪崩产生项的导数计入雅可比矩阵，帮助强场区收敛。
  AvalDerivatives
}
# Solve 按顺序求 0 V 初始状态，然后逐步施加反向电压。
Solve {
  # 先求泊松方程的初始电势，最多 100 次迭代。
  Coupled(Iterations=100) { Poisson }
  # 再联立求解泊松方程、电子及空穴连续性方程。
  Coupled { Poisson Electron Hole }
  # Quasistationary 用归一化扫描量 t∈[0,1] 逐步改变直流偏压。
  Quasistationary(
    # 起步步长、成功时的扩步因子、失败时的缩步因子。
    InitialStep=0.005 Increment=1.4 Decrement=2
    # 自适应步长下限和上限，单位为归一化 t，不是伏特。
    MinStep=1e-7 MaxStep=0.05
    # 阳极目标 -15 V；阴极为 0 V，因此反向电压为 15 V。
    Goal { Name="Anode" Voltage=-15.0 }
  # 每个扫描点均联立求解三个基本方程。
  ) { Coupled { Poisson Electron Hole } }
}
# 结果读取：取 ir_15v.plt 末点的 |Anode TotalCurrent|，再按假定的 1 mm²
# 有效面积乘 1e6；具体数值以重新运行后的 ir_15v.plt 为准，面积系数不要重复应用。
