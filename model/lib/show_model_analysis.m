function show_model_analysis(save_it,par,file_suffix)
% Simulate MPCs and share of household constrained implied by model

if nargin<2
    load('./store/params','par');
end

if nargin<3
	file_suffix = '';
end

datmom = load('store/moments');

%% Inputs and params for each class
K = 4;
p = initialize_inputs(K);

cluster_wgt = zeros(K,1);

for k = 1:K
    p{k} = initialize_inputs_pol(p{k});
    p{k} = initialize_parameters(par,p{k});
    cluster_wgt(k) = p{k}.N;
end

cluster_wgt = cluster_wgt/sum(cluster_wgt);

%% Baseline solution & simulation
vf_bsl = cell(K,1);
dG_bsl = cell(K,1);
pn_bsl = cell(K,1);
mm_bsl = cell(K,1);

for k = 1:K
    [tQ,flag,vf_bsl{k}] = solve_ind_dec(p{k});
    if flag
        error('Problem with equilibrium');
    end
    dG_bsl{k} = unpack_statio_dist(tQ,p{k});
    pn_bsl{k} = simulate_panel(tQ,p{k});
    mm_bsl{k} = calculate_moments(pn_bsl{k},datmom);
end

mm_bsl_all = calculate_moments(stack_panels(pn_bsl),datmom);

%% Insurance through lens of model
shr_cstr = zeros(4,K+1);
avg_mpcs = zeros(4,K+1);
avg_cons = zeros(4,K+1);

