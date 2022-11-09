function [expt] = adjust_experimentSettings(expt, h_fig, adjustment)
% This function can be called by pressing 'e' on the keyboard during an experiment ('e' for experiment settings) 
% 
% Currently only used by taimComp but theoretically could be used by any experiment that wanted to change any of these
% parameters about an experiment: 
% 
% - LPC order (this is already general to all experiments) 
% - Trial duration (particularly relevant for patient populations) (this is also general to all experiments) 
% - Target vowel durations (for duration training in compensation studies) (would have to be customized in the switch/case
% since taimComp uses multiple min/maxes for different words) 
% 
% inputs: 
% 
%   expt                    The expt structure for the experiment. You are almost certainly changing a setting that is saved
%                           in expt. 
% 
%   h_fig                   The experiment figure handle so that you can display a pause message to the participant
% 
%   adjustment              The kind of adjustment you want to make. 
% 
% Supported adjustments: 
% 
%   'LPC' (or 'lpc')        The LPC order. This is resaved under expt.audapterParams.nLPC
% 
%   'trialdur'              The duration of the trial (stimulus presentation) 
% 
%   'targetdur'             The target duration of whatever word you are duration training on. Will give you the option to
%                           change minimum or maximum. This will apply for ALL WORDS (not just one), with appropriate
%                           adjustments made for aijWord
% 
% In all cases, the current value will be displayed to you, and then you will be asked to provide the new value. 
%   
% Initiated RPK 11/7/2022, based on adjustOSTs
% 
% 

dbstop if error 

%% Set exptOst so that you don't lose original expt 
exptAdjust = expt; 

% Save original expt as original 
% TODO: the TRUE original should probably be save-saved? And then if you adjust multiple times you get different files... 
save(fullfile(expt.dataPath, 'expt_orig.mat'), 'expt'); % Because in some cases you may have changed expt to have a different trackingFileName 
fprintf('Original expt structure saved as expt_orig.mat. \n'); 


%% Display surface pause information 
get_figinds_audapter;

% text params
pausetxt = 'The experiment has been paused. Please wait for a few moments.';
pausetxt = textwrap({pausetxt}, 50); 
conttxt = 'We will now continue with the experiment.';
txtparams.Color = 'white';
txtparams.FontSize = 60;
txtparams.HorizontalAlignment = 'center';
txtparams.Units = 'normalized';

% display pause text and wait for keypress
figure(h_fig(stim))
h1_sub = subplot(1,1,1);
set(h1_sub, 'color', 'black')
axis off
h_text = text(.5,.5,pausetxt,txtparams);
CloneFig(h_fig(stim),h_fig(dup))

%% The actual adjustment

switch adjustment
    case {'lpc' 'LPC'}
        currentSetting = expt.audapterParams.nLPC; 
        question = sprintf('The current LPC order is %d. What would you like to set as the new LPC order?', currentSetting); 
        newLPC = askNChoiceQuestion(question, [9 11 13 15 17 19], 0); 
        exptAdjust.audapterParams.nLPC = newLPC; 
        
        % Initiate new LPC order into Audapter
        p = exptAdjust.audapterParams; 
        AudapterIO('init', p);        
        
    case {'trialdur'}
        currentSetting = expt.timing.stimdur; 
        question = sprintf('The current trial duration is %.2f seconds. What would you like to set as the new trial duration? ', currentSetting); 
        newStimdur = input(question); 
        exptAdjust.timing.stimdur = newStimdur; 
        
    case {'targetdur'}
        currentMin = expt.durcalc.(expt.aiWord).min_dur * 1000; 
        currentMax = expt.durcalc.(expt.aiWord).max_dur * 1000; 
        newMin = 1; 
        newMax = 0; 
        while newMax < newMin
            if newMax
                fprintf('Your minimum duration is longer than your maximum duration!\n'); 
            end
            questionMin = sprintf('The current MINIMUM target duration of /ai/ is %d ms. What would you like to set as the new minimum (in ms)? ', currentMin); 
            questionMax = sprintf('The current MAXIMUM target duration of /ai/ is %d ms. What would you like to set as the new maximum (in ms)? ', currentMax); 
            
            newMin = input(questionMin) / 1000; 
            newMax = input(questionMax) / 1000;            
        end
        
        % Set in the individual words
        exptAdjust.durcalc.(expt.aiWord).min_dur = newMin; 
        exptAdjust.durcalc.(expt.aiWord).max_dur = newMax; 
            
        exptAdjust.durcalc.(expt.aidWord).min_dur = newMin; 
        exptAdjust.durcalc.(expt.aidWord).max_dur = newMax; 
        
        exptAdjust.durcalc.(expt.aijWord).min_dur = newMin / expt.aiPerc; 
        exptAdjust.durcalc.(expt.aijWord).max_dur = newMax / expt.aiPerc; % For buy yogurt, have to set based on the percentage of aijo that is ai
      
end

%% resume
set(h_fig(stim),'CurrentCharacter','@')  % reset keypress
set(h_fig(ctrl),'CurrentCharacter','@')
set(h_fig(dup),'CurrentCharacter','@')

% Save new expt as expt
expt = exptAdjust; 
save(fullfile(expt.dataPath, 'expt.mat'), 'expt'); 
fprintf('New expt structure saved as expt.mat.\n'); 

% Refresh text
delete_exptText(h_fig, h_text)
pause(0.25)
h_text(1) = draw_exptText(h_fig, 0.5, 0.5, conttxt, txtparams); % display continue text
pause(2)
delete_exptText(h_fig, h_text)      % clear continue text
pause(1)



end