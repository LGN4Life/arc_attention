function [counts, N_total] = trials_needed(min_n, validities, n_flankers, collapse)
% Calculate total trials needed to achieve min_n valid AND min_n invalid
% changes at every stimulus location, within each validity level.
%
% Each validity level runs independently until its requirement is met.
% Invalid changes are not possible at 100% validity (excluded from that
% level's requirement). Assumes 50/50 left-right cueing each trial.
%
% Usage:
%   [counts, N_total] = Arc.trials_needed(100)
%   [counts, N_total] = Arc.trials_needed(100, [0.5 0.75 1.0])
%   [counts, N_total] = Arc.trials_needed(100, [0.5 0.75 1.0], 4)
%   [counts, N_total] = Arc.trials_needed(100, [0.5 0.75 1.0], 4, true)
%
% Returns:
%   counts.valid      - (n_rows x n_val) expected valid   changes
%   counts.invalid    - (n_rows x n_val) expected invalid changes
%   counts.row_labels - position labels or distance labels (when collapsed)
%   counts.validities - validity levels used
%   counts.N_per_val  - trials run at each validity level
%   counts.N_total    - total trials across all validity levels
%   N_total           - total trials across all validity levels

arguments
    min_n      (1,1) double  {mustBePositive, mustBeInteger}
    validities (1,:) double  {mustBeBetween(validities, 0, 1)}        = [0.50 0.75 1.00]
    n_flankers (1,1) double  {mustBePositive, mustBeInteger, mustBeEven} = 4
    collapse   (1,1) logical                                           = false
end

n_val   = numel(validities);
p_hot   = 0.50;
p_flank = 0.50 / n_flankers;

%% Build output matrices and compute N_per_val based on collapse mode
if collapse
    % Rows = distances 0, 1, ..., max_dist (both sides summed)
    % Positions per side at distance d >= 1: min(2, max(0, n_flankers - 2*(d-1)))
    max_dist  = ceil(n_flankers / 2);
    distances = 0:max_dist;
    n_rows    = numel(distances);

    n_at_dist    = zeros(1, n_rows);
    n_at_dist(1) = 1;
    for d = 1:max_dist
        n_at_dist(d+1) = min(2, max(0, n_flankers - 2*(d-1)));
    end

    % Rarest group: fewest positions across flanker distances × 2 sides
    p_min_unit = p_flank * min(n_at_dist(2:end)) * 2;

    % p_within per distance row (per position, per side)
    p_within_dist = [p_hot, repmat(p_flank, 1, max_dist)];

    N_per_val = compute_N_per_val(validities, p_min_unit, min_n);

    valid_counts   = zeros(n_rows, n_val);
    invalid_counts = zeros(n_rows, n_val);
    for vi = 1:n_val
        V = validities(vi);
        % factor 2 = both sides; n_at_dist = positions per side at this distance
        valid_counts(:,vi)   = (N_per_val(vi) * 0.5 * V     * p_within_dist .* n_at_dist * 2)';
        invalid_counts(:,vi) = (N_per_val(vi) * 0.5 * (1-V) * p_within_dist .* n_at_dist * 2)';
    end

    row_labels    = arrayfun(@(d) sprintf('dist %d', d), distances, 'UniformOutput', false);
    row_labels{1} = 'dist 0 (hot)';

else
    % Rows = individual positions: left hot, left flankers, right hot, right flankers
    % Hot spots fixed at 3 (left) and 9 (right); position 6 is the centre (no change).
    % Flankers are placed symmetrically: half = n_flankers/2 on each side of each hot spot.
    % Rarest event: a single flanker on one side
    p_min_unit = p_flank;

    half         = n_flankers / 2;
    hot_L        = 3;   hot_R = 9;
    left_flanks  = [hot_L-half : hot_L-1,  hot_L+1 : hot_L+half];
    right_flanks = [hot_R-half : hot_R-1,  hot_R+1 : hot_R+half];
    positions    = [hot_L, left_flanks, hot_R, right_flanks];
    n_rows       = numel(positions);
    p_within     = repmat([p_hot, repmat(p_flank, 1, n_flankers)], 1, 2);

    N_per_val = compute_N_per_val(validities, p_min_unit, min_n);

    valid_counts   = zeros(n_rows, n_val);
    invalid_counts = zeros(n_rows, n_val);
    for vi = 1:n_val
        V = validities(vi);
        valid_counts(:,vi)   = N_per_val(vi) * 0.5 * V     * p_within';
        invalid_counts(:,vi) = N_per_val(vi) * 0.5 * (1-V) * p_within';
    end

    row_labels = arrayfun(@(p) sprintf('%d', p), positions, 'UniformOutput', false);
end

N_total = sum(N_per_val);

counts.valid      = valid_counts;
counts.invalid    = invalid_counts;
counts.row_labels = row_labels;
counts.validities = validities;
counts.N_per_val  = N_per_val;
counts.N_total    = N_total;

%% Display
val_strs = arrayfun(@(v) sprintf('%g%%', v*100), validities, 'UniformOutput', false);

fprintf('\n=== Trials needed for >= %d changes per location per validity level ===\n', min_n);
fprintf('Validity levels : %s\n', mat2str(validities));
fprintf('Flankers/side   : %d   (p_hot = %.3f, p_flank = %.4f)\n', ...
    n_flankers, p_hot, p_flank);
if collapse
    fprintf('Collapsed by    : distance from hot spot (counts summed across both sides)\n');
end
fprintf('\n');

for vi = 1:n_val
    fprintf('  Validity %s: %d trials\n', val_strs{vi}, N_per_val(vi));
end
fprintf('  %s\n', repmat('-', 1, 35));
fprintf('  Total trials needed : %d\n\n', N_total);

fprintf('Valid changes:\n');
print_table(row_labels, val_strs, valid_counts);

fprintf('Invalid changes:\n');
print_table(row_labels, val_strs, invalid_counts);
end

%% -------------------------------------------------------------------------
function mustBeEven(x)
if mod(x, 2) ~= 0
    error('Value must be even.');
end
end

%% -------------------------------------------------------------------------
function N_per_val = compute_N_per_val(validities, p_min_unit, min_n)
% N needed at each validity level so the rarest event reaches min_n.
% p_min_unit is the per-trial probability of the rarest group (before
% multiplying by V or 1-V and the 0.5 cueing factor).
N_per_val = zeros(numel(validities), 1);
for vi = 1:numel(validities)
    V = validities(vi);
    p_active = [0.5 * V * p_min_unit, 0.5 * (1-V) * p_min_unit];
    p_active = p_active(p_active > 0);
    N_per_val(vi) = ceil(min_n / min(p_active));
end
end

%% -------------------------------------------------------------------------
function print_table(row_labels, val_strs, counts)
n_val = numel(val_strs);
col_w = 12;

fprintf('  %-16s', 'Location');
for vi = 1:n_val
    fprintf('  %*s', col_w, val_strs{vi});
end
fprintf('\n  %s\n', repmat('-', 1, 18 + n_val*(col_w+2)));

for ri = 1:numel(row_labels)
    fprintf('  %-16s', row_labels{ri});
    for vi = 1:n_val
        if counts(ri, vi) > 0
            fprintf('  %*.1f', col_w, counts(ri, vi));
        else
            fprintf('  %*s', col_w, 'N/A');
        end
    end
    fprintf('\n');
end
fprintf('  %s\n\n', repmat('-', 1, 18 + n_val*(col_w+2)));
end
