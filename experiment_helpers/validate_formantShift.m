function [h,e] = validate_formantShift(dataPath, p, bInterpret)
% Calculates the average formant for a trial. Plots the average formant
%   from signalIn and compares it against the average formant from
%   signalOut. Shows different plots for different conditions in expt.conds.
%
%   Can validate post-hoc that the proper perturbations were applied during
%   an experiment.
%
% In:   dataPath:   Filepath where data.mat and expt.mat files are saved.
%       p:   Plot parameters.
%       bInterpret:   Binary flag for if you want information about how to
%           interpret the data to be printed to the screen. Default 1 (print).
%
% Out:  h:   Handle for the figure.
%       e:   Properties of the ellipses drawn in the figures.

% 2021-03 CWN. init. Based very heavily on BP's plot_varMod_byParticipant.

if nargin < 1, dataPath = cd; end
if nargin < 3 || isempty(bInterpret), bInterpret = 1; end

load(fullfile(dataPath,'expt.mat'),'expt')
load(fullfile(dataPath,'data.mat'),'data')

nConds = length(expt.conds);
nVows = length(expt.vowels);

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
defaultParams.figpos = get(0,'ScreenSize') + [75 150 -150 -300];
if nargin < 2 || isempty(p)
    p = defaultParams;
else
    p = set_missingFields(p,defaultParams);
end

h = figure('Position', p.figpos);

%%
for iCond = 1:nConds
    cond = expt.conds{iCond};
    for iVow = p.vowInds
        vow = expt.vowels{iVow};
        trials2analyze = intersect(expt.inds.conds.(cond),expt.inds.vowels.(vow));
        
        nTrials = length(trials2analyze);
        
        F1in.(cond).(vow) = NaN(1,nTrials);
        F2in.(cond).(vow) = NaN(1,nTrials);
        F1out.(cond).(vow) = NaN(1,nTrials);
        F2out.(cond).(vow) = NaN(1,nTrials);
        for iTrial = 1:length(trials2analyze)
            trialnum = trials2analyze(iTrial);
            
            % TODO CWN test same points for in and out, continue if either is zero
            
            % find signal in points
            samps2plot = find(data(trialnum).fmts(:,1)>10);
            nSamps = length(samps2plot);
            if nSamps == 0, continue; end % skip to next trial if no sfmts exists
                % average fmt value from 25%-65% after onset
            fWindow(1) = samps2plot(floor(.25*nSamps));
            fWindow(2) = samps2plot(floor(.65*nSamps));
            F1in.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).fmts(fWindow(1):fWindow(2),1)));
            F2in.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).fmts(fWindow(1):fWindow(2),2)));
            
            % find signal out points
            samps2plot = find(data(trialnum).sfmts(:,1)>10);
            nSamps = length(samps2plot);
            if nSamps == 0, continue; end % skip to next trial if no sfmts exists
            
            fWindow(1) = samps2plot(floor(.25*nSamps));
            fWindow(2) = samps2plot(floor(.65*nSamps));
            F1out.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).sfmts(fWindow(1):fWindow(2),1)));
            F2out.(cond).(vow)(iTrial) = hz2mels(nanmean(data(trialnum).sfmts(fWindow(1):fWindow(2),2)));
        end
    end
    

    inMarkers = {'s','o','d','^'};
    outMarkers = {'x','*','+','.'};
    labels = expt.conds;
    subplot(1,nConds,iCond)
    h_leg_obj = zeros(p.vowInds(end), 1);
    leg_txt = cell(p.vowInds(end), 1);
    hold on
    for iVow = p.vowInds
        vow = expt.vowels{iVow};
        % plot signal in points
        scatter(F1in.(cond).(vow),F2in.(cond).(vow),p.MarkerSize,inMarkers{iVow},'MarkerEdgeColor',p.plotColors(iVow,:))
        [e.(cond).(vow).in] = FitEllipse(F1in.(cond).(vow),F2in.(cond).(vow));
        plot(e.(cond).(vow).in(:,1),e.(cond).(vow).in(:,2),'Color',p.plotColors(iVow,:),'LineWidth',p.LineWidth)
        
        % plot signal out points
        scatter(F1out.(cond).(vow),F2out.(cond).(vow),p.MarkerSizeShifted,outMarkers{iVow},'MarkerEdgeColor',p.plotColorsShifted(iVow,:))
        if ~all(isnan(F1out.(cond).(vow)))
            [e.(cond).(vow).out] = FitEllipse(F1out.(cond).(vow),F2out.(cond).(vow));
            plot(e.(cond).(vow).out(:,1),e.(cond).(vow).out(:,2),'Color',p.plotColorsShifted(iVow,:),'LineWidth',p.LineWidth)
        end
        
        %plot lines connection points
        lines = plot([F1out.(cond).(vow)' F1in.(cond).(vow)']',[F2out.(cond).(vow)' F2in.(cond).(vow)']','-','Color',[.8 .8 .8]);
        uistack(lines, 'bottom');
        
        %prepare objects for legend
        h_leg_obj(iVow) = plot(nan, nan, inMarkers{iVow}, 'color', p.plotColors(iVow, :), 'MarkerSize', 12);
        leg_txt(iVow) = {vow};
    end
    lgd = legend(h_leg_obj, leg_txt, 'Location', 'southwest', 'FontSize', 10);
    title(lgd, 'signalIn properties');
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


