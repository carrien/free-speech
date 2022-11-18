function adjustBtn = add_adjustOstButton(h_fig, buttons)
% Function adds a button to the experimenter control screen so you can access the function adjustOsts, which pauses the
% experiment to allow you to adjust OST parameters mid-experiment
% 
% Button effectively presses "a" (for "adjust"). Your trial code should have a statement checking for this state at the top 
% of the while loop: 
% 
% if get_pause_state(h_fig,'a')
%    adjustOsts(expt, h_fig);
% end
% 
% WARNING: DO NOT USE during the actual experimental phase of an experiment that simply turns on formant perturbation for an
% entire trial. This script indiscriminately feeds the OST file back into Audapter, which prevents trial-wide perturbation.

if nargin < 2 || isempty(buttons), buttons = {'ost'}; end
if ~iscell(buttons), buttons = {buttons}; end


get_figinds_audapter; 
adjustPanel = uipanel(h_fig(ctrl), 'FontSize',12,...
             'BackgroundColor',[.75 .75 .75], ...
             'Title', 'Mid-experiment OST adjustment', 'TitlePosition', 'centertop',...
             'Position',[.05 .9 .9 .08], 'Units', 'normalized');

if ismember('ost', buttons)
    adjustBtn = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust OSTs (A)', ...
            'Units', 'normalized', 'Position', [0.4, 0.1, 0.2, 0.6],...
            'Callback', @(hObject, eventdata)adjustCall(hObject, eventdata, h_fig)); 
end
if ismember('settings', buttons)
    settingsBtn = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust experiment settings (E)', ...
            'Units', 'normalized', 'Position', [0.1, 0.1, 0.25, 0.6],...
            'Callback', @(hObject, eventdata)adjustSettingsCall(hObject, eventdata, h_fig)); 
end
if ismember('pitchbound', buttons)
    settingsBtn = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust pitch boundaries (B)', ...
            'Units', 'normalized', 'Position', [0.7, 0.1, 0.25, 0.6],...
            'Callback', @(hObject, eventdata)adjustPitchboundsCall(hObject, eventdata, h_fig)); 
end


end

function adjustCall(hObject,eventdata,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','a')  % reset keypress
    set(h_fig(ctrl),'CurrentCharacter','a')
    set(h_fig(dup),'CurrentCharacter','a')
end

function adjustSettingsCall(hObject,eventdata,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','e')  % reset keypress
    set(h_fig(ctrl),'CurrentCharacter','e')
    set(h_fig(dup),'CurrentCharacter','e')
end

function adjustPitchboundsCall(hObject,eventdata,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','b')  % reset keypress
    set(h_fig(ctrl),'CurrentCharacter','b')
    set(h_fig(dup),'CurrentCharacter','b')
end