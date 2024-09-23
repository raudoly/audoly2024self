function [pn,flag] = simulate_panel(tQ,p)
% Simulate panel of workers conditional on optimal decisions. 
% tQ    Aggregate transition matrix.
% p     Structure of model inputs.

rng(12041961);      % set seed
pn.T = 48;          % simulation length (months)    

% Stationary distribution of workers
[dG,tQ,flag] = get_statio_dist(tQ);

if flag 
    % Exit procedure if can't find stationary
    % equilibrium.
    return;
end

% Dictionaries: mapping from aggregate states to
% income, wealth, etc.
ns = size(tQ,1);

lfs_dict = [...
    2*ones(p.na*p.nw,1);...                 paid-employed
    3*ones(p.na*p.ny,1);...                 self-employed
    1*ones(ns-p.na*(p.nw+p.ny),1);...       unemployed (on benefits or not)
    ];

ern_dict = [...
    kron(p.w,ones(p.na,1));...              paid-employed
    kron(p.y,ones(p.na,1));...              self-employed
    NaN*ones(ns - p.na*(p.nw+p.ny),1);...   unemployed: no earnings
    ];

nlw_dict = repmat(p.a,ns/p.na,1);

% Pre-allocate simulation arrays
state = zeros(p.N,pn.T);

pn.lfs = zeros(p.N,pn.T);
pn.ern = zeros(p.N,pn.T); 
pn.nlw = zeros(p.N,pn.T);

pn.cluster_id = p.k*ones(p.N,pn.T,'int8');


% Initial states drawn from stationary distribution
x_grid = cumsum(dG);  
s_grid = transpose(1:ns);
dice = rand(p.N,1);

sel_states = dG>eps('double'); % select states with density>0, else itp complains

if sum(sel_states)<2
    flag = true;
    return;
end

itp = griddedInterpolant(x_grid(sel_states),s_grid(sel_states),'next','nearest');
state(:,1) = itp(dice); 

% Fill in correponding earnings, assets, etc.
pn.lfs(:,1) = lfs_dict(state(:,1));
pn.ern(:,1) = ern_dict(state(:,1));
pn.nlw(:,1) = nlw_dict(state(:,1));

% Memory for spell variables
pn.spell_num = ones(p.N,pn.T);
pn.spell_dur = ones(p.N,pn.T);
pn.spell_lnern = [log(pn.ern(:,1)) zeros(p.N,pn.T-1)];

% Interpolation object for state next period
itp_Q = cell(ns,1);

for k = 1:ns
    coltQ = full(tQ(:,k));
    x_grid = cumsum(coltQ);
    sel_states = coltQ>eps('double'); % Again only states with positive density
    itp_Q{k} = griddedInterpolant(x_grid(sel_states),s_grid(sel_states),'next','nearest');
end
    
% Simulate panel
for t = 2:pn.T

    % shock and state next period
    dice = rand(p.N,1);

    for k = 1:ns
        previous_state = state(:,t-1)==k; 
        if any(previous_state)
            state(previous_state,t) = itp_Q{k}(dice(previous_state));
        end
    end
    
    % implied income, assets, etc.
    pn.lfs(:,t) = lfs_dict(state(:,t));
    pn.ern(:,t) = ern_dict(state(:,t));
    pn.nlw(:,t) = nlw_dict(state(:,t));

    % spell characteristics
    same_spell = pn.lfs(:,t)==pn.lfs(:,t-1);

    pn.spell_num(~same_spell,t) = pn.spell_num(~same_spell,t-1) + 1;
    pn.spell_dur(~same_spell,t) = 1;
    pn.spell_lnern(~same_spell,t) = log(pn.ern(~same_spell,t));

    pn.spell_num(same_spell,t) = pn.spell_num(same_spell,t-1);
    pn.spell_dur(same_spell,t) = pn.spell_dur(same_spell,t-1) + 1; 
    pn.spell_lnern(same_spell,t) = pn.spell_lnern(same_spell,t-1) + log(pn.ern(same_spell,t));

end

% Copy spell info back in time
for t = pn.T-1:-1:1
    same_spell = pn.lfs(:,t)==pn.lfs(:,t+1);
    pn.spell_dur(same_spell,t) = pn.spell_dur(same_spell,t+1);
    pn.spell_lnern(same_spell,t) = pn.spell_lnern(same_spell,t+1);
end
