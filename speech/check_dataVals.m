function errors = check_dataVals(dataPath,yesCalc)
%check formant data for errors and return trial numbers where errors are
%detected. Types of errors:
%             * jumpTrials in F1/F2 trajectory
%             * NaN values in F1 trajectory
%             * tracking obviously wrong F1
%             * durations under 100 ms
%             * durations over 1 s
% inputs: dataPath: path where data to check is located [snum/subdir].
%           Function reads from current directory if not specified
%         yesCalc:  option to calculate dataVals using
%           gen_dataVals_from_wave_viewer function (1) or not (0).
%           Defualt is 0 if not specified.

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(yesCalc), yesCalc = 0; end

%if yesCalc == 1, generate dataVals
if yesCalc
    gen_dataVals_from_wave_viewer(dataPath);
end

load(fullfile(dataPath,'dataVals'))

%set thresholds for errors
shortThresh = .125; %(<200 ms)
longThresh = 1; %(> 1 s)
jumpThresh = 300; %in Hz, upper limit for sample-to-sample change to detect jumpTrials in F1 trajectory
wrongFThresh = [300 1000]; %acceptable range of possible F1 values

badTrials = [];
shortTrials = [];
longTrials = [];
nanFTrials = [];
jumpF1Trials = [];
jumpF2Trials = [];
wrongFTrials = [];
goodTrials = [];

for i = 1:length(dataVals)
    if dataVals(i).bExcl
        badTrials = [badTrials dataVals(i).token];
    elseif dataVals(i).dur < shortThresh %check for too short trials
        shortTrials = [shortTrials dataVals(i).token];
    elseif dataVals(i).dur > longThresh %check for too long trials
        longTrials = [longTrials dataVals(i).token];
    elseif find(isnan(dataVals(i).f1(2:end))) %check if there are NaN values in formant tracks, excepting 1st sample
        nanFTrials = [nanFTrials dataVals(i).token];
    elseif max(abs(diff(dataVals(i).f1)))>jumpThresh || max(abs(diff(dataVals(i).f2)))>jumpThresh %check for trials with F1/F2 jumps
        if max(abs(diff(dataVals(i).f1)))>jumpThresh %check for trials with F1 jumps
            jumpF1Trials = [jumpF1Trials dataVals(i).token];
        elseif max(abs(diff(dataVals(i).f2)))>jumpThresh %check for trials with F2 jumps
            jumpF2Trials = [jumpF2Trials dataVals(i).token];
        end
    elseif any(dataVals(i).f1 < wrongFThresh(1)) || any(dataVals(i).f1 > wrongFThresh(2)) %check if wrong formant is being tracked for F1
        wrongFTrials = [wrongFTrials dataVals(i).token];
    else
        goodTrials = [goodTrials dataVals(i).token];
    end
end

errors.badTrials = badTrials;
errors.shortTrials = shortTrials;
errors.longTrials = longTrials;
errors.nanFTrials = nanFTrials;
errors.jumpF1Trials = jumpF1Trials;
errors.jumpF2Trials = jumpF2Trials;
errors.wrongFTrials = wrongFTrials;
errors.goodTrials = goodTrials;
    