function [rangeSig] = rangeperc(signal,range)
%RANGEPERC   Returns the samples of input signal that fall within a
%provided percentage range.
%Range should be a vector [start end] containing the percentages
% eg. the whole signal is [0 100]

startPerc = range(1);
endPerc = range(2);

if startPerc < 0 || endPerc > 100
    error('Supplied percentages must be between 0 and 100')
elseif endPerc < startPerc
    error('Second percentage supplied must be greater than the first')
end


if range(1) == 0
    startInd = 1;
else
    startInd = ceil(startPerc*.01*length(signal));
end
endInd = floor(endPerc*.01*length(signal));
rangeSig = signal(startInd:endInd);




end