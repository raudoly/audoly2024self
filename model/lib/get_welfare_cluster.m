function get_welfare_cluster(save_it)
% Find pair of policy parameter maximizing
% utilitarian welfare in each educ/ability
% group.
% 
% NB: 'align' case is hardcoded for now.

% Preallocate table for results
K = 4;
Cluster = (1:K)';
tauStar = zeros(K,1);
bStar = zeros(K,1);

res = table(Cluster,tauStar,bStar);

% Loop over worker cluster groups
load('store/params','par');
s = initialize_inputs(K);

for k = 1:K
    
    fprintf('\n\nStarting worker group %d:\n',k); 

    s{k} = initialize_inputs_pol(s{k});
    p = initialize_parameters(par,s{k});
    
    % Find optimal (\tau,b) in cluster
    obj = @(x) welfare_max_obj(x,p,s{k});
    b = fminbnd(obj,0.0,1.0,optimset('Display','iter'));
    tau = find_tau(b,p,s{k});
    
    res.tauStar(res.Cluster==k) = tau;
    res.bStar(res.Cluster==k) = b;
    
end
    
disp(r);

if save_it
    wsName = 'optimal_ui_cluster';
    wbName = '../tables/_tables_pol.xlsx';
    writetable(res,wbName,'Sheet',wsName);
end

%--------------------------------------------------------------------------

function obj = welfare_max_obj(b,p,s)
% Utilitarian welfare for 
% a given replacement rate

tau = find_tau(b,p,s);

obj = welfare_cluster(tau,b,'align',p,s);
obj = -obj; % Minimization


function tau = find_tau(b,p,s)
% Tax rate balancing budget

govbudget = @(x) gov_balance_cluster(x,b,'align',p,s);
tau = fzero(govbudget,[.0 .5]); % wide bracket to be on the safe side


function Omega = welfare_cluster(tau,b,polType,p,s)
% Compute welfare in this cluster 

% Get stationary distributions for this set of policy parameters
s = initialize_inputs_ui(s,tau,b,polType);

[tQ,flag,eq] = solve_ind_dec_ui(p,s);

if flag
    error('Individual decision procedure did not converge.');
end

[dG,~,flag] = get_statio_dist(tQ);

if flag
    error('Could not get stationary distributions.');
end

% Utilitarian welfare criterium
dGp = dG(1:s.na*s.nw);
dGs = dG(s.na*s.nw+1:s.na*(s.nw+s.ny));
dGb = dG(s.na*(s.nw+s.ny)+1:s.na*(s.nw+s.ny+s.nw));
dGu = dG(s.na*(s.nw+s.ny+s.nw)+1:s.na*(s.nw+s.ny+s.nw+1));
dGc = dG(s.na*(s.nw+s.ny+s.nw+1)+1:s.na*(s.nw+s.ny+s.nw+1+s.ny));

Omega = ... 
    sum(eq.Vp.*dGp) + ...
    sum(eq.Vs.*dGs) + ...
    sum(eq.Vb.*dGb) + ...
    sum(eq.Vu.*dGu) + ...
    sum(eq.Vc.*dGc);


function budget = gov_balance_cluster(tau,b,polType,p,s)
% Returns government budget given policy.
% (\tau,b) for cluster implied by p and s.

% Get stationary distributions for this set of policy parameters
s = initialize_inputs_ui(s,tau,b,polType);

[tQ,flag] = solve_ind_dec_ui(p,s);

if flag
    error('Individual decision procedure did not converge.');
end

[dG,~,flag] = get_statio_dist(tQ);

if flag
    error('Could not get stationary distributions.');
end

% Compute implied government budget
dGs = dG(s.na*s.nw+1:s.na*(s.nw+s.ny));
dGc = dG(s.na*(s.nw+s.ny+1+s.nw)+1:s.na*(s.nw+s.ny+1+s.nw+s.ny));

yrep = kron(p.y,ones(s.na,1));
res = tau*sum(yrep.*dGs);
xpd = sum(s.c(yrep).*dGc);

budget = res - xpd;