for k = 1:K

	% Share of households credit constrained
	shr_lb_p = sum(dG_bsl{k}.p(1,:))/sum(dG_bsl{k}.p(:)); 
	shr_lb_s = sum(dG_bsl{k}.s(1,:))/sum(dG_bsl{k}.s(:)); 
	shr_lb_b = sum(dG_bsl{k}.b(1,:))/sum(dG_bsl{k}.b(:)); 
	shr_lb_u = dG_bsl{k}.u(1)/sum(dG_bsl{k}.u); 

	shr_cstr(:,k) = [shr_lb_p;shr_lb_s;shr_lb_b;shr_lb_u];

	% Back out optimal consumption
	Yu = p{k}.Yu;
	Yp = p{k}.Yp(p{k}.w);
	Ys = p{k}.Ys(p{k}.y);

	b = p{k}.b_p(p{k}.w);

	Cp = kron(Yp,ones(p{k}.na,p{k}.na2)) + (1 + p{k}.r)*repmat(p{k}.a,p{k}.nw,p{k}.na2) - repmat(p{k}.a2',p{k}.na*p{k}.nw,1);
	Cs = kron(Ys,ones(p{k}.na,p{k}.na2)) + (1 + p{k}.r)*repmat(p{k}.a,p{k}.ny,p{k}.na2) - repmat(p{k}.a2',p{k}.na*p{k}.ny,1);
	Cb = kron(b,ones(p{k}.na,p{k}.na2)) + (1 + p{k}.r)*repmat(p{k}.a,p{k}.nw,p{k}.na2) - repmat(p{k}.a2',p{k}.na*p{k}.nw,1);
	Cu = Yu + (1 + p{k}.r)*repmat(p{k}.a,1,p{k}.na2) - repmat(p{k}.a2',p{k}.na,1); 

	Up = p{k}.u(Cp);
	Us = p{k}.u(p{k}.kappa*Cs); % Utility has extra non-pecuniary benefits
	Ub = p{k}.u(Cb);
	Uu = p{k}.u(Cu);

	c_p = choose_consumption(vf_bsl{k}.Rp,Up,Cp,p{k},p{k}.nw);
	c_s = choose_consumption(vf_bsl{k}.Rs,Us,Cs,p{k},p{k}.ny);
	c_b = choose_consumption(vf_bsl{k}.Rb,Ub,Cb,p{k},p{k}.nw);
	c_u = choose_consumption(vf_bsl{k}.Ru,Uu,Cu,p{k},1);

	% Compute MPCs
	avg_mpc_p = average_mpc(c_p,dG_bsl{k}.p,p{k},p{k}.nw);
	avg_mpc_s = average_mpc(c_s,dG_bsl{k}.s,p{k},p{k}.ny);
	avg_mpc_b = average_mpc(c_b,dG_bsl{k}.b,p{k},p{k}.nw);
	avg_mpc_u = average_mpc(c_u,dG_bsl{k}.u,p{k},1);

	avg_mpcs(:,k) = [avg_mpc_p;avg_mpc_s;avg_mpc_b;avg_mpc_u];

	% Average consumption in each class
	avg_c_p = average_c(c_p,dG_bsl{k}.p,p{k}.na,p{k}.nw);
	avg_c_s = average_c(c_s,dG_bsl{k}.s,p{k}.na,p{k}.ny);
	avg_c_b = average_c(c_b,dG_bsl{k}.b,p{k}.na,p{k}.nw);
	avg_c_u = average_c(c_u,dG_bsl{k}.u,p{k}.na,1);

	avg_cons(:,k) = [avg_c_p;avg_c_s;avg_c_b;avg_c_u];

end

shr_cstr(:,K+1) = shr_cstr(:,1:K)*cluster_wgt; 
avg_mpcs(:,K+1) = avg_mpcs(:,1:K)*cluster_wgt; 
avg_cons(:,K+1) = avg_cons(:,1:K)*cluster_wgt; 

% Result tables
r = {'P','S','B','U'};
c = {'worker_class_1','worker_class_2','worker_class_3','worker_class_4','all'};

shr_cstr = array2table(shr_cstr,'RowNames',r,'VariableNames',c);
avg_mpcs = array2table(avg_mpcs,'RowNames',r,'VariableNames',c);
avg_cons = array2table(avg_cons,'RowNames',r,'VariableNames',c);

disp('Share constrained:');
disp(shr_cstr);

disp('Average MPCs:');
disp(avg_mpcs);

disp('Average consumption:');
disp(avg_cons);


%% Transition rates by class

r = {'UP','US','PS','SP','PU','SU'};

lm_trans = zeros(length(r),K+1);

for k = 1:K
	lm_trans(:,k) = [...
	mm_bsl{k}.UP;...
	mm_bsl{k}.US;...
	mm_bsl{k}.PS;...
	mm_bsl{k}.SP;...
	mm_bsl{k}.PU;...
	mm_bsl{k}.SU];
end

lm_trans(:,K+1) = [...
	mm_bsl_all.UP;...
	mm_bsl_all.US;...
	mm_bsl_all.PS;...
	mm_bsl_all.SP;...
	mm_bsl_all.PU;...
	mm_bsl_all.SU];

lm_trans = array2table(lm_trans,'RowNames',r,'VariableNames',c);

disp('Transition rates:');
disp(lm_trans);

%% Study response to change in UI policy (benchmark)

elast = zeros(4,K+1);

%% Change in replacement rate
mm_rep = cell(K,1);
pn_rep = cell(K,1);

b_alt = .6;


for k = 1:K
    
	pn_rep{k} = get_panel_alt_rep(b_alt,p{k});
	mm_rep{k} = calculate_moments(pn_rep{k},datmom);
	
    elast(1,k) = log(1/(mm_rep{k}.UP + mm_rep{k}.US)); 
	elast(1,k) = elast(1,k) - log(1/(mm_bsl{k}.UP + mm_bsl{k}.US)); 
    elast(1,k) = elast(1,k)/(log(b_alt) - log(p{k}.b_rep_rate)); 
	
    elast(2,k) = log(1/mm_rep{k}.UP) - log(1/mm_bsl{k}.UP);
	elast(2,k) = elast(2,k)/(log(b_alt) - log(p{k}.b_rep_rate));
	
end 

mm_rep_all = calculate_moments(stack_panels(pn_rep),datmom);

elast(1,K+1) = log(1/(mm_rep_all.UP + mm_rep_all.US)); 
elast(1,K+1) = elast(1,K+1) - log(1/(mm_bsl_all.UP + mm_bsl_all.US)); 
elast(1,K+1) = elast(1,K+1)/(log(b_alt) - log(p{1}.b_rep_rate)); 

elast(2,K+1) = log(1/mm_rep_all.UP) - log(1/mm_bsl_all.UP);
elast(2,K+1) = elast(2,k)/(log(b_alt) - log(p{1}.b_rep_rate));


%% Change in potential benefits duration
pn_pbd = cell(K,1);
mm_pbd = cell(K,1);

T_alt = 7;

for k = 1:K
    
	pn_pbd{k} = get_panel_alt_pbd(T_alt,p{k});
	mm_pbd{k} = calculate_moments(pn_pbd{k},datmom);
    
	elast(3,k) = log(1/(mm_pbd{k}.UP + mm_pbd{k}.US)); 
	elast(3,k) = elast(3,k) - log(1/(mm_bsl{k}.UP + mm_bsl{k}.US)); 
    elast(3,k) = elast(3,k)/(log(T_alt) - log(p{k}.T_p)); 
	
    elast(4,k) = log(1/mm_pbd{k}.UP) - log(1/mm_bsl{k}.UP);
	elast(4,k) = elast(4,k)/(log(T_alt) - log(p{k}.T_p));
    
end

mm_pbd_all = calculate_moments(stack_panels(pn_pbd),datmom);

elast(3,K+1) = log(1/(mm_pbd_all.UP + mm_pbd_all.US)); 
elast(3,K+1) = elast(3,K+1) - log(1/(mm_bsl_all.UP + mm_bsl_all.US)); 
elast(3,K+1) = elast(3,K+1)/(log(T_alt) - log(p{k}.T_p)); 

elast(4,K+1) = log(1/mm_pbd_all.UP) - log(1/mm_bsl_all.UP);
elast(4,K+1) = elast(4,K+1)/(log(T_alt) - log(p{k}.T_p));


%% Results table

r = {'dlnDurToEdlnb','dlnDurToPdlnb','dlnDurToEdlnT','dlnDurToPdlnT'};
elast = array2table(elast,'RowNames',r,'VariableNames',c);

disp('Change in UI policy');
disp(elast);

%% Save results

if save_it

    wb_name = ['../tables/03_model_analysis',file_suffix,'.xlsx'];
    
    writetable(shr_cstr,wb_name,'WriteRowNames',1,'Sheet','share_cstr');
    writetable(avg_mpcs,wb_name,'WriteRowNames',1,'Sheet','average_mpcs');
    writetable(avg_cons,wb_name,'WriteRowNames',1,'Sheet','average_cons');
    writetable(lm_trans,wb_name,'WriteRowNames',1,'Sheet','transition_rates');
    writetable(elast,wb_name,'WriteRowNames',1,'Sheet','elast');
    
end

end

%--------------------------------------------------------------------------

function dG = unpack_statio_dist(tQ,p)

[dG_vec,~,~] = get_statio_dist(tQ);

dG.p = reshape(dG_vec(1:p.na*p.nw),p.na,p.nw);
dG.s = reshape(dG_vec(p.na*p.nw+1:p.na*(p.nw+p.ny)),p.na,p.ny);
dG.b = reshape(dG_vec(p.na*(p.nw+p.ny)+1:p.na*(p.nw+p.ny+p.nw)),p.na,p.nw);
dG.u = dG_vec(p.na*(p.nw+p.ny+p.nw)+1:p.na*(p.nw+p.ny+p.nw+1));

end

function c = choose_consumption(R,U,C,p,ny)

% Replicate continuation value
Rres = reshape(R,p.na,ny);
Ritp = interp1(p.a,Rres,p.a2);  % 'linear' interpolation implicitly
Rrep = kron(Ritp',ones(p.na,1));

% Maximize over next period asset choices
[~,a_choice_idx] = max(U + p.beta*Rrep,[],2,'linear');

% Consumption choice
c = C(a_choice_idx);

end

function c_avg = average_c(c,dG,na,ny)

dG_pmf = dG/sum(dG,'all');

c_tmp = reshape(c,na,ny);
c_avg = sum(c_tmp.*dG_pmf,'all');

end

function mpc_avg = average_mpc(c,dG,p,ny)

dG_pmf = dG/sum(dG,'all');

da = (p.a2(2) - p.a2(1))/2; 

c = reshape(c,p.na,ny);
c_ = interp1(p.a,c,p.a + da,'pchip','extrap');

mpc_avg = (c_ - c)/da;
mpc_avg = sum(mpc_avg.*dG_pmf,'all');

end

function pn = get_panel_class(p)

[tQ,flag] = solve_ind_dec(p);

if flag
	error('Problem with model solution.');
end

[pn,flag] = simulate_panel(tQ,p);

if flag 
	error('Problem with panel simulation.');
end


end

function pn = get_panel_alt_rep(b_rep_rate,p)

p.b_p = @(w) min(b_rep_rate*w,p.b_max);
pn = get_panel_class(p); 

end

function pn = get_panel_alt_pbd(T,p)

p.T_p = T;
pn = get_panel_class(p);

end
