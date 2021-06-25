function adjustBtn = add_adjustOstButton(h_fig)
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

get_figinds_audapter; 
adjustPanel = uipanel(h_fig(ctrl), 'FontSize',12,...
             'BackgroundColor',[.75 .75 .75], ...
             'Title', 'Mid-experiment OST adjustment', 'TitlePosition', 'centertop',...
             'Position',[.05 .9 .9 .08], 'Units', 'normalized');
adjustBtn = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust OSTs (A)', ...
        'Units', 'normalized', 'Position', [0.4, 0.1, 0.2, 0.6],...
        'Callback', @(hObject, eventdata)adjustCall(hObject, eventdata, h_fig)); 


end

function adjustCall(hObject,eventdata,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','a')  % reset keypress
    set(h_fig(ctrl),'CurrentCharacter','a')
    set(h_fig(dup),'CurrentCharacter','a')
end