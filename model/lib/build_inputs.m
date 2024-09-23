function build_inputs
% Build exogenous inputs for calibrating model.

transition_rates = readtable('dat/transition_rates.csv');

nlw_pctl = readtable('dat/nlw_pctl.csv');
lqw_pctl = readtable('dat/lqw_pctl.csv');
ern_pctl = readtable('dat/ern_pctl.csv');

lnern = readtable('dat/lnern_stats.csv');
lnern_cl = readtable('dat/lnern_cluster_stats.csv');

dlnern_ps = readtable('dat/dlnern_ps.csv');
dlnern_sp = readtable('dat/dlnern_sp.csv');

pu_cl = readtable('dat/pu_cluster.csv');
su_cl = readtable('dat/su_cluster.csv');


%% Targeted data moments
    
% Transition rates
m.up = transition_rates.up;
m.us = transition_rates.us;
m.pu = transition_rates.pu;
m.su = transition_rates.su;
m.sp = transition_rates.sp;
m.ps = transition_rates.ps;

% Net liquid wealth distributions 
m.nlw_p10_pctl_1 = nlw_pctl.p10(nlw_pctl.lfstat==1);
m.nlw_p25_pctl_1 = nlw_pctl.p25(nlw_pctl.lfstat==1);
m.nlw_p50_pctl_1 = nlw_pctl.p50(nlw_pctl.lfstat==1);
m.nlw_p75_pctl_1 = nlw_pctl.p75(nlw_pctl.lfstat==1);
m.nlw_p90_pctl_1 = nlw_pctl.p90(nlw_pctl.lfstat==1);

m.nlw_p10_pctl_2 = nlw_pctl.p10(nlw_pctl.lfstat==2);
m.nlw_p25_pctl_2 = nlw_pctl.p25(nlw_pctl.lfstat==2);
m.nlw_p50_pctl_2 = nlw_pctl.p50(nlw_pctl.lfstat==2);
m.nlw_p75_pctl_2 = nlw_pctl.p75(nlw_pctl.lfstat==2);
m.nlw_p90_pctl_2 = nlw_pctl.p90(nlw_pctl.lfstat==2);

m.nlw_p10_pctl_3 = nlw_pctl.p10(nlw_pctl.lfstat==3);
m.nlw_p25_pctl_3 = nlw_pctl.p25(nlw_pctl.lfstat==3);
m.nlw_p50_pctl_3 = nlw_pctl.p50(nlw_pctl.lfstat==3);
m.nlw_p75_pctl_3 = nlw_pctl.p75(nlw_pctl.lfstat==3);
m.nlw_p90_pctl_3 = nlw_pctl.p90(nlw_pctl.lfstat==3);

% Share with negative net liquid wealth
m.nlw_share_leq0_1 = nlw_pctl.nlw_share_leq0(nlw_pctl.lfstat==1); 
m.nlw_share_leq0_2 = nlw_pctl.nlw_share_leq0(nlw_pctl.lfstat==2); 
m.nlw_share_leq0_3 = nlw_pctl.nlw_share_leq0(nlw_pctl.lfstat==3); 

% Store the corresponding ECDF for each labor
% force status for convenience in estimation
m.nlw_p10_ecdf_1 = .10;
m.nlw_p25_ecdf_1 = .25;
m.nlw_p50_ecdf_1 = .50;
m.nlw_p75_ecdf_1 = .75;
m.nlw_p90_ecdf_1 = .90;

m.nlw_p10_ecdf_2 = .10;
m.nlw_p25_ecdf_2 = .25;
m.nlw_p50_ecdf_2 = .50;
m.nlw_p75_ecdf_2 = .75;
m.nlw_p90_ecdf_2 = .90;

m.nlw_p10_ecdf_3 = .10;
m.nlw_p25_ecdf_3 = .25;
m.nlw_p50_ecdf_3 = .50;
m.nlw_p75_ecdf_3 = .75;
m.nlw_p90_ecdf_3 = .90;

% Liquid wealth distributions 
m.lqw_p10_pctl_1 = lqw_pctl.p10(lqw_pctl.lfstat==1);
m.lqw_p25_pctl_1 = lqw_pctl.p25(lqw_pctl.lfstat==1);
m.lqw_p50_pctl_1 = lqw_pctl.p50(lqw_pctl.lfstat==1);
m.lqw_p75_pctl_1 = lqw_pctl.p75(lqw_pctl.lfstat==1);
m.lqw_p90_pctl_1 = lqw_pctl.p90(lqw_pctl.lfstat==1);

