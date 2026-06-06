function [all_data, hierarchical_performance, glme_percent_correct,glme_RT]  = demo_batch_analysis(batch_file)

% create data structure to hold data from all files

% We want to calculate performance as a function of (a) gap difference and (b) stimulus
% contrast. What parameters do we need: (1) stimulus polarity, (2) stimulus
% contrast, (3) difference in gap sizes (4) expected response, (5) observed
% response, (6) trial result (correct or incorrect)

% --- load and accumulate data ---
all_data   = UsBox.psych_util.batch_load_data(batch_file);

all_data.trialRT = all_data.responseTime - all_data.contrastChangeTime;

all_data.trialCorrectSide = all_data.trialRespondSide == all_data.expectedSideThisTrial;

slow_rt = all_data.trialRT > 1.5;

all_data.trialRT(slow_rt) = nan;
all_data.trialCorrect(slow_rt) = 0;

all_data.cuePct = nan(1,length(all_data.pctColor1));
color_1_trials=  all_data.pctColor1 > 50;
color_2_trials=  all_data.pctColor1 < 50;
all_data.cuePct(color_1_trials) =  all_data.pctColor1(color_1_trials);
all_data.cuePct(color_2_trials) =  100 - all_data.pctColor1(color_2_trials);
all_data.cuePct(~color_1_trials & ~color_2_trials) = 50;

all_data.cue_delay = all_data.contrastChangeTime - all_data.cueOffsetTime;




% change valid field to be -1 for invalid (negative information?), 0 = for
% 50/50 trials (no information), 1 for valid
no_information_trials =  all_data.cuePct'== 50;
valid_trials = all_data.valid == 1;
invalid_trials = all_data.valid == 0;
all_data.valid = nan(1,length(all_data.pctColor1));
all_data.valid(no_information_trials) = 0;
all_data.valid(valid_trials) = 1;
all_data.valid(invalid_trials) = -1;


all_data.collapsedPos = nan(1,length(all_data.pctColor1));
left_side_trials =  all_data.locThisTrial < 6;
right_side_trials =  all_data.locThisTrial > 6;

cued_left_side = all_data.pctColor1 > 50;
cued_right_side =  all_data.pctColor1 < 50;


all_data.collapsedPos(cued_left_side) = all_data.locThisTrial(cued_left_side) - 3;
all_data.collapsedPos(cued_right_side) = 9 -  all_data.locThisTrial(cued_right_side);
all_data.collapsedPos(no_information_trials & left_side_trials) = all_data.locThisTrial(no_information_trials & left_side_trials) - 3;
all_data.collapsedPos(no_information_trials & right_side_trials) = all_data.locThisTrial(no_information_trials & right_side_trials) - 3;


% distance from cue 
all_data.changeDistFromCue = nan(1,length(all_data.pctColor1));
all_data.changeDistFromCue(color_1_trials) = abs(3 - all_data.locThisTrial(color_1_trials));
all_data.changeDistFromCue(color_2_trials) = abs(9 - all_data.locThisTrial(color_2_trials));
% for 50/50 trials there is no true distance from cue, but we can say that
% in these trials the subject is cued to the middle
all_data.changeDistFromCue(no_information_trials & left_side_trials) = abs(3 - all_data.locThisTrial(no_information_trials & left_side_trials));
all_data.changeDistFromCue(no_information_trials & right_side_trials) = abs(9 - all_data.locThisTrial(no_information_trials & right_side_trials));

all_data.changeDistFromCue(invalid_trials & left_side_trials) = abs(3 - all_data.locThisTrial(invalid_trials & left_side_trials));
all_data.changeDistFromCue(invalid_trials & right_side_trials) = abs(9 - all_data.locThisTrial(invalid_trials & right_side_trials));

% distance from distractor

all_data.changeDistFromDistractor = nan(1,length(all_data.pctColor1));
all_data.changeDistFromDistractor(color_1_trials) = abs(9 - all_data.locThisTrial(color_1_trials));
all_data.changeDistFromDistractor(color_2_trials) = abs(3 - all_data.locThisTrial(color_2_trials));

all_data.changeDistFromDistractor(no_information_trials & left_side_trials) = abs(9 - all_data.locThisTrial(no_information_trials & left_side_trials));
all_data.changeDistFromDistractor(no_information_trials & right_side_trials) = abs(3 - all_data.locThisTrial(no_information_trials & right_side_trials));

all_data.changeDistFromDistractor(invalid_trials & left_side_trials) = abs(9 - all_data.locThisTrial(invalid_trials & left_side_trials));
all_data.changeDistFromDistractor(invalid_trials & right_side_trials) = abs(3 - all_data.locThisTrial(invalid_trials & right_side_trials));


all_data.trialValidity = nan(1,length(all_data.pctColor1));
all_data.trialValidity(valid_trials) = all_data.cuePct(valid_trials);
all_data.trialValidity(invalid_trials) = 100 - all_data.cuePct(invalid_trials);
all_data.trialValidity(no_information_trials) = 50;

config.levels(1).field = 'cuePct';    config.levels(1).label = '% Cue';
config.levels(2).field = 'valid'; config.levels(2).label = 'Valid';
%config.levels(3).field = 'changeDistFromCue';             config.levels(3).label = 'Position';
config.levels(3).field = 'collapsedPos';             config.levels(3).label = 'Position';
config.result_field    = 'trialCorrectSide';
config.rt_field = 'trialRT';

[all_hierarchical, cols] = UsBox.psych_util.create_data_matrix(all_data, config);




