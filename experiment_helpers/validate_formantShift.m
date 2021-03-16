function [h,e] = validate_formantShift(dataPath, p, pertConds)
% Calculates the average formant for a trial. For certain conditions (those
%   listed in `pertConds`), plots the average formant from signalIn and
%   compares it against the average formant from signalOut. Shows different
%   plots for different conditions in expt.conds.
%
%   Can validate post-hoc that the proper perturbations were applied during
%   an experiment.
%
% In:   dataPath:   Filepath where data.mat and expt.mat files are saved.
%       p:   Audapter parameters.
%       pertConds:   1xLength cell array of strings (which match elements
%           in expt.conds). Include any condition names where you want to
%           plot both the signalIn formants and signalOut formants. Any
%           conditions not in this list will only have signalIn fmts plotted.
%
% Out:  h:   Handle for the figure.
%       e:   Properties of the ellipses drawn in the figures.
%
%
% 2021-03 CWN. init. Based very heavily on CN's plot_varMod_byParticipant.

if nargin < 1, dataPath = cd; end

load(fullfile(dataPath,'expt.mat'),'expt')
load(fullfile(dataPath,'data.mat'),'data')
%signalIn = load(fullfile(dataPath,'dataVals.mat'),'dataVals');
%signalOut = load(fullfile(dataPath,'dataVals_signalOut.mat'),'dataVals');

h = figure;
nConds = length(expt.conds);
nVows = length(expt.vowels);

if nargin < 3 || isempty(pertConds)
    if length(expt.conds) == 1
        pertConds = expt.conds(1);
    else
        pertConds = expt.conds(2:end);
    end
end

%% set default params
defaultParams.plotColors = [0 .8 0;...
                    0 .2 1; ...
                    0 .8 .8; ...
                    .8 0 0];
defaultParams.plotColorsShifted = .7*[0 .8 0;...
                    0 .2 1; ...
                    0 .8 .8; ...
                    .8 0 0];                
defaultParams.LineWidth = 1.5;
defaultParams.MarkerSize = 15;
defaultParams.MarkerSizeShifted = 20;
defaultParams.vowInds = 1:nVows;
if nargin < 2 || isempty(p)
    p = defaultParams;
else
    p = set_missingFields(p,defaultParams);
end

%%
for iCond = 1:nConds
    cond = expt.conds{iCond};
    %if strcmp(cond,'shiftIH') || strcmp(cond, 'shiftAE')
    %if strcmp(cond,'hold')
    if any(strcmpi(cond, pertConds))
        bPert = 1;
    else
        bPert = 0;
    end
    for iVow = p.vowInds
        vow = expt.vowels{iVow};
        trials2analyze = intersect(expt.inds.conds.(cond),expt.inds.vowels.(vow));
        
        nTrials = length(trials2analyze);
        
        %inds2analyze = intersect(dataVals);
        
        F1in.(cond).(vow) = NaN(1,nTrials);
        F2in.(cond).(vow) = NaN(1,nTrials);
        F1out.(cond).(vow) = NaN(1,nTrials);
        F2out.(cond).(vow) = NaN(1,nTrials);
        for iTrial = 1:length(trials2analyze)
            trialnum = trials2analyze(iTrial);
            samps2plot = find(data(trialnum).fmts(:,1)>10);
            nSamps = length(samps2plot);
            fWindow(1) = samps2plot(floor(.25*nSamps));
            fWindow(2) = samps2plot(floor(.5*nSamps));
            F1in.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).fmts(fWindow(1):fWindow(2),1)));
            F2in.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).fmts(fWindow(1):fWindow(2),2)));

            if bPert
                samps2plot = find(data(trialnum).sfmts(:,1)>10);
                nSamps = length(samps2plot);
                fWindow(1) = samps2plot(floor(.25*nSamps));
                fWindow(2) = samps2plot(floor(.65*nSamps));
                F1out.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).sfmts(fWindow(1):fWindow(2),1)));
                F2out.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).sfmts(fWindow(1):fWindow(2),2)));
            end
        end
    end
    

    inMarkers = {'s','o','d','^'};
    outMarkers = {'x','*','+','.'};
    labels = expt.conds;
    subplot(1,nConds,iCond)
    hold on
    for iVow = p.vowInds
        vow = expt.vowels{iVow};
        scatter(F1in.(cond).(vow),F2in.(cond).(vow),p.MarkerSize,inMarkers{iVow},'MarkerEdgeColor',p.plotColors(iVow,:))
        [e.(cond).(vow).in] = FitEllipse(F1in.(cond).(vow),F2in.(cond).(vow));
        plot(e.(cond).(vow).in(:,1),e.(cond).(vow).in(:,2),'Color',p.plotColors(iVow,:),'LineWidth',p.LineWidth)
        if bPert
            scatter(F1out.(cond).(vow),F2out.(cond).(vow),p.MarkerSizeShifted,outMarkers{iVow},'MarkerEdgeColor',p.plotColorsShifted(iVow,:))
            [e.(cond).(vow).out] = FitEllipse(F1out.(cond).(vow),F2out.(cond).(vow));
            plot(e.(cond).(vow).out(:,1),e.(cond).(vow).out(:,2),'Color',p.plotColorsShifted(iVow,:),'LineWidth',p.LineWidth)
        
        %plot lines connection points
            plot([F1out.(cond).(vow)' F1in.(cond).(vow)']',[F2out.(cond).(vow)' F2in.(cond).(vow)']','-','Color',[.8 .8 .8])
        end
        
    end
    hold off
    %xlims = [650 950];
    %ylims = [1200 2000];
    %xlim(xlims);
    %ylim(ylims);
    if iCond ==1
        %set(gca,'XTick',[650 950], 'YTick', [1200 2000])
        ylabel('F2')
    else
        %set(gca,'XTick',[650 950]);
        set(gca,'YTick', []);
    end
    xlabel('F1')
    title(labels{iCond})
end


end