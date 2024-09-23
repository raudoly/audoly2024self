function m = calculate_moments(pn,mdat)
% Compute moments from simulated model. Coded individually to
% select ones to match. 

T = size(pn.lfs,2);

% Transition indicators
up = pn.lfs(:,1:T-1)==1 & pn.lfs(:,2:T)==2;
us = pn.lfs(:,1:T-1)==1 & pn.lfs(:,2:T)==3;
pu = pn.lfs(:,1:T-1)==2 & pn.lfs(:,2:T)==1;
su = pn.lfs(:,1:T-1)==3 & pn.lfs(:,2:T)==1;
ps = pn.lfs(:,1:T-1)==2 & pn.lfs(:,2:T)==3;
sp = pn.lfs(:,1:T-1)==3 & pn.lfs(:,2:T)==2;

% Transition rates 
m.up = mean(up(pn.lfs(:,1:T-1)==1));
m.us = mean(us(pn.lfs(:,1:T-1)==1));
m.pu = mean(pu(pn.lfs(:,1:T-1)==2));
m.su = mean(su(pn.lfs(:,1:T-1)==3));
m.ps = mean(ps(pn.lfs(:,1:T-1)==2));
m.sp = mean(sp(pn.lfs(:,1:T-1)==3));

% Job/business destruction rate, by cluster
m.pu_1 = mean(pu(pn.lfs(:,1:T-1)==2 & pn.cluster_id(:,1:T-1)==1));
m.pu_2 = mean(pu(pn.lfs(:,1:T-1)==2 & pn.cluster_id(:,1:T-1)==2));
m.pu_3 = mean(pu(pn.lfs(:,1:T-1)==2 & pn.cluster_id(:,1:T-1)==3));
m.pu_4 = mean(pu(pn.lfs(:,1:T-1)==2 & pn.cluster_id(:,1:T-1)==4));

m.su_1 = mean(su(pn.lfs(:,1:T-1)==3 & pn.cluster_id(:,1:T-1)==1));
m.su_2 = mean(su(pn.lfs(:,1:T-1)==3 & pn.cluster_id(:,1:T-1)==2));
m.su_3 = mean(su(pn.lfs(:,1:T-1)==3 & pn.cluster_id(:,1:T-1)==3));
m.su_4 = mean(su(pn.lfs(:,1:T-1)==3 & pn.cluster_id(:,1:T-1)==4));

% Asset distributions: percentiles
m.nlw_p10_pctl_1 = quantile(pn.nlw(pn.lfs==1),.10); 
m.nlw_p25_pctl_1 = quantile(pn.nlw(pn.lfs==1),.25);
m.nlw_p50_pctl_1 = quantile(pn.nlw(pn.lfs==1),.50);
m.nlw_p75_pctl_1 = quantile(pn.nlw(pn.lfs==1),.75);
m.nlw_p90_pctl_1 = quantile(pn.nlw(pn.lfs==1),.90);

m.nlw_p10_pctl_2 = quantile(pn.nlw(pn.lfs==2),.10); 
m.nlw_p25_pctl_2 = quantile(pn.nlw(pn.lfs==2),.25);
m.nlw_p50_pctl_2 = quantile(pn.nlw(pn.lfs==2),.50);
m.nlw_p75_pctl_2 = quantile(pn.nlw(pn.lfs==2),.75);
m.nlw_p90_pctl_2 = quantile(pn.nlw(pn.lfs==2),.90);

m.nlw_p10_pctl_3 = quantile(pn.nlw(pn.lfs==3),.10); 
m.nlw_p25_pctl_3 = quantile(pn.nlw(pn.lfs==3),.25);
m.nlw_p50_pctl_3 = quantile(pn.nlw(pn.lfs==3),.50);
m.nlw_p75_pctl_3 = quantile(pn.nlw(pn.lfs==3),.75);
m.nlw_p90_pctl_3 = quantile(pn.nlw(pn.lfs==3),.90);

