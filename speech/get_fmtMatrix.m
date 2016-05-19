function [rawf1,rawf2] = get_fmtMatrix(dataVals,inds,bMels,bFilt)
%GET_FMTMATRIX  Generate matrix of formant tracks from a dataVals object.
%   GET_FMTMATRIX(DATAVALS,INDS,BMELS,BFILT) extracts only the trials INDS
%   from DATAVALS and concatenates their formant tracks into the matrices
%   RAWF1 and RAWF2. BMELS and BFILT are binary variables that determine
%   whether the formant tracks are converted to mels and filtered,
%   respectively.
%
% CN 5/2014
% TODO: return a single struct RAWTRACKS with fields f1, f2, f0...?

if nargin < 2 || isempty(inds), inds = 1:length(dataVals); end
if nargin < 3 || isempty(bMels), bMels = 1; end
if nargin < 4 || isempty(bFilt), bFilt = 1; end

rawf1 = []; rawf2 = [];
for trialind = inds  % for each trial in the condition
    dat1 = dataVals(trialind).f1; % assumes Hz
    dat2 = dataVals(trialind).f2;
    
    if bFilt % try filtering
        hb = hamming(8)/sum(hamming(8));
        try
            dat1 = filtfilt(hb, 1, dat1);
            dat2 = filtfilt(hb, 1, dat2);
        catch  %#ok<*CTCH>
        end
    end
    
    if bMels % convert to mels
        dat1 = hz2mels(dat1);
        dat2 = hz2mels(dat2);
    end
    
    % add data to matrix
    rawf1 = nancat(rawf1,dat1);
    rawf2 = nancat(rawf2,dat2);
end