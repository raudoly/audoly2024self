function decompose_welfare_ui(tau,b,policy_name,save_it)
% Decompose welfare impact of change in policy.

datmom = load('store/moments');
load('store/params','par');

if strcmp(policy_name,'within')
    policy_type = 'progressive';
else 
    policy_type = policy_name;
end

%% Inputs and params for each class
K = 4;
p = initialize_inputs(K);

cl_ern = zeros(K,1);
cl_wgt = zeros(K,1);

for k = 1:K
    p{k} = initialize_inputs_pol(p{k});
    p{k} = initialize_parameters(par,p{k});
    cl_ern(k) = p{k}.ern_p50; % way to ID cluster
    cl_wgt(k) = p{k}.N;
end

cl_wgt = cl_wgt/sum(cl_wgt); % normalize to get class weight

%% Store baseline equilibrium
vf_bsl = cell(K,1);
pn_bsl = cell(K,1);

for k = 1:K
    [tQ,flag,vf_bsl{k}] = solve_ind_dec_bsl(p{k});
    if flag
        error('Not a valid equilibrium');
    end
    pn_bsl{k} = simulate_panel(tQ,p{k});
end

%% Store equilibrium with UI policy
vf_pol = cell(K,1);
pn_pol = cell(K,1); 
dG_pol = cell(K,1);

for k = 1:K
    p{k} = initialize_inputs_ui(p{k},tau(k),b,policy_type);
    [tQ,flag,vf_pol{k}] = solve_ind_dec_ui(p{k});
    if flag
        error('Not a valid equilibrium');
    end
    dG_pol{k} = extract_statio_dist_ui(tQ,p{k});
    pn_pol{k} = simulate_panel(tQ,p{k});
end

%% Policy scenario
gov_income = 0.0;

for k = 1:K
    yrep = kron(p{k}.y,ones(p{k}.na,1));
    gov_income = gov_income + sum(p{k}.govt(yrep).*dG_pol{k}.dGs);
end

pol = table(...
    [tau;b;p{1}.T_s;gov_income],...
    'VariableNames',{'Value'},...
    'RowNames',{'tau_1','tau_2','tau_3','tau_4','b','T','gov_income'});
  
disp('Policy scenario');    
disp(pol);

%% Benefits to contributions ratio by group
ben_and_cont = zeros(4,K);

for k = 1:K
    yrep = kron(p{k}.y,ones(p{k}.na,1));
    ben_and_cont(1,k) = sum(p{k}.govt(yrep).*dG_pol{k}.dGs);
    ben_and_cont(2,k) = sum(p{k}.b_s(yrep).*dG_pol{k}.dGc);
    ben_and_cont(3,k) = ben_and_cont(2,k)/ben_and_cont(1,k);
    ben_and_cont(4,k) = sum((p{k}.govt(yrep)./yrep).*dG_pol{k}.dGs);
end

ben_and_cont = array2table(ben_and_cont);  
ben_and_cont.Properties.RowNames = {'contributions','benefits','ratio_ben_to_cont','average_tax_rate'};
ben_and_cont.Properties.VariableNames = {'cluster_1','cluster_2','cluster_3','cluster_4'};


fprintf('\n\nBenefits and contributions:\n');    
disp(ben_and_cont);

%% Welfare stats: compensating differentials and compensating wealth 
cd_clus = zeros(6,K);
cg_clus = zeros(6,K);

for k = 1:K
    cd_clus(:,k) = avg_comp_diff(vf_pol{k},vf_bsl{k},dG_pol{k},p{k});
    cg_clus(:,k) = avg_cash_grant(vf_pol{k},vf_bsl{k},dG_pol{k},p{k});
end

cd_all = cd_clus*cl_wgt;
cg_all = cg_clus*cl_wgt;

%% Welfare stats table
v = {'cluster_1','cluster_2','cluster_3','cluster_4','all'};
r = {'ern_p50',...
    'cd','cd_p','cd_s','cd_b','cd_u','cd_c',...
    'cg','cg_p','cg_s','cg_b','cg_u','cg_c'};

