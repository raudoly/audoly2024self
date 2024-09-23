function show_fit(save_it,par,path_to_main)

close all;

if nargin<2
    load('store/params','par');
end

if nargin<3
    path_to_main = '.';
end

%% Inputs
reps = readtable([path_to_main,'/dat/bootstrap_reps.csv']);
dm = load([path_to_main,'/store/moments']);

K = 4;
p = initialize_inputs(K,path_to_main);

for k = 1:K
    p{k} = initialize_parameters(par,p{k});
end

%% Simulate model moments
pn = get_panel_all(par,p);
mm = calculate_moments(pn,dm);

%% Parameters

row_names = {...
    'r',...
    'gamma',...
    'beta',...
    'kappa',...
    'lamb_up',...
    'lamb_us',...
    'lamb_sp',...
    'lamb_ps',...
    'sig_p',...
    'rho_p',...
    'sig_s',...
    'rho_s',...
    };

tab_par_same = [...
    p{1}.r;...
    p{1}.crra;...
    p{1}.beta;...
    p{1}.kappa;...
    p{1}.lamb_up;...
    p{1}.lamb_us;...
    p{1}.lamb_sp;...
    p{1}.lamb_ps;...
    par(17);...
    par(18);...
    par(23);...
    par(24);...
    ];

tab_par_same = array2table(tab_par_same);  
tab_par_same.Properties.RowNames = row_names;
tab_par_same.Properties.VariableNames = {'Value'};

disp('Common parameters:');
disp(tab_par_same);

row_names = {'ern_p50','delt_p','delt_s','mu_p','mu_s'};
col_names = {'cluster_1','cluster_2','cluster_3','cluster_4'};

tab_par_cluster = zeros(length(row_names),K);

for k = 1:K
    tab_par_cluster(:,k) = [...
        p{k}.ern_p50;...
        par(04+p{k}.k);...
        par(08+p{k}.k);...
        par(12+p{k}.k);...
        par(18+p{k}.k);...
    ];
end

tab_par_cluster = array2table(tab_par_cluster);
tab_par_cluster.Properties.RowNames = row_names;
tab_par_cluster.Properties.VariableNames = col_names;

disp('Cluster-specific parameters:');
disp(tab_par_cluster);


%% Transition rates
tr_dat = [dm.up,dm.us,dm.sp,dm.ps,dm.pu,dm.su];
tr_mod = [mm.up,mm.us,mm.sp,mm.ps,mm.pu,mm.su];

tr_dat_ci_lb = quantile([reps.up,reps.us,reps.sp,reps.ps,reps.pu,reps.su],.025);
tr_dat_ci_ub = quantile([reps.up,reps.us,reps.sp,reps.ps,reps.pu,reps.su],.975);

tr_dat_std = std([reps.up,reps.us,reps.sp,reps.ps,reps.pu,reps.su]);

tr_names = {'UP','US','SP','PS','PU','SU'};
var_names = {'model','data','data_std'};

