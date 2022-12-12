function [trigSummary,trigAnalysis,warpSummary,warpAnalysis,fullAnalysis] = timeAdapt_pcfAnalysis(trackingFileLoc,trackingFileName,ost_stat,varargin)
% Checks if OST/PCF settings result in a time delay that occurs at the
% correct point.
%
% Input arguments:
% 1.) exptName: The name of the timeAdapt experiment being run. ex: 'ata'
% 2.) pcf: The file location of the PCF implemented on the speech sample
% 3.) ost_stat: The portion of the .mat file which includes information about
% where OST events occurred, based on OST/PCF settings. (data.ost_stat)
% 4.) appDesigner: (optional.) Default is 0. If using output in app designer, set to 1. 
% 5.) frameDur: (optional.) Default is 0.002. How long a "frame" in Audapter lasts.
%
% Output arguments:
% 1.) trigSummary:  A very brief description of if the target OST triggered.
% 2.) trigAnalysis: Sentence description of what happened with OST trigger.
% 3.) warpSummary:  A very brief "good or bad" description of the time
%           warping as a char array.
% 4.) warpAnalysis: Sentence description of what happened with time warping.
% 5.) fullAnalysis: A table giving information about key events in relation
%           to each other. Each event is a separate row in a char array.

% set frameDur
if nargin <= 3
    appDesigner = 0;
    frameDur = 0.002;
elseif nargin <= 4
    appDesigner = varargin{1};
    frameDur = 0.002;
else
    appDesigner = varargin{1};
    frameDur = varargin{2};
end

% Standard PCF values. Each segment gets a variable
[ostStat_initial, tBegin, rate1, dur1, durHold, rate2] = get_pcf(trackingFileLoc, trackingFileName, 'time', '1', 'all'); 

% Finds OST event that triggered perturbation
ostTrigger = find(ost_stat==ostStat_initial,1) * frameDur - frameDur; % convert to seconds
if isempty(ostTrigger)
    trigSummary = 'No trigger';
    warpSummary = '';
    trigAnalysis = sprintf('OST event %d did not occur. No perturbation took place.',ostStat_initial);
    warpAnalysis = 'No trigger';
    fullAnalysis = sprintf('OST event %d did not occur. No perturbation took place.',ostStat_initial);
    return;
elseif isempty(dur1) || dur1 == 0 || rate1 >= 0.995
    trigSummary = 'No slowdown programmed.';
    warpSummary = '';
    trigAnalysis = 'PCF file missing a slowdown duration (dur1 is zero or missing)';
    warpAnalysis = 'No warp anticipated (no dur1)';
    fullAnalysis = 'PCF file missing a slowdown duration (dur1 is zero or missing)';
    return;
else % Things are going well
    % Extra values for calculating
    trigSummary = 'Good trigger';
    trigAnalysis = '';
    durFast = ((1 - rate1) / (rate2 - 1)) * dur1 ;
    slowStart = ostTrigger + tBegin ;
    slowEnd =   ostTrigger + tBegin + dur1 ;
    holdEnd =   ostTrigger + tBegin + dur1 + durHold ;
    fastEnd =   ostTrigger + tBegin + dur1 + durHold + durFast ;
    
    % Preallocating matrix    
    fullAnalysis(11) = {' '};
