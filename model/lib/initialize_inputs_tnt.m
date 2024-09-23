function p = initialize_inputs_tnt(p,b,tau)
% Tax and transfer policy for all.

% UBI type of policy. Baseline: [tau,b] = 0
p.post = @(x) (1 - tau)*x + b;
p.govt = @(x) -b + tau*x;

p.y = exp(p.elast_lab_sup*log(1 - tau))*p.y;  
% p.w = exp(p.elast_lab_sup*log(1 - tau))*p.w;  % Wage rate is given?

% A more abstract general tax function. NB. I'm not sure about how to
% interpret \tau wrt literature on Frisch elasticity in this case.

% p.post = @(y) b*y.^(1 - tau);
% p.govt = @(y) y - b*y.^(1 - tau);

