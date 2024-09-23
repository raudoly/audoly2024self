function g = gov_balance_ui_cluster(tau,b,pol_type,p)
% Returns government budget given policy (\tau,b) and parameters p.

% Get stationary distributions for this set of policy parameters
p = initialize_inputs_ui(p,tau,b,pol_type);

[tQ,flag] = solve_ind_dec_ui(p);

if flag
    error('Individual decision procedure did not converge.');
end

[dG,~,flag] = get_statio_dist(tQ);

if flag
    error('Could not get stationary distributions.');
end

% Compute implied government budget
dGs = dG(p.na*p.nw+1:p.na*(p.nw+p.ny));
dGc = dG(p.na*(p.nw+p.ny+1+p.nw)+1:p.na*(p.nw+p.ny+1+p.nw+p.ny));

yrep = kron(p.y,ones(p.na,1));

inc = sum(p.govt(yrep).*dGs);
xpd = sum(p.b_s(yrep).*dGc);

g = inc - xpd;