%% print interpretation to screen
if bInterpret
    fprintf(['\n\n==========  How to interpret your results:  ==========\n' ...
        'For basic info, read function header. (run `help validate_formantShift`)\n\n']);
    fprintf(['Within each figure, O or Square or Diamond represents signalIn, X or + or *\n' ...
        ' represents signalOut, and the line represents the difference between\n' ...
        ' signalIn and signalOut on a single trial. For conditions where no shift is\n' ...
        ' expected, the O and X should be exactly on top of each other, which may look\n' ...
        ' like a square. Note also that the lighter variant of a color represents\n' ...
        ' signalIn and its darker variant is signalOut. This applies for both O and X\n' ...
        ' as well as the big circles (ellipses). The ellipse represents the \n' ...
        ' approximate scope of the data, and how similar the dataset is.\n\n']);
    fprintf(['The ANGLE of a line is its shift angle, a.k.a. phi, if using Audapter. The\n' ...
        ' LENGTH of a line is its shift magnitude. For many experiments, the shift\n' ...
        ' angle should be the same for all trials within a condition. Verify that this\n' ...
        ' is true. For some experiments, the shift magnitude should be different\n' ...
        ' within some conditions (a RAMP phase), but should be the same for all trials\n' ...
        ' within a different condition (a HOLD phase).\n\n']);
    fprintf(['You may want to zoom in to view trials from one word more closely. To do\n' ...
        ' this, hover your mouse over the figure you want to zoom in on. In the top\n' ...
        ' right, click the magnifying glass with the + sign. Click and drag on the\n' ...
        ' axis the region you want to zoom in to.\n\n']);
    fprintf(['Other things to note: You may have a few trials that are very far away from\n' ...
        ' their ellipse (meaning, they had very different F1 and F2 than the average).\n' ...
        ' As long as there''s only a few of these, they can safely be ignored. Each dot\n' ...
        ' is averaging [F1 F2] values from within the 25-65%% window of a vowel. (Or\n' ...
        ' more specifically, it considers the 25-65%% window of formant tracking values\n' ...
        ' that Audapter returned, and Audapter sometimes accidentally tracks formants\n' ...
        ' during non-vowels.) So if a vowel was very short or tracked improperly in\n' ...
        ' Audapter, you may see unusual values.\n\n']);
    fprintf(' Set input argument bInterpret == 0 to stop seeing this message.\n\n');
end



end