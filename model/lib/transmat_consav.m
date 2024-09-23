function Qa = transmat_consav(R,U,beta,p,ny)
    % Transition matrix at consumption-saving stage.
    
% Optimal choice of assets
Rres = reshape(R,p.na,ny);
Ritp = interp1(p.a,Rres,p.a2); % 'linear' interpolation implicitly
Rrep = kron(Ritp',ones(p.na,1));
[~,a2_i] = max(U + beta*Rrep,[],2);
a2_pol = p.a2(a2_i);

% Find indices below and above on original grid
ai_itp_bel = griddedInterpolant(p.a,1:p.na,'previous');
ai_itp_abv = griddedInterpolant(p.a,1:p.na,'next');

ai_bel = zeros(p.na*ny,1);
ai_abv = zeros(p.na*ny,1);

for k = 1:p.na*ny
    ai_bel(k) = ai_itp_bel(a2_pol(k));
    ai_abv(k) = ai_itp_abv(a2_pol(k));
end

% Weights to split mass on original grid
a_bel = p.a(ai_bel);
a_abv = p.a(ai_abv);

wgt_bel = (a_abv - a2_pol)./(a_abv - a_bel); 
wgt_abv = (a2_pol - a_bel)./(a_abv - a_bel);

% Choice exactly at a node: put all 
% mass on node below 
wgt_bel(ai_bel==ai_abv) = 1.0; 
wgt_abv(ai_bel==ai_abv) = 0.0;

% Sparse transition matrix
yidx = p.na*kron(transpose(0:ny-1),ones(p.na,1));  
Qa = sparse(1:p.na*ny,yidx+ai_bel,wgt_bel,p.na*ny,p.na*ny) ...
    + sparse(1:p.na*ny,yidx+ai_abv,wgt_abv,p.na*ny,p.na*ny); 
    
    