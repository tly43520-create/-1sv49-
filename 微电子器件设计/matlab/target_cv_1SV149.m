%% target_cv_1SV149.m
% Build the fitting targets for the 1SV149 varactor design from datasheet data:
%   (1) target C-V curve + lower/upper bound curves (1-8 V)
%   (2) the same in SDevice units c(a,a) [F/um] for a chosen junction area
%   (3) target local exponent n(V) = -dlnC/dln(V+Vbi)
%   (4) target doping profile N(W) by C-V profiling (depletion approximation)
%   (5) optional: compare with a simulated curve exported by svisual (n<node>_cv.csv)
% Outputs: target_cv_1SV149.csv, target_doping_1SV149.csv, figures
% No toolbox needed (uses pchip, gradient, readmatrix; MATLAB R2019a+)

clear; clc; close all;

%% 0. Settings --------------------------------------------------------------
A_mm2   = 1.0;      % junction area assumed in the design [mm^2]
Vbi     = 0.8;      % built-in voltage used for power-law interpolation [V]
simFile = '';       % e.g. 'n12_cv.csv' exported by svisual_vis.tcl ('' = skip)

% current design (iter01 / candidate A) for profile comparison
des.PPpeak = 1e20; des.PPsig = 0.08;              % P+ boron Gaussian at surface
des.HApeak = 6.5e16; des.HApos = 0.40; des.HAsig = 0.10;
des.HA2peak = 3e15;  des.HA2pos = 1.0;  des.HA2sig = 0.30;
des.Nepi = 2e14; des.Tepi = 8.0;

% constants
q     = 1.602e-19;              % C
epsSi = 11.7 * 8.854e-14;       % F/cm
A_cm2 = A_mm2 * 1e-2;           % cm^2
A_um2 = A_mm2 * 1e6;            % um^2

%% 1. Datasheet data (Toshiba 1SV149, f = 1 MHz, Ta = 25 C) ----------------
Vck = [1 3 5 8];                       % checkpoints [V]
lo  = [435   140.00  55.00  19.9 ];    % pF  (C1V, C8V: spec; C3V, C5V: Table 1 total range)
hi  = [540   249.9   104.12 30.0 ];    % pF
ctr = sqrt(lo .* hi);                  % log-center of each window [pF]
ratioSpecMin = 15.0; ratioTyp = 19.5;

%% 2. Target curves: monotone interpolation in log(C) vs log(V+Vbi) --------
V   = (1:0.05:8)';
lx  = log(Vck + Vbi);  lxq = log(V + Vbi);
Ctar = exp(pchip(lx, log(ctr), lxq));  % pF
Clo  = exp(pchip(lx, log(lo),  lxq));
Chi  = exp(pchip(lx, log(hi),  lxq));

%% 3. SDevice units: c(a,a) [F/um] for quasi-1D width 1 um -> F per um^2 ----
toSim = 1e-12 / A_um2;                 % pF (device) -> F/um^2
CtarSim = Ctar * toSim;  CloSim = Clo * toSim;  ChiSim = Chi * toSim;

%% 4. Target local exponent n(V) -------------------------------------------
nTar = -gradient(log(Ctar), lxq);

%% 5. Target doping profile by C-V profiling --------------------------------
% W = eps*A/C ; N(W) = C^3 / (q*eps*A^2*|dC/dV|)   (one-sided junction)
CF   = Ctar * 1e-12;                   % F
W_um = epsSi * A_cm2 ./ CF * 1e4;      % depletion width [um]
dCdV = gradient(CF, V);
Ntar = CF.^3 ./ (q * epsSi * A_cm2^2 .* abs(dCdV));   % cm^-3

%% 6. Current design: net N-side doping vs depth from metallurgical junction
x   = linspace(0, 8, 80001)';          % um from surface
NA  = des.PPpeak * exp(-x.^2 / (2*des.PPsig^2));
ND  = des.HApeak  * exp(-(x-des.HApos ).^2 / (2*des.HAsig ^2)) ...
    + des.HA2peak * exp(-(x-des.HA2pos).^2 / (2*des.HA2sig^2)) + des.Nepi;
net = ND - NA;
ij  = find(net > 0, 1, 'first');  xj = x(ij);
xN  = x(ij:end) - xj;  NN = net(ij:end);

%% 7. Console summary -------------------------------------------------------
fprintf('Area = %.2f mm^2 ; conversion: pF -> c(a,a) [F/um] multiply by %.1e\n', A_mm2, toSim);
fprintf('\n  V   window [pF]        center [pF]  center c(a,a) [F/um]\n');
for k = 1:4
    fprintf('%3d   %6.1f - %6.1f    %7.1f      %.4e\n', Vck(k), lo(k), hi(k), ctr(k), ctr(k)*toSim);
