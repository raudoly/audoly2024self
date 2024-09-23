function decompose_welfare_tnt(b,tau,save_it)
% Decompose welfare impact of change in policy.

datmom = load('store/moments');
load('store/params','par');

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

cl_wgt = cl_wgt/sum(cl_wgt); % normalize to get cluster weights

%% Store baseline equilibrium
vf_bsl = cell(K,1);
pn_bsl = cell(K,1);

for k = 1:K
    [tQ,flag,vf_bsl{k}] = solve_ind_dec(p{k});
    if flag
        error('Not a valid equilibrium');
    end
    pn_bsl{k} = simulate_panel(tQ,p{k});
end

%% Store equilibrium with extra tax and transfers
vf_pol = cell(K,1);
pn_pol = cell(K,1); 
dG_pol = cell(K,1);

for k = 1:K
    p{k} = initialize_inputs_tnt(p{k},b,tau);
    [tQ,flag,vf_pol{k}] = solve_ind_dec_tnt2(p{k});
    if flag
        error('Not a valid equilibrium');
    end
    dG_pol{k} = extract_statio_dist(tQ,p{k});
    pn_pol{k} = simulate_panel(tQ,p{k});
end

%% Policy scenario
gov_income = zeros(1,K);
gov_payout = zeros(1,K);

for k = 1:K

    repTp = kron(p{k}.govt(p{k}.Yp(p{k}.w)),ones(p{k}.na,1)); 
    repTs = kron(p{k}.govt(p{k}.Ys(p{k}.y)),ones(p{k}.na,1));
    repTb = kron(p{k}.govt(p{k}.Yu),ones(p{k}.na*p{k}.nw,1));
    repTu = kron(p{k}.govt(p{k}.Yu),ones(p{k}.na,1));
    
    gov_income(k) = gov_income(k) + sum((repTp>0).*repTp.*dG_pol{k}.dGp);
    gov_income(k) = gov_income(k) + sum((repTs>0).*repTs.*dG_pol{k}.dGs);
    gov_income(k) = gov_income(k) + sum((repTb>0).*repTb.*dG_pol{k}.dGb);
    gov_income(k) = gov_income(k) + sum((repTu>0).*repTu.*dG_pol{k}.dGu);

    gov_payout(k) = gov_payout(k) + sum((repTp<=0).*repTp.*dG_pol{k}.dGp);
    gov_payout(k) = gov_payout(k) + sum((repTs<=0).*repTs.*dG_pol{k}.dGs);
    gov_payout(k) = gov_payout(k) + sum((repTb<=0).*repTb.*dG_pol{k}.dGb);
    gov_payout(k) = gov_payout(k) + sum((repTu<=0).*repTu.*dG_pol{k}.dGu);

end

pol = table([b;tau;sum(gov_income)]);
pol.Properties.RowNames = {'b','tau','gov_inc'};
pol.Properties.VariableNames = {'Value'};

fprintf('\nPolicy scenario\n');    
disp(pol);  

%% Benefits to contribution ratio by group
ben_cont = [gov_income;gov_payout;gov_payout./gov_income];
ben_cont = array2table(ben_cont);  
ben_cont.Properties.RowNames = {'contributions','benefits','ratio_ben_to_cont'};
ben_cont.Properties.VariableNames = {'cluster_1','cluster_2','cluster_3','cluster_4'};

fprintf('\n\nBenefits and contributions:\n');    
disp(ben_cont);

%% Compensating differentials & cash grant
cd_clus = zeros(5,K);
cg_clus = zeros(5,K);

for k = 1:K
	cd_clus(:,k) = avg_comp_diff(vf_pol{k},vf_bsl{k},dG_pol{k},p{k});
    cg_clus(:,k) = avg_cash_grant(vf_pol{k},vf_bsl{k},dG_pol{k},p{k});
end

cd_all = cd_clus*cl_wgt;
cg_all = cg_clus*cl_wgt;

%% Welfare stats table
v = {'cluster_1','cluster_2','cluster_3','cluster_4','all'};
r = {'ern_p50',...
    'cd','cd_p','cd_s','cd_b','cd_u',...
    'cg','cg_p','cg_s','cg_b','cg_u'};