m.lqw_p10_pctl_2 = lqw_pctl.p10(lqw_pctl.lfstat==2);
m.lqw_p25_pctl_2 = lqw_pctl.p25(lqw_pctl.lfstat==2);
m.lqw_p50_pctl_2 = lqw_pctl.p50(lqw_pctl.lfstat==2);
m.lqw_p75_pctl_2 = lqw_pctl.p75(lqw_pctl.lfstat==2);
m.lqw_p90_pctl_2 = lqw_pctl.p90(lqw_pctl.lfstat==2);

m.lqw_p10_pctl_3 = lqw_pctl.p10(lqw_pctl.lfstat==3);
m.lqw_p25_pctl_3 = lqw_pctl.p25(lqw_pctl.lfstat==3);
m.lqw_p50_pctl_3 = lqw_pctl.p50(lqw_pctl.lfstat==3);
m.lqw_p75_pctl_3 = lqw_pctl.p75(lqw_pctl.lfstat==3);
m.lqw_p90_pctl_3 = lqw_pctl.p90(lqw_pctl.lfstat==3);

% Share with zero liquid wealth
m.lqw_share_leq0_1 = lqw_pctl.lqw_share_leq0(lqw_pctl.lfstat==1); 
m.lqw_share_leq0_2 = lqw_pctl.lqw_share_leq0(lqw_pctl.lfstat==2); 
m.lqw_share_leq0_3 = lqw_pctl.lqw_share_leq0(lqw_pctl.lfstat==3); 

% Store the corresponding ECDF for each labor
% force status for convenience in estimation
m.lqw_p10_ecdf_1 = .10;
m.lqw_p25_ecdf_1 = .25;
m.lqw_p50_ecdf_1 = .50;
m.lqw_p75_ecdf_1 = .75;
m.lqw_p90_ecdf_1 = .90;

m.lqw_p10_ecdf_2 = .10;
m.lqw_p25_ecdf_2 = .25;
m.lqw_p50_ecdf_2 = .50;
m.lqw_p75_ecdf_2 = .75;
m.lqw_p90_ecdf_2 = .90;

m.lqw_p10_ecdf_3 = .10;
m.lqw_p25_ecdf_3 = .25;
m.lqw_p50_ecdf_3 = .50;
m.lqw_p75_ecdf_3 = .75;
m.lqw_p90_ecdf_3 = .90;

% Income distribution
m.ern_p10_pctl_2 = ern_pctl.p10(ern_pctl.lfstat==2);
m.ern_p25_pctl_2 = ern_pctl.p25(ern_pctl.lfstat==2);
m.ern_p50_pctl_2 = ern_pctl.p50(ern_pctl.lfstat==2);
m.ern_p75_pctl_2 = ern_pctl.p75(ern_pctl.lfstat==2);
m.ern_p90_pctl_2 = ern_pctl.p90(ern_pctl.lfstat==2);

m.ern_p10_pctl_3 = ern_pctl.p10(ern_pctl.lfstat==3);
m.ern_p25_pctl_3 = ern_pctl.p25(ern_pctl.lfstat==3);
m.ern_p50_pctl_3 = ern_pctl.p50(ern_pctl.lfstat==3);
m.ern_p75_pctl_3 = ern_pctl.p75(ern_pctl.lfstat==3);
m.ern_p90_pctl_3 = ern_pctl.p90(ern_pctl.lfstat==3);

% Corresponding ECDF
m.ern_p10_ecdf_2 = .10;
m.ern_p25_ecdf_2 = .25;
m.ern_p50_ecdf_2 = .50;
m.ern_p75_ecdf_2 = .75;
m.ern_p90_ecdf_2 = .90;

m.ern_p10_ecdf_3 = .10;
m.ern_p25_ecdf_3 = .25;
m.ern_p50_ecdf_3 = .50;
m.ern_p75_ecdf_3 = .75;
m.ern_p90_ecdf_3 = .90;

% Within labor form log-earnings parameters
m.lnern_avg_2 = lnern.avg(lnern.lfstat==2);
m.lnern_std_2 = lnern.std(lnern.lfstat==2);
m.lnern_rho_2 = lnern.rho(lnern.lfstat==2);

m.lnern_avg_3 = lnern.avg(lnern.lfstat==3);
m.lnern_std_3 = lnern.std(lnern.lfstat==3);
m.lnern_rho_3 = lnern.rho(lnern.lfstat==3);

% Between labor form log-earnings change
m.dlnern_p50_ps = dlnern_ps.p50;
m.dlnern_p50_sp = dlnern_sp.p50;
m.dlnern_avg_ps = dlnern_ps.avg;
m.dlnern_avg_sp = dlnern_sp.avg;

