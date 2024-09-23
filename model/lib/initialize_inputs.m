function p = initialize_inputs(K,path_to_main)
% Declare all exogenous inputs and settings 

if nargin<2
    inputs_file = 'store/inputs';
else
    inputs_file = [path_to_main,'/store/inputs'];
end

load(inputs_file,'amin','amax','ern_p50','inc_p50','N','cst','slp');

p = cell(K,1);

for k = 1:K
    
% Cluster characteristics
p{k}.k = k;                     % cluster ID
p{k}.N = N(k);                  % cluster k: number of workers 
p{k}.ern_p50 = ern_p50(k);      % cluster k: median earnings 
p{k}.inc_p50 = inc_p50(k);      % cluster k: median household income

% Asset grids
p{k}.na = 80;
p{k}.na2 = 5*p{k}.na; % thinner grid for interpolation

% p{k}.a_lb = 0.0;
p{k}.a_lb = amin(k);
% p{k}.a_lb = -p{k}.inc_p50*3*.74; 

% Note. I use a similar rationale as in Kaplan and Violante (2014)
% for the borrowing limit: 74% of quarterly household income.
% (74% comes from the SCF asking households about their 'total
% credit limit' as a ratio to quarterly household income.) I use
% the median household income in each cluster as an anchoring
% point.

% p{k}.a_ub = min(p{k}.a_lb + p{k}.na*p{k}.ern_p50/2,amax(k));
p{k}.a_ub = amax(k);

p{k}.a = linspace(p{k}.a_lb,p{k}.a_ub,p{k}.na)';
p{k}.a2 = linspace(p{k}.a_lb,p{k}.a_ub,p{k}.na2)';

% Income grid sizes
p{k}.ny = 51;
p{k}.nw = 51;
 
% Rate of returns on assets [0.0167 is the average risk-adjusted
% after-tax real returns in SCF for net worth from Kaplan and
% Violante (2014)]
p{k}.r = 0;   
% p{k}.r = (1 + 0.0167)^(1/12) - 1;   

% Utility function
p{k}.crra = 1.0;
% p{k}.crra = 3/2;

if p{k}.crra==1.0
    p{k}.u = @(c) (c>0).*log(c) - (c<=0)*1e9;
else
    p{k}.u = @(c) (c>0).*((c.^(1 - p{k}.crra))/(1 - p{k}.crra)) - (c<=0)*1e9;
end

% UI policy
p{k}.T_p = 6;           % duration (months)
p{k}.b_rep_rate = 0.5;  % replacement rate
p{k}.b_max = 2000;      % cap on monthly benefit payments

% Note: 2000 is approximately 4.5 x $450 ($450 is about the max
% weekly benefits amount). Search "Significant Provisions of
% State Unemployment Insurance Laws" for detailed tables.
               
p{k}.b_p = @(w) min(p{k}.b_rep_rate*w,p{k}.b_max);

% Household income function
p{k}.Yu = exp(cst(1,k));
p{k}.Yp = @(y) exp(cst(2,k) + slp(2,k)*log(y)); 
p{k}.Ys = @(y) exp(cst(3,k) + slp(3,k)*log(y));

end    
