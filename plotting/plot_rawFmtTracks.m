function [htracks,hsub] = plot_rawFmtTracks(dataVals,grouping,trialset,parent,expt)
%PLOT_RAWFMTTRACKS  Plot formant tracks from dataVals object.
%   PLOT_RAWFMTTRACKS(DATAVALS,GROUPING,TRIALSET,PARENT) plots the first and
%   second formant tracks from each trial in TRIALSET in the figure or
%   panel defined by PARENT.  GROUPING defines the field in DATAVALS by
%   which data should be grouped; e.g. GROUPING = 'vowel' will create a
%   separate subplot for each vowel.

if nargin < 2 || isempty(grouping), grouping = 'vowel'; end
if nargin < 1 || isempty(dataVals)
    fprintf('Loading dataVals from current directory...')
    load dataVals.mat;
    fprintf(' done.\n')
    if exist(fullfile(cd,'expt.mat'),'file')
        fprintf('Loading expt from current directory...')
        load expt.mat;
        fprintf(' done.\n')
    end
end
if nargin < 3 || isempty(trialset), trialset = 1:length(dataVals); end
if nargin < 4 || isempty(parent), h = figure('Units','normalized', 'Position',[.01 .25 .98 .5]); parent = h; end

f1color = [0 0 1]; % blue
f2color = [1 0 0]; % red

groups = unique([dataVals.(grouping)]);

% RPK for non-compressed display with fewer words 
if length(groups) < 4
    nCols = length(groups); 
else
    nCols = 4;
end
for g = 1:length(groups)
    groupId = groups(g); 
    hsub(g) = subplot(ceil(length(groups)/nCols), nCols, g, 'Parent', parent);
%     hsub(g) = subplot(1,length(groups),g,'Parent',parent);
    % plot tracks and ends
    ihandle = 1;
    for i=trialset % set of trials (jump, short, late, etc.) 
%         disp(i)
        if (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl) && dataVals(i).(grouping) == groupId
            %plot tracks
            taxis = dataVals(i).ftrack_taxis - dataVals(i).ftrack_taxis(1);
            htracks(g).f1(ihandle) = plot(taxis,dataVals(i).f1,'Color',f1color);
            set(htracks(g).f1(ihandle),'Tag',num2str(i),'YdataSource','f1')
            hold on;
            htracks(g).f2(ihandle) = plot(taxis,dataVals(i).f2,'Color',f2color);
            set(htracks(g).f2(ihandle),'Tag',num2str(i),'YdataSource','f2')
            
            %plot ends
            x = taxis(end);
            htracks(g).f1Ends(ihandle) = plot(x,dataVals(i).f1(end),'o','MarkerEdgeColor',f1color,'MarkerFaceColor',get_lightcolor(f1color,1.2),'MarkerSize',5);
            htracks(g).f2Ends(ihandle) = plot(x,dataVals(i).f2(end),'o','MarkerEdgeColor',f2color,'MarkerFaceColor',get_lightcolor(f2color,1.2),'MarkerSize',5);
            
            ihandle = ihandle+1;
        end
    end
    
    % figure labels
    if exist('expt','var')
        groupnames = expt.(sprintf('%ss',grouping));
        titlesuffix = sprintf(': %s',groupnames{groupId});
    else
        titlesuffix = [];
    end
    title(sprintf('%s %d%s',grouping,groupId,titlesuffix))
    xlabel('time (s)')
    ylabel('frequency (Hz)')
    box off;
    
    makeFig4Screen([],[],0);    
end
