function obj = fit_moments(params,p,datmom,W)
% Fit to selected moments.

[pn,flag] = get_panel_all(params,p);
% [pn,flag] = get_panel_all_parallel(params,p);

if flag 
	obj = 1e9;
	return;
end

modmom = calculate_moments(pn,datmom);

mvdat = select_moments(datmom);
mvmod = select_moments(modmom);

obj = (mvmod - mvdat)*W*(mvmod - mvdat)';
