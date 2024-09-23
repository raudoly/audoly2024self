% Master file to replicate results in paper.

close all; 
clearvars; 
clc;

addpath('./lib/');      % Function library
save_it = true;         % Save model output?

%% Build inputs from data

build_inputs;

%% Fit to moments

show_fit(save_it);

%% Experiment: UI-align
b_s = .5; % Replacement rate 

% Compute tax rate balancing budget 
govbal = @(x) gov_balance_ui(x,b_s,'align');
tau_s = fzero(govbal,[.0 .1],optimset('Display','iter','TolX',1e-10)); 

save('store/params_ui_align','b_s','tau_s');

%% Analysis: UI-align
load('store/params_ui_align');
tau_s = repmat(tau_s,4,1);
decompose_welfare_ui(tau_s,b_s,'align',save_it);

%% Experiment: UI-Progressive
govbal = @(x) gov_balance_ui(x,b_s,'progressive');
tau_s = fzero(govbal,[.0 .1],optimset('Display','iter','TolX',1e-10));

save('store/params_ui_progressive','b_s','tau_s');

%% Analysis - UI-progressive
load('store/params_ui_progressive');
tau_s = repmat(tau_s,4,1);
decompose_welfare_ui(tau_s,b_s,'progressive',save_it);

%% Experiment: UI-within

K = 4;
tau_s = zeros(4,1);
load('store/params','par');
p = initialize_inputs(K);

for k = 1:K
    p{k} = initialize_inputs_pol(p{k});
    p{k} = initialize_parameters(par,p{k});
    govbal = @(x) gov_balance_ui_cluster(x,b_s,'progressive',p{k});
    tau_s(k) = fzero(govbal,[.0 .1],optimset('Display','iter','TolX',1e-10));
end

save('store/params_ui_within','b_s','tau_s');

%% Analysis: UI-within

load('store/params_ui_within');
decompose_welfare_ui(tau_s,b_s,'within',save_it);


%% Experiment: unconditional transfer

B = gov_balance_bsl; % Savings from removing UI expenditures.

b = 100:100:200;  
tau = zeros(size(b));

for k = 1:length(b)
    govbal = @(x) gov_balance_tnt(b(k),x) - B;
    tau(k) = fzero(govbal,[.0 .1],optimset('Display','iter','TolX',1e-10));
end

save('store/params_transfer','tau','b');

%% Analysis: cash transfer

load('store/params_transfer');

for k = 1:length(tau)
    decompose_welfare_tnt(b(k),tau(k),save_it);
end


%% Figures

fig_fmt = 'png';
fig_size = {'units','inches','position',[0 0 8 5]};
subfig_size = {'units','inches','position',[0 0 7 7]};
fig_font = {'fontsize',12};

pol_ui_a = load('store/policy_align_b_0.5.mat');
pol_ui_p = load('store/policy_progressive_b_0.5.mat');
pol_ui_w = load('store/policy_within_b_0.5.mat');

K = 4;

% Welfare
cash_grant = zeros(3,K);

for k = 1:K
    cash_grant(1,k) = pol_ui_a.wf{'cg',k}/pol_ui_a.wf{'ern_p50',k};
    cash_grant(2,k) = pol_ui_p.wf{'cg',k}/pol_ui_p.wf{'ern_p50',k};
    cash_grant(3,k) = pol_ui_w.wf{'cg',k}/pol_ui_w.wf{'ern_p50',k};
end

fig = figure;
ax = axes();
b = bar(1:K,cash_grant);

xlabel(ax,'Worker earnings group');
ylabel(ax,{'Compensating cash grant','(share of p50 earnings)'});
set(ax,'XTickLabel',{'Low','Med-Low','Med-High','High'});
set(ax,fig_font{:});

legend(b,'Align (UI-A)','Progressive (UI-P)','Within (UI-W)','Location','best');

set(fig,fig_size{:}); 
print(fig,'../plots/welfare_cash_grant',['-d' fig_fmt]);

%% Ratio contribution to benefits
cont_ben = [...
    pol_ui_a.ben_and_cont{'ratio_ben_to_cont',:};...
    pol_ui_p.ben_and_cont{'ratio_ben_to_cont',:};...
    pol_ui_w.ben_and_cont{'ratio_ben_to_cont',:};...
    ];

fig = figure;
ax = axes();
b = bar(1:K,cont_ben);

xlabel(ax,'Worker earnings group');
ylabel(ax,{'Ratio benefits to contributions'});
yline(ax,1.0);
set(ax,'XTickLabel',{'Low','Med-Low','Med-High','High'});
set(ax,fig_font{:});

legend(b,'Align (UI-A)','Progressive (UI-P)','Within (UI-W)','Location','best');

set(fig,fig_size{:}); 
print(fig,'../plots/welfare_ratio_ben_to_cont',['-d' fig_fmt]);

%% Flow transition rates

transitions = {'UP','US','PU','SU','PS','SP'};

for j = 1:length(transitions)

row_name = transitions{j};

plot_array = zeros(3,K);

for k = 1:K
    col_name_bsl = ['bsl_',num2str(k)];
    col_name_pol = ['pol_',num2str(k)];
    
    plot_array(1,k) = 100*(pol_ui_a.transitions{row_name,col_name_pol}/pol_ui_a.transitions{row_name,col_name_bsl} - 1);
    plot_array(2,k) = 100*(pol_ui_p.transitions{row_name,col_name_pol}/pol_ui_p.transitions{row_name,col_name_bsl} - 1);
    plot_array(3,k) = 100*(pol_ui_w.transitions{row_name,col_name_pol}/pol_ui_w.transitions{row_name,col_name_bsl} - 1);
end

fig = figure;
ax = axes();
b = bar(1:K,plot_array);

xlabel(ax,'Worker earnings group');
ylabel(ax,{[row_name,' transition rate'],'% change relative to baseline'});
set(ax,'XTickLabel',{'Low','Med-Low','Med-High','High'});
set(ax,fig_font{:});

legend(b,'Align (UI-A)','Progressive (UI-P)','Within (UI-W)','Location','best');

set(fig,subfig_size{:}); 
print(fig,['../plots/policy_',lower(num2str(row_name))],['-d' fig_fmt]);

end