unique_h = UsBox.psych_util.get_unique_h(all_hierarchical);

hierarchical_performance = UsBox.psych_util.calculate_hierarchical_performance(all_hierarchical, cols, unique_h);



config.y_lim = [0 100];
plot_handles = UsBox.psych_util.plot_hierarchical_performance(hierarchical_performance, unique_h, config);

plot_handles.percent_correct(2).Color = [0 1 1];
plot_handles.reaction_time(2).Color = [0 1 1];

figure(2), clf, hold on
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(3,3,:)),squeeze(hierarchical_performance.percent_correct_e(3,3,:)),'r')
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(1,2,:)),squeeze(hierarchical_performance.percent_correct_e(1,2,:)),'b')
legend('100% valid', '50/50')

figure(3), clf, hold on
%errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(3,2,:)),squeeze(hierarchical_performance.percent_correct_e(3,2,:)),'k')
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(2,3,:)),squeeze(hierarchical_performance.percent_correct_e(2,3,:)),'r')
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(2,1,:)),squeeze(hierarchical_performance.percent_correct_e(2,1,:)),'b')
legend('75% valid','75% invalid')

figure(4), clf, hold on
errorbar(unique_h{3},squeeze(hierarchical_performance.reaction_time(2,3,:)),squeeze(hierarchical_performance.reaction_time_e(2,3,:)),'r')
errorbar(unique_h{3},squeeze(hierarchical_performance.reaction_time(2,1,:)),squeeze(hierarchical_performance.reaction_time_e(2,1,:)),'b')
legend('valid','invalid')
xlabel('relative pos')
ylabel('reaction time (s)')
title('75% valid vs invalid')

figure(5), clf, hold on
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(3,3,:)),squeeze(hierarchical_performance.percent_correct_e(3,3,:)),'r')
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(2,3,:)),squeeze(hierarchical_performance.percent_correct_e(2,3,:)),'c')
legend('valid','invalid')
xlabel('relative pos')
ylabel('reaction time (s)')
title('100% valid vs 75% valid')
set(gca,'YLim',[50 100])


figure(6), clf, hold on
errorbar(unique_h{3},squeeze(mean(hierarchical_performance.percent_correct(2:3,3,:))),squeeze(mean(hierarchical_performance.percent_correct_e(2:3,3,:))),'r')
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(2,1,:)),squeeze(hierarchical_performance.percent_correct_e(2,1,:)),'b')
legend('valid','invalid')
xlabel('relative pos')
ylabel('reaction time (s)')
title('all valid vs all valid')
set(gca,'YLim',[50 100])

figure(7), clf, hold on
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(3,3,:)),squeeze(hierarchical_performance.percent_correct_e(3,3,:)),'r-o','LineWidth',3)
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(2,3,:)),squeeze(hierarchical_performance.percent_correct_e(2,3,:)),'g-o','LineWidth',3)
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(2,1,:)),squeeze(hierarchical_performance.percent_correct_e(2,1,:)),'k-','LineWidth',3)
errorbar(unique_h{3},squeeze(hierarchical_performance.percent_correct(1,2,:)),squeeze(hierarchical_performance.percent_correct_e(1,2,:)),'c-','LineWidth',3)
%set(gca,'XLim',[-.5 2.5])
legend('100','75 valid','75 invalid','50')
xlabel('distance from cue')
ylabel('% correct')

figure(8), clf, hold on
errorbar(unique_h{3},squeeze(hierarchical_performance.reaction_time(3,3,:)),squeeze(hierarchical_performance.reaction_time_e(3,3,:)),'r-o','LineWidth',3)
errorbar(unique_h{3},squeeze(hierarchical_performance.reaction_time(2,3,:)),squeeze(hierarchical_performance.reaction_time_e(2,3,:)),'g-o','LineWidth',3)
errorbar(unique_h{3},squeeze(hierarchical_performance.reaction_time(2,1,:)),squeeze(hierarchical_performance.reaction_time_e(2,1,:)),'k-','LineWidth',3)
errorbar(unique_h{3},squeeze(hierarchical_performance.reaction_time(1,2,:)),squeeze(hierarchical_performance.reaction_time_e(1,2,:)),'c-','LineWidth',3)
legend('100','75 valid','75 invalid','50')
set(gca,'YLim',[.7 1])
%set(gca,'XLim',[-.5 2.5])
xlabel('distance from cue')
ylabel('reaction time')


[all_data.LocX, all_data.LocY] = Arc.pos2xy(all_data.locThisTrial, 1);

T = table(all_data.trialCorrect',all_data.trialRT',all_data.trialCorrectSide', (all_data.trialValidity/100)', ...
    all_data.collapsedPos',all_data.expectedSideThisTrial',all_data.changeDistFromCue',all_data.changeDistFromDistractor',...
    all_data.cue_delay',all_data.LocX',all_data.LocY','VariableNames',{'trialCorrect','trialRT','trialCorrectSide','trialValidity',...
    'collapsedPos','sideChange','changeDist','changeDistFromDistractor','changeDelay','LocX','LocY'});

glme_percent_correct = fitglme(T,'trialCorrectSide ~ 1 + trialValidity  + changeDist + changeDelay + sideChange',...
    'Distribution','Binomial','FitMethod','Laplace')

glme_RT = fitglme(T,'trialRT ~ 1 + trialValidity  + changeDist + changeDelay + sideChange',...
    'Distribution','Normal','FitMethod','Laplace')
tic