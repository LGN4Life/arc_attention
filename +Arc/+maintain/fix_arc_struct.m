function data = fix_arc_struct(data)

%files collected before the SFN abstract deadline have incorrect data
%structtures



data.colorCuedThisTrial(data.pctColor1 < 50) = 2;
data.colorCuedThisTrial(data.pctColor1 == 50) = 0;
data.colorCuedThisTrial(data.pctColor1 > 50) = 1;

valid_trials = (data.color1ChangesThisTrial == 1 & data.colorCuedThisTrial == 1) | ...
    (data.color2ChangesThisTrial == 1 & data.colorCuedThisTrial == 2);

invalid_trials = (data.color1ChangesThisTrial & data.colorCuedThisTrial == 2) | ...
    (data.color2ChangesThisTrial & data.colorCuedThisTrial == 1);

data.valid(valid_trials) = 1;
data.valid(invalid_trials) = 0;
data.valid(data.pctColor1 == 50) = -1;
tic
