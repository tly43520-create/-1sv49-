function S = analyze_cv(cases, opts)
% ANALYZE_CV  Full-curve analysis of 1D SDevice C-V exports for the 1SV149 design.
%   S = analyze_cv(cases, opts)
%   cases(k).name : label used in legends and the summary
%   cases(k).cv   : C-V csv, columns v(a) [V], c(a,a) [F/um] (+ optional a(a,a) [S/um]).
%                   One header line; the v3 svisual script or a manual SVisual export both work.
%   cases(k).dop  : optional doping csv, columns Y [um], DopingConcentration [cm^-3] ('' = none)
%   opts.outdir   : folder for figures + summary csv (default: pwd)
%   opts.tag      : file-name prefix (default 'cv')
% Per case: checkpoint C and margin (CLAUDE.md §2), C1/C8, rms vs target curve, local n(V),
% C-V profiled N(W) (+ real doping overlay), epi plateau, punch-through onset, Q(V) if a(a,a).
% Works in MATLAB (R2016b+) and GNU Octave. Mirrors tools/analyze_cv.py.

if nargin < 2, opts = struct(); end
if ~isfield(opts, 'outdir'), opts.outdir = pwd; end
if ~isfield(opts, 'tag'),    opts.tag = 'cv'; end
if ~exist(opts.outdir, 'dir'), mkdir(opts.outdir); end

% ---- constants and datasheet windows (pF @ 1 mm^2, f = 1 MHz)
q = 1.602e-19; epsSi = 11.7*8.854e-14; Vbi = 0.8; f = 1e6;
Vck = [1 3 5 8]; lo = [435 140 55 19.9]; hi = [540 249.9 104.12 30.0];
Vt = (1:0.05:8)';
Ct = exp(pchip(log(Vck+Vbi), log(sqrt(lo.*hi)), log(Vt+Vbi)));      % target curve (as target_cv_1SV149.m)
[Wt, Nt] = profile_cv(Vt, Ct);

nc = numel(cases);
col = lines(max(nc, 1));
S = struct('name', {}, 'C', {}, 'ratio', {}, 'margin', {}, 'rms', {}, 'nmax', {}, 'Vnmax', {}, ...
           'Nplateau', {}, 'Vpt', {}, 'Q1V', {});
figs = zeros(1, 5);
for k = 1:5, figs(k) = figure('Color', 'w'); hold on; box on; grid on; end

for k = 1:nc
  M = read_num_csv(cases(k).cv);
  V = -M(:,1); C = M(:,2)*1e18;                   % V_R [V], pF @ 1 mm^2
  [V, iu] = unique(V); C = C(iu);
  G = []; if size(M,2) >= 3, G = abs(M(iu,3)); end

  Cck = interp1(V, C, Vck);
  mg  = min(log(Cck./lo), log(hi./Cck)) ./ log(hi./lo);
  Cv8 = interp1(V, C, Vt);
  rmsT = sqrt(mean(log(Cv8./Ct).^2));
  n = -gradient(log(C), log(V+Vbi));
  in18 = V >= 1 & V <= 8;
  [nmax, im] = max(n(in18)); V18 = V(in18);
  [W, N] = profile_cv(V, C);
  k1 = find(V > 1);
  [Nmin, imin] = min(N(k1));
  ipt = find(V > V(k1(imin)) & N > 3*Nmin, 1);
  Vpt = NaN; if ~isempty(ipt), Vpt = V(ipt); end
  Q = []; Q1 = NaN;
  if ~isempty(G), Q = 2*pi*f*C*1e-18 ./ G; Q1 = interp1(V, Q, 1); end

  S(k).name = cases(k).name; S(k).C = Cck; S(k).ratio = Cck(1)/Cck(4); S(k).margin = min(mg);
  S(k).rms = rmsT; S(k).nmax = nmax; S(k).Vnmax = V18(im); S(k).Nplateau = Nmin; S(k).Vpt = Vpt;
  S(k).Q1V = Q1;

  fprintf('== %s\n', cases(k).name);
  fprintf('   C1/3/5/8 = %.1f / %.1f / %.2f / %.2f pF  C1/C8 %.2f  margin %+.3f (%s)\n', Cck, ...
          S(k).ratio, S(k).margin, strjoin(arrayfun(@(m) ok(m), mg, 'UniformOutput', false), ' '));
  fprintf('   rms vs target %.1f%%  n_max %.2f @ %.1f V  plateau %.2e  punch-through %.1f V  Q(1V) %.0f\n', ...
          100*rmsT, nmax, S(k).Vnmax, Nmin, Vpt, Q1);

  c = col(k,:);
  figure(figs(1)); semilogy(V, C, '-', 'Color', c, 'LineWidth', 1.5, 'DisplayName', cases(k).name);
  figure(figs(2)); plot(Vt, 100*(Cv8./Ct-1), '-', 'Color', c, 'LineWidth', 1.5, 'DisplayName', cases(k).name);
  figure(figs(3)); plot(V, n, '-', 'Color', c, 'LineWidth', 1.5, 'DisplayName', cases(k).name);
  figure(figs(4)); semilogy(W, N, '-', 'Color', c, 'LineWidth', 1.5, 'DisplayName', [cases(k).name ' C-V profiled']);
  if isfield(cases, 'dop') && ~isempty(cases(k).dop)
    D = read_num_csv(cases(k).dop);
    [y, iy] = unique(D(:,1)); Nd = D(iy,2);
    ij = find(Nd(1:end-1) < 0 & Nd(2:end) >= 0, 1);        % P+ -> N metallurgical junction
    if ~isempty(ij)
      xj = y(ij) - Nd(ij)*(y(ij+1)-y(ij))/(Nd(ij+1)-Nd(ij));
      m = y > xj;
      semilogy(y(m)-xj, Nd(m), '--', 'Color', c, 'LineWidth', 1, 'DisplayName', ...
               sprintf('%s doping (x_j = %.3f um)', cases(k).name, xj));
    end
  end
  if ~isempty(Q)
    figure(figs(5)); plot(V, Q, '-', 'Color', c, 'LineWidth', 1.5, 'DisplayName', cases(k).name);
  end
