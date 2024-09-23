function p = initialize_inputs_ui(p,tau,b,pol_type)
% UI policy for self-employed.

p.T_s = 6;                          % Potential duration                                   
p.b_s = @(y) min(b*y,p.b_max);      % UI monthly payment with cap.

switch pol_type
    case 'align'
        p.govt = @(y) tau*min(y,7000/12);
        p.post = @(y) y - tau*min(y,7000/12);
    case 'progressive'
        p.govt = @(y) tau*y;                 
        p.post = @(y) y - tau*y;
        p.y = exp(p.elast_lab_sup*log(1 - tau))*p.y;          
end

% Elasticity is loosely based on Josef's comments on the rest of the
% literature: a range of .3-.4 seems reasonable. So .5 is upper bound?
