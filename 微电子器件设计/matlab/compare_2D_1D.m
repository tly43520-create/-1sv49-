%% compare_2D_1D.m
% Bring 2D SDevice C-V results into MATLAB and compare them with the 1D result.
%   (1) normalize the 2D c(a,a) [F/um] by the window width -> per-um^2 value
%   (2) compare with the quasi-1D result (same vertical doping) -> edge contribution
%   (3) optional: with a second 2D run (different window width), separate
%       area capacitance Ca [F/um^2] and edge capacitance Ce [F/um per edge]
%       and project to a real square die of area A_mm2
% Input files: CSV exported by svisual_vis.tcl (column 1 = v(a), column 2 = c(a,a))

clear; clc; close all;

%% 0. Settings --------------------------------------------------------------
file1D   = 'n_1D_cv.csv';     % quasi-1D run with the SAME vertical doping (e.g. iter00 baseline)
file2D_1 = 'n_2D20_cv.csv';   % 2D run, window width W1
W1       = 20;                % window (anode) width of run 1 [um]
file2D_2 = '';                % optional 2D run with a different window, e.g. 'n_2D40_cv.csv'
W2       = 40;                % window width of run 2 [um]
A_mm2    = 1.0;               % real junction area for projection [mm^2] (square die)

A_um2 = A_mm2 * 1e6;          % um^2
P_um  = 4 * sqrt(A_um2);      % perimeter of a square die [um]
Vck   = [1 3 5 8];
lo    = [435 140.00 55.00 19.9];  hi = [540 249.9 104.12 30.0];   % 1SV149 windows [pF]
Vq    = (0:0.1:15)';           % common voltage grid (V_R)

%% 1. Read data ------------------------------------------------------------
[V1, c1]  = readCV(file1D);          % c in F/um (1D: width 1 um -> F/um^2)
[Va, ca_] = readCV(file2D_1);        % F/um for a W1-wide window
c1D  = interp1(V1, c1,  Vq, 'linear', NaN);           % F/um^2
c2Da = interp1(Va, ca_, Vq, 'linear', NaN);           % F/um (whole 2D device)

%% 2. Normalize 2D by window width and compare with 1D ---------------------
c2Dn  = c2Da / W1;                                    % F/um^2 (includes edge)
edgeF = 1 - c1D ./ c2Dn;                              % share of 2D C not explained by the planar area

pF = @(c_perum2) c_perum2 * A_um2 * 1e12;             % per-um^2 -> pF for A_mm2
fprintf('Run 1: window %g um. Values scaled to %.2f mm^2 by planar area only:\n', W1, A_mm2);
fprintf('  V    1D [pF]   2D/W [pF]   2D/1D-1   edge share\n');
for v = Vck
    i = find(abs(Vq - v) < 1e-9);
    fprintf('%3d  %8.1f  %9.1f   %+6.1f%%    %5.1f%%\n', v, pF(c1D(i)), pF(c2Dn(i)), ...
        100*(c2Dn(i)/c1D(i) - 1), 100*edgeF(i));
end
r1 = c1D(Vq==1)/c1D(Vq==8);  r2 = c2Dn(Vq==1)/c2Dn(Vq==8);
fprintf('Ratio C1/C8:  1D = %.2f   2D(W=%g) = %.2f\n', r1, W1, r2);

%% 3. Optional: area / edge separation with two window widths -------------
hasTwo = ~isempty(file2D_2) && isfile(file2D_2);
if hasTwo
    [Vb, cb_] = readCV(file2D_2);
    c2Db = interp1(Vb, cb_, Vq, 'linear', NaN);        % F/um, W2-wide window
    Ca = (c2Db - c2Da) / (W2 - W1);                    % F/um^2   (area term)
    Ce = (c2Da - W1 * Ca) / 2;                         % F/um per edge (two edges in 2D)
    Creal = Ca * A_um2 + Ce * P_um;                    % F, square die, 2D edge approximation

    fprintf('\nArea/edge separation (W1 = %g, W2 = %g um):\n', W1, W2);
    fprintf('  V   Ca vs 1D   Ce [F/um]    real die [pF]  edge share  window\n');
    for k = 1:4
        i = find(abs(Vq - Vck(k)) < 1e-9);
        C_pF = Creal(i) * 1e12;
        fprintf('%3d   %+6.2f%%   %.3e    %8.1f       %5.2f%%     %d\n', Vck(k), ...
            100*(Ca(i)/c1D(i) - 1), Ce(i), C_pF, 100*Ce(i)*P_um/Creal(i), ...
            C_pF >= lo(k) && C_pF <= hi(k));
    end
    fprintf('Projected real-die ratio C1/C8 = %.2f\n', Creal(Vq==1)/Creal(Vq==8));
    fprintf('(Ca vs 1D should be within ~1%%: this validates the 2D model)\n');
end

%% 4. Export ---------------------------------------------------------------
T = table(Vq, pF(c1D), pF(c2Dn), edgeF, ...
    'VariableNames', {'VR_V','C1D_pF','C2D_norm_pF','edge_share'});
if hasTwo
    T.Ca_vs_1D   = Ca ./ c1D - 1;
    T.Ce_F_per_um = Ce;
    T.Creal_pF   = Creal * 1e12;
end
writetable(T, 'compare_2D_1D.csv');
fprintf('\nSaved: compare_2D_1D.csv\n');

%% 5. Figures ---------------------------------------------------------------
figure('Color','w','Name','C-V 1D vs 2D');
semilogy(Vq, pF(c1D), 'k-', 'LineWidth', 1.6); hold on;
semilogy(Vq, pF(c2Dn), 'b--', 'LineWidth', 1.4);
leg = {'1D','2D / window width'};
if hasTwo
    semilogy(Vq, Creal*1e12, 'r-', 'LineWidth', 1.4); leg{end+1} = 'projected real die';
end
errorbar(Vck, sqrt(lo.*hi), sqrt(lo.*hi)-lo, hi-sqrt(lo.*hi), 'o', 'Color', [0.11 0.62 0.46]);
leg{end+1} = '1SV149 windows';
grid on; xlim([0 15]); xlabel('V_R (V)'); ylabel(sprintf('C (pF, %.2f mm^2)', A_mm2));
legend(leg, 'Location', 'southwest'); title('Quasi-1D vs 2D C-V');

figure('Color','w','Name','Edge share');
plot(Vq, 100*edgeF, 'b-', 'LineWidth', 1.4); grid on;
xlabel('V_R (V)'); ylabel('edge share of 2D capacitance (%)');
title(sprintf('Edge contribution in the %g-um-window 2D structure', W1));

%% local function -----------------------------------------------------------
function [VR, c] = readCV(fname)
    if ~isfile(fname), error('File not found: %s', fname); end
    M = readmatrix(fname);
    M = M(all(isfinite(M(:,1:2)), 2), 1:2);
    VR = abs(M(:,1)); c = M(:,2);
    [VR, iu] = unique(VR); c = c(iu);
end
