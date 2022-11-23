function hbtn = add_adjustOstButton(h_fig, buttons)
% Function adds a button to the experimenter control screen so you can access the function adjustOsts, which pauses the
% experiment to allow you to adjust OST parameters mid-experiment
% 
% Adds buttons to a top panel of the experimenter control screen. These buttons have pre-specified text, including the
% keyboard press that is equivalent to pressing the button. For these buttons to be effective, you need to have a
% corresponding pause state check in the trial loop (cf: adjustOsts, adjust_experimentSettings). The end goal of these
% buttons is to be able to adjust experiment settings in the middle of an experiment if necessary. 
% 
% Input arguments: 
% 
%   h_fig           The handle to the set of figures used in typical experiments (not PTB experiments)
% 
%   buttons         A cell array of buttons that you would like to include. E.g. {'ost' 'settings'} 
% 
% Possible buttons: 
% 
%   'ost'           A button that will press 'a', which should be linked to calling adjustOsts in your experiment file. Only
%                   use this button in experiments that NEED an OST file, not one where formant perturbation is applied
%                   throughout a trial. 
%                   Text: "Adjust OSTs (A)" 
% 
%   'settings'      A button that will press 'e', which should be linked to calling adjust_experimentSettings in your
%                   experiment file. 
%                   Text: "Adjust experiment settings (E)"
% 
%   'pitchbound'    A button that will press 'b', which should be linked to calling adjust_experimentSettings in your
%                   experiment file with adjustment specified as 'pitchbound'. 
%                   Text: "Adjust pitch boundaries (B)"  
% 
% Example call to mid-experiment adjustment: 
% 
% if get_pause_state(h_fig,'a')
%    adjustOsts(expt, h_fig);
% end
% 
% Initiated RPK June 2021
% Updated RPK November 2022 to add more, prespecified buttons. 

%% Defaults

if nargin < 2 || isempty(buttons), buttons = {'ost'}; end % If unspecified, assumes OST type 
if ~iscell(buttons), buttons = {buttons}; end

%% Make the buttons and put in panel 
get_figinds_audapter; 
adjustPanel = uipanel(h_fig(ctrl), 'FontSize',12,...
             'BackgroundColor',[.75 .75 .75], ...
             'Title', 'Mid-experiment OST adjustment', 'TitlePosition', 'centertop',...
             'Position',[.05 .9 .9 .08], 'Units', 'normalized');

if ismember('ost', buttons)
    hbtn.adjust = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust OSTs (A)', ...
            'Units', 'normalized', 'Position', [0.4, 0.1, 0.2, 0.6],...
            'Callback', @(hObject, eventdata)adjustCall(hObject, eventdata, h_fig)); 
end
if ismember('settings', buttons)
    hbtn.settings = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust experiment settings (E)', ...
            'Units', 'normalized', 'Position', [0.1, 0.1, 0.25, 0.6],...
            'Callback', @(hObject, eventdata)adjustSettingsCall(hObject, eventdata, h_fig)); 
end
if ismember('pitchbound', buttons)
    hbtn.pitch = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust pitch boundaries (B)', ...
            'Units', 'normalized', 'Position', [0.7, 0.1, 0.25, 0.6],...
            'Callback', @(hObject, eventdata)adjustPitchboundsCall(hObject, eventdata, h_fig)); 
end


end

function adjustCall(hObject,eventdata,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','a')  % set keypress to A
    set(h_fig(ctrl),'CurrentCharacter','a')
    set(h_fig(dup),'CurrentCharacter','a')
end

function adjustSettingsCall(hObject,eventdata,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','e')  % set keypress to E
    set(h_fig(ctrl),'CurrentCharacter','e')
    set(h_fig(dup),'CurrentCharacter','e')
end

function adjustPitchboundsCall(hObject,eventdata,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','b')  % set keypress to B
    set(h_fig(ctrl),'CurrentCharacter','b')
    set(h_fig(dup),'CurrentCharacter','b')
end