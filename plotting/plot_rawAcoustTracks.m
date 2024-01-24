function [htracks,hsub] = plot_rawAcoustTracks(dataVals,grouping,trialset,parent,expt,sigs2plot)
%PLOT_RAWACOUSTTRACKS  Plot acoustic tracks from dataVals object.
%   PLOT_RAWACOUSTTRACKS(DATAVALS,GROUPING,TRIALSET,PARENT) plots the
%   formant/f0/amplitude
%   track from each trial in TRIALSET in the figure or
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
if nargin < 3 || isempty(trialset), trialset = [dataVals.token]; end
if nargin < 4 || isempty(parent), h = figure('Units','normalized', 'Position',[.01 .25 .98 .5]); parent = h; end


plotcolor{1} = [0 0 1]; % blue
plotcolor{2} = [1 0 0]; % red

nSigs = length(sigs2plot);
if nSigs > length(plotcolor)
    error('This function can currently only plot 2 signals at a time.')
end

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
    
    %collect the indices of dataVals where the trialset and token values
    %are the same
    [~,inds] =  ismember(trialset, [dataVals.token]);
    
    for i=inds % set of trials (jump, short, late, etc.) 
%         disp(i)
        if (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl) && dataVals(i).(grouping) == groupId
            %plot tracks
            for s = 1:nSigs
                if strcmp(sigs2plot{s},'f1') || strcmp(sigs2plot{s},'f2')
                    taxis = dataVals(i).ftrack_taxis - dataVals(i).ftrack_taxis(1);
                elseif strcmp(sigs2plot{s},'f0') 
                    taxis = dataVals(i).pitch_taxis - dataVals(i).pitch_taxis(1);
                elseif strcmp(sigs2plot{s},'int') 
                    taxis = dataVals(i).ampl_taxis - dataVals(i).ampl_taxis(1);
                else
                    error("Signal type not supported. Must be 'f1', 'f2', 'f0', or 'int'.")
                end
                htracks(g).(sigs2plot{s})(ihandle) = plot(taxis,dataVals(i).(sigs2plot{s}),'Color',plotcolor{s});
                set(htracks(g).(sigs2plot{s})(ihandle),'Tag',num2str(dataVals(i).token),'YdataSource',sigs2plot{s})
                hold on;
            
                %plot ends
                x = taxis(end);
                handleName = strcat(sigs2plot{s},'Ends');
                htracks(g).(handleName)(ihandle) = plot(x,dataVals(i).(sigs2plot{s})(end),'o','MarkerEdgeColor',plotcolor{s},'MarkerFaceColor',get_lightcolor(plotcolor{s},1.2),'MarkerSize',5);
            end
            
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
    if strcmp(sigs2plot{s},'int') 
        ylabel('intensity (Hz)')
    else
        ylabel('frequency (Hz)')
    end
    box off;
    
    makeFig4Screen([],[],0);    
end
