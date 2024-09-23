function mu = value_draw(Vopt,Vref,dFrep,nopt,nref,na)
% Value from drawing from dF,
% given current labor market
% state value Vref.

% Replicate value of option 
Vopt_rsp = reshape(Vopt,na,nopt);
Vopt_rep = repmat(Vopt_rsp,nref,1);

% Replicate reference value
Vref_rep = repmat(Vref,1,nopt);

% Expected value of a draw
mu = sum((Vopt_rep>Vref_rep).*(Vopt_rep - Vref_rep).*dFrep,2);