wf = [cl_ern' NaN;cd_clus cd_all;cg_clus cg_all];
wf = array2table(wf,'RowNames',r,'VariableNames',v);    

fprintf('\n\nWelfare:\n');    
disp(wf);

%% Change in transition rates
tr_bsl_1 = get_transition_rates(pn_bsl{1});
tr_pol_1 = get_transition_rates(pn_pol{1});
tr_bsl_4 = get_transition_rates(pn_bsl{4});
tr_pol_4 = get_transition_rates(pn_pol{4});

tr_bsl_all = get_transition_rates_all(pn_bsl);
tr_pol_all = get_transition_rates_all(pn_pol);

tr = table(...
    tr_bsl_1,tr_pol_1,tr_bsl_4,tr_pol_4,tr_bsl_all,tr_pol_all,...
    'VariableNames',{'bsl_1','pol_1','bsl_4','pol_4','bsl_all','pol_all'},...
    'RowNames',{'UP','US','PS','SP','PU','SU','u_rate','p_rate','s_rate'});

fprintf('\n\nTransitions:\n');    
disp(tr);   

%% Change in earnings distribution
ern_bsl_1 = get_ern_dist(pn_bsl{1},datmom);
ern_pol_1 = get_ern_dist(pn_pol{1},datmom);
ern_bsl_4 = get_ern_dist(pn_bsl{4},datmom);
ern_pol_4 = get_ern_dist(pn_pol{4},datmom);

ern = table(...
    ern_bsl_1,ern_pol_1,ern_bsl_4,ern_pol_4,...
    'VariableNames',{'bsl_1','pol_1','bsl_4','pol_4'},...
    'RowNames',{...
    'P-p10','P-p25','P-p50','P-p75','P-p90',...
    'S-p10','S-p25','S-p50','S-p75','S-p90'});

fprintf('\n\nLabor Earnings:\n');    
disp(ern);

if save_it

    wb_name = '../tables/04_model_policy.xlsx';
    ws_name = ['_tnt_b_',num2str(b)];
    
    r = 1;
    
    ws_cell = ['A',num2str(r)]; 
    writetable(pol,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);
    r = r + height(pol) + 2; 

    ws_cell = ['A',num2str(r)]; 
    writetable(ben_cont,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);
    r = r + height(ben_cont) + 2; 

    ws_cell = ['A',num2str(r)]; 
    writetable(wf,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);
    r = r + height(wf) + 2; 

    ws_cell = ['A',num2str(r)]; 
    writetable(tr,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);
    r = r + height(tr) + 2; 

    ws_cell = ['A',num2str(r)]; 
    writetable(ern,wb_name,'Sheet',ws_name,'Range',ws_cell,'WriteRowNames',1);

    file_name = ['store/policy_tnt_b_',num2str(b),'.mat'];
    save(file_name,'pol','ben_cont','wf','tr','ern');

end

end

%--------------------------------------------------------------------------
function cd_avg = avg_comp_diff(Vpol,Vbsl,dG,p)

% Compensating differentials in consumption for moving from
% economy 0 to 1 (for CRRA utility function)
if ne(p.crra,1.0)
    cdc = @(V1,V0) (V1./V0).^(1.0/(1.0 - p.crra)) - 1.0;
else
    cdc = @(V1,V0) exp((1.0 - p.beta)*(V1 - V0)) - 1.0;
end

% Compensating differential in each group
cd_p = cdc(Vpol.Vp,Vbsl.Vp);
cd_s = cdc(Vpol.Vs,Vbsl.Vs);
cd_b = cdc(Vpol.Vb,Vbsl.Vb);
cd_u = cdc(Vpol.Vu,Vbsl.Vu);

cd_avg = zeros(5,1);

% Average across all groups
cd_avg(1) = sum(cd_p.*dG.dGp) ...
        + sum(cd_s.*dG.dGs) ...
        + sum(cd_b.*dG.dGb) ...
        + sum(cd_u.*dG.dGu);

% Average for sub-groups
cd_avg(2) = sum(cd_s.*dG.dGp)/sum(dG.dGp);
cd_avg(3) = sum(cd_s.*dG.dGs)/sum(dG.dGs);
cd_avg(4) = sum(cd_b.*dG.dGb)/sum(dG.dGb);
cd_avg(5) = sum(cd_u.*dG.dGu)/sum(dG.dGu);

end

function cg_avg = avg_cash_grant(Vpol,Vbsl,dG,p)

% Compensating grant in each group
cg_p = cashgrant(Vpol.Vp,Vbsl.Vp,p.a,p.na,p.nw);
cg_s = cashgrant(Vpol.Vs,Vbsl.Vs,p.a,p.na,p.ny);
cg_b = cashgrant(Vpol.Vb,Vbsl.Vb,p.a,p.na,p.nw);
cg_u = cashgrant(Vpol.Vu,Vbsl.Vu,p.a,p.na,1);


cg_avg = zeros(5,1);

% Average across all groups
cg_avg(1) = sum(cg_p.*dG.dGp)...
        + sum(cg_s.*dG.dGs)...
        + sum(cg_b.*dG.dGb)...
        + sum(cg_u.*dG.dGu);

% Average for sub-groups
cg_avg(2) = sum(cg_p.*dG.dGp)/sum(dG.dGp);
cg_avg(3) = sum(cg_s.*dG.dGs)/sum(dG.dGs);
cg_avg(4) = sum(cg_b.*dG.dGb)/sum(dG.dGb);
cg_avg(5) = sum(cg_u.*dG.dGu)/sum(dG.dGu);

end

function cg = cashgrant(V1,V0,a,na,ny)
% Cash grant making agents indifferent between 
% two economies 0 and 1 at the same node.

% Reshape value functions
V0rsh = reshape(V0,na,ny);
V1rsh = reshape(V1,na,ny);

% Interpolate to find cash grants that makes agent indifferent
na_itp = 50*na;
a_itp = linspace(a(1),a(na),na_itp)'; % denser grid for itp
cg = zeros(na,ny);

for yi = 1:ny
    V = griddedInterpolant(a,V0rsh(:,yi),'linear'); 
    Vitp = V(a_itp);
    for ai = 1:na
        a_idx = find(V1rsh(ai,yi)<=Vitp,1,'first');
        if isempty(a_idx) 
            a_idx = na_itp;
            % This is really a quick fix: assign last point on
            % grid. Shouldn't happen too often, though, because
            % policies are redistributive by design.
        end
        cg(ai,yi) = a_itp(a_idx) - a(ai);  
    end
end

cg = cg(:);

end

function [tQ,flag,q] = solve_ind_dec_tnt2(p)
% Model solution in the tax and transfer policy, but with all the
% same labor force states as in the baseline version.

p.b_p = @(x) zeros(size(x)); % Wipe out UI benefits

p.Yu = p.post(p.Yu);
p.Yp = @(x) p.post(p.Yp(x));
p.Ys = @(x) p.post(p.Ys(x));

[tQ,flag,q] = solve_ind_dec(p);

end

function dG = extract_statio_dist(tQ,p)

[dGvec,~,~] = get_statio_dist(tQ);

dG.dGp = dGvec(1:p.na*p.nw);
dG.dGs = dGvec(p.na*p.nw+1:p.na*(p.nw+p.ny));
dG.dGb = dGvec(p.na*(p.nw+p.ny)+1:p.na*(p.nw+p.ny+p.nw));
dG.dGu = dGvec(p.na*(p.nw+p.ny+p.nw)+1:p.na*(p.nw+p.ny+p.nw+1));

end

% function dG = extract_statio_dist_tnt(tQ,p)

% [dGvec,~,~] = get_statio_dist(tQ);

% dG.dGp = dGvec(1:p.na*p.nw);
% dG.dGs = dGvec(p.na*p.nw+1:p.na*(p.nw+p.ny));
% dG.dGu = dGvec(p.na*(p.nw+p.ny)+1:p.na*(p.nw+p.ny+1));

% end

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
% 
% pn_all = stack_panels(pn);
% 
% v = get_ern_dist(pn_all,mdat);

% end

    
