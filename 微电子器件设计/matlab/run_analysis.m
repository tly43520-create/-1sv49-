%% run_analysis.m -- driver for analyze_cv / analyze_iv
% Edit the case lists below, then run this script from anywhere.
% File naming convention (results/iterNN/): <case>_cv.csv, <case>_dop.csv, <case>_iv.csv
clear; close all;
here = fileparts(mfilename('fullpath'));
res  = fullfile(here, '..', 'results');

%% C-V: iter02 final candidates vs iter01
cv = struct('name', {'iter02-R', 'iter02-3G', 'iter01'}, ...
            'cv',   {fullfile(res, 'iter02', 'iter02-R_cv.csv'), ...
                     fullfile(res, 'iter02', 'iter02-3G_cv.csv'), ...
                     fullfile(res, 'iter01', 'iter01_cv.csv')}, ...
            'dop',  {'', '', ''});                  % add <case>_dop.csv paths once exported
S = analyze_cv(cv, struct('outdir', fullfile(res, 'iter02'), 'tag', 'iter02_cv'));

%% I-V (uncomment once n<node>_iv.csv is copied into results/iter03/)
% iv = struct('name', {'iter02-R'}, 'iv', {fullfile(res, 'iter03', 'iter02-R_iv.csv')});
% T = analyze_iv(iv, struct('outdir', fullfile(res, 'iter03'), 'tag', 'iter03_iv'));