tab_transition_rates = table(tr_mod',tr_dat',tr_dat_std');
tab_transition_rates.Properties.RowNames = tr_names;
tab_transition_rates.Properties.VariableNames = var_names;

disp('Transition Rates');
disp(tab_transition_rates);

fig_transition_rates = plot_fit(...
    [tr_dat;tr_mod],[tr_dat_ci_lb;tr_dat_ci_ub],tr_names,...
    'Transition type','Monthly transition rate');

%% Cluster-specific destruction rates
dr_dat = [dm.pu_1,dm.pu_2,dm.pu_3,dm.pu_4,dm.su_1,dm.su_2,dm.su_3,dm.su_4];
dr_mod = [mm.pu_1,mm.pu_2,mm.pu_3,mm.pu_4,mm.su_1,mm.su_2,mm.su_3,mm.su_4];
dr_rep = [reps.pu_1,reps.pu_2,reps.pu_3,reps.pu_4,reps.su_1,reps.su_2,reps.su_3,reps.su_4];

dr_dat_ci_lb = quantile(dr_rep,.025);
dr_dat_ci_ub = quantile(dr_rep,.975);

dr_dat_std = std(dr_rep);

row_names = { ...
    'PU: Low','PU: Med-Low','PU: Med-High','PU: High',...
    'SU: Low','SU: Med-Low','SU: Med-High','SU: High',...
    };

tab_destruction_rates = table(dr_mod',dr_dat',dr_dat_std');
tab_destruction_rates.Properties.RowNames = row_names;
tab_destruction_rates.Properties.VariableNames = var_names;

disp('Destruction rate type by worker cluster');
disp(tab_destruction_rates);

fig_destruction_rates = plot_fit(...
    [dr_dat;dr_mod],[dr_dat_ci_lb;dr_dat_ci_ub],row_names,...
    'Destruction rate by worker cluster','Monthly destruction rate');
xtickangle(22.5);

%% Wealth distributions
row_names = {...
    'U_p10','U_p25','U_p50','U_p75','U_p90',...
    'P_p10','P_p25','P_p50','P_p75','P_p90',...
    'S_p10','S_p25','S_p50','S_p75','S_p90',...
    };

% Percentiles
nlw_dat = select_nlw_pctl(dm);
nlw_mod = select_nlw_pctl(mm);
nlw_rep = select_nlw_pctl(reps);

nlw_dat_std = std(nlw_rep);

tab_nlw_pctl = table(nlw_mod',nlw_dat',nlw_dat_std');
tab_nlw_pctl.Properties.RowNames = row_names;
tab_nlw_pctl.Properties.VariableNames = var_names;

% Empirical CDF
nlw_dat = select_nlw_ecdf(dm);
nlw_mod = select_nlw_ecdf(mm);
nlw_rep = select_nlw_ecdf(reps);

nlw_dat_std = std(nlw_rep);

tab_nlw_ecdf = table(nlw_mod',nlw_dat',nlw_dat_std');
tab_nlw_ecdf.Properties.RowNames = row_names;
tab_nlw_ecdf.Properties.VariableNames = var_names;

% Share with negative net liquid wealth
nlw_dat = [dm.nlw_share_leq0_1,dm.nlw_share_leq0_2,dm.nlw_share_leq0_3];
nlw_mod = [mm.nlw_share_leq0_1,mm.nlw_share_leq0_2,mm.nlw_share_leq0_3];
nlw_rep = [reps.nlw_share_leq0_1,reps.nlw_share_leq0_2,reps.nlw_share_leq0_3];

row_names = {'U','P','S'};

nlw_dat_std = std(nlw_rep);

tab_nlw_leq0 = table(nlw_mod',nlw_dat',nlw_dat_std');
tab_nlw_leq0.Properties.RowNames = row_names;
tab_nlw_leq0.Properties.VariableNames = var_names;

% Net liquid wealth fit table
disp('Wealth distributions:');
disp(tab_nlw_pctl);
disp(tab_nlw_ecdf);
disp('Share with negative net liquid wealth');
disp(tab_nlw_leq0);

% Figure wealth less than zero
% nlw_dat = [dm.nlw_share_leq0_1,dm.nlw_share_leq0_2,dm.nlw_share_leq0_3];
% nlw_mod = [mm.nlw_share_leq0_1,mm.nlw_share_leq0_2,mm.nlw_share_leq0_3];
% nlw_rep = [reps.nlw_share_leq0_1,reps.nlw_share_leq0_2,reps.nlw_share_leq0_3];
% 
% y = [nlw_dat;nlw_mod];
% ci = [quantile(nlw_rep,.025);quantile(nlw_rep,.975)];
% 
% xlab = 'Labor force status';
% ylab = 'Share of household with net liquid wealth below 0';
% 
% fig_nlw_leq0 = plot_fit(y,ci,row_names,xlab,ylab);
% ylim([.30 .80]);

% Figure ecdf
nlw_dat = [...
    dm.nlw_p25_ecdf_2,dm.nlw_p50_ecdf_2,dm.nlw_p75_ecdf_2,...
    dm.nlw_p25_ecdf_3,dm.nlw_p50_ecdf_3,dm.nlw_p75_ecdf_3,...
    ];

nlw_mod = [...
    mm.nlw_p25_ecdf_2,mm.nlw_p50_ecdf_2,mm.nlw_p75_ecdf_2,...
    mm.nlw_p25_ecdf_3,mm.nlw_p50_ecdf_3,mm.nlw_p75_ecdf_3,...
    ];

nlw_rep = [...
    reps.nlw_p25_ecdf_2,reps.nlw_p50_ecdf_2,reps.nlw_p75_ecdf_2,...
    reps.nlw_p25_ecdf_3,reps.nlw_p50_ecdf_3,reps.nlw_p75_ecdf_3,...
    ];

row_names = {...
    'p25 - P','p50 - P','p75 - P',...
    'p25 - S','p50 - S','p75 - S',...
    };

y = [nlw_dat;nlw_mod];
ci = [quantile(nlw_rep,.025);quantile(nlw_rep,.975)];

xlab = 'Percentile - Labor form';
ylab = 'Empirical CDF of net liquid wealth';

fig_nlw_ecdf = plot_fit(y,ci,row_names,xlab,ylab);
ylim([0.0 1.0]);
% xtickangle(22.5);


%% Earnings distributions
ern_mod = select_income(mm);
ern_dat = select_income(dm);
ern_rep = select_income(reps);

ern_dat_std = std(ern_rep);

row_names = {...
    'P_p10','P_p25','P_p50','P_p75','P_p90',...
    'S_p10','S_p25','S_p50','S_p75','S_p90',...
	};

tab_ern = table(ern_mod',ern_dat',ern_dat_std');
tab_ern.Properties.RowNames = row_names;
tab_ern.Properties.VariableNames = var_names;

disp('Earnings distribution');
disp(tab_ern);

%% Log-earnings stats
lnern_mod = [...
    mm.lnern_avg_2,mm.lnern_avg_3,...
    mm.lnern_std_2,mm.lnern_std_3,...
    mm.lnern_rho_2,mm.lnern_rho_3,...
    ];

lnern_dat = [...
    dm.lnern_avg_2,dm.lnern_avg_3,...
    dm.lnern_std_2,dm.lnern_std_3,...
    dm.lnern_rho_2,dm.lnern_rho_3,...
    ];

lnern_rep = [...
    reps.lnern_avg_2,reps.lnern_avg_3,...
    reps.lnern_std_2,reps.lnern_std_3,...
    reps.lnern_rho_3,reps.lnern_rho_3,...
    ];

lnern_dat_std = std(lnern_rep);

row_names = {'avg. P','avg. S','std. P','std. S','acl. P','acl. S'};

tab_lnern = table(lnern_mod',lnern_dat',lnern_dat_std');
tab_lnern.Properties.RowNames = row_names;
tab_lnern.Properties.VariableNames = var_names;

disp('Log earnings stats');
disp(tab_lnern);

% Corresponding plot
lnern_mod = [...
    mm.lnern_std_2,mm.lnern_std_3,...
    mm.lnern_rho_2,mm.lnern_rho_3,...
    ];

lnern_dat = [...
    dm.lnern_std_2,dm.lnern_std_3,...
    dm.lnern_rho_2,dm.lnern_rho_3,...
    ];

lnern_rep = [...
    reps.lnern_std_2,reps.lnern_std_3,...
    reps.lnern_rho_2,reps.lnern_rho_3,...
    ];

lnern_dat_ci_lb = quantile(lnern_rep,.025);
lnern_dat_ci_ub = quantile(lnern_rep,.975);

xlab = 'Labor form - Summary statistic';
ylab = {'Standard deviation (Std)','12-month autocorrorrelation within spell (Acl)'};

fig_lnern_stats = plot_fit(...
    [lnern_dat;lnern_mod],...
    [lnern_dat_ci_lb;lnern_dat_ci_ub],...
    {'Paid: Std','Self: Std','Paid: Acl', 'Self: Acl'}, xlab, ylab);

%% Log-earnings stats by cluster
lnern_mod = [...
    mm.lnern_avg_2_1,mm.lnern_avg_2_2,mm.lnern_avg_2_3,mm.lnern_avg_2_4,...
    mm.lnern_avg_3_1,mm.lnern_avg_3_2,mm.lnern_avg_3_3,mm.lnern_avg_3_4,...
    ];

lnern_dat = [...
    dm.lnern_avg_2_1,dm.lnern_avg_2_2,dm.lnern_avg_2_3,dm.lnern_avg_2_4,...
    dm.lnern_avg_3_1,dm.lnern_avg_3_2,dm.lnern_avg_3_3,dm.lnern_avg_3_4,...
    ];

lnern_rep = [...
    reps.lnern_avg_2_1,reps.lnern_avg_2_2,reps.lnern_avg_2_3,reps.lnern_avg_2_4,...
    reps.lnern_avg_3_1,reps.lnern_avg_3_2,reps.lnern_avg_3_3,reps.lnern_avg_3_4,...
    ];

lnern_dat_std = std(lnern_rep);

row_names = {...
    'P: Low','P: Med-Low','P: Med-High','P: High',...
    'S: Low','S: Med-Low','S: Med-High','S: High',...
    };

tab_lnern_cluster = table(lnern_mod',lnern_dat',lnern_dat_std');
tab_lnern_cluster.Properties.RowNames = row_names;
tab_lnern_cluster.Properties.VariableNames = var_names;

disp('Log earnings cluster stats');
disp(tab_lnern_cluster);

% Plot 
lnern_dat_ci_lb = quantile(lnern_rep,.025);
lnern_dat_ci_ub = quantile(lnern_rep,.975);

fig_lnern_cluster = plot_fit(...
    [lnern_dat;lnern_mod],...
    [lnern_dat_ci_lb;lnern_dat_ci_ub],...
    row_names,...
    'Labor form by worker cluster',...
    'Average monthly log-earnings');
xtickangle(22.5);


%% Earnings change after transition
dlnern_mod = [mm.dlnern_p50_ps,mm.dlnern_p50_sp];
dlnern_dat = [dm.dlnern_p50_ps,dm.dlnern_p50_sp];

dlnern_rep = [reps.dlnern_p50_ps,reps.dlnern_p50_sp];

dlnern_dat_std = std(dlnern_rep);

row_names = {'p50 - PS','p50 - SP'};

tab_dlnern_trans = table(dlnern_mod',dlnern_dat',dlnern_dat_std');
tab_dlnern_trans.Properties.RowNames = row_names;
tab_dlnern_trans.Properties.VariableNames = var_names;

disp('Earnings growth with voluntary change of status:');
disp(tab_dlnern_trans);
    
dlnern_dat_ci_lb = quantile(dlnern_rep,.025);
dlnern_dat_ci_ub = quantile(dlnern_rep,.975);

fig_dlnern_trans = plot_fit( ...
    [dlnern_dat;dlnern_mod], ...
    [dlnern_dat_ci_lb;dlnern_dat_ci_ub], ...
    {'PS','SP'}, ...
    'Transition type','Median log-earnings change across spell');
ylim([-0.4 0.4]);


%% Save output

if save_it

    % Plots
    fig_fmt = 'png';

    saveas(fig_transition_rates,'../plots/fit_transition_rates',fig_fmt); 
    saveas(fig_destruction_rates,'../plots/fit_destruction_rates',fig_fmt);
    % saveas(fig_nlw_leq0,'../plots/fit_nlw_leq0',fig_fmt);
    saveas(fig_nlw_ecdf,'../plots/fit_nlw_ecdf',fig_fmt);
    saveas(fig_lnern_stats,'../plots/fit_lnern_stats',fig_fmt);
    saveas(fig_lnern_cluster,'../plots/fit_lnern_cluster',fig_fmt);
    saveas(fig_dlnern_trans,'../plots/fit_dlnern_trans',fig_fmt);

    % Tables
    wb_name = '../tables/02_model_fit.xlsx';
    
    writetable(tab_par_same,wb_name,'WriteRowNames',1,'Sheet','par_same');
    writetable(tab_par_cluster,wb_name,'WriteRowNames',1,'Sheet','par_cluster');
    writetable(tab_transition_rates,wb_name,'WriteRowNames',1,'Sheet','transition_rates');
    writetable(tab_destruction_rates,wb_name,'WriteRowNames',1,'Sheet','destruction_rates');
    writetable(tab_nlw_ecdf,wb_name,'WriteRowNames',1,'Sheet','nlw_ecdf');
    writetable(tab_nlw_pctl,wb_name,'WriteRowNames',1,'Sheet','nlw_pctl');
    writetable(tab_nlw_leq0,wb_name,'WriteRowNames',1,'Sheet','nlw_leq0');
    writetable(tab_lnern,wb_name,'WriteRowNames',1,'Sheet','lnern');
    writetable(tab_lnern_cluster,wb_name,'WriteRowNames',1,'Sheet','lnern_cluster');
    writetable(tab_dlnern_trans,wb_name,'WriteRowNames',1,'Sheet','dlnern_trans');

end

%--------------------------------------------------------------------------
function v = select_nlw_pctl(m)

v = [...
    m.nlw_p10_pctl_1,...
    m.nlw_p25_pctl_1,...
    m.nlw_p50_pctl_1,...
    m.nlw_p75_pctl_1,...
    m.nlw_p90_pctl_1,...
    m.nlw_p10_pctl_2,...
    m.nlw_p25_pctl_2,...
    m.nlw_p50_pctl_2,...
    m.nlw_p75_pctl_2,...
    m.nlw_p90_pctl_2,...
    m.nlw_p10_pctl_3,...
    m.nlw_p25_pctl_3,...
    m.nlw_p50_pctl_3,...
    m.nlw_p75_pctl_3,...
    m.nlw_p90_pctl_3,...
    ];

function v = select_nlw_ecdf(m)

v = [...
    m.nlw_p10_ecdf_1,...
    m.nlw_p25_ecdf_1,...
    m.nlw_p50_ecdf_1,...
    m.nlw_p75_ecdf_1,...
    m.nlw_p90_ecdf_1,...
    m.nlw_p10_ecdf_2,...
    m.nlw_p25_ecdf_2,...
    m.nlw_p50_ecdf_2,...
    m.nlw_p75_ecdf_2,...
    m.nlw_p90_ecdf_2,...
    m.nlw_p10_ecdf_3,...
    m.nlw_p25_ecdf_3,...
    m.nlw_p50_ecdf_3,...
    m.nlw_p75_ecdf_3,...
    m.nlw_p90_ecdf_3,...
    ];

function v = select_income(m)

v = [...
    m.ern_p10_pctl_2,...
    m.ern_p25_pctl_2,...
    m.ern_p50_pctl_2,...
    m.ern_p75_pctl_2,...
    m.ern_p90_pctl_2,...
    m.ern_p10_pctl_3,...
    m.ern_p25_pctl_3,...
    m.ern_p50_pctl_3,...
    m.ern_p75_pctl_3,...
    m.ern_p90_pctl_3,...
	];

function f = plot_fit(y,ci,x_names,x_lab,y_lab)
% Plot fit, reporting CI around data moments.

x = 1:length(x_names);

y_dat = y(1,:);
y_mod = y(2,:);

ci_lb = ci(1,:);
ci_ub = ci(2,:);

y_neg = abs(ci_lb - y_dat);
y_pos = abs(ci_ub - y_dat);

f = figure;
eb = errorbar(x,y_dat,y_neg,y_pos,'+');
eb.LineWidth = 1.6;
eb.Color = 'blue';

hold('on');
plot(x,y_mod,'rs','MarkerSize',8,'MarkerEdgeColor','red','MarkerFaceColor','red');
xlim([0,length(x)+1]);
set(gca,'XTick',0:length(x)+1,'XTickLabel',[{''},x_names,{''}]);
hold('off');

% xtickangle(45);
legend('Data (95% CI)','Model','Location','best');

xlabel(x_lab);
ylabel(y_lab);


% function f = plot_fit_bar(xCat,yBars,x_title,y_lab)
% % Wrapper around bar function to display model fit
% 
% xCat = categorical(xCat);
% 
% f = figure;
% barh(xCat,yBars);
% xlabel(x_title);
% ylabel(y_lab);
% legend('Data','Model','Location','Best'); 
