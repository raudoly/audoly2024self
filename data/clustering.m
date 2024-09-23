% Create clustering groups

clearvars;
clc;

find_clusters = true;
figfmt = '.png';
data_dir = '~/data/sipp/kmeans';

% Load data
input_data = readtable([data_dir filesep 'input_data.csv']);
percentile_data = readtable([data_dir filesep 'ern_pctl.csv']);

%% Kmeans optimization for alternative K  --------

filename = [data_dir filesep 'kmeans_results']; 

K = 10;
X = input_data{:,2:end};

if find_clusters
    
    rng(19741129);
    max_iter = 1000;
    n_init = 10000;
    
    results = cell(K,1);
    
    for k = 1:K

        [cluster_id,C,sumd] = kmeans(X,k,'Replicates',n_init,'MaxIter',max_iter);
        
        results{k,1}.cluster_id = cluster_id;
        results{k,1}.C = C;
        results{k,1}.sumd = sumd;
        
        fprintf('Done with K = %d. Distance = %.3e\n',k,sum(sumd));
        
    end
    
    save(filename,'results');

else

    load(filename);

end

%% Plot choice of K stats ------------

close all;
line_width = 1.2;
marker_size = 6;

color_1 = [0 0.4470 0.7410];
color_2 = [0.8500 0.3250 0.0980];
color_3 = [0.9290 0.6940 0.1250];
color_4 = [0.4940 0.1840 0.5560];
color_5 = [0.4660 0.6740 0.1880];
color_6 = [0.3010 0.7450 0.9330];
color_7 = [0.6350 0.0780 0.1840];

colors = [color_1;color_2;color_3;color_4;color_5;color_6;color_7];

K_model = 4;

% Compute several measures to choose k
wss = [sum(results{1}.sumd);zeros(K-1,1)];
eta_square = [0.0;zeros(K-1,1)];
pre = [NaN;zeros(K-1,1)];

for k = 2:K 
    wss(k) = sum(results{k}.sumd);
    eta_square(k) = 1 - wss(k)/wss(1);
    pre(k) = (wss(k-1) - wss(k))/wss(k-1);
end

% Within sum of square
f_wss = figure;
plt = plot(1:K,wss);

plt(1).LineWidth = line_width;
plt(1).Color = color_1;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = color_1;
plt(1).MarkerSize = marker_size;

xl = xline(K_model,'-',{'Model K'});
xl.LabelHorizontalAlignment = 'center';
xl.LabelVerticalAlignment = 'middle';
% grid('on');

xlabel('Number of groups: K');
ylabel('Within sum of squares: WSS(K)');

% Within sum of square (log)
f_log_wss = figure;
plt = plot(1:K,log(wss));

plt(1).LineWidth = line_width;
plt(1).Color = color_1;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = color_1;
plt(1).MarkerSize = marker_size;

xl = xline(K_model,'-',{'Model K'});
xl.LabelHorizontalAlignment = 'center';
xl.LabelVerticalAlignment = 'middle';
% grid('on');

xlabel('Number of groups: K');
ylabel('log WSS(K)');

% Coefficient of determination
f_eta = figure;
plt = plot(1:K,eta_square);

plt(1).LineWidth = line_width;
plt(1).Color = color_1;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = color_1;
plt(1).MarkerSize = marker_size;

xl = xline(K_model,'-',{'Model K'});
xl.LabelHorizontalAlignment = 'center';
xl.LabelVerticalAlignment = 'middle';
% grid('on');

xlabel('Number of groups: K');
ylabel('Coefficient of determination: 1 - WSS(K)/WSS(1)');

% Proportional reduction of error
f_pre = figure;
plt = plot(1:K,pre);

plt(1).LineWidth = line_width;
plt(1).Color = color_1;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = color_1;
plt(1).MarkerSize = marker_size;

xl = xline(K_model,'-',{'Model K'});
xl.LabelHorizontalAlignment = 'center';
xl.LabelVerticalAlignment = 'middle';
% grid('on');

xlabel('Number of groups: K');
ylabel('Proportional reduction of error: 1 - WSS(K)/WSS(K-1)');

exportgraphics(f_wss,['../plots/kmeans_wss',figfmt]);
exportgraphics(f_log_wss,['../plots/kmeans_log_wss',figfmt]);
exportgraphics(f_eta,['../plots/kmeans_eta',figfmt]);
exportgraphics(f_pre,['../plots/kmeans_pre',figfmt]);


%% Output for chosen number of groups -----

K = 4;

C = results{K}.C;
[~,sorted_cluster_id] = sort(C(:,1),'descend');
C = C(sorted_cluster_id,:);

% Labor market attachment
f_lmattach = figure;
x = categorical(1:K);
% x = categorical({'Low','Medium-Low','Medium-High','High'});
% x = reordercats(x,{'Low','Medium-Low','Medium-High','High'});
y = C(:,1)';
b = barh(x,y);
b.FaceColor = 'flat';

for k = 1:K
    b.CData(k,:) = colors(k,:);
end 

sample_avg = mean(input_data.lmattach);
xline(sample_avg,'-',{'Sample average'},'linewidth',line_width);
% xl.LabelVerticalAlignment = 'top';
% xl.LabelHorizontalAlignment = 'center';

xlabel('Fraction survey non-employed');
ylabel('Cluster identifier');
grid('on');

% ECDF of earnings
f_ecdf = figure;
x = percentile_data.ern_pctl;
y = [C(:,2:end)' percentile_data.pctl/100];
plt = plot(x,y);

for k = 1:K
    plt(k).LineWidth = line_width;
    plt(k).Color = colors(k,:);
    plt(k).Marker = 's';
    plt(k).MarkerFaceColor = colors(k,:);
    plt(k).MarkerSize = marker_size;
end

plt(K+1).LineWidth = line_width;
plt(K+1).Color = 'k';
plt(K+1).LineStyle = ':';
plt(K+1).Marker = 's';
plt(K+1).MarkerFaceColor = 'k';
plt(K+1).MarkerSize = marker_size;

xlabel('Monthly labor income ($2009)');
ylabel('Empirical CDF');
grid('on');

legend_names = [append('Cluster ',string(1:K)) 'Sample']; 
legend(legend_names,'Location','best');

exportgraphics(f_lmattach,[sprintf('../plots/kmeans_nemp_%d',K),figfmt]);
exportgraphics(f_ecdf,[sprintf('../plots/kmeans_ecdf_%d',K),figfmt]);

% Save cluster assignment
id = input_data.id;
cluster_id = results{K}.cluster_id;
assignment = table(id,cluster_id);
filename = [data_dir filesep sprintf('assignment_%d',K),'.csv'];
writetable(assignment,filename);

cluster_id = transpose(1:K);
sorted_clusters = table(cluster_id,sorted_cluster_id);
filename = [data_dir filesep sprintf('sorted_clusters_%d',K),'.csv'];
writetable(sorted_clusters,filename);






