function simulate_attention(varargin)
% Simulate percent correct under 1-window and 2-window attention models.
%
% Usage:
%   Arc.simulate_attention()
%   Arc.simulate_attention('sigma', 2, 'p_max', 0.90, 'n_trials', 10000)
%
% Parameters:
%   sigma    - SD of Gaussian attention window in position units (default 2)
%   p_max    - peak percent correct at fully attended location (default 0.90)
%   n_trials - simulated trials per cue condition (default 10000)

%% Parse inputs
pr = inputParser;
addParameter(pr, 'sigma',    2);
addParameter(pr, 'p_max',    0.90);
addParameter(pr, 'n_trials', 10000);
parse(pr, varargin{:});
sigma    = pr.Results.sigma;
p_max    = pr.Results.p_max;
n_trials = pr.Results.n_trials;

%% Task structure
positions = [1 2 3 4 5 7 8 9 10 11];
n_pos     = numel(positions);
p_chance  = 1 / n_pos;
flanks_L  = [1 2 4 5];
flanks_R  = [7 8 10 11];

cues       = [0 0.25 0.5 0.75 1.0];
cue_labels = {'0% red','25% red','50/50','75% red','100% red'};
n_cues     = numel(cues);

%% Unit-area Gaussians (constant resource constraint)
G3    = unit_gauss(positions, 3, sigma);
G9    = unit_gauss(positions, 9, sigma);
a_ref = max(G3);   % peak attention in fully-focused 1-window case

%% Attention profiles for each model and cue condition
A1 = zeros(n_cues, n_pos);   % 1-window
A2 = zeros(n_cues, n_pos);   % 2-window

for ci = 1:n_cues
    P = cues(ci);
    if P > 0.5
        A1(ci,:) = G3;
    elseif P < 0.5
        A1(ci,:) = G9;
    else
        A1(ci,:) = ones(1, n_pos) / n_pos;   % uniform at 50/50
    end
    A2(ci,:) = P * G3 + (1-P) * G9;
end

%% Simulate trials
pc1    = NaN(n_cues, n_pos);
pc2    = NaN(n_cues, n_pos);
ci95_1 = zeros(n_cues, n_pos);
ci95_2 = zeros(n_cues, n_pos);

for ci = 1:n_cues
    P = cues(ci);

    % Vectorised target sampling
    is_left = rand(1, n_trials) < P;        % left side on P_red fraction of trials
    is_hot  = rand(1, n_trials) < 0.5;      % hot spot vs flanker

    lf = flanks_L(randi(4, 1, n_trials));
    rf = flanks_R(randi(4, 1, n_trials));

    tgt_L = 3 * is_hot + lf .* ~is_hot;
    tgt_R = 9 * is_hot + rf .* ~is_hot;
    tgt   = tgt_L .* is_left + tgt_R .* ~is_left;

    % Percent correct at each position via binomial sampling
    for pi = 1:n_pos
        n = sum(tgt == positions(pi));
        if n == 0, continue; end

        p_c1 = p_chance + (p_max - p_chance) * A1(ci,pi) / a_ref;
        p_c2 = p_chance + (p_max - p_chance) * A2(ci,pi) / a_ref;

        pc1(ci,pi) = mean(rand(1,n) < p_c1);
        pc2(ci,pi) = mean(rand(1,n) < p_c2);

        ci95_1(ci,pi) = 1.96 * sqrt(p_c1*(1-p_c1) / n);
        ci95_2(ci,pi) = 1.96 * sqrt(p_c2*(1-p_c2) / n);
    end
end

%% Plot
plot_results(positions, A1, A2, pc1, pc2, ci95_1, ci95_2, ...
    cue_labels, p_chance, p_max, a_ref);
end

%% -------------------------------------------------------------------------
function g = unit_gauss(positions, mu, sigma)
g = exp(-(positions - mu).^2 / (2*sigma^2));
g = g / sum(g);
end

%% -------------------------------------------------------------------------
function plot_results(positions, A1, A2, pc1, pc2, ci95_1, ci95_2, ...
    cue_labels, p_chance, p_max, a_ref)

n_cues = size(pc1, 1);
col1   = [0.2 0.4 0.8];   % blue  — 1-window
col2   = [0.8 0.3 0.2];   % red   — 2-window

figure(3), clf
set(gcf, 'Color', 'w', 'Position', [50 50 1400 620])
sgtitle('Spatial attention model simulation', 'FontSize', 14, 'FontWeight', 'bold')

for ci = 1:n_cues

    % --- Row 1: attention profiles ---
    subplot(2, n_cues, ci), hold on
    plot(positions, A1(ci,:)/a_ref, 'o-', 'Color', col1, 'LineWidth', 1.5, ...
        'MarkerFaceColor', col1, 'DisplayName', '1-window')
    plot(positions, A2(ci,:)/a_ref, 's-', 'Color', col2, 'LineWidth', 1.5, ...
        'MarkerFaceColor', col2, 'DisplayName', '2-window')
    yline(1/(numel(positions)*a_ref), 'k--', 'LineWidth', 0.8)
    ylim([0 1.15])
    xlim([0 12])
    xticks(positions)
    title(cue_labels{ci}, 'FontSize', 11)
    if ci == 1
        ylabel('Normalised attention', 'FontSize', 10)
        legend('Location', 'north', 'FontSize', 8)
    end
    xlabel('Position')
    set(gca, 'XGrid', 'off', 'Box', 'off')

    % --- Row 2: simulated percent correct ---
    subplot(2, n_cues, n_cues + ci), hold on
    errorbar(positions - 0.15, pc1(ci,:), ci95_1(ci,:), 'o-', ...
        'Color', col1, 'LineWidth', 1.5, 'MarkerFaceColor', col1, 'CapSize', 3)
    errorbar(positions + 0.15, pc2(ci,:), ci95_2(ci,:), 's-', ...
        'Color', col2, 'LineWidth', 1.5, 'MarkerFaceColor', col2, 'CapSize', 3)
    yline(p_chance, 'k--', 'LineWidth', 0.8)
    yline(p_max,    'k:',  'LineWidth', 0.8)
    ylim([0 1])
    xlim([0 12])
    xticks(positions)
    if ci == 1
        ylabel('P(correct)', 'FontSize', 10)
    end
    xlabel('Position')
    set(gca, 'Box', 'off')
end
end
