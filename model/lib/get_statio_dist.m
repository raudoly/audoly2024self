function [dG,tQ,flag] =  get_statio_dist(tQ)
%  Get stationary distribution of workers.

% Renormalize transition matrix (to for correct small numerical
% error). Loop not to run into memory problems on cluster.
 
ns = size(tQ,1);

for k = 1:ns
    tQ(:,k) = tQ(:,k)/sum(tQ(:,k));
end

% Iterate on LOM to get stationary distribution 
dG0 = ones(ns,1)/ns;  

iter = 0;
crit = 1.0;
iterMax = 30000;

while crit>1e-8 && iter<iterMax
    iter = iter + 1;
    dG = tQ*dG0;
    crit = max(abs(dG - dG0));
    dG0 = dG;
end

% Checks
flag = iter==iterMax;

dG = dG/sum(dG); % Renormalize to deal with small numerical error

