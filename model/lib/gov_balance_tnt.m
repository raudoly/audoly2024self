function g = gov_balance_tnt(b,tau)
% Get overall government budget for  policy parameters (b,\tau)

load('store/params','par');

K = 4;

p = initialize_inputs(K);

cluster_balance = zeros(K,1);
cluster_share = zeros(K,1);

for k = 1:K 
	p{k} = initialize_inputs_pol(p{k});
    p{k} = initialize_parameters(par,p{k});
    cluster_share(k) = p{k}.N;
    cluster_balance(k) = gov_balance_tnt_cluster(b,tau,p{k});
end

cluster_share = cluster_share/sum(cluster_share);
g = dot(cluster_share,cluster_balance);

function g = gov_balance_tnt_cluster(b,tau,p)
% Returns government budget given policy for worker class

p = initialize_inputs_tnt(p,b,tau);

% Get stationary distributions for this set of policy parameters
[tQ,flag] = solve_ind_dec_tnt(p);

if flag
    error('Individual decision procedure did not converge.');
end

[dG,~,flag] = get_statio_dist(tQ);

if flag
    error('Could not get stationary distributions.');
end

% Implied government budget
dGp = dG(1:p.na*p.nw);
dGs = dG(p.na*p.nw+1:p.na*(p.nw+p.ny));
dGu = dG(p.na*(p.nw+p.ny)+1:p.na*(p.nw+p.ny+1));

repTp = kron(p.govt(p.Yp(p.w)),ones(p.na,1)); 
repTs = kron(p.govt(p.Ys(p.y)),ones(p.na,1));
repTu = kron(p.govt(p.Yu),ones(p.na,1));

g = sum(repTp.*dGp) + sum(repTs.*dGs) + sum(repTu.*dGu);
    
