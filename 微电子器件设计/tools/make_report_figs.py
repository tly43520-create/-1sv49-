import numpy as np, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyBboxPatch
plt.rcParams['font.family']=['WenQuanYi Zen Hei','DejaVu Sans']
plt.rcParams['axes.unicode_minus']=False
OUT='./'
# ---------- doping ----------
sp=0.297/np.sqrt(2*np.log(1000))
def prof(p,y):
    Nepi,g=p
    N=np.where(y<6.0,Nepi+sum(a*np.exp(-(y-b)**2/(2*c*c)) for a,b,c in g),1e19)
    NA=1e20*np.exp(-y**2/(2*sp*sp))
    return N,NA
R=(1.5e14,[(7.3e16,0.40,0.063),(7.6e15,0.54,0.25),(1.0e15,0.88,0.80)])
P3=(1.75e14,[(7.67e16,0.341,0.110),(3.41e15,0.582,0.345),(8.67e14,1.09,0.584)])
y=np.linspace(0,8,40001)
fig,axs=plt.subplots(1,2,figsize=(11,4.6),gridspec_kw={'width_ratios':[1.25,1]})
for ax,xmax in zip(axs,[8,2.0]):
    for p,lab,col,ls in [(R,'R（最终设计）','#1f4e79','-'),(P3,'P3（可制造候选）','#c55a11','--')]:
        N,NA=prof(p,y); net=N-NA
        ax.semilogy(y,np.abs(net),color=col,ls=ls,lw=2,label=lab)
        if xmax==2.0:
            j=y[np.argmax(net>0)]
            ax.axvline(j,color=col,ls=':',lw=1)
            ax.annotate(f'结深 {j:.3f} µm',(j,3e14 if p is R else 1e15),xytext=(j+0.12,(3e14 if p is R else 1e15)),color=col,fontsize=10)
    ax.set_xlim(0,xmax); ax.set_ylim(1e14,2e20)
    ax.set_xlabel('距硅表面深度 y (µm)',fontsize=12)
    ax.grid(alpha=.3,which='both',lw=.5)
axs[0].set_ylabel('净掺杂浓度 |N_D − N_A| (cm⁻³)',fontsize=12)
axs[0].text(0.35,3e19,'P⁺',fontsize=12); axs[0].text(1.2,3e15,'N 型超突变区',fontsize=11); axs[0].text(3.3,2.2e14,'N⁻ 外延',fontsize=11); axs[0].text(6.25,3e18,'N⁺ 衬底',fontsize=11)
axs[0].legend(fontsize=10,loc='center right',bbox_to_anchor=(0.98,0.5))
axs[0].set_title('(a) 0–8 µm 全深度',fontsize=12); axs[1].set_title('(b) 结附近放大（0–2 µm）',fontsize=12)
plt.tight_layout(); plt.savefig(OUT+'fig_doping_1d.png',dpi=200); plt.close()
for p,n in [(R,'R'),(P3,'P3')]:
    N,NA=prof(p,y); net=N-NA; print(n,'junction',y[np.argmax(net>0)])
# ---------- structure ----------
fig,ax=plt.subplots(figsize=(11,5.2))
W=30; xw1,xw2=5,25
def yy(d):  # compress depth: 0-1.5 um stretched, then linear
    return -d*2.2 if d<=1.5 else -(1.5*2.2+(d-1.5)*0.55)
ax.add_patch(Rectangle((0,yy(8)),W,yy(6)-yy(8),fc='#9db7d5',ec='k',lw=1))
ax.add_patch(Rectangle((0,yy(6)),W,0-yy(6),fc='#e3edf7',ec='k',lw=1))
# HA gradient band
for i,d0 in enumerate(np.linspace(0.32,1.6,30)):
    a=0.75*np.exp(-((d0-0.42)/0.35)**2)+0.12
    ax.add_patch(Rectangle((0,yy(d0+0.043)),W,yy(d0)-yy(d0+0.043),fc=(0.36,0.55,0.8,a),ec='none'))
# P+ diffusion inside Si, with lateral rounded edges
xs=np.linspace(xw1-0.32,xw2+0.32,400)
def depth(x):
    if xw1<=x<=xw2: return 0.32
    dx=min(abs(x-xw1),abs(x-xw2)); return np.sqrt(max(0.32**2-dx**2,0))
ax.fill_between(xs,[0]*len(xs),[yy(depth(x)) for x in xs],color='#e06c5a',zorder=3)
ax.add_patch(Rectangle((0,0),xw1,0.9,fc='#d9d9d9',ec='k',lw=1,zorder=4))
ax.add_patch(Rectangle((xw2,0),W-xw2,0.9,fc='#d9d9d9',ec='k',lw=1,zorder=4))
ax.plot([xw1,xw2],[0.06,0.06],color='#333',lw=5,zorder=5,solid_capstyle='butt')
ax.plot([0,W],[yy(8)-0.08]*2,color='#333',lw=5)
ax.text(2.5,0.42,'SiO₂ 0.5 µm',ha='center',va='center',fontsize=11,zorder=6)
ax.text(27.5,0.42,'SiO₂',ha='center',va='center',fontsize=11,zorder=6)
ax.text(15,0.55,'阳极（理想欧姆接触，P⁺ 窗口 W = 20 / 40 µm）',ha='center',fontsize=11)
ax.text(15,yy(0.16),'P⁺ 硼扩散区（单晶 Si 内，峰值 1×10²⁰ cm⁻³，结深 ≈ 0.32 µm）',ha='center',va='center',fontsize=10.5,color='white',zorder=6)
ax.text(15,yy(0.75),'N 型超突变区：HA 主峰 + HA2 过渡 + HA3 拖尾（磷，贯穿全宽）',ha='center',va='center',fontsize=11,color='#0b2d55')
ax.text(15,yy(3.6),'N⁻ 外延层  Tepi = 6 µm，Nepi = 1.5×10¹⁴ cm⁻³（单晶 Si）',ha='center',va='center',fontsize=11)
ax.text(15,yy(7),'N⁺ 衬底（截取 2 µm，1×10¹⁹ cm⁻³）',ha='center',va='center',fontsize=11)
ax.text(15,yy(8)-0.45,'阴极',ha='center',fontsize=11)
ax.annotate('',xy=(xw1-0.15,yy(0.22)),xytext=(2.6,yy(0.95)),arrowprops=dict(arrowstyle='->',color='#7a1f12'))
ax.text(0.3,yy(1.25),'P⁺ 横向扩展\n形成弯曲结（拐角）',fontsize=9.5,color='#7a1f12')
for d in [0,0.32,1.5,6,8]:
    ax.plot([-0.3,0],[yy(d)]*2,color='k',lw=.8); ax.text(-0.5,yy(d),f'{d:g}',ha='right',va='center',fontsize=9)
ax.text(-2.2,yy(3),'深度 (µm)\n非线性标尺',rotation=90,va='center',ha='center',fontsize=10)
ax.set_xlim(-3,W+0.5); ax.set_ylim(yy(8)-0.9,1.3); ax.axis('off')
plt.tight_layout(); plt.savefig(OUT+'fig_structure.png',dpi=200); plt.close()
