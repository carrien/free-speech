function [] = plot_rawFmtTracks(dataVals,taxis,grouping,trialset)
%PLOT_RAWFMTTRACKS  Plot formant tracks from dataVals object.
%   PLOT_RAWFMTTRACKS(DATAVALS,TAXIS,SPLIT,TRIALSET) plots the first and
%   second formant tracks from each trial in TRIALSET against an optional
%   time axis TAXIS.  GROUPING defines the field in DATAVALS by which data
%   should be grouped; e.g. GROUPING = 'vowel' will create a separate plot
%   for each vowel.

if nargin < 2 || isempty(taxis), taxis = 1; end
if nargin < 3 || isempty(grouping), grouping = 'vowel'; end
if nargin < 4, trialset = 1:length(dataVals); end

for j=unique([dataVals.(grouping)])
    figure;
    for i=trialset
        if dataVals(i).(grouping) == j && (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl)
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
    
    % plot ends
    for i=trialset
        if dataVals(i).(grouping) == j && (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl)
            len = length(dataVals(i).f1);
            if taxis
                plot(.003*(len-1),dataVals(i).f1(end),'co');
                plot(.003*(len-1),dataVals(i).f2(end),'mo');
            else
                plot(len,dataVals(i).f1(end),'co');
                plot(len,dataVals(i).f2(end),'mo');
            end
            
        end
    end
    
end