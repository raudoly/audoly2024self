function [pn_all,flag] = get_panel_all(par,p)

K = 4;
pn = cell(K,1);

% Solve and simulate panel for each class
for k = 1:K
	p{k} = initialize_parameters(par,p{k});
	[tQ,flag] = solve_ind_dec(p{k});
	if flag
		break;
	end
	[pn{k},flag] = simulate_panel(tQ,p{k});
    if flag 
		break;
    end
end


if flag
    pn_all = struct;
    return;
end

% Stack all panels for different clusters
pn_all = stack_panels(pn);