end
fprintf('\nTarget ratio C1/C8 (centers) = %.2f  (spec >= %.0f, typ %.1f)\n', ctr(1)/ctr(4), ratioSpecMin, ratioTyp);
fprintf('Design metallurgical junction xj = %.3f um\n', xj);
fprintf('\nTarget profile checkpoints:\n   V    W [um]   N [cm^-3]   n_local\n');
for v = [1 2 3 4 5 6 7 8]
    [~, i] = min(abs(V - v));
    fprintf('%4.1f  %6.3f   %.2e    %.2f\n', V(i), W_um(i), Ntar(i), nTar(i));
end

%% 8. Optional: compare a simulated curve --------------------------------
hasSim = ~isempty(simFile) && isfile(simFile);
if hasSim
    M = readmatrix(simFile);
    M = M(all(isfinite(M(:,1:2)), 2), 1:2);
    Vs = abs(M(:,1));  Cs = M(:,2) / toSim;            % V_R [V], pF
    [Vs, iu] = unique(Vs); Cs = Cs(iu);
    sel = Vs >= 1 & Vs <= 8;
    ns = -gradient(log(Cs), log(Vs + Vbi));
    Cs_ck = interp1(Vs, Cs, Vck);
    fprintf('\nSimulation vs target:\n  V   sim [pF]  center [pF]  dev    in window\n');
    for k = 1:4
        fprintf('%3d  %8.1f   %8.1f   %+5.1f%%   %d\n', Vck(k), Cs_ck(k), ctr(k), ...
            100*(Cs_ck(k)/ctr(k)-1), Cs_ck(k) >= lo(k) && Cs_ck(k) <= hi(k));
    end
    Cint = interp1(Vs(sel), Cs(sel), V, 'linear', 'extrap');
    fprintf('RMS log error 1-8 V vs target curve: %.1f %%\n', 100*sqrt(mean(log(Cint./Ctar).^2)));
    fprintf('Sim ratio C1/C8 = %.2f ; max local n (1-8 V) = %.2f (target max %.2f)\n', ...
        Cs_ck(1)/Cs_ck(4), max(ns(sel)), max(nTar));
end

%% 9. Export ---------------------------------------------------------------
T1 = table(V, Ctar, Clo, Chi, CtarSim, CloSim, ChiSim, nTar, ...
    'VariableNames', {'VR_V','Ctarget_pF','Clow_pF','Chigh_pF', ...
    'ctarget_F_per_um','clow_F_per_um','chigh_F_per_um','n_local_target'});
writetable(T1, 'target_cv_1SV149.csv');
T2 = table(V, W_um, Ntar, 'VariableNames', {'VR_V','W_um','Ntarget_cm3'});
writetable(T2, 'target_doping_1SV149.csv');
fprintf('\nSaved: target_cv_1SV149.csv, target_doping_1SV149.csv\n');

%% 10. Figures --------------------------------------------------------------
figure('Name','Target C-V','Color','w');
semilogy(V, Ctar, 'k-', 'LineWidth', 1.6); hold on;
fill([V; flipud(V)], [Clo; flipud(Chi)], [0.11 0.62 0.46], ...
    'FaceAlpha', 0.18, 'EdgeColor', 'none');
errorbar(Vck, ctr, ctr-lo, hi-ctr, 'o', 'Color', [0.11 0.62 0.46], 'LineWidth', 1.2);
if hasSim, semilogy(Vs, Cs, 'b-', 'LineWidth', 1.4); end
grid on; xlim([0.5 8.5]); xlabel('V_R (V)'); ylabel(sprintf('C (pF, A = %.2f mm^2)', A_mm2));
title('1SV149 target C-V (window centers, pchip in log-log)');
if hasSim, legend('target','window band','checkpoint windows','simulation','Location','southwest');
else,      legend('target','window band','checkpoint windows','Location','southwest'); end

figure('Name','Local n','Color','w');
plot(V, nTar, 'k-', 'LineWidth', 1.6); hold on;
if hasSim, plot(Vs(sel), ns(sel), 'b-', 'LineWidth', 1.4); end
yline(0.5, ':', 'abrupt 0.5'); grid on; xlabel('V_R (V)'); ylabel('n = -dlnC / dln(V+V_{bi})');
title('Local C-V exponent');

figure('Name','Doping','Color','w');
semilogy(W_um, Ntar, 'k-', 'LineWidth', 1.8); hold on;
semilogy(xN, NN, 'r--', 'LineWidth', 1.2);
grid on; xlim([0 6]); ylim([1e13 1e18]);
xlabel('Depth from metallurgical junction (um)'); ylabel('N (cm^{-3})');
legend('target N(W) from C-V','current design (net, N side)','Location','northeast');
title('Target doping profile vs current design');
