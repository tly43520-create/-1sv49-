# sprocess_Pstraggle_fps.cmd -- measure phosphorus Rp / dRp (as-implanted) and anneal broadening
# SWB parameter: @Energy@ [keV]; suggested values 290 370 440 680 (iter04 F3/F2 layers)
# Commands follow sp tutorial §2 (1D process): line / region / init / implant / diffuse / WritePlx.
# Background is boron 1e12 so the phosphorus profile is not mixed with an N background
# (for the straggle fit only; the real epi is N-).
# SetPlxList is omitted on purpose: then all solutions are saved (sp §2.11).

line x location= 0.0      spacing= 1<nm>   tag= SiTop
line x location= 0.5<um>  spacing= 5<nm>
line x location= 1.5<um>  spacing= 10<nm>
line x location= 4.0<um>  spacing= 50<nm>  tag= SiBottom

region Silicon xlo= SiTop xhi= SiBottom
init concentration= 1.0e12<cm-3> field= Boron

implant Phosphorus energy= @Energy@<keV> dose= 1e12<cm-2> tilt= 7<degree> rotation= 0<degree>
WritePlx n@node@_asimpl.plx

diffuse temperature= 1100<C> time= 60<min>
WritePlx n@node@_1100C60min.plx
