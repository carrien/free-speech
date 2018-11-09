function [] = plot_rawFmtTracks(dataVals,grouping,trialset)
%PLOT_RAWFMTTRACKS  Plot formant tracks from dataVals object.
%   PLOT_RAWFMTTRACKS(DATAVALS,GROUPING,TRIALSET) plots the first and
%   second formant tracks from each trial in TRIALSET.  GROUPING defines
%   the field in DATAVALS by which data should be grouped; e.g. GROUPING =
%   'vowel' will create a separate plot for each vowel.

if nargin < 1 || isempty(dataVals)
    fprintf('Loading dataVals from current directory...')
    load dataVals.mat;
    fprintf(' done.\n')
    if exist(fullfile(cd,'expt.mat'),'file')
        fprintf('Loading expt from current directory...')
        load expt.mat;
        fprintf(' done.\n')
        groupnames = expt.(sprintf('%ss',grouping));
    end
end
if nargin < 2 || isempty(grouping), grouping = 'vowel'; end
if nargin < 3, trialset = 1:length(dataVals); end

f1color = [0 0 1]; % blue
f2color = [1 0 0]; % red

for g=unique([dataVals.(grouping)])
    figure;
    % plot tracks
    for i=trialset
        if (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl) && dataVals(i).(grouping) == g
            taxis = dataVals(i).ftrack_taxis - dataVals(i).ftrack_taxis(1);
            plot(taxis,dataVals(i).f1,'Color',f1color);
            hold on;
            plot(taxis,dataVals(i).f2,'Color',f2color);
        end
    end
    
    % plot ends
    for i=trialset
        if (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl) && dataVals(i).(grouping) == g
            taxis = dataVals(i).ftrack_taxis - dataVals(i).ftrack_taxis(1);
            x = taxis(end);
            plot(x,dataVals(i).f1(end),'o','MarkerEdgeColor',f1color,'MarkerFaceColor',get_lightcolor(f1color,1.2),'MarkerSize',5);
            plot(x,dataVals(i).f2(end),'o','MarkerEdgeColor',f2color,'MarkerFaceColor',get_lightcolor(f2color,1.2),'MarkerSize',5);
        end
    end
    
    % figure labels
    if exist('groupnames','var')
        titlesuffix = sprintf(': %s',groupnames{g});
    else
        titlesuffix = [];
    end
    title(sprintf('%s %d%s',grouping,g,titlesuffix))
    xlabel('time (s)')
    ylabel('frequency (Hz)')
    box off;
    makeFig4Screen([],0);
    
end