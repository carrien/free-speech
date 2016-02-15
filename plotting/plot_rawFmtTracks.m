function [] = plot_rawFmtTracks(dataVals,taxis,split,trialset)
%PLOT_RAWFMTTRACKS  Plot formant tracks from dataVals object.
%   PLOT_RAWFMTTRACKS(DATAVALS,TAXIS,SPLIT,TRIALSET) plots the first and
%   second formant tracks from each trial in TRIALSET against an optional
%   time axis TAXIS.  SPLIT defines the field in DATAVALS by which data
%   should be grouped; e.g. SPLIT = 'vowel' will create a separate plot for
%   each vowel.

if nargin < 2 || isempty(taxis), taxis = 1; end
if nargin < 3 || isempty(split), split = 'vowel'; end
if nargin < 4, trialset = 1:length(dataVals); end

for j=unique([dataVals.(split)])
    figure;
    for i=trialset
        if dataVals(i).(split) == j && (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl)
            len = length(dataVals(i).f1);
            if taxis
                plot(.003.*(0:len-1),dataVals(i).f1,'b');
                hold on;
                plot(.003.*(0:len-1),dataVals(i).f2,'r');
            else
                plot(dataVals(i).f1,'b');
                hold on;
                plot(dataVals(i).f2,'r');
            end
        end;
    end;
end