wf = [cl_ern' NaN; cd_clus cd_all; cg_clus cg_all];
wf = array2table(wf,'RowNames',r,'VariableNames',v);    

fprintf('\n\nWelfare:\n');    
disp(wf);

%% Change in transition rates
bsl_1 = get_transition_rates(pn_bsl{1});
pol_1 = get_transition_rates(pn_pol{1});
bsl_2 = get_transition_rates(pn_bsl{2});
pol_2 = get_transition_rates(pn_pol{2});
bsl_3 = get_transition_rates(pn_bsl{3});
pol_3 = get_transition_rates(pn_pol{3});
bsl_4 = get_transition_rates(pn_bsl{4});
pol_4 = get_transition_rates(pn_pol{4});

bsl_all = get_transition_rates_all(pn_bsl);
pol_all = get_transition_rates_all(pn_pol);

transitions = table(bsl_1,pol_1,bsl_2,pol_2,bsl_3,pol_3,bsl_4,pol_4,bsl_all,pol_all,...
    'RowNames',{'UP','US','PS','SP','PU','SU','u_rate','p_rate','s_rate'});

fprintf('\n\nTransitions:\n');    
disp(transitions);    

%% Change in earnings distribution
ern_bsl_1 = get_ern_dist(pn_bsl{1},datmom);
ern_pol_1 = get_ern_dist(pn_pol{1},datmom);
ern_bsl_4 = get_ern_dist(pn_bsl{4},datmom);
ern_pol_4 = get_ern_dist(pn_pol{4},datmom);

tab_ern = table(...
    ern_bsl_1,ern_pol_1,ern_bsl_4,ern_pol_4,...
    'VariableNames',{'bsl_1','cl_1','bsl_4','cl_4'},...
    'RowNames',{...
    'P-p10','P-p25','P-p50','P-p75','P-p90',...
    'S-p10','S-p25','S-p50','S-p75','S-p90'});

fprintf('\n\nLabor Earnings:\n');    
disp(tab_ern);

if save_it

    wb_name = '../tables/04_model_policy.xlsx';
    ws_name = ['_',policy_name,'_b_',num2str(b)];
    
    row = 1;
    
    ws_cell = ['A',num2str(row)]; 
    writetable(pol,wb_name,'Sheet',ws_name,'WriteMode','overwritesheet','Range',ws_cell,'WriteRowNames',1);
    row = row + height(pol) + 2; 

    ws_cell = ['A',num2str(row)]; 
    writetable(ben_and_cont,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);
    row = row + height(ben_and_cont) + 2; 

    ws_cell = ['A',num2str(row)]; 
    writetable(wf,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);
    row = row + height(wf) + 2; 

    ws_cell = ['A',num2str(row)]; 
    writetable(transitions,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);
    row = row + height(transitions) + 2; 

    ws_cell = ['A',num2str(row)]; 
    writetable(tab_ern,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);

    file_name = ['store/policy_',policy_name,'_b_',num2str(b),'.mat'];
    save(file_name,'pol','ben_and_cont','wf','transitions','tab_ern');

end

end

function cd_avg = avg_comp_diff(vf_pol,vf_bsl,dGpol,p)

% Compensating differentials in consumption for moving from
% economy 0 to 1 (for CRRA utility function)
if ne(p.crra,1.0)
    cdc = @(V1,V0) (V1./V0).^(1.0/(1.0 - p.crra)) - 1.0;
else
    cdc = @(V1,V0) exp((1.0 - p.beta)*(V1 - V0)) - 1.0;
end

% Compensating differential in each group
cd_p = cdc(vf_pol.Vp,vf_bsl.Vp);
cd_s = cdc(vf_pol.Vs,vf_bsl.Vs);
cd_b = cdc(vf_pol.Vb,vf_bsl.Vb);
cd_u = cdc(vf_pol.Vu,vf_bsl.Vu);
cd_c = cdc(vf_pol.Vc,vf_bsl.Vc); % Baseline = no UI 

cd_avg = zeros(6,1);

% Average across all groups
cd_avg(1) = sum(cd_p.*dGpol.dGp) ...
    + sum(cd_s.*dGpol.dGs) ...
    + sum(cd_b.*dGpol.dGb) ...
    + sum(cd_u.*dGpol.dGu) ...
    + sum(cd_c.*dGpol.dGc);

% Average for sub-groups
cd_avg(2) = sum(cd_p.*dGpol.dGp)/sum(dGpol.dGp);
cd_avg(3) = sum(cd_s.*dGpol.dGs)/sum(dGpol.dGs);
cd_avg(4) = sum(cd_b.*dGpol.dGb)/sum(dGpol.dGb);
cd_avg(5) = sum(cd_u.*dGpol.dGu)/sum(dGpol.dGu);
cd_avg(6) = sum(cd_c.*dGpol.dGc)/sum(dGpol.dGc);

end

function cg_avg = avg_cash_grant(vf_pol,vf_bsl,dGpol,p)

% Compensating differential in each group
cg_p = cashgrant(vf_pol.Vp,vf_bsl.Vp,p.a,p.na,p.nw);
cg_s = cashgrant(vf_pol.Vs,vf_bsl.Vs,p.a,p.na,p.ny);
cg_b = cashgrant(vf_pol.Vb,vf_bsl.Vb,p.a,p.na,p.nw);
cg_u = cashgrant(vf_pol.Vu,vf_bsl.Vu,p.a,p.na,1);
cg_c = cashgrant(vf_pol.Vc,vf_bsl.Vc,p.a,p.na,p.ny); 

cg_avg = zeros(6,1);

% Average across all groups
cg_avg(1) = sum(cg_p.*dGpol.dGp) ...
    + sum(cg_s.*dGpol.dGs) ...
    + sum(cg_b.*dGpol.dGb) ...
    + sum(cg_u.*dGpol.dGu) ...
    + sum(cg_c.*dGpol.dGc);

% Average for sub-groups
cg_avg(2) = sum(cg_p.*dGpol.dGp)/sum(dGpol.dGp);
cg_avg(3) = sum(cg_s.*dGpol.dGs)/sum(dGpol.dGs);
cg_avg(4) = sum(cg_b.*dGpol.dGb)/sum(dGpol.dGb);
cg_avg(5) = sum(cg_u.*dGpol.dGu)/sum(dGpol.dGu);
cg_avg(6) = sum(cg_c.*dGpol.dGc)/sum(dGpol.dGc);

end

function cg = cashgrant(V1,V0,a,na,ny)
% Cash grant making agents indifferent between two economies
% 0 and 1 at the same node.

% Reshape value functions
V0rsh = reshape(V0,na,ny);
V1rsh = reshape(V1,na,ny);

% Interpolate to find cash grants that makes agent indifferent
naItp = 50*na;
aItp = linspace(a(1),a(na),naItp)'; % denser grid for itp
cg = zeros(na,ny);

for yi = 1:ny
    V = griddedInterpolant(a,V0rsh(:,yi),'linear'); 
    Vitp = V(aItp);
    for ai = 1:na
        aIdx = find(V1rsh(ai,yi)<=Vitp,1,'first');
        if isempty(aIdx) 
            aIdx = naItp;
            % This is really a quick fix: assign last point on
            % grid. Shouldn't happen too often, though, because
            % policies are redistributive by design.
        end
        cg(ai,yi) = aItp(aIdx) - a(ai);  
    end
end

cg = cg(:);

end

% function dG = extract_statio_dist(tQ,p)

% [dGvec,~,~] = get_statio_dist(tQ);

% dG.dGp = dGvec(1:p.na*p.nw);
% dG.dGs = dGvec(p.na*p.nw+1:p.na*(p.nw+p.ny));
% dG.dGb = dGvec(p.na*(p.nw+p.ny)+1:p.na*(p.nw+p.ny+p.nw));
% dG.dGu = dGvec(p.na*(p.nw+p.ny+p.nw)+1:p.na*(p.nw+p.ny+p.nw+1));

function [tQ,flag,q] = solve_ind_dec_bsl(p)
% Compute baseline equilibrium, but with the C state.

p.T_s = 6;                          % Potential duration                                   
p.b_s = @(y) zeros(size(y));        % Baseline: no UI...
p.post = @(y) y;                    % ... and no extra tax

[tQ,flag,q] = solve_ind_dec_ui(p);

end

function dG = extract_statio_dist_ui(tQ,p)

[dGvec,~,~] = get_statio_dist(tQ);

dG.dGp = dGvec(1:p.na*p.nw);
dG.dGs = dGvec(p.na*p.nw+1:p.na*(p.nw+p.ny));
dG.dGb = dGvec(p.na*(p.nw+p.ny)+1:p.na*(p.nw+p.ny+p.nw));
dG.dGu = dGvec(p.na*(p.nw+p.ny+p.nw)+1:p.na*(p.nw+p.ny+p.nw+1));
dG.dGc = dGvec(p.na*(p.nw+p.ny+p.nw+1)+1:p.na*(p.nw+p.ny+p.nw+1+p.ny));

end

function v = get_transition_rates(pn)

T = size(pn.lfs,2);

up = sum(pn.lfs(:,1:T-1)==1 & pn.lfs(:,2:T)==2,'all')/sum(pn.lfs(:,1:T-1)==1,'all');
us = sum(pn.lfs(:,1:T-1)==1 & pn.lfs(:,2:T)==3,'all')/sum(pn.lfs(:,1:T-1)==1,'all');
pu = sum(pn.lfs(:,1:T-1)==2 & pn.lfs(:,2:T)==1,'all')/sum(pn.lfs(:,1:T-1)==2,'all');
su = sum(pn.lfs(:,1:T-1)==3 & pn.lfs(:,2:T)==1,'all')/sum(pn.lfs(:,1:T-1)==3,'all');
ps = sum(pn.lfs(:,1:T-1)==2 & pn.lfs(:,2:T)==3,'all')/sum(pn.lfs(:,1:T-1)==2,'all');
sp = sum(pn.lfs(:,1:T-1)==3 & pn.lfs(:,2:T)==2,'all')/sum(pn.lfs(:,1:T-1)==3,'all');

u_rate = mean(pn.lfs==1,'all');
p_rate = mean(pn.lfs==2,'all');
s_rate = mean(pn.lfs==3,'all');

v = [up;us;ps;sp;pu;su;u_rate;p_rate;s_rate];

end

function v = get_transition_rates_all(pn)

pn_all = stack_panels(pn);
v = get_transition_rates(pn_all);

end

function v = get_ern_dist(pn,mdat)

m = calculate_moments(pn,mdat);        

v = [...
    m.ern_p10_pctl_2;...
    m.ern_p25_pctl_2;...
    m.ern_p50_pctl_2;...
    m.ern_p75_pctl_2;...
    m.ern_p90_pctl_2;...
    m.ern_p10_pctl_3;...
    m.ern_p25_pctl_3;...
    m.ern_p50_pctl_3;...
    m.ern_p75_pctl_3;...
    m.ern_p90_pctl_3];

end

% function v = get_ern_dist_all(pn,mdat)

% pn_all = stack_panels(pn);

% v = get_ern_dist(pn_all,mdat);

% end
