function g = gov_balance_bsl
% Get government balance in baseline economy, ie, expenditures on UI.

load('store/params','par');

K = 4;    
p = initialize_inputs(K);

cl_bal = zeros(K,1);
cl_wgt = zeros(K,1);

for k = 1:K 
	p{k} = initialize_inputs_pol(p{k});
    p{k} = initialize_parameters(par,p{k});
    cl_wgt(k) = p{k}.N;
    cl_bal(k) = gov_balance_cluster(p{k});
end

cl_wgt = cl_wgt/sum(cl_wgt);

g = dot(cl_wgt,cl_bal);

function g = gov_balance_cluster(p)
% Within worker class.

% Get stationary distributions. 
[tQ,flag] = solve_ind_dec(p);

if flag
    error('Individual decision procedure did not converge.');
end

[dG,~,flag] = get_statio_dist(tQ);

if flag
    error('Could not get stationary distributions.');
end

% NB. Error checking shouldn't be needed?

% Implied government expenditures
dGb = dG(p.na*(p.nw+p.ny)+1:p.na*(p.nw+p.ny+p.nw));
wrep = kron(p.w,ones(p.na,1)); 
g = -sum(p.b_p(wrep).*dGb);


