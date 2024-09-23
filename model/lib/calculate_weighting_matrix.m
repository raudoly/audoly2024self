function W = calculate_weighting_matrix(dat_dir)
% Weighting matrix for fitting moments.

% Bootstrap replications from Stata
file_name = 'bootstrap_reps.csv';

if nargin<1
    moment_bootstraps = readtable(['dat' filesep file_name]);
else
	moment_bootstraps = readtable([dat_dir filesep file_name]);
end

D = select_moments(moment_bootstraps);

% Weighting matrix: inverse of VCV
% C = cov(D);
% W = inv(C);

% Weighting matrix: inverse of variance
S = var(D,1);
W = diag(S.^(-1));

