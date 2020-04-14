function [meanF1,meanF2] = calc_avgVowelSpace_crossSubj(dataPaths,fdataFile,avgFn)
%CALC_AVGVOWELSPACE_CROSSSUBJ  Calculate average vowel space across subjects.
%   CALC_AVGVOWELSPACE_CROSSSUBJ(DATAPATHS,FDATAFILE,AVGFN) returns the
%   average F1-F2 space across subjects whose data are in DATAPATHS.
%   FDATAFILE is the name of the fdata file to load (e.g. fdata_cond).
%   AVGFN is the window in which to average the formants (e.g. first50ms).
%
%CN 5/2019

if nargin < 2 || isempty(fdataFile), fdataFile = 'fdata_word'; end
if nargin < 3, avgFn = 'mid50p'; end

% load fdata for each subject
for s = 1:length(dataPaths)
    dataPath = dataPaths{s}; 
    load(fullfile(dataPath,fdataFile),'fmtdata')
    
    % get word-specific median formants
    words = fieldnames(fmtdata.mels);
    for w = 1:length(words)
        word = words{w};
        f1(s).(word) = fmtdata.mels.(word).(avgFn).med.f1;
        f2(s).(word) = fmtdata.mels.(word).(avgFn).med.f2;
    end
    
    magShift(s).rid = sqrt( (f1(s).rid - f1(s).red)^2 + (f2(s).rid - f2(s).red)^2 );
    magShift(s).rad = sqrt( (f1(s).rad - f1(s).red)^2 + (f2(s).rad - f2(s).red)^2 );

    magShift(s).grin = sqrt( (f1(s).grin - f1(s).green)^2 + (f2(s).grin - f2(s).green)^2 );
    magShift(s).grain = sqrt( (f1(s).grain - f1(s).green)^2 + (f2(s).grain - f2(s).green)^2 );

    magShift(s).bleed = sqrt( (f1(s).bleed - f1(s).blue)^2 + (f2(s).bleed - f2(s).blue)^2 );
    magShift(s).blow = sqrt( (f1(s).blow - f1(s).blue)^2 + (f2(s).blow - f2(s).blue)^2 );
    
end

% average across all subjects
for w = 1:length(words)
    word = words{w};
    allF1s.(word) = [f1.(word)];
    meanF1.(word) = nanmean(allF1s.(word));
    allF2s.(word) = [f2.(word)];
    meanF2.(word) = nanmean(allF2s.(word));
end
