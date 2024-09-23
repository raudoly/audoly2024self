function [tQ,flag,q] = solve_ind_dec(p)
% Solve for individual decisions using VFI. Baseline model: UI
% benefits are only paid-out after PU transitions (s = B)


%%% Preallocate arrays.

% grid sizes
nw = p.nw;
ny = p.ny;
na = p.na;

na2 = p.na2; % size of interpolation grid for asset choice
nay = na*ny;
naw = na*nw;

% replicate earnings draw distributions
dFw_ay = repmat(p.dFw',nay,1);
dFw_aw = repmat(p.dFw',naw,1);
dFy_aw = repmat(p.dFy',naw,1);
dFw_a = repmat(p.dFw',na,1);
dFy_a = repmat(p.dFy',na,1);

% replicate income transition matrices
dQw = kron(p.dQw,speye(na));
dQy = kron(p.dQy,speye(na));

% unemployment benefits array
b = p.b_p(p.w);

% household income array
Yu = p.Yu;
Yp = p.Yp(p.w);
Ys = p.Ys(p.y);

% allocate utility arrays
Up = kron(Yp,ones(na,na2));
Up = Up + (1 + p.r)*repmat(p.a,nw,na2) - repmat(p.a2',naw,1);
Up = p.u(Up);

Us = kron(Ys,ones(na,na2));
Us = Us + (1 + p.r)*repmat(p.a,ny,na2) - repmat(p.a2',nay,1);
Us = p.u(Us + p.kappa); % self-employment gives non-pecuniary boost

Ub = Yu + kron(b,ones(na,na2));
Ub = Ub + (1 + p.r)*repmat(p.a,nw,na2) - repmat(p.a2',naw,1);
Ub = p.u(Ub);

Uu = Yu + (1 + p.r)*repmat(p.a,1,na2) - repmat(p.a2',na,1);
Uu = p.u(Uu);


%%% Solve iterating on VFs.

% initial value functions - start from present value of hand-to-mouth
Vp_upd = max(p.r*kron(ones(nw,1),p.a),0) + kron(Yp,ones(na,1));
Vp_upd = p.u(Vp_upd)/(1 - p.beta);

Vs_upd = max(p.r*kron(ones(ny,1),p.a),0) + kron(Ys,ones(na,1));
Vs_upd = p.u(Vs_upd + p.kappa)/(1 - p.beta);

Vb_upd = max(p.r*kron(ones(nw,1),p.a),0) + Yu + kron(b,ones(na,1));
Vb_upd = p.u(Vb_upd)/(1 - p.beta);

Vu_upd = max(p.r*p.a,0) + Yu;
Vu_upd = p.u(Vu_upd)/(1 - p.beta);

iter = 0; 
crit = 1.0; 
itermax = 10000;

while iter<itermax && crit>1e-8

	iter = iter + 1;
    
	% update value functions
    Vp = Vp_upd;
	Vs = Vs_upd;
    Vb = Vb_upd;
    Vu = Vu_upd;
    
    % unemployed, no benefits (expired or quits of formerly self-employed)
    mu_s_u = value_draw(Vs,Vu,dFy_a,ny,1,na);
	mu_p_u = value_draw(Vp,Vu,dFw_a,nw,1,na);
    Ru = Vu + p.lamb_up*mu_p_u + p.lamb_us*mu_s_u;
    Vu_upd  = value_consav(Ru,Uu,p.beta,p,1);
    
    % unemployed with benefits (destruction for paid-employed)
    mu_p_b = value_draw(Vp,Vb,dFw_aw,nw,nw,na);
    mu_s_b = value_draw(Vs,Vb,dFy_aw,ny,nw,na);
    Rb = Vb + p.lamb_up*mu_p_b + p.lamb_us*mu_s_b;
    Ru_rep_w = repmat(Ru,nw,1);
    Rb = (1 - 1/p.T_p)*Rb + (1/p.T_p)*Ru_rep_w;
    Vb_upd = value_consav(Rb,Ub,p.beta,p,nw);
       
    % paid-employed
	opt_s_p = value_draw(Vs,Vp,dFy_aw,ny,nw,na); 
    Vu_rep_w = repmat(Vu,nw,1); 
    Rp = max(Vu_rep_w,p.delt_p*Vb + (1 - p.delt_p)*(Vp + p.lamb_ps*opt_s_p));
    Rp = dQw*Rp;
    Vp_upd = value_consav(Rp,Up,p.beta,p,nw);
    
    % self-employed
    opt_p_s = value_draw(Vp,Vs,dFw_ay,nw,ny,na);
    Vu_rep_y = repmat(Vu,ny,1);
	Rs = max(Vu_rep_y,p.delt_s*Vu_rep_y + (1 - p.delt_s)*(Vs + p.lamb_sp*opt_p_s));
    Rs = dQy*Rs;
	Vs_upd = value_consav(Rs,Us,p.beta,p,ny);
        
    % convergence
	crit = max(abs([Vp - Vp_upd;Vs - Vs_upd;Vb - Vb_upd;Vu - Vu_upd]));

end

% Exit early if equilibrium doesn't look right.
flag = iter==itermax; 

if flag
    tQ = sparse(2*naw+nay+na,2*naw+nay+na);  % type stability: Q sparse
    return;
end

% Optionally pack-up stuff required
% for welfare computations (str q).

if nargout>2
    q.Vp = Vp;
    q.Vs = Vs;
    q.Vb = Vb;
    q.Vu = Vu;
    q.Rp = Rp;
    q.Rs = Rs;
    q.Rb = Rb;
    q.Ru = Ru;
end


%%% Compute implied aggregate transition matrix.

% Search stage
d_p = Vu_rep_w>(p.delt_p*Vb + (1 - p.delt_p)*(Vp + p.lamb_ps*opt_s_p));

Qr_pe = spdiags((1 - p.delt_p)*~d_p,0,naw,naw); % Remain employed
Qr_ps = transmat_search(Vs,Vp,dFy_aw,ny,nw,na); 
Qr_ps = p.lamb_ps*Qr_ps;
Qr_pp = spdiags(1 - sum(Qr_ps,2),0,naw,naw);
Qr_ps = Qr_pe*Qr_ps;
Qr_pp = Qr_pe*Qr_pp; 
Qr_pb = spdiags(p.delt_p*~d_p,0,naw,naw);
Qr_pu = sparse(1:naw,repmat(1:na,nw,1),d_p);

d_s = Vu_rep_y>(p.delt_s*Vu_rep_y + (1 - p.delt_s)*(Vs + p.lamb_sp*opt_p_s));

Qr_se = spdiags((1 - p.delt_s)*~d_s,0,nay,nay); % Remain employed
Qr_sp = transmat_search(Vp,Vs,dFw_ay,nw,ny,na); 
Qr_sp = p.lamb_sp*Qr_sp;
Qr_ss = spdiags(1 - sum(Qr_sp,2),0,nay,nay);
Qr_sp = Qr_se*Qr_sp;
Qr_ss = Qr_se*Qr_ss;
Qr_su = sparse(1:naw,repmat(1:na,ny,1),d_s + p.delt_s*~d_s);

Qr_bp = transmat_search(Vp,Vb,dFw_aw,nw,nw,na);
Qr_bp = p.lamb_up*Qr_bp;
Qr_bs = transmat_search(Vs,Vb,dFy_aw,ny,nw,na);
Qr_bs = p.lamb_us*Qr_bs;
Qr_bb = spdiags(1 - sum(Qr_bp,2) - sum(Qr_bs,2),0,naw,naw);

Qr_up = transmat_search(Vp,Vu,dFw_a,nw,1,na);
Qr_up = p.lamb_up*Qr_up;
Qr_us = transmat_search(Vs,Vu,dFy_a,ny,1,na);
Qr_us = p.lamb_us*Qr_us;
Qr_uu = spdiags(1 - sum(Qr_up,2) - sum(Qr_us,2),0,na,na);

% Transition matrix: search to consumption-savings
Qr_sb = sparse(nay,naw);
Qr_bu = sparse(naw,na);
Qr_ub = sparse(na,naw);

Qr = [ ...  
    Qr_pp Qr_ps Qr_pb Qr_pu; ... 
    Qr_sp Qr_ss Qr_sb Qr_su; ... 
    Qr_bp Qr_bs Qr_bb Qr_bu; ...
    Qr_up Qr_us Qr_ub Qr_uu; ...
    ];

% Transition matrix: income to search stage
Qi = [...
    sparse(naw,naw+nay+naw+na);...
    sparse(nay,naw+nay+naw+na);...
    sparse(naw,naw+nay+naw) sparse(1:naw,repmat(1:na,nw,1),1/p.T_p);...
    sparse(na,naw+nay+naw+na); ... 
    ];

Qi = Qi + blkdiag(dQw,dQy,(1 - 1/p.T_p)*speye(naw),speye(na));

% NB. Benefits expire after T months, which is modeled as chance 1/T that 
% they expire next period.

% Transition matrix: consumpation-savings to income shock 
Qa_pp = transmat_consav(Rp,Up,p.beta,p,nw);
Qa_ss = transmat_consav(Rs,Us,p.beta,p,ny);
Qa_bb = transmat_consav(Rb,Ub,p.beta,p,nw);  
Qa_uu = transmat_consav(Ru,Uu,p.beta,p,1);   
Qa = blkdiag(Qa_pp,Qa_ss,Qa_bb,Qa_uu);

% All together: consumption-savings to consumption-savings
tQ = Qa*Qi*Qr;
tQ = tQ';

% NB. The transition matrix is ALREADY transposed for panel simulations.

