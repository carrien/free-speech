function [rangeSig] = rangeperc(signal,range)
%RANGEPERC Returns a the section of a signal within a provided range.
%   RANGEPERC(SIGNAL,RANGE)
%       Returns the samples of input SIGNAL that fall within a
%       provided RANGE of percentages between 0 and 100.
%
%       SIGNAL: non empty vector containing signal to be restricted within
%       the range.
%       RANGE: should be a vector [start end] containing the percentages
%           eg. the whole signal is [0 100]

%Error if signal is missing or empty
if nargin < 1 || isempty(signal), error('rangeperc requires a signal argument that is not empty'); end

%handle missing range argument
if nargin < 2 || isempty(range), range = ...
        input('Please enter a range in the form [x y], where x/y are the starting/ending percentages between 0 and 100: '); end

%% Find indices containing range
startVal = range(1);
endVal = range(2);

%OOB percentages or end before start
if startVal < 0 || endVal > 100
    error('Supplied percentages must be between 0 and 100')
elseif endVal < startVal
    error('Second percentage supplied must be greater than the first')
end

%compute indices from provided percentages
if startVal == 0
    startInd = 1;
else
    startInd = ceil(startVal*.01*length(signal));
end
endInd = floor(endVal*.01*length(signal));

%set return signal to the input signal indexed at the computed indicies.
rangeSig = signal(startInd:endInd);

end