function D = draw_arc_design()
% Draws 11 circles arranged on a clock face from 0 (12 o'clock) to 180
% degrees (6 o'clock), evenly spaced.

n          = 10;       % number of circles
R          = 1;        % radius of the clock arrangement
r          = 0.12;     % radius of each individual circle

% clock angles 0-180, converted to standard math angles
% clock 0 deg = 12 o'clock = 90 deg in math coords
% clock 180 deg = 6 o'clock = -90 deg in math coords
clock_deg = linspace(-90, 90, n);
math_rad  = deg2rad(90 - clock_deg);

% unit circle for drawing each disk
theta = linspace(0, 2*pi, 128);
cx    = cos(theta);
cy    = sin(theta);

figure(10), clf, hold on, axis equal, axis off
set(gcf, 'Color', 'w')

for k = 1:n
    x = R * cos(math_rad(k));
    y = R * sin(math_rad(k));
    if k <= 5
        fill_color = [1 0 0];
    elseif k > 5
        fill_color = [0 0.7 0];
    else
        fill_color = [1 1 1];
    end
    if ismember(k, [1 2 4 5 6 7 9 10])
        face_alpha = 0.4;
    else
        face_alpha = 1;
    end
    fill(x + r*cx, y + r*cy, fill_color, 'EdgeColor', 'k', 'FaceAlpha', face_alpha);
    text(x, y, num2str(k), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'middle', ...
        'FontSize', 16);
end

% bottom semicircle: mirror of top, no labels, no fill
for k = 2:n-1
    x =  R * cos(math_rad(k));
    y = -R * sin(math_rad(k));
    fill(x + r*cx, y + r*cy, [1 1 1], 'EdgeColor', 'k');
end

% center circle with random dot cloud (75% red, 25% green)
r = 3*r;
fill(2*r*cx, r*cy, [1 1 1], 'EdgeColor', 'none');
n_dots = 300;
pts    = [];
while size(pts, 1) < n_dots
    cands = (2*rand(n_dots, 2) - 1) * r;
    pts   = [pts; cands(sum(cands.^2, 2) <= r^2, :)];
end
pts   = pts(1:n_dots, :);
n_red = round(0.75 * n_dots);
plot(pts(1:n_red, 1),         pts(1:n_red, 2),         '.', 'Color', [1 0 0],   'MarkerSize', 12);
plot(pts(n_red+1:end, 1),     pts(n_red+1:end, 2),     '.', 'Color', [0 0.7 0], 'MarkerSize', 12);
%plot(r*cx, r*cy, 'k');  % redraw edge on top of dots
r = r/4;
plot([-r r], [0  0], 'k', 'LineWidth', 1.5);
plot([0  0], [-r r], 'k', 'LineWidth', 1.5);

axis([-1.2 1.2 -1.2 1.2])

%% Interstimulus distance matrix (visual degrees, R = 6 deg)
R_deg      = 6;
stim_idx   = [1 2 3 4 5 6 7 8 9 10];   % position labels 
x_deg      = R_deg * cos(math_rad(stim_idx));
y_deg      = R_deg * sin(math_rad(stim_idx));

D = sqrt((x_deg' - x_deg).^2 + (y_deg' - y_deg).^2);

% Display as a labelled table in the command window
fprintf('\nInterstimulus distances (visual degrees, R = %g deg)\n', R_deg);
fprintf('     ');
fprintf(' %6d', stim_idx);
fprintf('\n');
for i = 1:numel(stim_idx)
    fprintf('%4d ', stim_idx(i));
    fprintf(' %6.2f', D(i,:));
    fprintf('\n');
end
end