% Asset distributions: ECDF
m.nlw_p10_ecdf_1 = sim_ecdf(pn.nlw(pn.lfs==1),mdat.nlw_p10_pctl_1); 
m.nlw_p25_ecdf_1 = sim_ecdf(pn.nlw(pn.lfs==1),mdat.nlw_p25_pctl_1);
m.nlw_p50_ecdf_1 = sim_ecdf(pn.nlw(pn.lfs==1),mdat.nlw_p50_pctl_1);
m.nlw_p75_ecdf_1 = sim_ecdf(pn.nlw(pn.lfs==1),mdat.nlw_p75_pctl_1);
m.nlw_p90_ecdf_1 = sim_ecdf(pn.nlw(pn.lfs==1),mdat.nlw_p90_pctl_1);

m.nlw_p10_ecdf_2 = sim_ecdf(pn.nlw(pn.lfs==2),mdat.nlw_p10_pctl_2); 
m.nlw_p25_ecdf_2 = sim_ecdf(pn.nlw(pn.lfs==2),mdat.nlw_p25_pctl_2);
m.nlw_p50_ecdf_2 = sim_ecdf(pn.nlw(pn.lfs==2),mdat.nlw_p50_pctl_2);
m.nlw_p75_ecdf_2 = sim_ecdf(pn.nlw(pn.lfs==2),mdat.nlw_p75_pctl_2);
m.nlw_p90_ecdf_2 = sim_ecdf(pn.nlw(pn.lfs==2),mdat.nlw_p90_pctl_2);

m.nlw_p10_ecdf_3 = sim_ecdf(pn.nlw(pn.lfs==3),mdat.nlw_p10_pctl_3); 
m.nlw_p25_ecdf_3 = sim_ecdf(pn.nlw(pn.lfs==3),mdat.nlw_p25_pctl_3);
m.nlw_p50_ecdf_3 = sim_ecdf(pn.nlw(pn.lfs==3),mdat.nlw_p50_pctl_3);
m.nlw_p75_ecdf_3 = sim_ecdf(pn.nlw(pn.lfs==3),mdat.nlw_p75_pctl_3);
m.nlw_p90_ecdf_3 = sim_ecdf(pn.nlw(pn.lfs==3),mdat.nlw_p90_pctl_3);

% Asset distributions: share with less than zero wealth
m.nlw_share_leq0_1 = mean(pn.nlw(pn.lfs==1)<=0.0);
m.nlw_share_leq0_2 = mean(pn.nlw(pn.lfs==2)<=0.0);
m.nlw_share_leq0_3 = mean(pn.nlw(pn.lfs==3)<=0.0);

% Income distributions: percentiles
m.ern_p10_pctl_2 = quantile(pn.ern(pn.lfs==2),.10); 
m.ern_p25_pctl_2 = quantile(pn.ern(pn.lfs==2),.25);
m.ern_p50_pctl_2 = quantile(pn.ern(pn.lfs==2),.50);
m.ern_p75_pctl_2 = quantile(pn.ern(pn.lfs==2),.75);
m.ern_p90_pctl_2 = quantile(pn.ern(pn.lfs==2),.90);

m.ern_p10_pctl_3 = quantile(pn.ern(pn.lfs==3),.10); 
m.ern_p25_pctl_3 = quantile(pn.ern(pn.lfs==3),.25);
m.ern_p50_pctl_3 = quantile(pn.ern(pn.lfs==3),.50);
m.ern_p75_pctl_3 = quantile(pn.ern(pn.lfs==3),.75);
m.ern_p90_pctl_3 = quantile(pn.ern(pn.lfs==3),.90);

% Income distributions: ECDF
m.ern_p10_ecdf_2 = sim_ecdf(pn.ern(pn.lfs==2),mdat.ern_p10_pctl_2); 
m.ern_p25_ecdf_2 = sim_ecdf(pn.ern(pn.lfs==2),mdat.ern_p25_pctl_2);
m.ern_p50_ecdf_2 = sim_ecdf(pn.ern(pn.lfs==2),mdat.ern_p50_pctl_2);
m.ern_p75_ecdf_2 = sim_ecdf(pn.ern(pn.lfs==2),mdat.ern_p75_pctl_2);
m.ern_p90_ecdf_2 = sim_ecdf(pn.ern(pn.lfs==2),mdat.ern_p90_pctl_2);