% Cluster-specific destruction rate 
m.pu_1 = pu_cl.pu(pu_cl.cluster_id==1);
m.pu_2 = pu_cl.pu(pu_cl.cluster_id==2);
m.pu_3 = pu_cl.pu(pu_cl.cluster_id==3);
m.pu_4 = pu_cl.pu(pu_cl.cluster_id==4);

m.su_1 = su_cl.su(su_cl.cluster_id==1);
m.su_2 = su_cl.su(su_cl.cluster_id==2);
m.su_3 = su_cl.su(su_cl.cluster_id==3);
m.su_4 = su_cl.su(su_cl.cluster_id==4);

% Cluster-specific log earnings distribution
m.lnern_avg_2_1 = lnern_cl.avg(lnern_cl.lfstat==2 & lnern_cl.cluster_id==1);
m.lnern_avg_2_2 = lnern_cl.avg(lnern_cl.lfstat==2 & lnern_cl.cluster_id==2);
m.lnern_avg_2_3 = lnern_cl.avg(lnern_cl.lfstat==2 & lnern_cl.cluster_id==3);
m.lnern_avg_2_4 = lnern_cl.avg(lnern_cl.lfstat==2 & lnern_cl.cluster_id==4);

m.lnern_std_2_1 = lnern_cl.std(lnern_cl.lfstat==2 & lnern_cl.cluster_id==1);
m.lnern_std_2_2 = lnern_cl.std(lnern_cl.lfstat==2 & lnern_cl.cluster_id==2);
m.lnern_std_2_3 = lnern_cl.std(lnern_cl.lfstat==2 & lnern_cl.cluster_id==3);
m.lnern_std_2_4 = lnern_cl.std(lnern_cl.lfstat==2 & lnern_cl.cluster_id==4);

m.lnern_avg_3_1 = lnern_cl.avg(lnern_cl.lfstat==3 & lnern_cl.cluster_id==1);
m.lnern_avg_3_2 = lnern_cl.avg(lnern_cl.lfstat==3 & lnern_cl.cluster_id==2);
m.lnern_avg_3_3 = lnern_cl.avg(lnern_cl.lfstat==3 & lnern_cl.cluster_id==3);
m.lnern_avg_3_4 = lnern_cl.avg(lnern_cl.lfstat==3 & lnern_cl.cluster_id==4);

m.lnern_std_3_1 = lnern_cl.std(lnern_cl.lfstat==3 & lnern_cl.cluster_id==1);
m.lnern_std_3_2 = lnern_cl.std(lnern_cl.lfstat==3 & lnern_cl.cluster_id==2);
m.lnern_std_3_3 = lnern_cl.std(lnern_cl.lfstat==3 & lnern_cl.cluster_id==3);
m.lnern_std_3_4 = lnern_cl.std(lnern_cl.lfstat==3 & lnern_cl.cluster_id==4);

save('store/moments','-struct','m');


%% Exogenous inputs taken from data. 

K = 4; 

% Household income function
inc_f = readtable('dat/inc_function.csv');

% Data specific to earning cluster
% cl_lqw = readtable('dat/cluster_lqw.csv');
cl_nlw = readtable('dat/cluster_nlw.csv');
cl_cnt = readtable('dat/cluster_cnt.csv');

cl_ern_all = readtable('dat/cluster_ern_all.csv');
cl_inc_all = readtable('dat/cluster_inc_all.csv');

% Data specific to each cluster
s.N = zeros(K,1);

s.ern_p50 = zeros(K,1);
s.inc_p50 = zeros(K,1);

s.amin = zeros(K,1);
s.amax = zeros(K,1);

s.cst = zeros(3,K); 
s.slp = zeros(3,K); 

for k = 1:K
    
	s.N(k) = cl_cnt.N(cl_cnt.cluster_id==k);
	
	s.ern_p50(k) = cl_ern_all.ern(cl_ern_all.cluster_id==k); 
	s.inc_p50(k) = cl_inc_all.inc(cl_inc_all.cluster_id==k); 

	s.amin(k) = cl_nlw.amin(cl_nlw.cluster_id==k); 
	s.amax(k) = cl_nlw.amax(cl_nlw.cluster_id==k);

	s.cst(1,k) = inc_f.b0(inc_f.lfstat==1 & inc_f.cluster_id==k);
	s.cst(2,k) = inc_f.b0(inc_f.lfstat==2 & inc_f.cluster_id==k);   
	s.cst(3,k) = inc_f.b0(inc_f.lfstat==3 & inc_f.cluster_id==k);

	s.slp(1,k) = NaN;   
	s.slp(2,k) = inc_f.b1(inc_f.lfstat==2 & inc_f.cluster_id==k);
	s.slp(3,k) = inc_f.b1(inc_f.lfstat==3 & inc_f.cluster_id==k);

end

save('store/inputs','-struct','s');
