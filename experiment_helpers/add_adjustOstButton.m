function adjustBtn = add_adjustOstButton(expt, h_fig)

get_figinds_audapter; 
adjustPanel = uipanel(h_fig(ctrl), 'FontSize',12,...
             'BackgroundColor',[.75 .75 .75], ...
             'Title', 'Mid-experiment OST adjustment', 'TitlePosition', 'centertop',...
             'Position',[.05 .9 .9 .08], 'Units', 'normalized');
adjustBtn = uicontrol(adjustPanel, 'Style', 'pushbutton', 'String', 'Adjust OSTs (Q)', ...
        'Units', 'normalized', 'Position', [0.4, 0.1, 0.2, 0.6],...
        'Callback', @(hObject, eventdata)adjustCall(hObject, eventdata, expt, h_fig)); 


end

function adjustCall(hObject,eventdata,expt,h_fig)    
    % Pressing the button will end up calling a pause_trial4osts state
    get_figinds_audapter; 
    set(h_fig(stim),'CurrentCharacter','q')  % reset keypress
    set(h_fig(ctrl),'CurrentCharacter','q')
    set(h_fig(dup),'CurrentCharacter','q')
end