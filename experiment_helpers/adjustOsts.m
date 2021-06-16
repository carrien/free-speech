function [] = adjustOsts(expt, h_fig)
% This function will be used by the button "Adjust OSTs" in the control window of an experiment display. The purpose of this
% is to adjust the OST files for a participant mid-experiment, if they have changed their speech such that the OSTs are no
% longer working (especially talking louder or something, where your thresholds may no longer be accurate)
% 
% Process: 
% 1. Takes in expt and h_fig (so that you can show participant a message)
% 2. Compiles data from last 9 (-18?) temp trials into one data file so it can be read by audapter_viewer all at once 
% 3. Opens audapter_viewer with that data file and the expt 
% 4. Use audapter_viewer as normal 
% 5. Marks last temporary trial 1 for bChangedOsts
% 
% Initiated RPK 6/2/2021
% 
% 

dbstop if error 

% Number of trials to compile
nCompiledTrials = 18; 

pause_trial(h_fig); 
fprintf('hi\n')

%% Information on participant screen
% 
% 
% waitMessage = 'Please wait. The experiment will begin again shortly.'; 
% h_wait = draw_exptText(h_fig, 0.5, 0.5, waitMessage, expt.instruct.txtparams);
% 
% %% Get temporary data files
% 
% % Look for temporary trial directory
% tempdirs = regexp(genpath(expt.dataPath),'[^;]*temp_trials','match')';
% if isempty(tempdirs)
%     % If there isn't one
%     fprintf('No trials left to adjust OSTs for.\n')
%     expPath = [];
%     return;
% end
% 
% compiledData = []; 
% for d = 1:length(tempdirs)
%     tempdir = tempdirs{d}; 
%     trialnums = get_sortedTrials(tempdirs{d});
%     
%     % Get last nCompiledTrials trials (finds the integers so that you get a full indexed list) 
%     trials2compile = find(round(trialnums) == trialnums, nCompiledTrials, 'last'); 
%     trials2compile = trialnums(trials2compile); % Just in case your trial list for some reason doesn't start at 1 
%     
%     
%     for t = 1:length(trials2compile)
%         trialNo = trials2compile(t); 
%         load(fullfile(tempdir, [num2str(trialNo) '.mat'])); 
%         compiledData = [compiledData; data]; 
%     end
%     
%     
% end
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %%
% stimWord = 'test'; 
% h_fig = setup_exptFigs;
%     get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;
%     h_sub = get_subfigs_audapter(h_fig(ctrl),1);
%     
%         practiceText = sprintf(['Some of the words in this study are not real, but sound like they could be real English words.\n', ...
%         'The phrase you will be saying for this portion of the study is: \n\n my %s\n'],upper(stimWord)); 
%     practiceText = textwrap({practiceText}, 50); 
%     h_newword = draw_exptText(h_fig,.5,.5,practiceText,expt.instruct.txtparams);
%     pause
%     delete_exptText(h_fig,h_newword)
%     
%      
%     
%  %%   
% buttonPanelPos = [0 0.8 0.9 0.1]; 
% panelFontSize = 12; 
% p.guidata.buttonPanel = uipanel(h_fig(ctrl),'Units','Normalized',...
%     'Position',buttonPanelPos,...
%     'FontUnits','Normalized','FontSize',panelFontSize,...
%     'TitlePosition', 'CenterTop',...
%     'Tag','button_panel');
%    %%
%    saveParamsButtonPos = [0.1 0.1 0.4 0.4]; 
%    buttonFontSize = 0.5; 
%     hbutton.saveParams = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
%     'String','Adjust OSTs',...
%     'Units','Normalized','Position',saveParamsButtonPos,...
%     'FontUnits','Normalized','FontSize',buttonFontSize,...
%     'Callback',@adjust_osts);
% 
% function adjust_osts(hObject,eventdata)
%         fprintf('hi there cutie\n') % 
%         % Gather 9 most recent trials from the temp_trials 
%     end



end