%     
    % Column headers
    if appDesigner == 1
        fullAnalysis(1) = {'Event               | Start Time | End Time '};
        fullAnalysis(2) = {sprintf('OST Event %d     |    %.3f     |     -',ostStat_initial,ostTrigger)};
        if tBegin == 0
            fullAnalysis(3) = {'Waiting Period  |     none      |     -'};
        else
            fullAnalysis(3) = {sprintf('Waiting Period |    %.3f     | %.3f',ostTrigger,slowStart)};
        end
        fullAnalysis(4) = {sprintf('Slow Pert.        |    %.3f      | %.3f',slowStart,slowEnd)};
        if durHold == 0
            fullAnalysis(5) = {'Hold Period     |     none      |     -'};
        else
            fullAnalysis(5) = {sprintf('Hold Period      |    %.3f      | %.3f',slowEnd,holdEnd)};
        end
        fullAnalysis(6) = {sprintf('Catch Up          |    %.3f      | %.3f',holdEnd,fastEnd)};
    else 
        fullAnalysis(1) = {'Event           | Start Time | Duration | End Time '};
        fullAnalysis(2) = {sprintf('OST Event %d     |    %.3f   |     -    |    -',ostStat_initial,ostTrigger)};
        if tBegin == 0
            fullAnalysis(3) = {'Waiting Period  |    none    |     -    |    -'};
        else
            fullAnalysis(3) = {sprintf('Waiting Period  |    %.3f  |   %.3f  |  %.3f',ostTrigger,durHold,slowStart)};
        end
        fullAnalysis(4) = {sprintf('Slow Pert.      |    %.3f   |   %.3f  |  %.3f',slowStart,dur1,slowEnd)};
        if durHold == 0
            fullAnalysis(5) = {'Hold Period     |     none      |     -    |    -'};
        else
            fullAnalysis(5) = {sprintf('Hold Period     |    %.3f   |   %.3f  |  %.3f',slowEnd,durHold,holdEnd)};
        end
        fullAnalysis(6) = {sprintf('Catch Up        |    %.3f   |   %.3f  |  %.3f',holdEnd,durFast,fastEnd)};
    end
end

%% Perturbation timing OK or not
if strcmp(trackingFileLoc,'ata') || strcmp(trackingFileLoc,'capper')
    lastOsts = find(ost_stat==(ostStat_initial + 2));
else
    lastOsts = find(ost_stat==(ostStat_initial + 0));
end

try
    timeNextOst = (lastOsts(end) + 1) * frameDur - frameDur;
catch
    warning('timeNextOst in timeAdapt_pcfAnalysis.m couldn''t be calculated. Setting timeNextOst to empty.')
    timeNextOst = [];
end


fullAnalysis(7) = {sprintf('--------------------\nInterpretation:')}; 
if isempty(timeNextOst)
    warpSummary = 'Unknown. Next OST didn''t trigger.';
    warpAnalysis = 'Can''t tell if perturbation occurred during correct window without the next OST event.';
    fullAnalysis(8) = {'Can''t tell if perturbation occurred during correct window without the next OST event.'};
    fullAnalysis(9) = {'Look to graph for judgment call.'};
    fullAnalysis(10) = [];
else % Things are going well
    fullAnalysis(8) = {sprintf('The next OST event occurred at %.3f s.',timeNextOst)};
    pertDur = calcPertValue('perturb','dur1',dur1,'rate1',rate1);
    if timeNextOst > slowEnd && timeNextOst <= holdEnd
        warpAnalysis = 'Great! This is during the Hold Period.';
        fullAnalysis(9) = {'Great! This is during the Hold Period.'};
        fullAnalysis(10) = {sprintf('The consonant was lengthened the full %.3f s.',pertDur)};
        fullAnalysis(11) = [];
        warpSummary = 'Good';
    elseif timeNextOst < slowEnd
        warpAnalysis = 'The slow perturbation persisted into the second vowel.';
        fullAnalysis(9) = {'Not good. This is during the slow perturbation.'};
        fullAnalysis(10) = {'The slow perturbation persisted into the second vowel.'};
        fullAnalysis(11) = {sprintf('The listener experienced less than %.3f s of consonant lengthening.',pertDur)};
        warpSummary = 'Slowdown persisted into the vowel';
    elseif timeNextOst > holdEnd
        warpAnalysis = 'The feedback began speeding up while the speaker was still uttering the consonant.';
        fullAnalysis(9) = {'Not good. This is after the hold period has ended.'};
        fullAnalysis(10) = {'The feedback began speeding up while the speaker was still uttering the consonant.'};
        fullAnalysis(11) = {sprintf('The listener experienced less than %.3f s of consonant lengthening.',pertDur)};
        warpSummary = 'Speedup began during the consonant';
    else
        warpSummary = 'Help';
        warpAnalysis = 'Analysis help';
    end
    
    
end

varargout{1} = trigSummary; 
varargout{2} = trigAnalysis; 
varargout{3} = warpSummary;
varargout{4} = warpAnalysis; 
varargout{5} = fullAnalysis;

end

