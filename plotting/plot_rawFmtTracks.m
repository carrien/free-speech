function [bShort] = plot_rawFmtTracks(dataVals,taxis,split)
%PLOT_RAWFMTTRACKS  Plot formant tracks from dataVals object.
%   PLOT_RAWFMTTRACKS(DATAVALS,TAXIS,SPLIT) plots the first and second
%   formant tracks from each trial in DATAVALS against an optional time
%   axis TAXIS.  SPLIT defines the field in DATAVALS by which data should
%   be grouped; e.g. SPLIT = 'vowel' will create a separate plot for each
%   vowel.  The function returns BSHORT, a vector of trials less than 30
%   elements long.

if nargin < 2, taxis = 1; end
if nargin < 3, split = 'vowel'; end
bShort = zeros(1,length(dataVals));

for j=unique([dataVals.(split)])
    figure;
    for i=1:length(dataVals)
        if dataVals(i).(split) == j && (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl)
            len = length(dataVals(i).f1);
            if len < 30
                bShort(i) = 1;
            end
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