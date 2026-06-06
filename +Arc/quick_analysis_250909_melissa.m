function percent_correct = quick_analysis_250909_melissa(data)

data = Arc.maintain.fix_arc_struct(data);

cue_certainty = data.pctColor1;
cue_certainty(cue_certainty<50) = 100 - cue_certainty(cue_certainty<50);

unique_cue_certainty = unique(cue_certainty);



valid_trials = data.valid;

change_location =  data.expectedAnswerThisTrial;

unique_change_location = 1:11;%unique(change_location);



% for each pct red, calculate percent correct for each location

percent_correct.valid = nan(length(unique_cue_certainty), length(unique_change_location));
percent_correct.valid_n = nan(length(unique_cue_certainty), length(unique_change_location));

percent_correct.invalid = nan(length(unique_cue_certainty), length(unique_change_location));
percent_correct.invalid_n = nan(length(unique_cue_certainty), length(unique_change_location));
figure(1),clf, hold on
figure(2),clf, hold on

for cert_index = 1:length(unique_cue_certainty)

    current_pct = cue_certainty == unique_cue_certainty(cert_index);

    for loc_index = 1:length(unique_change_location)
        current_location = change_location == unique_change_location(loc_index);
    

        current_valid_trials = current_pct & current_location & valid_trials ~= 0;


        percent_correct.valid(cert_index, loc_index) = mean(data.trialCorrect(current_valid_trials),'omitmissing');
        percent_correct.valid_n(cert_index, loc_index) = sum(isfinite(data.trialCorrect(current_valid_trials)));

        tic

    end

figure(1), plot(unique_change_location,percent_correct.valid(cert_index,:),'-o')
end

figure(1),
title('Valid')
legend('50','75','100')
xlabel('spatial location')
ylabel('% correct')





figure(4),clf
hold on
plot(unique_change_location(1:5),percent_correct.valid(3,1:5),'-or')
plot(unique_change_location(7:11),percent_correct.valid(3,7:11),'-og')
plot(unique_change_location(1:5),percent_correct.valid(1,1:5),'-ok')
plot(unique_change_location(7:11),percent_correct.valid(1,7:11),'-ok')
title('100 vs 50 valid')
xlabel('spatial location')
ylabel('% correct')

tic