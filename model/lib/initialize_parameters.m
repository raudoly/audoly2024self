function p = initialize_parameters(par,p)
% Initialize all inputs that depend on calibration parameters. 

% transition parameters
p.lamb_up = par(1);
p.lamb_us = par(2);
p.lamb_sp = par(3);
p.lamb_ps = par(4);
p.delt_p  = par(4+p.k);
p.delt_s  = par(8+p.k);

% Income distributions in class k

% Paid-employment income
m_w = par(12+p.k); 
s_w = par(17); 
rho_w = par(18);

[p.lnw,p.dQw] = tauchen(p.nw,m_w,rho_w,s_w,4);
p.w = exp(p.lnw); 

p.dFw = null(transpose(p.dQw) - eye(p.nw));
p.dFw = p.dFw/sum(p.dFw);

% Self-employment income 
m_y = par(18+p.k);
s_y = par(23);
rho_y = par(24);

[p.lny,p.dQy] = tauchen(p.ny,m_y,rho_y,s_y,4);
p.y = exp(p.lny); 

p.dFy = null(transpose(p.dQy) - eye(p.ny));
p.dFy = p.dFy/sum(p.dFy);

% Discount factor (r<\rho by assumption)
rho_year = par(25);
rho_month = (1 + rho_year)^(1/12) - 1;

p.beta = 1/(1 + rho_month);

% Non-pecuniary benefits of self-employment \kappa>0 as a premium
% on consumption.
p.kappa = par(26);

