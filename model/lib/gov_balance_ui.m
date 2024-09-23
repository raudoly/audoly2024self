function g = gov_balance_ui(tau,b,pol_type)
% Get overall government budget given policy (\tau,b).

load('store/params','par');

K = 4;    

p = initialize_inputs(K);

cluster_balance = zeros(K,1);
cluster_share = zeros(K,1);

for k = 1:K 
	p{k} = initialize_inputs_pol(p{k});
    p{k} = initialize_parameters(par,p{k});
    cluster_share(k) = p{k}.N;
    cluster_balance(k) = gov_balance_ui_cluster(tau,b,pol_type,p{k});
end

cluster_share = cluster_share/sum(cluster_share);
g = dot(cluster_share,cluster_balance);