end

% ---- decorate
figure(figs(1));
semilogy(Vt, Ct, 'k:', 'LineWidth', 1.2, 'DisplayName', 'target (log-centre)');
for i = 1:4
  plot([Vck(i) Vck(i)], [lo(i) hi(i)], 'k-', 'LineWidth', 3, 'HandleVisibility', 'off');
end
set(gca, 'YScale', 'log'); xlim([0 15]);
xlabel('V_R (V)'); ylabel('C (pF @ 1 mm^2)'); title('C-V, 1 MHz (bars = datasheet windows)'); legend('show');
figure(figs(2)); plot([1 8], [0 0], 'k-', 'HandleVisibility', 'off');
xlabel('V_R (V)'); ylabel('C / C_{target} - 1 (%)'); title('Deviation from target curve'); legend('show');
figure(figs(3)); plot(Vt, -gradient(log(Ct), log(Vt+Vbi)), 'k:', 'LineWidth', 1.2, 'DisplayName', 'target');
xlim([0 15]); xlabel('V_R (V)'); ylabel('n = -dlnC/dln(V+V_{bi})'); title('Local exponent n'); legend('show');
figure(figs(4)); semilogy(Wt, Nt, 'k:', 'LineWidth', 1.2, 'DisplayName', 'target N(W)');
set(gca, 'YScale', 'log'); xlim([0 7]); ylim([1e13 1e18]);
xlabel('W or depth from x_j (um)'); ylabel('N (cm^{-3})'); title('C-V profiled N(W) vs doping'); legend('show');
figure(figs(5));
if any(~isnan([S.Q1V]))
  plot([0 15], [200 200], 'r--', 'DisplayName', 'spec Q >= 200 @ 1 V');
  xlabel('V_R (V)'); ylabel('Q = \omega C / G'); title('Q at 1 MHz'); legend('show');
else
  close(figs(5)); figs(5) = 0;
end

names = {'cv', 'dev', 'n', 'NW', 'Q'};
for i = 1:5
  if figs(i), print(figs(i), fullfile(opts.outdir, sprintf('%s_%s.png', opts.tag, names{i})), '-dpng', '-r150'); end
end

% ---- summary csv
fid = fopen(fullfile(opts.outdir, [opts.tag '_summary.csv']), 'w');
fprintf(fid, 'case,C1V_pF,C3V_pF,C5V_pF,C8V_pF,Ratio18,margin,rms_vs_target,n_max,V_nmax,N_plateau,V_punchthrough,Q1V\n');
for k = 1:numel(S)
  fprintf(fid, '%s,%.2f,%.2f,%.3f,%.3f,%.3f,%.4f,%.4f,%.3f,%.2f,%.3e,%.2f,%.1f\n', S(k).name, S(k).C, ...
          S(k).ratio, S(k).margin, S(k).rms, S(k).nmax, S(k).Vnmax, S(k).Nplateau, S(k).Vpt, S(k).Q1V);
end
fclose(fid);
fprintf('Figures + %s_summary.csv written to %s\n', opts.tag, opts.outdir);
end

% ------------------------------------------------------------------------
function [W, N] = profile_cv(V, C)
% depletion width [um] and C-V profiled doping [cm^-3], C in pF @ 1 mm^2
q = 1.602e-19; epsSi = 11.7*8.854e-14;
Cf = C*1e-10;                                    % F/cm^2
W = epsSi ./ Cf * 1e4;
N = Cf.^3 ./ (q*epsSi*abs(gradient(Cf, V)));
end

function M = read_num_csv(fname)
% numeric csv with exactly one header line of any content (BOM, spaces, quotes are fine)
fid = fopen(fname, 'r');
if fid < 0, error('analyze_cv:file', 'cannot open %s', fname); end
fgetl(fid);
M = [];
while true
  s = fgetl(fid);
  if ~ischar(s), break; end
  v = sscanf(strrep(s, ',', ' '), '%f')';
  if ~isempty(v), M(end+1, 1:numel(v)) = v; end %#ok<AGROW>
end
fclose(fid);
end

function s = ok(m)
if m > 0, s = 'OK'; else, s = 'X'; end
end
