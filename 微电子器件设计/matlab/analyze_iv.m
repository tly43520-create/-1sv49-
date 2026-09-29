function S = analyze_iv(cases, opts)
% ANALYZE_IV  Reverse I-V check of 1D SDevice exports against the 1SV149 datasheet.
%   S = analyze_iv(cases, opts)
%   cases(k).name, cases(k).iv : csv from svisual_iv_vis.tcl (n<node>_iv.csv),
%                                columns "Anode InnerVoltage" [V], "Anode TotalCurrent" [A/um]
%   opts.outdir, opts.tag ('iv'), opts.A_um2 (junction area, default 1e6 = 1 mm^2)
% Datasheet: I_R <= 50 nA @ V_R = 15 V ; V_R >= 15 V @ I_R = 10 uA.
% Quasi-1D (width 1 um): A/um * 1e6 = A for a 1 mm^2 junction.

if nargin < 2, opts = struct(); end
if ~isfield(opts, 'outdir'), opts.outdir = pwd; end
if ~isfield(opts, 'tag'),    opts.tag = 'iv'; end
if ~isfield(opts, 'A_um2'),  opts.A_um2 = 1e6; end
if ~exist(opts.outdir, 'dir'), mkdir(opts.outdir); end

IRmax = 50e-9; Ibv = 10e-6; VRmax = 15;
fg = figure('Color', 'w'); hold on; box on; grid on;
col = lines(max(numel(cases), 1));
S = struct('name', {}, 'IR15_nA', {}, 'BV10uA_V', {}, 'Vmax', {});
for k = 1:numel(cases)
  M = read_num_csv(cases(k).iv);
  V = abs(M(:,1)); I = abs(M(:,2)) * opts.A_um2;
  [V, iu] = unique(V); I = I(iu);
  I15 = NaN; if V(end) >= VRmax, I15 = exp(interp1(V, log(max(I, 1e-30)), VRmax)); end
  BV = NaN; ib = find(I >= Ibv, 1);
  if ~isempty(ib) && ib > 1
    BV = V(ib-1) + (log(Ibv)-log(I(ib-1)))/(log(I(ib))-log(I(ib-1)))*(V(ib)-V(ib-1));
  end
  S(k).name = cases(k).name; S(k).IR15_nA = I15*1e9; S(k).BV10uA_V = BV; S(k).Vmax = V(end);
  if isnan(BV), bvs = sprintf('> %.1f V (10 uA not reached)', V(end)); else, bvs = sprintf('%.2f V', BV); end
  fprintf('== %s: I_R(15 V) = %.3g nA (spec <= 50, %s); BV(10 uA) %s (spec >= 15, %s); sweep to %.1f V\n', ...
          cases(k).name, S(k).IR15_nA, pf(I15 <= IRmax), bvs, pf(isnan(BV) || BV >= VRmax), V(end));
  semilogy(V, I, '-', 'Color', col(k,:), 'LineWidth', 1.5, 'DisplayName', cases(k).name);
end
xl = get(gca, 'XLim');
plot(xl, [IRmax IRmax], 'r--', 'DisplayName', 'I_R spec 50 nA');
plot(xl, [Ibv Ibv], 'm--', 'DisplayName', 'BV criterion 10 uA');
yl = get(gca, 'YLim'); plot([VRmax VRmax], yl, 'k:', 'DisplayName', 'V_R max 15 V');
set(gca, 'YScale', 'log');
xlabel('V_R (V)'); ylabel(sprintf('|I_R| (A, %.3g mm^2)', opts.A_um2/1e6)); title('Reverse I-V'); legend('show');
print(fg, fullfile(opts.outdir, [opts.tag '_IV.png']), '-dpng', '-r150');

fid = fopen(fullfile(opts.outdir, [opts.tag '_summary.csv']), 'w');
fprintf(fid, 'case,IR15_nA,BV10uA_V,Vmax_V\n');
for k = 1:numel(S), fprintf(fid, '%s,%.4g,%.3f,%.2f\n', S(k).name, S(k).IR15_nA, S(k).BV10uA_V, S(k).Vmax); end
fclose(fid);
end

function M = read_num_csv(fname)
fid = fopen(fname, 'r');
if fid < 0, error('analyze_iv:file', 'cannot open %s', fname); end
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

function s = pf(b)
if b, s = 'PASS'; else, s = 'FAIL'; end
end
