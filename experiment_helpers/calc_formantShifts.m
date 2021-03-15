function shifts = calc_formantShifts(fmtMeans, shiftMag, vowel2shift, targets, bMels)
% Calculate formant shifts for Audapter experiments where the
% shifts are from one vowel (vowel2shift) towards one or more other vowels
% (targets) in F1/F2 space.
% Inputs:   fmtMeans: output of calc_vowelMeans. This is a structure with
%               vowel (in ARPABET) as fields, each of which has [F1 F2]
%               values for that vowel midpoint in Hz. Required.
%           shiftMag: the magnitude of the shift to be applied. Required
%           vowel2shift: string with lower-case arpabet of vowel that will 
%               be shifted in the experiment. must match a field in
%               fmtMeans. Required.
%           targets: cell array with elements that are strings of the
%               vowels towards which formants will be shifted. defaults to
%               all other vowels in fmtMeans, but you should specify these
%               if you want the shifts to be in a certain order
%           bMels: binary flag to calculate formants in mels (1, default)
%               or Hz (if set to 0). This should match how you are
%               implementing shifts in Audapter (probably mels)
%
% Outputs:  shifts: structure with fields for polar coordinates (shift
%               angle and magnitude, which are needed for Audapter) and
%               Cartesian F1/F2 coordinates (which are needed for other
%               analysis functions)
%

if nargin < 5 || isempty(bMels)
    bMels = 1;
end
vowelList = fieldnames(fmtMeans);
if ~any(strcmp(vowelList,vowel2shift))
    %first check that the target vowel exists in the formant structure
    error('Target vowel must be in vowel formant structure. ')
end
if nargin < 4 || isempty(targets)
    %default to calculating shifts to all other vowels available
    targets = vowelList(~strcmp(vowelList,vowel2shift));
end
if size(targets, 1) > 1, targets = targets'; end %force to a row

%calculate formants in mels, if flagged
if bMels
    for i = 1:length(vowelList)
        fmtMeans.(vowelList{i}) = hz2mel(fmtMeans.(vowelList{i}));
    end
end

%keep a record of the order the shifts are calculated in
shifts.order = targets;


for i = 1:length(targets)
    tar = targets{i};
    %calculate direction in F1/F2 space
    F1diff(i) = fmtMeans.(tar)(1) - fmtMeans.(vowel2shift)(1);
    F2diff(i) = fmtMeans.(tar)(2) - fmtMeans.(vowel2shift)(2);
    
    %calculate shifts in vector space
    shifts.shiftAng(i) = atan(F2diff(i)/F1diff(i));
    shifts.shiftMag(i) = shiftMag;
    %Handle cases where direction needs to be flipped.
    if F1diff(i)<0
        shifts.shiftAng(i) = shifts.shiftAng(i) - pi;
    end
    
    %save F1/F2 shifts
    if bMels
        shifts.mels{i} = [cos(shifts.shiftAng(i))*shifts.shiftMag(i) ...
            sin(shifts.shiftAng(i))*shifts.shiftMag(i)];
        shifts.hz{i} = mel2hz(shifts.mels{i});
    else
        shifts.hz{i} = [cos(shifts.shiftAng(i))*shifts.shiftMag(i) ...
            sin(shifts.shiftAng(i))*shifts.shiftMag(i)];
        shifts.mels{i} = hz2mel(shifts.hz{i});
    end
end