m.ern_p10_ecdf_3 = sim_ecdf(pn.ern(pn.lfs==3),mdat.ern_p10_pctl_3); 
m.ern_p25_ecdf_3 = sim_ecdf(pn.ern(pn.lfs==3),mdat.ern_p25_pctl_3);
m.ern_p50_ecdf_3 = sim_ecdf(pn.ern(pn.lfs==3),mdat.ern_p50_pctl_3);
m.ern_p75_ecdf_3 = sim_ecdf(pn.ern(pn.lfs==3),mdat.ern_p75_pctl_3);
m.ern_p90_ecdf_3 = sim_ecdf(pn.ern(pn.lfs==3),mdat.ern_p90_pctl_3);

% Log-earnings stats
lnern = log(pn.ern);

m.lnern_avg_2 = mean(lnern(pn.lfs==2));
m.lnern_avg_3 = mean(lnern(pn.lfs==3));

m.lnern_std_2 = std(lnern(pn.lfs==2));
m.lnern_std_3 = std(lnern(pn.lfs==3));

% Log-earnings stats by cluster
m.lnern_avg_2_1 = mean(lnern(pn.lfs==2 & pn.cluster_id==1));
m.lnern_avg_2_2 = mean(lnern(pn.lfs==2 & pn.cluster_id==2));
m.lnern_avg_2_3 = mean(lnern(pn.lfs==2 & pn.cluster_id==3));
m.lnern_avg_2_4 = mean(lnern(pn.lfs==2 & pn.cluster_id==4));

m.lnern_std_2_1 = std(lnern(pn.lfs==2 & pn.cluster_id==1));
m.lnern_std_2_2 = std(lnern(pn.lfs==2 & pn.cluster_id==2));
m.lnern_std_2_3 = std(lnern(pn.lfs==2 & pn.cluster_id==3));
m.lnern_std_2_4 = std(lnern(pn.lfs==2 & pn.cluster_id==4));

m.lnern_avg_3_1 = mean(lnern(pn.lfs==3 & pn.cluster_id==1));
m.lnern_avg_3_2 = mean(lnern(pn.lfs==3 & pn.cluster_id==2));
m.lnern_avg_3_3 = mean(lnern(pn.lfs==3 & pn.cluster_id==3));
m.lnern_avg_3_4 = mean(lnern(pn.lfs==3 & pn.cluster_id==4));

m.lnern_std_3_1 = std(lnern(pn.lfs==3 & pn.cluster_id==1));
m.lnern_std_3_2 = std(lnern(pn.lfs==3 & pn.cluster_id==2));
m.lnern_std_3_3 = std(lnern(pn.lfs==3 & pn.cluster_id==3));
m.lnern_std_3_4 = std(lnern(pn.lfs==3 & pn.cluster_id==4));

% Income change within spell
lnern_now = lnern(:,13:T);
lnern_lag = lnern(:,1:T-12);

lfs_now = pn.lfs(:,13:T);
lfs_lag = pn.lfs(:,1:T-12);

same_spell = pn.spell_num(:,13:T)==pn.spell_num(:,1:T-12);

m.lnern_rho_2 = corr_xy(lnern_now(lfs_now==2 & same_spell==1),lnern_lag(lfs_lag==2 & same_spell==1));
m.lnern_rho_3 = corr_xy(lnern_now(lfs_now==3 & same_spell==1),lnern_lag(lfs_lag==3 & same_spell==1));

% Income change for direct transitions
lnern_avg = pn.spell_lnern./pn.spell_dur; 
dlnern_avg = lnern_avg(:,2:T) - lnern_avg(:,1:T-1);

sel_trans = ps==1 & pn.spell_dur(:,2:T)>=12 & pn.spell_dur(:,1:T-1)>=12;
m.dlnern_p50_ps = quantile(dlnern_avg(sel_trans),0.50); 
m.dlnern_avg_ps = mean(dlnern_avg(sel_trans)); 

sel_trans = sp==1 & pn.spell_dur(:,2:T)>=12 & pn.spell_dur(:,1:T-1)>=12;
m.dlnern_p50_sp = quantile(dlnern_avg(sel_trans),0.50); 
m.dlnern_avg_sp = mean(dlnern_avg(sel_trans)); 


% --------------------------------
function u = sim_ecdf(simdat,pctl)
% ECDF of data

u = mean(simdat<=pctl);


% -----------------------
function r = corr_xy(x,y)

R = corr([x y]);
r = R(2,1);


