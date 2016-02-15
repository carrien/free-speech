function [outs] = plot_rawTracks(dataVals,whichtracks,split)
%PLOT_RAWTRACKS  Plot formant tracks from dataVals object.
%   PLOT_RAWTRACKS(DATAVALS,WHICHTRACKS,SPLIT) plots the specified
%   pitch or formant tracks from each trial in DATAVALS against an optional
%   time axis TAXIS.  SPLIT defines the field in DATAVALS by which data should
%   be grouped; e.g. SPLIT = 'vowel' will create a separate plot for each
%   vowel.  The function returns OUTS, a vector of outliers.

if nargin < 2, whichtracks = [0 1 1]; end
if nargin < 3, split = 'vowel'; end

tracknames = {'f0' 'f1' 'f2'};
%axis2use = {'pitch_taxis' 'ftrack_taxis' 'ftrack_taxis'};
colors = varycolor(length(tracknames));

for j=unique([dataVals.(split)])
    figure;
    for i=1:length(dataVals)
        if dataVals(i).(split) == j && (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl)
            for k=1:length(whichtracks)
                if whichtracks(k)
                    %taxis_itvl = mode(diff(dataVals(1).(axis2use{k})));
                    %plot(taxis_itvl.*(0:len-1),dataVals(i).(tracknames{k}),'Color',colors(k,:));
                    plot(dataVals(i).(tracknames{k}),'Color',colors(k,:));
                    hold on;
                end
            end
        end;
    end;
end
xlabel('time (s)')
ylabel('freq (Hz)')
title('Click to drag a rectangle around outliers. Double-click in the rectangle to accept.')

% capture box coords
set(gcf,'Position',[50 50 1200 660])
h = imrect(gca);
setColor(h,'black');
pos = wait(h);
x = [pos(1) pos(1)+pos(3)];
y = [pos(2) pos(2)+pos(4)];

frange = y(1):y(2);
trange = max(floor(x(1)),1):ceil(x(2));

% find trials with tracks within box
outs = get_trials_in_range(dataVals,1,'f0',frange,trange);
% overlay them in red
for o=outs
    for k=1:length(whichtracks)
        if whichtracks(k)
            plot(dataVals(o).(tracknames{k}),'r');
        end
    end
end