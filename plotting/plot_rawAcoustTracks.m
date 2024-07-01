function [htracks,hsub] = plot_rawAcoustTracks(dataVals,grouping,trialset,parent,expt,sigs2plot)
%PLOT_RAWACOUSTTRACKS  Plot acoustic tracks from dataVals object.
%   PLOT_RAWACOUSTTRACKS(DATAVALS,GROUPING,TRIALSET,PARENT) plots the
%   formant/f0/amplitude
%   track from each trial in TRIALSET in the figure or
%   panel defined by PARENT.  GROUPING defines the field in DATAVALS by
%   which data should be grouped; e.g. GROUPING = 'vowel' will create a
%   separate subplot for each vowel.

if nargin < 1 || isempty(dataVals)
    fprintf('Loading dataVals from current directory...')
    load dataVals.mat;
    fprintf(' done.\n')
end
if nargin < 2 || isempty(grouping), grouping = 'vowel'; end
if nargin < 3 || isempty(trialset), trialset = [dataVals.token]; end
if nargin < 4 || isempty(parent), h = figure('Units','normalized', 'Position',[.01 .25 .98 .5]); parent = h; end
if nargin < 5 || isempty(expt)
    if exist(fullfile(cd,'expt.mat'),'file')
            fprintf('Loading expt from current directory...')
            load expt.mat;
            fprintf(' done.\n')
    end
end
if nargin < 6 || isempty(sigs2plot); sigs2plot = {'f1','f2'}; end


plotcolor{1} = [0 0 1]; % blue
plotcolor{2} = [1 0 0]; % red

nSigs = length(sigs2plot);
if nSigs > length(plotcolor)
    error('This function can currently only plot 2 signals at a time.')
end

groups = unique([dataVals.(grouping)]);

% RPK for non-compressed display with fewer words 
nCols = min(length(groups),4); 
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
                sigtype = sigs2plot{s};
                if strcmp(sigtype,'f1') || strcmp(sigtype,'f2')
                    taxis = dataVals(i).ftrack_taxis - dataVals(i).ftrack_taxis(1);
                elseif strcmp(sigtype,'f0') 
                    taxis = dataVals(i).pitch_taxis - dataVals(i).pitch_taxis(1);
                elseif strcmp(sigtype,'int') 
                    taxis = dataVals(i).ampl_taxis - dataVals(i).ampl_taxis(1);
                else
                    error("Signal type not supported. Must be 'f1', 'f2', 'f0', or 'int'.")
                end
                htracks(g).(sigtype)(ihandle) = plot(taxis,dataVals(i).(sigtype),'Color',plotcolor{s});
                set(htracks(g).(sigtype)(ihandle),'Tag',num2str(dataVals(i).token),'YdataSource',sigtype)
                hold on;
            
                %plot ends
                x = taxis(end);
                handleName = strcat(sigtype,'Ends');
                htracks(g).(handleName)(ihandle) = plot(x,dataVals(i).(sigtype)(end),'o','MarkerEdgeColor',plotcolor{s},'MarkerFaceColor',get_lightcolor(plotcolor{s},1.2),'MarkerSize',5);
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
    if strcmp(sigs2plot{1},'int') 
        ylabel('intensity')
    else
        ylabel('frequency (Hz)')
    end
    box off;
    
    makeFig4Screen([],[],0);    
end
