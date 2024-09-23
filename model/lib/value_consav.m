function V = value_consav(R,U,beta,p,ny)
% Saving/borrowing decision at 
% consumption-savings stage.
    
% Replicate continuation value
Rres = reshape(R,p.na,ny);
Ritp = interp1(p.a,Rres,p.a2);          % 'linear' interpolation implicitly
Rrep = kron(Ritp',ones(p.na,1));

% Maximize over next period asset choices
V = max(U + beta*Rrep,[],2);