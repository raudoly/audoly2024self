function [tQ,flag,q] = solve_ind_dec_tnt(p)
% Solve for individual decisions using VFI. Alternative
% policy: Scrap UI benefits and rely solely on tax and
% transfer instead.


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
dFy_aw = repmat(p.dFy',naw,1);
dFw_a = repmat(p.dFw',na,1);
dFy_a = repmat(p.dFy',na,1);

% replicate income transition matrices
dQw = kron(p.dQw,speye(na));
dQy = kron(p.dQy,speye(na));

% post tax and transfers income
Yu = p.post(p.Yu);
Yp = p.post(p.Yp(p.w));
Ys = p.post(p.Ys(p.y));

% utility arrays
Up = kron(Yp,ones(na,na2));
Up = Up + (1 + p.r)*repmat(p.a,nw,na2) - repmat(p.a2',naw,1);
Up = p.u(Up);

Us = kron(Ys,ones(na,na2));
Us = Us + (1 + p.r)*repmat(p.a,ny,na2) - repmat(p.a2',nay,1);
Us = p.u(Us + p.kappa); % self-employment gives consumption boost

Uu = Yu + (1 + p.r)*repmat(p.a,1,na2) - repmat(p.a2',na,1);
Uu = p.u(Uu);


%%% Solve iterating on VFs.

% initial value functions - start from present value of hand-to-mouth
Vp_upd = max(p.r*kron(ones(nw,1),p.a),0) + kron(Yp,ones(na,1));
Vp_upd = p.u(Vp_upd)/(1 - p.beta);
Vs_upd = max(p.r*kron(ones(ny,1),p.a),0) + kron(Ys,ones(na,1));
Vs_upd = p.u(Vs_upd + p.kappa)/(1 - p.beta);
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
    Vu = Vu_upd;

    % unemployed (no benefits in this version)
    mu_s_u = value_draw(Vs,Vu,dFy_a,ny,1,na);
	mu_p_u = value_draw(Vp,Vu,dFw_a,nw,1,na);
    Ru = Vu + p.lamb_up*mu_p_u + p.lamb_us*mu_s_u;
    Vu_upd  = value_consav(Ru,Uu,p.beta,p,1);

 	% paid-employed
	opt_s_p = value_draw(Vs,Vp,dFy_aw,ny,nw,na);
	Vu_rep_w = repmat(Vu,nw,1); 
    Rp = max(Vu_rep_w,p.delt_p*Vu_rep_w + (1 - p.delt_p)*(Vp + p.lamb_ps*opt_s_p));
    Rp = dQw*Rp;
    Vp_upd = value_consav(Rp,Up,p.beta,p,nw);

    % self-employed
    opt_p_s = value_draw(Vp,Vs,dFw_ay,nw,ny,na);
    Vu_rep_y = repmat(Vu,ny,1);
	Rs = max(Vu_rep_y,p.delt_s*Vu_rep_y + (1 - p.delt_s)*(Vs + p.lamb_sp*opt_p_s));
    Rs = dQy*Rs;
	Vs_upd = value_consav(Rs,Us,p.beta,p,ny);

    % convergence
	crit = max(abs([Vp - Vp_upd;Vs - Vs_upd;Vu - Vu_upd]));

end


% Exit early if equilibrium doesn't look right.
flag = iter==itermax; 

if flag
    tQ = sparse(naw+nay+na,naw+nay+na);  % type stability: Q sparse
    return;
end

% Optionally pack-up stuff required
% for welfare computations (str q).

if nargout>2
    q.Vp = Vp;
    q.Vs = Vs;
    q.Vu = Vu;
end


%%% Compute implied aggregate transition matrix.

% Search stage
d_p = Vu_rep_w>(p.delt_p*Vu_rep_w + (1 - p.delt_p)*(Vp + p.lamb_ps*opt_s_p));
Qr_pe = spdiags((1 - p.delt_p)*~d_p,0,naw,naw);
Qr_ps = transmat_search(Vs,Vp,dFy_aw,ny,nw,na); 
Qr_ps = p.lamb_ps*Qr_ps;
Qr_pp = spdiags(1 - sum(Qr_ps,2),0,naw,naw);
Qr_ps = Qr_pe*Qr_ps;
Qr_pp = Qr_pe*Qr_pp; 
Qr_pu = sparse(1:naw,repmat(1:na,nw,1),d_p + p.delt_p*~d_p);

d_s = Vu_rep_y>(p.delt_s*Vu_rep_y + (1 - p.delt_s)*(Vs + p.lamb_sp*opt_p_s));
Qr_se = spdiags((1 - p.delt_s)*~d_s,0,nay,nay);
Qr_sp = transmat_search(Vp,Vs,dFw_ay,nw,ny,na); 
Qr_sp = p.lamb_sp*Qr_sp;
Qr_ss = spdiags(1 - sum(Qr_sp,2),0,nay,nay);
Qr_sp = Qr_se*Qr_sp;
Qr_ss = Qr_se*Qr_ss;
Qr_su = sparse(1:naw,repmat(1:na,ny,1),d_s + p.delt_s*~d_s);

Qr_up = transmat_search(Vp,Vu,dFw_a,nw,1,na);
Qr_up = p.lamb_up*Qr_up;
Qr_us = transmat_search(Vs,Vu,dFy_a,ny,1,na);
Qr_us = p.lamb_us*Qr_us;
Qr_uu = spdiags(1 - sum(Qr_up,2) - sum(Qr_us,2),0,na,na);

% Transition matrix: search to consumption-savings
Qr = [ ...  
    Qr_pp Qr_ps Qr_pu; ... 
    Qr_sp Qr_ss Qr_su; ... 
    Qr_up Qr_us Qr_uu  ...
    ];

% Transition matrix: income to destruction stage 
Qi = blkdiag(dQw,dQy,speye(na));

% Transition matrix: consumpation-savings to income shock 
Qa_pp = transmat_consav(Rp,Up,p.beta,p,nw);
Qa_ss = transmat_consav(Rs,Us,p.beta,p,ny); 
Qa_uu = transmat_consav(Ru,Uu,p.beta,p,1);   
Qa = blkdiag(Qa_pp,Qa_ss,Qa_uu);

% All together: consumption-savings to consumption-savings
tQ = Qa*Qi*Qr;
tQ = tQ';

% NB. The transition matrix is ALREADY transposed for panel simulations. 

