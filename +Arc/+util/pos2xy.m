function [x, y] = pos2xy(pos, R)
% Convert stimulus position(s) 1-11 to (x, y) coordinates on a semicircle.
% pos 1 = far left, pos 6 = straight up, pos 11 = far right.
% R is the radius (default = 1).

if nargin < 2
    R = 1;
end

clock_deg = linspace(-90, 90, 11);
math_rad  = deg2rad(90 - clock_deg(pos));

x = R .* cos(math_rad);
y = R .* sin(math_rad);
end
