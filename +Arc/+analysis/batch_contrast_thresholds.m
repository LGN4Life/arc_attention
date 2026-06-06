function [all_data, hierarchical_performance, glme_percent_correct,glme_RT]  = batch_contrast_thresholds(batch_file)

% create data structure to hold data from all files

% We want to calculate performance as a function of (a) gap difference and (b) stimulus
% contrast. What parameters do we need: (1) stimulus polarity, (2) stimulus
% contrast, (3) difference in gap sizes (4) expected response, (5) observed
% response, (6) trial result (correct or incorrect)

% --- load and accumulate data ---
all_data   = UsBox.psych_util.batch_load_data(batch_file);

all_data.ThresholdData = ones(1,length(all_data.color1ChangesThisTrial));

config.levels(1).field = 'ThresholdData';    config.levels(1).label = 'All';
config.levels(2).field = 'locThisTrial'; config.levels(2).label = 'Location';
config.levels(3).field = 'MOCSContrastThisTrial';             config.levels(3).label = 'Contrast';
config.result_field    = 'trialCorrect';
config.rt_field = 'trialRT';

all_data.trialRT = all_data.responseTime - all_data.contrastChangeTime;

slow_trial_threshold =  prctile(all_data.trialRT,95);
slow_trials = all_data.trialRT> slow_trial_threshold;
all_data.trialRT(slow_trials) = nan;
all_data.trialCorrect(slow_trials) = 0;
[all_hierarchical, cols] = UsBox.psych_util.create_data_matrix(all_data, config);



%% invert no-go trials
no_go =  all_hierarchical(:,3) == min(all_hierarchical(:,3));
all_hierarchical(no_go,4) = 1+(-1*all_hierarchical(no_go,4));
%hierarchical_performance.percent_correct(1,:,1) = 100 - hierarchical_performance.percent_correct(1,:,1);



unique_h = UsBox.psych_util.get_unique_h(all_hierarchical);

hierarchical_performance = UsBox.psych_util.calculate_hierarchical_performance(all_hierarchical, cols, unique_h);



%% plot no-go trials

figure(2), clf
hold on
bar(squeeze(hierarchical_performance.percent_correct(1,:,1)))
errorbar(squeeze(hierarchical_performance.percent_correct(1,:,1)),squeeze(hierarchical_performance.percent_correct_e(1,:,1)),'.')
config.y_lim = [0 100];
plot_handles = UsBox.psych_util.plot_hierarchical_performance(hierarchical_performance, unique_h, config);

figure(3), clf

for index = 1:10
    subplot(2,5,index), axis square, box off
    errorbar(squeeze(hierarchical_performance.percent_correct(1,index,:)),squeeze(hierarchical_performance.percent_correct_e(1,index,:)))
    set(gca,'ylim',[0 110])
    title(index)
end

figure(4), clf

for index = 1:5
    subplot(1,5,index),hold on, axis square, box off
    errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(1,index,:)),squeeze(hierarchical_performance.percent_correct_e(1,index,:)),'g')
    errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(1,11-index,:)),squeeze(hierarchical_performance.percent_correct_e(1,11-index,:)),'r')
    set(gca,'ylim',[0 110])
    title(index)
end

%% calculate threshold
bs_count = 500;
figure(5), clf
bs_alpha = nan(bs_count,1);
bs_beta = nan(bs_count,1);
bs_rss = nan(bs_count,1);
alpha = nan(1,10);
beta = nan(1,10);
alpha_e = nan(1,10);
beta_e = nan(1,10);

bs_threshold = nan(bs_count,1);
threshold  = nan(1,10);
threshold_e  = nan(1,10);
for index = 1:10
    subplot(2,5,index), hold on , axis square, box off
    current_trials = find(all_hierarchical(:,2) == index & ~no_go);
    % current_result = all_hierarchical(current_trials,4);
    % current_contrast = all_hierarchical(current_trials,3);
    
    for bs_index = 1:bs_count
        current_resample = UsBox.stats.sample_with_replacement(current_trials);
        current_result = all_hierarchical(current_resample,4);
        current_contrast = all_hierarchical(current_resample,3);
        if bs_index < 10
            plot_flag = true;
        else
            plot_flag = false;
        end
        [bs_alpha(bs_index), bs_beta(bs_index), bs_threshold(bs_index), bs_rss(bs_index)] = UsBox.psycho.fit_weibull_trials(current_result, current_contrast,processing_method='none',plot=plot_flag);
        title(index)
        set(gca,'ylim',[0 1])
        
    end
    noisy_fits =  bs_rss > prctile(bs_rss,95); 
    alpha(index) = mean(bs_alpha(~noisy_fits),'omitmissing');
    alpha_e(index) = std(bs_alpha(~noisy_fits),'omitmissing');

    beta(index) = mean(bs_beta(~noisy_fits),'omitmissing');
    beta_e(index) = std(bs_beta(~noisy_fits),'omitmissing');

    threshold(index) = mean(bs_threshold(~noisy_fits),'omitmissing');
    threshold_e(index) = std(bs_threshold(~noisy_fits),'omitmissing');
    pause(2)
end
figure(6),
hold on
%errorbar(alpha,alpha_e,'b')
errorbar(threshold,threshold_e,'k')
set(gca,'ylim',[65 80])
plot_handles.percent_correct(2).Color = [0 1 1];
plot_handles.reaction_time(2).Color = [0 1 1];
tic
