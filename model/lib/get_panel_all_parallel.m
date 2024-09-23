function [pn_all,flag] = get_panel_all_parallel(par,p)

K = 4;

% NB. Number of clusters is hardcoded,  but could be easily fixed
% retrieving number of individuals simulated in  panel, p{k}.N

flag_sol = false(K,1);
flag_sim = false(K,1);

pn = cell(K,1);
pn_all = struct;

% Solve and simulate panel for each class
parfor k = 1:K
	p{k} = initialize_parameters(par,p{k});
	[tQ,flag_sol(k)] = solve_ind_dec(p{k});
	[pn{k},flag_sim(k)] = simulate_panel(tQ,p{k});
end

flag = any(flag_sol) || any(flag_sim);

if flag
	return;
end

% Stack all panels for different clusters
pn_all = stack_panels(pn);
	
