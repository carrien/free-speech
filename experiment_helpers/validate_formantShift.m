function [h, e, err] = validate_formantShift(dataPath, p, bInterpret, fieldName)
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
%       err: Struct with information necessary to follow up on
%            discrepancies between fmts and sfmts.
%
% Other validation functions at: https://kb.wisc.edu/smng/109809

% 2021-03 CWN. init. Based very heavily on BP's plot_varMod_byParticipant.

if nargin < 1, dataPath = cd; end
if nargin < 3 || isempty(bInterpret), bInterpret = 1; end
if nargin < 4 || isempty(fieldName), fieldName = 'vowels'; end

load(fullfile(dataPath,'expt.mat'),'expt')
fprintf('Loading data... ')
load(fullfile(dataPath,'data.mat'),'data')
fprintf('done.\n');

nConds = length(expt.conds);
nElements = length(expt.(fieldName));

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
defaultParams.elemInds = 1:nElements;
defaultParams.figpos = get(0,'ScreenSize') + [75 150 -150 -300];
if nargin < 2 || isempty(p)
    p = defaultParams;
else
    p = set_missingFields(p,defaultParams);
end

h = figure('Position', p.figpos);

errIx = 1;
err(errIx).badTrial = [];       % trial number of bad trial

%%
for iCond = 1:nConds
    cond = expt.conds{iCond};
    for iElement = p.elemInds
        elem = expt.(fieldName){iElement};
        trials2analyze = intersect(expt.inds.conds.(cond),expt.inds.(fieldName).(elem));
        
        nTrials = length(trials2analyze);
        
        F1in.(cond).(elem) = NaN(1,nTrials);
        F2in.(cond).(elem) = NaN(1,nTrials);
        F1out.(cond).(elem) = NaN(1,nTrials);
        F2out.(cond).(elem) = NaN(1,nTrials);
        for iTrial = 1:length(trials2analyze)
            trialnum = trials2analyze(iTrial); 
            
            % find signal in points
            samps2plot = find(data(trialnum).fmts(:,1)>10);
            nSamps = length(samps2plot);
            if nSamps == 0, continue; end % skip to next trial if no fmts exists
            
                % average fmt value from 25%-65% after onset
            fWindow(1) = samps2plot(floor(.25*nSamps));
            fWindow(2) = samps2plot(floor(.65*nSamps));
            F1in.(cond).(elem)(iTrial) = hz2mels(mean(data(trialnum).fmts(fWindow(1):fWindow(2),1), 'omitnan'));
            F2in.(cond).(elem)(iTrial) = hz2mels(mean(data(trialnum).fmts(fWindow(1):fWindow(2),2), 'omitnan'));
            
            
            samps2plot_out = find(data(trialnum).sfmts(:,1)>10);
            nSamps_out = length(samps2plot_out);
            
            if nSamps_out == 0, continue; end % skip to next trial if no sfmts exists
            
            % check for fmts and sfmts discrepancies. populate err struct
            if length(samps2plot) ~= length(samps2plot_out) || any(samps2plot ~= samps2plot_out)
                err(errIx).badTrial = trialnum; %#ok<*AGROW>
                err(errIx).diffFrames = setdiff(samps2plot, samps2plot_out);
                
                % make table showing discrepancies between fmts and sfmts
                err(errIx).diffFrames_table = table(hz2mels(data(trialnum).fmts([err(errIx).diffFrames])), ...
                    hz2mels(data(trialnum).sfmts([err(errIx).diffFrames])), ...
                    'VariableNames', {'fmts', 'sfmts'});
                
                % flag if discrepant frames were within sampling window
                if any(err(errIx).diffFrames > fWindow(1) & err(errIx).diffFrames < fWindow(2))
                    err(errIx).errorInWindow = 1;
                else
                    err(errIx).errorInWindow = 0;
                end
                err(errIx).msg = sprintf('Different fmts and sfmts values for trial %d. Evaluate discrepancy.', trialnum);
                %warning(err(errIx).msg);
                
                errIx = errIx + 1;
                continue;
            end
             
                %fWindow(1) = samps2plot_out(floor(.25*nSamps_out));
                %fWindow(2) = samps2plot_out(floor(.65*nSamps_out));
            % use same sampling window for sfmts as fmts
            F1out.(cond).(elem)(iTrial) = hz2mels(mean(data(trialnum).sfmts(fWindow(1):fWindow(2),1), 'omitnan'));
            F2out.(cond).(elem)(iTrial) = hz2mels(mean(data(trialnum).sfmts(fWindow(1):fWindow(2),2), 'omitnan'));
        end
    end
    

    inMarkers = {'s','o','d','^'};
    outMarkers = {'x','*','+','.'};
    labels = expt.conds;
    subplot(1,nConds,iCond)
    h_leg_obj = zeros(p.elemInds(end), 1);
    leg_txt = cell(p.elemInds(end), 1);
    hold on
    for iElement = p.elemInds
        elem = expt.(fieldName){iElement};
        % plot signal in points
        scatter(F1in.(cond).(elem),F2in.(cond).(elem),p.MarkerSize,inMarkers{iElement},'MarkerEdgeColor',p.plotColors(iElement,:))
        [e.(cond).(elem).in] = FitEllipse(F1in.(cond).(elem),F2in.(cond).(elem));
        plot(e.(cond).(elem).in(:,1),e.(cond).(elem).in(:,2),'Color',p.plotColors(iElement,:),'LineWidth',p.LineWidth)
        
        % plot signal out points
        scatter(F1out.(cond).(elem),F2out.(cond).(elem),p.MarkerSizeShifted,outMarkers{iElement},'MarkerEdgeColor',p.plotColorsShifted(iElement,:))
        if ~all(isnan(F1out.(cond).(elem)))
            [e.(cond).(elem).out] = FitEllipse(F1out.(cond).(elem),F2out.(cond).(elem));
            plot(e.(cond).(elem).out(:,1),e.(cond).(elem).out(:,2),'Color',p.plotColorsShifted(iElement,:),'LineWidth',p.LineWidth)
        end
        
        %plot lines connection points
        lines = plot([F1out.(cond).(elem)' F1in.(cond).(elem)']',[F2out.(cond).(elem)' F2in.(cond).(elem)']','-','Color',[.8 .8 .8]);
        uistack(lines, 'bottom');
        
        %prepare objects for legend
        h_leg_obj(iElement) = plot(nan, nan, inMarkers{iElement}, 'color', p.plotColors(iElement, :), 'MarkerSize', 12);
        leg_txt(iElement) = {elem};
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
        %set(gca,'YTick', []); % can un-comment if all axes are Y-aligned
    end
    xlabel('F1')
    title(labels{iCond})
end

if errIx > 1        %it's 1 by default
    warning(sprintf(['\n\nError summary: There were %d trials where fmts and sfmts were different lengths. ' ...
        'For %d of those trials, the discrepant fmts/sfmts values were inside the ' ...
        'sampling window (25-65%%), meaning those trials were more severely affected.'], ...
        length(err), sum([err.errorInWindow]))); %#ok<SPWRN>
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