function viewer_end_state = audapter_viewer(y,x,trials,varargin) 
% GUI for testing OST and PCF parameter changes. Currently only supports timewarping changes in PCF. 
% 
% Inputs: 
% 1. y: a data output structure from Audapter. If not given, will look for data.mat in the current directory. 
% 2. x: an expt corresponding to the data structure. If not given, will look for expt.mat in the current directory. 
% 3. trials: the trials you want to look at. Defaults to all trials in the data.mat structure
% 4. Varargin doesn't actually do anything right now. 
% 
% -----------------------------------------
% 
% version 3.0 
% --- allows viewing formants 
% --- 3.0.1 (2/1/2021): adaptation for using flexdapter with old
% experiments (and not calling different audapter versions) 
%
% version 3.1 
% --- Now reads in RMS ratio slope and new heuristics (June 2021). Backwards compatible with Audapter Mex files that do not
% have the new heuristics in (simply catches the lack of matching heuristic and informs you that it cannot be done). 
% --- Includes change for three parameters for a heuristic. 
% 
% version 3.2 
% --- change to look into data structure for OST information, which is now potentially different from trial to trial.
% Displays which trial it is showing you the OST information from much like the PCF shows you the PCF settings from a
% specific trial 

dbstop if error

% Turn off warning that tells you if you don't have audio (remoting in requires audio to be out)
warning('off','MATLAB:audiovideo:audioplayer:noAudioOutputDevice') 
% Turn off warning about sliders being out of range. Just annoying. 
warning('off', 'MATLAB:hg:uicontrol:ValueMustBeInRange')

%% Default input arguments

if nargin < 1 || isempty(y)
    fprintf('No data structure included. Looking for one in current working directory... ')
    try
        data = []; 
        load(fullfile(pwd, 'data.mat'), 'data'); 
        y = data; 
        clear data
        fprintf('Success. \n')
    catch 
        fprintf('No data.mat file found. \n')
        return; 
    end
end

if nargin < 2 || isempty(x)
    fprintf('No expt included. Looking for one in current working directory... ')
    try
        expt = []; 
        load(fullfile(pwd, 'expt.mat'), 'expt');
        x = expt; 
        clear expt
        fprintf('Success. \n')
    catch 
        fprintf('No expt.mat file found. \n')
        return; 
    end
end

% Trial info
availableTrials = 1:length(y); 
if nargin < 3 || isempty(trials)
    if length(y) >= 9
        trials = 1:9; 
    else
        trials = availableTrials;  
    end
elseif length(trials) > 9 
    fprintf('Only plotting first 9 trials\n')
    trials = min(trials):min(trials)+8; 
end

% Set trial slider
if availableTrials == 1
    trialSliderStep = [1 1];     
else
    trialSliderStep = [1/(max(availableTrials) - min(availableTrials)) 9/(max(availableTrials) - min(availableTrials))]; 
end

pcfTrial = min(trials); 
ostTrial = min(trials); % they have to be separate, but they start out at the same value
trials2calc = []; % declaring a global variable I guess

%% Set up audapter

% Hack for setting up audapter and warping files correctly
exptName = x.name; 
% defaultMeasureExperiments = {'varModOut' 'varModOut2' 'adaptRetest' 'compRetest' 'varModOut2' 'vsaGeneralize' 'varModInOut' 'attentionComp'}; % experiments that use run_measureFormants
pert2DExperiments = {'varModOut' 'varModInOut'}; % experiments that use 2D perturbation
pert1DExperiments = {'compRetest' 'adaptRetest'}; % that use 1D
highFsExperiments = {'timeAdapt' 'sAdapt'}; % that use highFs

% Add pert2D field to x (expt) if it's not there already. Necessary to
% convert from old audapter versions to flexdapter 
if isfield(x, 'audapterParams') && ~isfield(x.audapterParams,'bShift2D')
    switch exptName
        case pert2DExperiments
            x.audapterParams.bShift2D = 1; 
        case pert1DExperiments
            x.audapterParams.bShift2D = 0; 
    end
end

% Momentary placeholder RK 2021/02/09. Will eventually have to figure out (when formant OST perturbation is implemented) how
% to switch this based on something like bShift
timeSpace = 'time'; 




%% Plotting defaults 

p.plot_params = get_plot_params;
p.sigproc_params = get_sigproc_params;
p.sigproc_params.fs = y(1).params.sRate;
p.audapter_params = y(1).params; 
% is this what we want? What params go into data.params and which into expt.audapterParams? will bShift2D need to be put in here?
fs = p.sigproc_params.fs; 

p.event_params = get_event_params;
all_ms_framespecs = get_all_ms_framespecs();



%% Setting up info for use in manipulating OST/PCF files. 
% Now fitted to be  more general, checks for trackingFileLoc and trackingFileName in expt structure, uses defaults if the 
% right experiment

% Location of OST/PCF files 
if isfield(x,'trackingFileDir')
    trackingFileDir = x.trackingFileDir; 
elseif isfield(x, 'trackingFileLoc')
    trackingFileDir = x.trackingFileLoc; 
else
    % If you don't have a trackingFileDir field, add to your expt and save.
    % If you were running run_measureFormants/are doing a default vowel boundary track and perturb, it should be 
    % 'experiment_helpers'
    switch exptName
        case 'timeAdapt'
            trackingFileDir = exptName; 
        otherwise 
            trackingFileDir = 'experiment_helpers'; 
    end
end

try
    word = x.listWords{1}; 
catch   % dipSwitch compatibility edit
    word = y.word;
end

% Get name of tracking files (not including Working/Master tag) : RK 2020/09/11
if isfield(x,'trackingFileName')
    trackingFileName = x.trackingFileName; 
    % Short-term workaround for taimComp
    if iscell(trackingFileName), trackingFileName=trackingFileName{1}; end
else
    switch exptName
        case 'timeAdapt'
            trackingFileName = word; 
        otherwise
            trackingFileName = 'measureFormants'; 
    end
end
    

%% Ost-related stuff

% Reset OST file to how it was when the experiment ran. Prioritize data
%   over expt; and calcSubjOstParams over subjOstParams.
set_subjOstParams_auto(x, y, 1, ostTrial);

ostList = get_ost(trackingFileDir, trackingFileName, 'list'); 
triggerStatus = get_pcf(trackingFileDir, trackingFileName, 'time', '1', 'ostStat_initial'); % note that this assumes that you only want to look at the first time warping event
% This will treat the first time warping event as the trigger at all times even if there is a second one
% Note also that this should be made more flexible to handle the event that there is a tBegin-specified warping event. RPK 2020/11/12
% Formant perturbation PCFs don't have a trigger status, so just set to the minimum in the list 
if isempty(triggerStatus) || isnan(triggerStatus), triggerStatus = str2double(ostList{1}); end

p.sigproc_params.triggerStatus = triggerStatus; 
ostStatus = triggerStatus;  % ostStatus can change, but starts out as triggerStatus
allHeuristics = {'ELAPSED_TIME', 'INTENSITY_RISE_HOLD', 'INTENSITY_RISE_HOLD_POS_SLOPE', 'POS_INTENSITY_SLOPE_STRETCH',...
    'NEG_INTENSITY_SLOPE_STRETCH_SPAN', 'INTENSITY_SLOPE_BELOW_THRESH', 'INTENSITY_SLOPE_ABOVE_THRESH', 'INTENSITY_FALL', 'INTENSITY_BELOW_THRESH_NEG_SLOPE', ...
    'INTENSITY_RATIO_RISE', 'INTENSITY_RATIO_ABOVE_THRESH_WITH_RMS_FLOOR', ...
    'INTENSITY_AND_RATIO_ABOVE_THRESH', 'INTENSITY_AND_RATIO_BELOW_THRESH', ...
    'INTENSITY_RATIO_FALL_HOLD', ...
    'INTENSITY_RATIO_SLOPE_ABOVE_THRESH', 'INTENSITY_RATIO_SLOPE_BELOW_THRESH'}; 


[heuristic, heurParam1, heurParam2, heurParam3] = get_ost(trackingFileDir, trackingFileName, triggerStatus);
[heurUnits, heurMin, heurMax, heurStep] = get_heuristicParams(heuristic); 
wp.word = word; 

% For recalculating everything 
bAllOstRecalculated = 1; 
bTheseOstRecalculated = 1; 

% For tooltips on the OST status lines 
p.eventNumbers = str2double(ostList); 
p.eventNames = get_ostEventNamesNumbers(trackingFileDir, trackingFileName, p.eventNumbers, 1, 0, 0); 
p.ostMultiplier = round((6000/(max(p.eventNumbers)+2))/10)*10; % In the future this should be changed so there are many y axes, but this works okay for now

%% PCF-related stuff

if isfield(y,'calcPcfLine')
    calcPcfLine = {y.calcPcfLine}; 
else
    calcPcfLine = cell(1,max(availableTrials)); 
end
if ~isfield(y, 'pcfLine')
    pcfLine = '2, 0.999, 0.5, 0.000, 0.000, 2'; %no timewarping; fills pcfLine
    fprintf(['No pcfLine found. Using default "empty" pcfLine.\n' ...
        ' This is expected for experiments without OST-based perturbation.\n']);
elseif isempty(calcPcfLine{pcfTrial})
    pcfLine = y(pcfTrial).pcfLine;
else
    pcfLine = calcPcfLine{pcfTrial};
end

if ischar(pcfLine)    
    pcfComponents = strsplit(pcfLine,',');
    ostStat_initial = str2double(pcfComponents{1});
    tBegin = str2double(pcfComponents{2}); 
    rate1 = str2double(pcfComponents{3}); 
    dur1 = str2double(pcfComponents{4}); 
    durHold = str2double(pcfComponents{5}); 
    rate2 = str2double(pcfComponents{6}); 
else
    % NOTE RPK 2/8/2021: this should really be made more flexible for formant changes, and pcfLines that only have a tBegin 
    ostStat_initial = pcfLine(1); 
    tBegin = pcfLine(2); 
    rate1 = pcfLine(3); 
    dur1 = pcfLine(4); 
    durHold = pcfLine(5); 
    rate2 = pcfLine(6); 
    
end


%% set up GUI 
% create new figure
hf = figure('Name',p.plot_params.name,'Units','normalized','Position',p.plot_params.figpos, 'CloseRequestFcn', @save_exit);
set(hf,'DeleteFcn',@delete_func); % Keep delete_func, which just calls the save and exit prompt

% Tabs for signalIn and signalOut
inputTab = uitab('Title','signalIn'); 
outputTab = uitab('Title','signalOut'); 

p.guidata = guihandles(hf);
p.guidata.f = hf;
set(hf,'Tag', 'audapter_viewer','HandleVisibility','on');

% Figures to be closed 
alert2mismatchMex = gobjects(1); 
fWaiting = gobjects(1); 

%% Trial range panel
panelPad = 0.01; 
panelFontSize = 0.025; 

trialPanelXSpan = 1 - panelPad*2; 
trialPanelYSpan = panelPad*4; 
trialPanelXPos = panelPad; 
trialPanelYPos = panelPad; 
trialPanelPos = [trialPanelXPos trialPanelYPos trialPanelXSpan trialPanelYSpan]; 
p.guidata.trialPanel = uipanel(hf,'Units','Normalized',...
    'Position',trialPanelPos,...
    'FontUnits','Normalized','FontSize',panelFontSize,...
    'TitlePosition', 'CenterTop',...
    'Tag','trial_panel');


%% INPUT panels 
panelPad = .01;
panelFontSize = .025;

% create panel for buttons
buttonPanelXSpan = 0.15;
buttonPanelYSpan = 1 - panelPad*5;
buttonPanelXPos = 1 - buttonPanelXSpan - panelPad;
buttonPanelYPos = panelPad *5;
buttonPanelPos = [buttonPanelXPos buttonPanelYPos buttonPanelXSpan buttonPanelYSpan];
p.guidata.buttonPanel = uipanel(inputTab,'Units','Normalized',...
    'Position',buttonPanelPos,...
    'FontUnits','Normalized','FontSize',panelFontSize,...
    'TitlePosition', 'CenterTop',...
    'Tag','button_panel');

% create panel for frequency-based axes
faxesPanelXPos = panelPad;
faxesPanelYPos = panelPad*5; % extra pad on bottom
faxesPanelXSpan = 1 - buttonPanelXSpan - panelPad*2; 
faxesPanelYSpan = 1 - panelPad*5;
faxesPanelPos = [faxesPanelXPos faxesPanelYPos faxesPanelXSpan faxesPanelYSpan];
p.guidata.faxesPanel = uipanel(inputTab,'Units','Normalized',...
    'Position',faxesPanelPos,...
    'FontUnits','Normalized','FontSize',panelFontSize,...
    'TitlePosition','CenterTop',...
    'Tag','faxes_panel');

%% OUTPUT panels
% Updated 10/30/2019 RPK
panelPad = .01;
panelFontSize = .025;

% create panel for buttons
p.guidata.pcf_buttonPanel = uipanel(outputTab,'Units','Normalized',...
    'Position',buttonPanelPos,...
    'FontUnits','Normalized','FontSize',panelFontSize,...
    'TitlePosition', 'CenterTop',...
    'Tag','pcf_button_panel');

% create panel for frequency-based axes
p.guidata.pcf_faxesPanel = uipanel(outputTab,'Units','Normalized',...
    'Position',faxesPanelPos,...
    'FontUnits','Normalized','FontSize',panelFontSize,...
    'TitlePosition','CenterTop',...
    'Tag','output_faxes_panel');

%% axes 
if ~isfield(y,'ost_calc')
    if ~isfield(y,'calcOST') % for changing calcOST to ost_calc. Retrofitting for timeAdapt and other experiments that may have had calcOST
        % If neither version of the field exists, make a new cell array called ost_calc
        ost_calc = cell(1,max(availableTrials)); 
    else
        % if calcOST (but not ost_calc) exists, then make ost_calc equal to y.calcOST
        ost_calc = {y.calcOST};
    end
else
    % If the new version of the field does exist, then set ost_calc to {y.ost_calc}
    ost_calc = {y.ost_calc}; 
end
[trial_axes,h_rms,h_rms_rat,h_dRms,h_dRms_rat,h_ost,h_ostref,h_editost_ref,audTAxis] = new_trial_axes(y,p,trials,ostStatus,heuristic,ost_calc); % This should work 10/31/2019
% Need to update to store each individual OST line so that it can be refreshed with the OST changing

% Same retrofitting for calcSignalOut/ signalOut_calc
if ~isfield(y,'signalOut_calc')
    if ~isfield(y,'calcSignalOut')
        signalOut_calc = {y.signalOut};%cell(1,max(availableTrials)); 
    else
        signalOut_calc = {y.calcSignalOut};
    end
else
    signalOut_calc = {y.signalOut_calc}; 
end
[output_trial_axes, h_outputOst, output_audTAxis,h_formantsIn_1,h_formantsIn_2,h_formantsOut_1,h_formantsOut_2] = new_output_trial_axes(y,x,p,trackingFileDir,trackingFileName,trials,signalOut_calc); 

% Only keeping this in because I haven't gotten rid of all the functions yet and Matlab parses them as
% erroring if these vars aren't defined RPK 10/31
if isempty(y)
ampl_ax = new_ampl_ax(wave_ax,p,sigmat);
pitch_ax = new_pitch_ax(wave_ax,ampl_ax,p,sigmat);
gram_ax = new_gram_ax(wave_ax,ampl_ax,p,sigmat);
spec_ax = new_spec_ax(gram_ax,p);
end



%% INPUT BUTTON PARAMETERS

% For appearances
padL = .05;
padYButton = .01;
padYBig = .02;
padHalfButton = 0.003; 
padYSmall = .002;

buttonWidth = .9;
buttonHeight = .045;
halfButtonWidth = 0.45; 
halfButtonHeight = 0.035; 
quarterButtonWidth = 0.2; 
quarterButtonHeight = 0.035; 
buttonFontSize = .4;

sliderHeight = .04;
sliderWidth = 0.4; 
quarterSliderHeight = 0.035; 
quarterSliderWidth = 0.27; 

dropdownHeight = .03;
dropdownFontSize = .5;

editHeight = .04;
editWidth = 0.4; 
quarterEditHeight = 0.035; 
quarterEditWidth = 0.27; 
editFontSize = .6;

textHeight = buttonHeight;
textFontSize = buttonFontSize;
textPosYOffset = 0.0240;
tinyHeight = textHeight*.75;
tinyPosYOffset = textPosYOffset*.75;
goodBGcolor = [0 0.9 0];
badBGcolor = [0.9 0 0];

playbackButtonWidth = 0.075; 
playbackButtonHeight = 0.025; 

vert_orig = padYBig;
horiz_orig = padL; 

%%
% Button creation 
% Button to open PCF/playback GUI
% vert_orig = vert_orig + buttonHeight + padYButton;
% playbackButtonPos = [padL vert_orig buttonWidth buttonHeight]; 
% hbutton.playbackGUI = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
%     'String','Open playback',...
%     'Units','Normalized','Position',playbackButtonPos,...
%     'FontUnits','Normalized','FontSize',buttonFontSize,...
%     'Callback',@open_playbackGUI);
%     function open_playbackGUI(hObject, eventdata)
%        audapter_pcf_viewer(y,x,p); 
%     end
% 
% % help button
% helpButtonPos = [padL vert_orig buttonWidth buttonHeight];
% hbutton.help = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
%     'String','Help',...
%     'Units','Normalized','Position',helpButtonPos,...
%     'FontUnits','Normalized','FontSize',buttonFontSize,...
%     'Callback',@my_help_func); % Change help function to reflect time warping
%     function my_help_func(hObject,eventdata) % callback for help button
%         helpstr = sprintf(['GUI to set Audapter time warping thresholds\n', ...
%             'The dropdown menu should show the word being used.\n', ...
%             'Use either the edit boxes or the sliders to change parameters.\n', ...
%             'Once you have a new configuration you want to try, hit Recalculate OST.\n', ...
%             'Check if the OST Trigger status is hitting the reference line at the right point.\n', ...
%             '"Reset to defaults" will change the parameters back to their default values.\n', ...
%             'When you are satisfied with the parameters, press "Exit" and select Save and exit.\n']);
%         helpdlg(helpstr);
%     end

% save parameters and exit
% vert_orig = vert_orig + buttonHeight + padYSmall;
saveParamsButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight];
hbutton.saveParams = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','Continue/Exit',...
    'Units','Normalized','Position',saveParamsButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@save_exit);
normal_bgcolor = get(hbutton.saveParams,'BackgroundColor');
    function save_exit(hObject,eventdata)
        answer = questdlg('Save current OST parameters and exit?', ...
            'Exit GUI', ... % question dialog title
            'Cancel (do not exit)','Save and exit','Exit without saving',... % button names
            'Cancel (do not exit)'); % Default selection 
        switch answer
            case 'Save and exit'
                expt = x; 
                
                % Check if you did any recalculation, if you did but not for all trials, ask if you want to do them all
                bNeedToSaveData = 0; 
                if ~bAllOstRecalculated
                    recalculateAnswer = questdlg('You have recalculated a subset of the trials in this data structure. Would you like to apply the current parameters to all trials?', ...
                        'Recalculate all OSTs', ... % question dialog title
                        'Yes, recalculate all', 'No, keep this subset', 'Cancel (do not exit)', ... % button names
                        'Yes, recalculate all'); % Default selection 

                    
                    switch recalculateAnswer
                        case 'Yes, recalculate all'
                            fWaiting = waitbar(0,'Setting OST parameters...');
                            waitbar(0.33,fWaiting,'Calculating new OST vectors...')
                            ost_calc = calc_newAudapterData({y.signalIn},p.audapter_params,trackingFileDir,trackingFileName,'ost_stat');
                            
                            % Also put in new OST values for all the trials 
                            waitbar(0.66,fWaiting,'Writing trial OST information to data...')
                            set_ost(trackingFileDir,trackingFileName,ostStatus,hdropdown.heuristicChoice.String{hdropdown.heuristicChoice.Value},...
                                str2double(hedit.statusParam1.String),str2double(hedit.statusParam2.String),str2double(hedit.statusParam3.String)); 
%                             for o = 1:length(ostList)
%                                 ostNumber = str2double(ostList{o});
%                                 [heur,param1,param2] = get_ost(trackingFileDir,trackingFileName,ostNumber,'working'); 
%                                 calcSubjOstParams{o} = {ostNumber heur param1 param2}; 
%                             end
                            calcSubjOstParams = get_ost(trackingFileDir, trackingFileName, 'full', 'working'); 
                            for i = 1:length(y)
                                y(i).calcSubjOstParams = calcSubjOstParams; 
                            end
                            
                            waitbar(1,fWaiting,'Done')
                            pause(0.5)
                            close(fWaiting)
                            bNeedToSaveData = 1; 
                        case 'No, keep this subset'
                            fprintf('Some trials may be calculated with different OST parameters than others.\n')                            
                    end                        
                    
                end
                

                startWaitBar = 0; 
                fWaiting = waitbar(0,'Saving...'); 
                if any(~cellfun(@isempty,ost_calc)) % if you did any calculation of new OSTs at all. if not it will not be saved (to save time)
                    startWaitBar = startWaitBar + 0.25; 
                    waitbar(startWaitBar,fWaiting,'Adding new OSTs to data structure...'); 
                    for i = 1:length(y)
                        y(i).ost_calc = ost_calc{i}; 
                    end
                    bNeedToSaveData = 1;                     
                end
                
                if any(~cellfun(@isempty,signalOut_calc)) % if you did any calculation of new signal outs at all. if not it will not be saved (to save time)
                    startWaitBar = startWaitBar + 0.25; 
                    waitbar(startWaitBar,fWaiting,'Adding new signalOuts to data structure...'); 
                    for i = 1:length(y)
                        y(i).signalOut_calc = signalOut_calc{i}; 
                    end
                    bNeedToSaveData = 1;                     
                end
                
                if any(~cellfun(@isempty,calcPcfLine)) % if you did any calculation of new signal outs at all. if not it will not be saved (to save time)
                    startWaitBar = startWaitBar + 0.25; 
                    waitbar(startWaitBar,fWaiting,'Adding new pcfLines to data structure...'); 
                    for i = 1:length(y)
                        y(i).calcPcfLine = calcPcfLine{i}; 
                    end
                    bNeedToSaveData = 1;                     
                end
                
                if bNeedToSaveData
                    data = y; 
                    switch x.name
                        case 'dipSwitch' % dipswitch has exceptional behavior because it can be run on a mac
                            isOnServer = exist(get_acoustLoadPath(x.name,x.snum,x.session,word),'dir');
                            if isOnServer
                                savePath = get_acoustLoadPath(x.name,x.snum,sprintf('session%d', x.session),word);
                            else
                                if ispc && strcmp(expt.dataPath(1), '/') % on pc, but dataPath is Mac formatted
                                    savePath = pwd;
                                    warning('OS mismatch -- couldn''t save to expt.dataPath. Saving instead to current directory: \n%s\n', pwd);
                                else
                                    savePath = fullfile(x.dataPath,sprintf('session%d', x.session),word);
                                end
                            end
                        case 'timeAdapt' % timeAdapt has exceptional behavior because the expt.dataPath was saved for whole experiment, not word-specific 
                            isOnServer = exist(get_acoustLoadPath(x.name,x.snum,word),'dir');
                            if isOnServer
                                savePath = get_acoustLoadPath(x.name,x.snum,word);                                
                            else
                                savePath = get_acoustSavePath(x.name,x.snum,word); 
                            end
                            
                            if strcmp(x.conds,'pre')
                                savePath = fullfile(savePath,'pre'); 
                            end
                            
                        otherwise % Assume that you will simply save to dataPath, but check if it should go to server or not
                            % Translate between server path and expt path to get two options
                            dataPathParts = strsplit(x.dataPath, 'experiments'); 
                            if length(dataPathParts) > 1 % assumes you're using default SMNG filepath structures and might access SMNG server
                                serverPrefix = '\\wcs-cifs.waisman.wisc.edu\wc\smng\'; 
                                serverPath = fullfile(serverPrefix, 'experiments', dataPathParts{2}); 
                                isOnServer = exist(serverPath,'dir'); 
                                savePath = choosePathDialog({serverPath, x.dataPath, pwd}, isOnServer); 
                            else % not using default SMNG filepath structure; don't offer SMNG server
                                savePath = choosePathDialog({x.dataPath, pwd}, 0);
                            end
                            
                            % If you've hit cancel when choosing, then take away dialogs and don't save or anything
                            if ~savePath
                                waitbar(1,fWaiting,'Canceling save')
                                pause(0.5)
                                delete(fWaiting)
                                return; 
                            end
                            
                            if ~exist(savePath, 'dir')
                                shouldIMkDir = questdlg(sprintf('The path you chose does not currently exist. Would you like to create this directory and save?\n\n Chosen path: %s', savePath), ...
                                    'Verify creating directory', ... % question dialog title
                                    'Yes, create this directory', 'No, cancel save', ... % button names
                                    'No, cancel save'); % Default selection 
                                
                                if strcmp(shouldIMkDir, 'Yes, create this directory')
                                    mkdir(savePath); 
                                else
                                    return; 
                                end
                            end

                    end
                    waitbar(0.9,fWaiting,'Saving data...')
                    save(fullfile(savePath,'data.mat'),'data')
                    waitbar(0.95,fWaiting,'Saving expt...')
                    save(fullfile(savePath,'expt.mat'),'expt'); 
            
                end    
                waitbar(1,fWaiting,'Done')
                pause(0.5)
                delete(fWaiting)
                try delete(alert2mismatchMex); catch; end
                try delete(fWaiting); catch; end
                delete(hf)
            case 'Exit without saving'
                try delete(alert2mismatchMex); catch; end
                try delete(fWaiting); catch; end
                delete(hf)            
        end
    end

% Reset all trials to Master specifications
vert_orig = vert_orig + buttonHeight + padYBig;
resetParamsButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.resetParams = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','Restore all trials to default',...
    'Units','Normalized','Position',resetParamsButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@restore_defaults);
    function restore_defaults(hObject,eventdata)
        [oldHeur,oldThresh,oldDur, oldParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        refreshWorkingCopy(trackingFileDir,trackingFileName,'ost')
        set_ostParams
        [newHeur,newThresh,newDur, newParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        refresh_RMS_lines;
        set_alert4calcOST_if_true(oldThresh ~= newThresh || oldDur ~= newDur || ~strcmp(oldHeur,newHeur) || oldParam3 ~= newParam3); % 
    end

% Restore all trials to original experiment OSTs
vert_orig = vert_orig + buttonHeight + padYBig; 
restoreAllParamButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.restoreAllParams = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','Restore ALL trials'' params',...
    'Units','Normalized','Position',restoreAllParamButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@restore_all_trials);
    function restore_all_trials(hObject,eventdata)        
        [oldHeur,oldThresh,oldDur,oldParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        
        % Make data.calcSubjOstParams be the same as whatever the originals were, regardless of whether it is stored in y or
        % expt
        % Then set OST file based on whatever the active OST trial is
        if isfield(y, 'subjOstParams')
            [y.calcSubjOstParams] = y(:).subjOstParams; 
            set_subjOstParams(trackingFileDir, trackingFileName, y(ostTrial), 'calc'); % Calc because it's guaranteed to exist and has just been set to be original
        elseif isfield(x, 'subjOstParams')
            reppedParams = repmat({x.subjOstParams}, 1, length(y)); 
            [y.calcSubjOstParams] = reppedParams{:}; 
            set_subjOstParams(trackingFileDir, trackingFileName, y(ostTrial), 'calc'); 
        else
            msgbox('No parameters stored for this participant')
        end
        
        set_ostParams
        [newHeur,newThresh,newDur,newParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        refresh_RMS_lines;
        set_alert4calcOST_if_true(oldThresh ~= newThresh || oldDur ~= newDur || ~strcmp(oldHeur,newHeur) || oldParam3 ~= newParam3); % 
    end

% Restore single trial to original experiment OSTs
vert_orig = vert_orig + buttonHeight + padYSmall;
restoreSingleParamButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.resetSingleOSTLine = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','Restore SINGLE trial''s params',...
    'Units','Normalized','Position',restoreSingleParamButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@restore_single_trial);
    function restore_single_trial(hObject,eventdata)    
        [oldHeur,oldThresh,oldDur,oldParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        % Make data.calcSubjOstParams be the same as whatever the originals were, regardless of whether it is stored in y or
        % expt
        % Then set OST file based on whatever the active OST trial is
        if isfield(y, 'subjOstParams') && ~isempty(y(ostTrial).subjOstParams)
            y(ostTrial).calcSubjOstParams = y(ostTrial).subjOstParams; 
            set_subjOstParams(trackingFileDir, trackingFileName, y(ostTrial), 'calc'); % Calc because it's guaranteed to exist and has just been set to be original
        elseif isfield(x, 'subjOstParams')
            y(ostTrial).calcSubjOstParams = x.subjOstParams; 
            set_subjOstParams(trackingFileDir, trackingFileName, y(ostTrial), 'calc'); 
        else
            msgbox('No parameters stored for this participant for trial %d', ostTrial)
        end
        
        set_ostParams
        [newHeur,newThresh,newDur,newParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        refresh_RMS_lines;
        set_alert4calcOST_if_true(oldThresh ~= newThresh || oldDur ~= newDur || ~strcmp(oldHeur,newHeur) || oldParam3 ~= newParam3); % 
    end

% Reset single line of parameters to default
% vert_orig = vert_orig + buttonHeight + padYSmall;
% resetSubjParamsButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
% hbutton.resetSingleOSTLine = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
%     'String','Restore participant params',...
%     'Units','Normalized','Position', resetSubjParamsButtonPos,...
%     'FontUnits','Normalized','FontSize',buttonFontSize,...
%     'Callback',@restore_subj_params);
%     function restore_subj_params(hObject,eventdata)
%         if isfield(y, 'subjOstParams') && ~isempty(y(ostTrial).subjOstParams)
%             set_subjOstParams(trackingFileDir, trackingFileName, y, 'orig'); 
%         end
%         
%         if isfield(x,'subjOstParams')
%             % ***** CHANGE FOR MIDEXPT
%             set_subjOstParams(trackingFileDir, trackingFileName, x,'orig'); 
%             set_ostParams(trackingFileName); 
%             refresh_RMS_lines; 
%             set_alert4calcOST_if_true(1); 
%         else
%             msgbox('No parameters stored for this participant')
%         end
%     end

%% Recalculation buttons
% recalculate OST button
vert_orig = vert_orig + buttonHeight + padYBig;
calcAllButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight];
hbutton.calcAllOST = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','Recalculate ALL trials',...
    'Units','Normalized','Position',calcAllButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@calc_allOST);
    function calc_allOST(hObject,eventdata)
        % Get values from slider/edit 
        newThresh = str2double(hedit.statusParam1.String); 
        newDur = str2double(hedit.statusParam2.String);       
        newThird = str2double(hedit.statusParam3.String); 
        % Insert into OST file at appropriate line
        fWaiting = waitbar(0,'Setting OST parameters...');
        
        % For handling mismatches between mex and available heuristics
        try 
            set_ost(trackingFileDir,trackingFileName,ostStatus,heuristic,newThresh,newDur,newThird); 

            % Keeping track of when all OSTs have been recalculated
            bAllOstRecalculated = 1; 

            data2calc = y; 
            waitbar(0.25,fWaiting,'Calculating new OST vectors...')
            ost_calc = calc_newAudapterData({data2calc.signalIn},p.audapter_params,trackingFileDir,trackingFileName,'ost_stat'); 

            % Clear h_ost
            delete(h_ost(1:end));       

            % Make new h_ost and plot
            waitbar(0.75,fWaiting,'Plotting...')
            for traxix = 1:length(trials)
               ost_stat = ost_calc{trials(traxix)}; 
               axes(trial_axes(traxix)); %set the current axes to trial_axis(n)
               yyaxis left % plot onto the left axis so that the RMS values don't get smashed to the bottom
               h_ost(traxix) = plot(audTAxis{traxix},ost_stat * p.ostMultiplier, 'w-', 'LineWidth', 1.5); 
            end
            waitbar(1,fWaiting,'Done')
            set(htoggle.ost,'Value',1); 
            bAlert4calcOST = 0;
            set_alert4calcOST_if_true(bAlert4calcOST); 
            close(fWaiting)
        catch exception
            errorText = getReport(exception, 'basic', 'hyperlinks','off'); 
            if contains(errorText, 'Unrecognized OST heuristic mode')
                message = sprintf('Your chosen heuristic, %s, does not exist in this Audapter Mex file. OSTs have not been recalculated.', heuristic); 
            else
                message = sprintf(['Something has gone wrong with the calc All try/catch statement in audapter_viewer: \n\n ------ \n\n' errorText]); 
            end
            close(fWaiting)
            alert2mismatchMex = msgbox(message); 
                
        end
    end
% recalculate SHOWING TRIALS' OST button
vert_orig = vert_orig + buttonHeight + padYSmall;
calcSubsetButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight];
hbutton.calcSubsetOST = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','Recalculate THESE trials',...
    'Units','Normalized','Position',calcSubsetButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@calc_subsetOST);
normal_bgcolor = get(hbutton.calcAllOST,'BackgroundColor');

% recalculate SINGLE TRIAL OST button
vert_orig = vert_orig + buttonHeight + padYSmall;
calcSingleButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight];
hbutton.calcSingleOST = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','Recalculate SINGLE trial',...
    'Units','Normalized','Position',calcSingleButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@calc_subsetOST);
normal_bgcolor = get(hbutton.calcAllOST,'BackgroundColor');

    function calc_subsetOST(hObject,eventdata)
        % Get values from slider/edit 
        if hObject == hbutton.calcSingleOST 
            trials2calc = ostTrial; 
        elseif hObject == hbutton.calcSubsetOST
            trials2calc = trials; 
        end
        newThresh = str2double(hedit.statusParam1.String); 
        newDur = str2double(hedit.statusParam2.String);   
        newThird = str2double(hedit.statusParam3.String); 
        
        % Addition 6/2/2021 for possibly using a mex file that does not have all the heuristics
        try % See if this goes through or not
            % Insert into OST file at appropriate line
            set_ost(trackingFileDir,trackingFileName,ostStatus,heuristic,newThresh,newDur,newThird); % updated for third parameter
            
            % Addition for trial-specific OST values: 
%             for o = 1:length(ostList)
%                 % Get the OST info as is, with the newly changed parameter
%                 ostNumber = str2double(ostList{o});
%                 [heur,param1,param2,param3] = get_ost(trackingFileDir,trackingFileName,ostNumber,'working'); 
%                 calcSubjOstParams{o} = {ostNumber heur param1 param2 param3}; 
%             end
            calcSubjOstParams = get_ost(trackingFileDir, trackingFileName, 'full', 'working'); 
            for t = trials2calc
                % Put this info into the calcSubjOstParams for those trials
                y(t).calcSubjOstParams = calcSubjOstParams; 
            end

            % To keep track of when a subset of trials has been recalculated
            if isequal(trials2calc, availableTrials)
                bAllOstRecalculated = 1;
                % If you only have nine (or fewer) trials then anytime you do the subset, the whole experiment is also done
            else
                bAllOstRecalculated = 0;         
            end
            
            % Midexpt addition: also keep track of if all showing trials have been recalculated
            if isequal(trials2calc, trials)
                bTheseOstRecalculated = 1; 
            else
                bTheseOstRecalculated = 0; 
            end

            data2calc = y(trials2calc); 
            if length(trials2calc) == 1
                ost_calc{trials2calc} = calc_newAudapterData({data2calc.signalIn},p.audapter_params,trackingFileDir,trackingFileName,'ost_stat'); 
            else
                ost_calc(trials2calc) = calc_newAudapterData({data2calc.signalIn},p.audapter_params,trackingFileDir,trackingFileName,'ost_stat'); 
            end

            % Clear h_ost
            if hObject == hbutton.calcSingleOST 
                traxix = find(trials == ostTrial); 
                delete(h_ost(traxix)); 
                ost_stat = ost_calc{trials2calc}; 
                axes(trial_axes(traxix)); %set the current axes to trial_axis(n)
                yyaxis left % plot onto the left axis so that the RMS values don't get smashed to the bottom
                h_ost(traxix) = plot(audTAxis{traxix},ost_stat * p.ostMultiplier, 'w-', 'LineWidth', 1.5); 
            else
                delete(h_ost(1:end));
                % Make new h_ost and plot
                for traxix = 1:length(trials2calc)
                   ost_stat = ost_calc{trials2calc(traxix)}; 
                   axes(trial_axes(traxix)); %set the current axes to trial_axis(n)
                   yyaxis left % plot onto the left axis so that the RMS values don't get smashed to the bottom
                   h_ost(traxix) = plot(audTAxis{traxix},ost_stat * p.ostMultiplier, 'w-', 'LineWidth', 1.5); 
                end
            end

            set(htoggle.ost,'Value',1); 
            bAlert4calcOST = 0;
            set_alert4calcOST_if_true(bAlert4calcOST); 
        catch exception
            errorText = getReport(exception, 'basic', 'hyperlinks','off'); 
            if contains(errorText, 'Unrecognized OST heuristic mode')
                message = sprintf('Your chosen heuristic, %s, does not exist in this Audapter Mex file. OSTs have not been recalculated.', heuristic); 
            else
                message = sprintf(['Something has gone wrong with the calc Subset try/catch statement in audapter_viewer: \n\n ------ \n\n' errorText]); 
            end
            alert2mismatchMex = msgbox(message); 
                
        end
       
    end



    function set_alert4calcOST_if_true(yes_true)
        bAlert4calcFx = yes_true;
        if bAlert4calcFx
            set(hbutton.calcAllOST,'BackgroundColor',badBGcolor);
            set(hbutton.calcSubsetOST,'BackgroundColor',badBGcolor);
            set(hbutton.calcSingleOST,'BackgroundColor',badBGcolor);
        else
            % Only put the calc ALL OST back to normal if all OSTs have been recalculated
            set(hbutton.calcSingleOST, 'BackgroundColor', normal_bgcolor); 
            if bAllOstRecalculated
                set(hbutton.calcAllOST,'BackgroundColor',normal_bgcolor);
            else
                set(hbutton.calcAllOST,'BackgroundColor',badBGcolor);
            end
            % Only put the calc THESE back to normal if all showing OSTs have been recalculated
            if bTheseOstRecalculated
                set(hbutton.calcSubsetOST,'BackgroundColor',normal_bgcolor);
            else
                set(hbutton.calcSubsetOST, 'BackgroundColor', badBGcolor); 
            end
        end
    end

%% Setting OST heuristics/paramters 
% Units (static text) 
vert_orig = vert_orig + buttonHeight + padYButton;
triggerThreshUnitPos = [horiz_orig vert_orig quarterEditWidth quarterEditHeight]; 
htext.statusParam1Unit = uicontrol(p.guidata.buttonPanel, 'Style','text',...
    'String',heurUnits{1},...
    'Units','Normalized','Position',triggerThreshUnitPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75); 

horiz_orig = 1 - 2*quarterEditWidth - 2*padL; 
triggerDurUnitPos = [horiz_orig vert_orig quarterEditWidth quarterEditHeight]; 
htext.statusParam2Unit = uicontrol(p.guidata.buttonPanel, 'Style','text',...
    'String',heurUnits{2},...
    'Units','Normalized','Position',triggerDurUnitPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

horiz_orig = 1 - quarterEditWidth - padL; 
triggerThirdUnitPos = [horiz_orig vert_orig quarterEditWidth quarterEditHeight]; 
htext.statusParam3Unit = uicontrol(p.guidata.buttonPanel, 'Style','text',...
    'String','third',...
    'Units','Normalized','Position',triggerThirdUnitPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

    function set_heuristicParams
        [heurUnits, heurMin, heurMax, heurStep] = get_heuristicParams(heuristic);
        % warning('off')
        htext.statusParam1Unit.String = heurUnits{1}; 
        htext.statusParam2Unit.String = heurUnits{2}; 
        htext.statusParam3Unit.String = heurUnits{3}; 
        
        set(hslider.statusParam1,'Min',heurMin(1)); 
        set(hslider.statusParam1,'Max',heurMax(1)); 
        set(hslider.statusParam1,'SliderStep',heurStep(1,:)); 
        
        set(hslider.statusParam2,'Min',heurMin(2)); 
        set(hslider.statusParam2,'Max',heurMax(2)); 
        set(hslider.statusParam2,'SliderStep',heurStep(2,:)); 
        
        set(hslider.statusParam3,'Min',heurMin(3)); 
        set(hslider.statusParam3,'Max',heurMax(3)); 
        set(hslider.statusParam3,'SliderStep',heurStep(3,:)); 
        % warning('on')
    end

    function set_heuristicDefaults
        [heurUnits, heurMin, heurMax, heurStep] = get_heuristicParams(heuristic); 
        hslider.statusParam1.Value = heurMin(1) + heurStep(1,1); 
        hslider.statusParam2.Value = heurMin(2) + heurStep(1,1); 
        hslider.statusParam3.Value = heurMin(3) + heurStep(1,1); 
        
        hedit.statusParam1.String = num2str(heurMin(1) + heurStep(1,1)); 
        hedit.statusParam2.String = num2str(heurMin(2) + heurStep(1,1)); 
        hedit.statusParam3.String = num2str(heurMin(3) + heurStep(1,1)); 
    end

% Trigger sliders
horiz_orig = padL; 
vert_orig = vert_orig + editHeight + padYButton;
triggerThreshSliderPos = [horiz_orig vert_orig quarterSliderWidth quarterSliderHeight]; 
hslider.statusParam1 = uicontrol(p.guidata.buttonPanel,'Style','slider',...
    'Min',heurMin(1),... % placeholder
    'Max',heurMax(1),...
    'SliderStep', heurStep(1,:),...
    'Value',heurParam1, ...
    'Units','Normalized','Position',triggerThreshSliderPos,...
    'Callback',@set_param1_edit);
    function set_param1_edit(hObject,eventdata) % callback for h_slider_preemph
        heurParam1 = get(hObject, 'Value');
        set(hedit.statusParam1,'String',heurParam1);
        [~,savedThresh,~] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        set_alert4calcOST_if_true(heurParam1 ~= savedThresh); 
    end

horiz_orig = 1 - 2*quarterSliderWidth - 2*padL; 
triggerDurSliderPos = [horiz_orig vert_orig quarterSliderWidth quarterSliderHeight]; 
hslider.statusParam2 = uicontrol(p.guidata.buttonPanel,'Style','slider',...
    'Min',heurMin(2),... % probably 0-1 is fine (only exception is if we use stretch/span)
    'Max',heurMax(2),...
    'SliderStep', heurStep(2,:),...
    'Value',heurParam2, ... % placeholder
    'Units','Normalized','Position',triggerDurSliderPos,...
    'Callback',@set_param2_edit);
    function set_param2_edit(hObject,eventdata) % callback for h_slider_preemph
        heurParam2 = get(hObject, 'Value');
        set(hedit.statusParam2,'String',heurParam2);
        [~,~,savedDur] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        set_alert4calcOST_if_true(heurParam2 ~= savedDur); 
    end

horiz_orig = 1 - quarterSliderWidth - padL; 
triggerThirdSliderPos = [horiz_orig vert_orig quarterSliderWidth quarterSliderHeight]; 
hslider.statusParam3 = uicontrol(p.guidata.buttonPanel,'Style','slider',...
    'Min',heurMin(3),... % probably 0-1 is fine (only exception is if we use stretch/span)
    'Max',heurMax(3),...
    'SliderStep', heurStep(3,:),...
    'Value',heurParam3, ... % placeholder
    'Units','Normalized','Position',triggerThirdSliderPos,...
    'Callback',@set_param3_edit);
    function set_param3_edit(hObject,eventdata) % callback for h_slider_preemph
        heurParam3 = get(hObject, 'Value');
        set(hedit.statusParam3,'String',heurParam3);
        [~,~,~,savedThird] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        set_alert4calcOST_if_true(heurParam3 ~= savedThird); 
    end

% Corresponding edit boxes
horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padYSmall;
statusParam1EditPos = [horiz_orig vert_orig quarterEditWidth quarterEditHeight]; 
hedit.statusParam1 = uicontrol(p.guidata.buttonPanel,'Style','edit',...
    'String',num2str(heurParam1), ...
    'Units','Normalized','Position',statusParam1EditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_param1_slider,...
    'TooltipString','Default of 0 includes Praat preemph');

horiz_orig = 1 - 2*quarterEditWidth - 2*padL; 
statusParam2EditPos = [horiz_orig vert_orig quarterEditWidth quarterEditHeight]; 
hedit.statusParam2 = uicontrol(p.guidata.buttonPanel,'Style','edit',...
    'String',num2str(heurParam2), ...
    'Units','Normalized','Position',statusParam2EditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_param2_slider,...
    'TooltipString','Default of 0 includes Praat preemph');

horiz_orig = 1 - quarterEditWidth - padL; 
statusParam3EditPos = [horiz_orig vert_orig quarterEditWidth quarterEditHeight]; 
hedit.statusParam3 = uicontrol(p.guidata.buttonPanel,'Style','edit',...
    'String',num2str(heurParam3), ...
    'Units','Normalized','Position',statusParam3EditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_param3_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
 
function set_param1_slider(hObject,eventdata) % Change slider to match edit field; alert that recalculation is available
    newParam1 = hObject.String;
    [~,oldParam1,~] = get_ost(trackingFileDir,trackingFileName,ostStatus,'working'); 
    hslider.statusParam1.Value = str2double(newParam1); 
    set_alert4calcOST_if_true(oldParam1 ~= str2double(newParam1));         
end 

function set_param2_slider(hObject,eventdata) % Change slider to match edit field; alert that recalculation is available
    newParam2 = hObject.String;
    [~,~,oldParam2] = get_ost(trackingFileDir,trackingFileName,ostStatus,'working'); 
    hslider.statusParam2.Value = str2double(newParam2); 
    set_alert4calcOST_if_true(oldParam2 ~= str2double(newParam2)); 
end 

function set_param3_slider(hObject,eventdata) % Change slider to match edit field; alert that recalculation is available
    newParam3 = hObject.String;
    [~,~,~,oldParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus,'working'); 
    hslider.statusParam3.Value = str2double(newParam3); 
    set_alert4calcOST_if_true(oldParam3 ~= str2double(newParam3)); 
end 

% Dropdown to change which OST status you are trying to alter
horiz_orig = padL; 
vert_orig = vert_orig + editHeight + padYButton;
ostNumberDropdownPos = [horiz_orig vert_orig 0.5*editWidth buttonHeight]; 
hdropdown.ostNumber = uicontrol(p.guidata.buttonPanel,'Style','popupmenu',...
    'Units','Normalized','Position',ostNumberDropdownPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'String',ostList,... 
    'Value',find(strcmp(ostList,num2str(ostStatus))),... 
    'Callback',@ostNumber_select); 
    function ostNumber_select(hObject,eventdata)
        ostStatus = str2double(hObject.String{hObject.Value});
        [heuristic,heurParam1,heurParam2] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        hdropdown.heuristicChoice.Value = find(strcmp(allHeuristics,heuristic)); 
        %         hbutton.heuristicHelp.String = heuristic;         
        plot_editStatusLine(ostStatus);
        refresh_RMS_lines;
        set_ostParams;        
    end
    function plot_editStatusLine(ostStatus)
        delete(h_editost_ref(1:end));
        ostIndex = find(p.eventNumbers == ostStatus); 
        if isempty(ostIndex)
            statusLabel = ['ostStatus ' num2str(ostStatus)]; 
        else
            statusLabel = p.eventNames{ostIndex}; 
        end
        for traxix = 1:length(trial_axes)
            axes(trial_axes(traxix));  
            yyaxis left
            h_editost_ref(traxix) = yline(ostStatus * p.ostMultiplier, ['--' p.plot_params.line_colors.editost_ref], statusLabel);
        end
        htoggle.editOstRef.Value = 1; 
    end

% Dropdown to change the heuristic you are going to use for the current OST status
horiz_orig = 2*padL + 0.5*editWidth; 
heuristicDropdownPos = [horiz_orig vert_orig buttonWidth - horiz_orig + padL buttonHeight]; 

hdropdown.heuristicChoice = uicontrol(p.guidata.buttonPanel,'Style','popupmenu',...
    'Units','Normalized','Position',heuristicDropdownPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'String',allHeuristics,... 
    'Value',find(strcmp(allHeuristics,heuristic)),... 
    'Callback',@heuristic_select); 
    function heuristic_select(hObject,eventdata)
        [oldHeuristic,~,~] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
        heuristic = hObject.String{hObject.Value}; 
        get_heuristicParams(heuristic); 
        % warning('off'); 
        set_heuristicParams;
        set_heuristicDefaults;
        refresh_RMS_lines; 
        % warning('on'); 
        set_alert4calcOST_if_true(~strcmp(heuristic,oldHeuristic));         
    end
    


% hbutton.heuristicHelp = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
%     'String',heuristic,...
%     'Units','Normalized','Position',heuristicHelpButtonPos,...
%     'FontUnits','Normalized','FontSize',buttonFontSize/1.5,...
%     'Callback',@heuristic_help);
    function heuristic_help(hObject,eventdata)
        switch heuristic
            case 'ELAPSED_TIME'
                heurhelpstr = sprintf(['Elapsed time from previous state.\n',...
                    'One parameter: duration (in seconds)\n']);                 
            case 'INTENSITY_RISE_HOLD'
                heurhelpstr = sprintf(['Crossing an intensity (RMS) threshold from below and hold.\n',...
                    'First parameter: RMS threshold\n',...
                    'Second parameter: minimum duration (s)\n']);                 
            case 'INTENSITY_RISE_HOLD_POS_SLOPE'
                heurhelpstr = sprintf(['Crossing an intensity threshold from below and hold, during positive RMS slope.\n',...
                    'First parameter: RMS threshold\n',...
                    'Second parameter: minimum duration (s)\n']);                 
            case 'POS_INTENSITY_SLOPE_STRETCH'
                heurhelpstr = sprintf(['Stretch of positive intensity slope, with only a stretch count threshold.\n',...
                    'First parameter: stretch count threshold (in frames)\n']);                 
            case 'NEG_INTENSITY_SLOPE_STRETCH_SPAN'
                heurhelpstr = sprintf(['Stretch of negative intensity slope, with a stretch count threshold and a stretch span threshold.\n',...
                    'First parameter: stretch count threshold (in frames)\n',...
                    'Second parameter: stretch span threshold (in RMS space covered??  Probably negative?)\n']); 
                % In future-proofing this GUI will have to be more flexible with the min/max of the sliders/edit fields.
                % Probably set based on heuristic.                 
            case 'INTENSITY_FALL'
                heurhelpstr = sprintf(['Fall from a certain intensity threshold.\n',...
                    'First parameter: RMS threshold\n',...
                    'Second parameter: minimum duration (s)\n']); 
            case 'INTENSITY_RATIO_RISE'
                heurhelpstr = sprintf(['Intensity ratio cross from below and hold. Higher ratios indicate presence of high frequency noise.\n',...
                    'First parameter: RMS ratio threshold\n',...
                    'Second parameter: minimum duration (s)\n']); 
            case 'INTENSITY_RATIO_FALL_HOLD'
                heurhelpstr = sprintf(['Intensity ratio fall from a threshold and hold. Lower ratio indicates something more like a vowel.\n',...
                    'First parameter: RMS ratio threshold\n',...
                    'Second parameter: minimum duration (s)\n']);                 
            case 'OST_END'
                heurhelpstr = sprintf(['Ending rule.\n',...
                    'If you''re looking at this you have probably committed a grave error somewhere.']); 
        end
        helpdlg(heurhelpstr);
    end
    function refresh_RMS_lines % When switching heuristic, RMS vs. ratio vs. slope need to be reprioritized
        % Clear h_rms, h_rms_rat
        delete(h_rms(1:end)); 
        delete(h_rms_rat(1:end)); 
        delete(h_dRms(1:end)); 
        delete(h_dRms_rat(1:end)); 
        data2plot = y(trials); 
        for traxix = 1:length(data2plot)
            if traxix <= 9
                rms = data2plot(traxix).rms(:,1); 
                rms_rat = data2plot(traxix).rms(:,2) ./ rms;  
                dRms = data2plot(traxix).rms_slope; 
                try 
                    dRms_rat = data2plot(traxix).rms_ratio_slope; 
                catch
                    dRms_rat = diff([rms(1); rms]); 
                end
                    
                % Make new h_rms, h_rms_rat and plot
                axes(trial_axes(traxix));
                yyaxis right % RMS/RMS ratio on right
                [valMultipliers, lineVisibility, lineType] = get_rmsLineProperties(heuristic, rms, dRms, rms_rat, dRms_rat); 


                h_rms(traxix) = plot(audTAxis{traxix}, rms * valMultipliers.rms, [lineType.rms p.plot_params.line_colors.rms]); 
                set(h_rms(traxix),'visible',lineVisibility.rms)
                h_rms_rat(traxix) = plot(audTAxis{traxix}, rms_rat * valMultipliers.rms_rat, [lineType.rms_rat p.plot_params.line_colors.rms_rat]); 
                set(h_rms_rat(traxix),'visible',lineVisibility.rms_rat) 
                h_dRms(traxix) = plot(audTAxis{traxix}, dRms * valMultipliers.dRms, [lineType.dRms p.plot_params.line_colors.dRms]); 
                set(h_dRms(traxix),'visible',lineVisibility.dRms)
                h_dRms_rat(traxix) = plot(audTAxis{traxix}, dRms_rat * valMultipliers.dRms_rat, 'linestyle', lineType.dRms_rat, 'color', p.plot_params.line_colors.dRms_rat, 'marker', 'none'); 
                set(h_dRms_rat(traxix), 'visible', lineVisibility.dRms_rat); 
                
            else
                fprintf('Only plotting the first nine trials\n')
            end
        end
        
        htoggle.rms.Value = strcmp(lineVisibility.rms,'on'); 
        htoggle.rmsRatio.Value = strcmp(lineVisibility.rms_rat,'on');
        htoggle.dRms.Value = strcmp(lineVisibility.dRms,'on');
        htoggle.dRms_rat.Value = strcmp(lineVisibility.dRms_rat,'on');
    end

horiz_orig = padL; 
vert_orig = vert_orig + buttonHeight + padYBig;
ostFromTrialSliderPos = [horiz_orig vert_orig buttonWidth*0.75 sliderHeight]; 
hslider.ostFromTrial = uicontrol(p.guidata.buttonPanel,'Style','slider',...
    'Min',1,... 
    'Max',max(availableTrials),...
    'SliderStep', trialSliderStep,...
    'Value',min(trials), ...
    'Units','Normalized','Position',ostFromTrialSliderPos,...
    'Callback',@set_ostFromTrial_edit);
    function set_ostFromTrial_edit(hObject, eventdata)
        newTrial = hObject.Value; 
        % don't allow non-integers 
        if floor(newTrial) ~= newTrial
            newTrial = floor(newTrial); 
            set(hslider.trials2display,'Value',newTrial); 
        end
        ostTrial = newTrial;
        set(hedit.ostFromTrial,'String',num2str(ostTrial)); 
%         load_new_ostFromTrial
    end

horiz_orig = horiz_orig*2 + buttonWidth*0.75; 
switchOstFromTrialButtonPos = [horiz_orig vert_orig buttonWidth*0.2 sliderHeight]; 
hbutton.ostFromTrial = uicontrol(p.guidata.buttonPanel,'Style','pushbutton',...
    'String','GO',...
    'Units','Normalized','Position',switchOstFromTrialButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize/1.5,...
    'Callback',@load_new_ostFromTrial);
    function load_new_ostFromTrial(hObject,eventdata)
        if ~ismember(ostTrial,trials)
            newMinTrial = ostTrial; 
            newMaxTrial = ostTrial + 8; 
            if newMaxTrial > max(availableTrials)
                newMaxTrial = max(availableTrials); 
            end
            set(hedit.firstTrial,'String',num2str(newMinTrial)); 
            set(hedit.lastTrial,'String',num2str(newMaxTrial)); 
            set(hslider.trials2display,'Value',newMinTrial); 
            trials = newMinTrial:newMaxTrial; 
            plot_new_trials
            set(htoggle.formantsOut, 'Value', sum(strcmp({h_formantsOut_1(1:end).Visible},'on')) > 0); 
        end
        
        % Check if trial-specific information is available
        set_subjOstParams_auto(x, y, 1, ostTrial);
        
        % Now that the OST file is set to the OST values from that particular trial, set dropdowns and edit fields
        set_ostParams; % Note that you don't move from the particular status number you are on     

    end

horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padYSmall; 
ostFromTrialTextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.ostFromTrial = uicontrol(p.guidata.buttonPanel, 'Style','text',...
    'String','OST from trial:',...
    'Units','Normalized','Position',ostFromTrialTextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);


horiz_orig = horiz_orig + editWidth + padL*2; 
ostFromTrialEditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.ostFromTrial = uicontrol(p.guidata.buttonPanel,'Style','edit',...
    'String',num2str(ostTrial), ...
    'Units','Normalized','Position',ostFromTrialEditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_ostFromTrial_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_ostFromTrial_slider(hObject,eventdata)
        newTrial = hObject.String; 
        ostTrial = str2double(newTrial);
        if floor(ostTrial) ~= ostTrial
            fprintf('Can only accept positive integers\n')
            ostTrial = ceil(ostTrial);
        end
        % Make sure the trials are within the bounds of the available trials
        if ostTrial > max(availableTrials) 
            fprintf('No trial number %d. Setting at last trial.\n', ostTrial)
            ostTrial = max(availableTrials);             
        elseif ostTrial < min(availableTrials)
            fprintf('No trial number %d. Setting at first trial.\n', ostTrial)
            ostTrial = min(availableTrials);             
        end

        newTrial = num2str(ostTrial); 

        set(hedit.ostFromTrial,'String',newTrial); 
        set(hslider.ostFromTrial,'Value',ostTrial); 
        
    end


% Descriptive text
horiz_orig = padL; 
vert_orig = vert_orig + editHeight + padYButton; 
headerTextPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
htext.triggerHeader = uicontrol(p.guidata.buttonPanel, 'Style','text',...
    'String','OST Settings',...
    'ForegroundColor','k','FontWeight','bold',...
    'Units','Normalized','Position',headerTextPos,...
    'FontUnits','Normalized','FontSize',0.5);



%%
% Toggling lines
vert_orig = vert_orig + buttonHeight + padYBig; 
% reference OST (trigger)
ostRefTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.ostRef = uicontrol(p.guidata.buttonPanel,'Style','togglebutton',...
    'String','Trigger',...
    'Value',1,...
    'BackgroundColor',p.plot_params.line_colors.ost_ref,...
    'Units','Normalized','Position',ostRefTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_ref);
    function toggle_ref(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_ostref)
                axes(trial_axes(traxix));
                set(h_ostref(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_ostref)
                axes(trial_axes(traxix));
                set(h_ostref(traxix),'visible','off')
            end
        end
    end
% editing reference OST (not the trigger)
horiz_orig = 1-halfButtonWidth-padL; 
editOstRefTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.editOstRef = uicontrol(p.guidata.buttonPanel,'Style','togglebutton',...
    'String','Non-trigger',...
    'Value',0,...
    'BackgroundColor',p.plot_params.line_colors.editost_ref,...
    'Units','Normalized','Position',editOstRefTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_editref);
    function toggle_editref(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_editost_ref)
                axes(trial_axes(traxix));
                set(h_editost_ref(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_editost_ref)
                axes(trial_axes(traxix));
                set(h_editost_ref(traxix),'visible','off')
            end
        end
    end

horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padHalfButton; 
% OST
ostTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.ost = uicontrol(p.guidata.buttonPanel,'Style','togglebutton',...
    'String','OST Status',...
    'Value',1,...
    'BackgroundColor',p.plot_params.line_colors.ost,...
    'Units','Normalized','Position',ostTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_ost);
    function toggle_ost(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_ost)
                axes(trial_axes(traxix));
                set(h_ost(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_rms)
                axes(trial_axes(traxix));
                set(h_ost(traxix),'visible','off')
            end
        end
    end

horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padHalfButton; 
% rms slope
dRmsTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.dRms = uicontrol(p.guidata.buttonPanel,'Style','togglebutton',...
    'String','RMS slope',...
    'Value',strcmp(h_dRms(1).Visible,'on'),...
    'BackgroundColor',p.plot_params.line_colors.dRms,...
    'Units','Normalized','Position',dRmsTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_dRms);
    function toggle_dRms(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_dRms)
                axes(trial_axes(traxix));
                set(h_dRms(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_dRms)
                axes(trial_axes(traxix));
                set(h_dRms(traxix),'visible','off')
            end
        end
    end

% RMS ratio slope
horiz_orig = 1-halfButtonWidth-padL; 
dRmsRatTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.dRms_rat = uicontrol(p.guidata.buttonPanel,'Style','togglebutton',...
    'String','RMS RatSlope',...
    'Value',strcmp(h_dRms_rat(1).Visible,'on'),...
    'BackgroundColor',p.plot_params.line_colors.dRms_rat,...
    'Units','Normalized','Position',dRmsRatTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_dRmsRat);
    function toggle_dRmsRat(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_dRms_rat)
                axes(trial_axes(traxix));
                set(h_dRms_rat(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_dRms_rat)
                axes(trial_axes(traxix));
                set(h_dRms_rat(traxix),'visible','off')
            end
        end
    end



% Next line up
horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padHalfButton;
% RMS
rmsTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.rms = uicontrol(p.guidata.buttonPanel,'Style','togglebutton',...
    'String','RMS',...
    'Value',strcmp(h_rms(1).Visible,'on'),...
    'BackgroundColor',p.plot_params.line_colors.rms,...
    'Units','Normalized','Position',rmsTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_rms);
    function toggle_rms(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_rms)
                axes(trial_axes(traxix));
                set(h_rms(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_rms)
                axes(trial_axes(traxix));
                set(h_rms(traxix),'visible','off')
            end
        end
    end

% RMS ratio
horiz_orig = 1-halfButtonWidth-padL; 
rmsRatioTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.rmsRatio = uicontrol(p.guidata.buttonPanel,'Style','togglebutton',...
    'String','RMS Ratio',...
    'Value',strcmp(h_rms_rat(1).Visible,'on'),...
    'BackgroundColor',p.plot_params.line_colors.rms_rat,...
    'Units','Normalized','Position',rmsRatioTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_rmsRatio);
    function toggle_rmsRatio(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_rms_rat)
                axes(trial_axes(traxix));
                set(h_rms_rat(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_rms_rat)
                axes(trial_axes(traxix));
                set(h_rms_rat(traxix),'visible','off')
            end
        end
    end

% Descriptive text for toggles
horiz_orig = padL; 
vert_orig = vert_orig + halfButtonHeight; 
toggleTextPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
htext.toggleHeader = uicontrol(p.guidata.buttonPanel, 'Style','text',...
    'String','Plot Options',...
    'ForegroundColor','k','FontWeight','bold',...
    'Units','Normalized','Position',toggleTextPos,...
    'FontUnits','Normalized','FontSize',0.5);

    function set_ostParams
       [heuristic,heurParam1,heurParam2,heurParam3] = get_ost(trackingFileDir,trackingFileName,ostStatus); 
       ostList = get_ost(trackingFileDir,trackingFileName,'list'); 
       set_heuristicParams; 
       set(hdropdown.ostNumber,'String',ostList)
       set(hdropdown.ostNumber,'Value',find(strcmp(ostList,num2str(ostStatus)))); 
       set(hedit.statusParam1,'String',num2str(heurParam1)); 
       set(hedit.statusParam2,'String',num2str(heurParam2)); 
       set(hedit.statusParam3,'String',num2str(heurParam3)); 
       
       % warning('off'); % Turn them off so the slider doesn't get mad
       set(hslider.statusParam1,'Value',heurParam1); 
       set(hslider.statusParam2,'Value',heurParam2); 
       set(hslider.statusParam3,'Value',heurParam3); 
       % warning('on'); 
       set(hdropdown.heuristicChoice,'Value',find(strcmp(allHeuristics,heuristic))); 
%        set(hbutton.heuristicHelp,'String',heuristic); 
    end
set_ostParams; 
wp.dur = hslider.statusParam2.Value;
wp.thresh = hslider.statusParam1.Value; 

%% Controls to change trials 
trialPanelEditWidth = 0.025; 
trialPanelPadL = 0.005; 

vert_orig = padYSmall;
horiz_orig = 0; 
trialSliderPos = [horiz_orig vert_orig 0.84 1-padYSmall]; 
hslider.trials2display = uicontrol(p.guidata.trialPanel,'Style','slider',...
    'Min',1,... 
    'Max',max(availableTrials),...
    'SliderStep', trialSliderStep,...
    'Value',min(trials), ...
    'BackgroundColor', [0.6 0.6 0.6], ...
    'Units','Normalized','Position',trialSliderPos,...
    'Callback',@move_trials);
    function move_trials(hObject, eventdata)
        newMinTrial = hObject.Value; 
        oldtrials = trials; 
        % don't allow non-integers 
        if floor(newMinTrial) ~= newMinTrial
            newMinTrial = floor(newMinTrial); 
            set(hslider.trials2display,'Value',newMinTrial); 
        end

        % Make sure the trials are within the bounds of the available trials
        newMaxTrial = newMinTrial + 8;
        if newMaxTrial > max(availableTrials)
            newMaxTrial = max(availableTrials); 
        end
        
        trials = newMinTrial:newMaxTrial; 

        set(hedit.firstTrial,'String',num2str(newMinTrial)); 
        set(hedit.lastTrial,'String',num2str(newMaxTrial)); 
        if ~isequal(trials,oldtrials)
            set(hbutton.plotNewTrials, 'BackgroundColor', badBGcolor); 
        end
        
    end


% Jump to trials... 
horiz_orig = 0.84; 
trialLabelPos = [horiz_orig vert_orig trialPanelEditWidth*2 1]; 
htext.trialLabel = uicontrol(p.guidata.trialPanel,'Style','text',...
    'String', 'Jump to trials...','FontWeight','Bold',...
    'Units','Normalized','Position',trialLabelPos,...
    'FontUnits','Normalized','FontSize',0.4); 


% Edit fields for trial
horiz_orig = horiz_orig + trialPanelEditWidth*2 + trialPanelPadL; 
% vert_orig = vert_orig + sliderHeight + padYButton; 
firstTrialEditPos = [horiz_orig vert_orig trialPanelEditWidth 1]; 
hedit.firstTrial = uicontrol(p.guidata.trialPanel,'Style','edit',...
    'String', num2str(min(trials)), ...
    'Units','Normalized','Position',firstTrialEditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_trialSlider_trialMax,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_trialSlider_trialMax(hObject, eventdata)
        newMinTrial = hObject.String; 
        oldtrials = trials; 
        num_newMinTrial = str2double(newMinTrial);
        if floor(num_newMinTrial) ~= num_newMinTrial
            num_newMinTrial = ceil(num_newMinTrial);
            fprintf('Can only accept positive integers as trial numbers\n')
        end
        % Make sure the trials are within the bounds of the available trials
        if num_newMinTrial > max(availableTrials) 
            fprintf('No trial number %d. Setting range maximum at last trial.\n', num_newMinTrial)
            num_newMinTrial = max(availableTrials);             
        elseif num_newMinTrial < min(availableTrials)
            fprintf('No trial number %d. Setting range minimum at first trial.\n', num_newMinTrial)
            num_newMinTrial = min(availableTrials); 
        end
        
        num_newMaxTrial = num_newMinTrial + 8; 
        if num_newMaxTrial > max(availableTrials)
            num_newMaxTrial = max(availableTrials); 
        end
        
        newMinTrial = num2str(num_newMinTrial); 
        newMaxTrial = num2str(num_newMaxTrial); 
        
        trials = num_newMinTrial:num_newMaxTrial; 
        set(hedit.firstTrial,'String',newMinTrial); 
        set(hslider.trials2display,'Value',num_newMinTrial); 
        set(hedit.lastTrial,'String',newMaxTrial);        
        
        if ~isequal(trials,oldtrials)
            set(hbutton.plotNewTrials, 'BackgroundColor', badBGcolor); 
        end
    end

% "to" 
horiz_orig = horiz_orig + trialPanelEditWidth + trialPanelPadL; 
trial2trialPos = [horiz_orig vert_orig trialPanelPadL*2 0.6]; 
htext.trial2trial = uicontrol(p.guidata.trialPanel,'Style','text',...
    'String', ' to ',...
    'Units','Normalized','Position',trial2trialPos,...
    'FontUnits','Normalized','FontSize',0.7); 

% Last trial edit 
horiz_orig = horiz_orig + trialPanelPadL*2 + trialPanelPadL; 
lastTrialEditPos = [horiz_orig vert_orig trialPanelEditWidth 1]; 
hedit.lastTrial = uicontrol(p.guidata.trialPanel,'Style','edit',...
    'String', num2str(max(trials)), ...
    'Units','Normalized','Position',lastTrialEditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_trialSlider_fromEnd,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_trialSlider_fromEnd(hObject, eventdata)
        newMaxTrial = hObject.String; 
        oldtrials = trials; 
        num_newMaxTrial = str2double(newMaxTrial);
        if floor(num_newMaxTrial) ~= num_newMaxTrial
            num_newMaxTrial = ceil(num_newMaxTrial);
            fprintf('Can only accept positive integers as trial numbers\n')
        end
        % Make sure the trials are within the bounds of the available trials
        if num_newMaxTrial > max(availableTrials) 
            fprintf('No trial number %d. Setting range maximum at last trial.\n', num_newMaxTrial)
            num_newMaxTrial = max(availableTrials); 
        elseif num_newMaxTrial < min(availableTrials)
            fprintf('No trial number %d. Setting range minimum at first trial.\n', num_newMaxTrial)
            num_newMaxTrial = min(availableTrials); 
        end
        
        % Keep min where it is unless you run into some trouble
        num_currentMinTrial = str2double(hedit.firstTrial.String); 
        if num_currentMinTrial < num_newMaxTrial - 8 || num_currentMinTrial > num_newMaxTrial
            num_newMinTrial = num_newMaxTrial - 8; 
            if num_newMinTrial < min(availableTrials)
                num_newMinTrial = min(availableTrials); 
            end
        else 
            num_newMinTrial = num_currentMinTrial; 
        end
        
        newMinTrial = num2str(num_newMinTrial); 
        newMaxTrial = num2str(num_newMaxTrial); 
        
        trials = num_newMinTrial:num_newMaxTrial; 
        set(hedit.firstTrial,'String',newMinTrial); 
        set(hslider.trials2display,'Value',num_newMinTrial); 
        set(hedit.lastTrial,'String',newMaxTrial); 
        if ~isequal(trials,oldtrials)
            set(hbutton.plotNewTrials, 'BackgroundColor', badBGcolor); 
        end
    end

% Trial GO button
horiz_orig = horiz_orig + trialPanelEditWidth + trialPanelPadL; 
plotNewTrialsButtonPos = [horiz_orig vert_orig trialPanelEditWidth 1]; 
hbutton.plotNewTrials = uicontrol(p.guidata.trialPanel,'Style','pushbutton',...
    'String','GO',...
    'Units','Normalized','Position',plotNewTrialsButtonPos,...
    'FontUnits','Normalized','FontSize',0.5,...
    'Callback',@plot_new_trials);
    function plot_new_trials(hObject,eventdata)
        for i = 1:length(trial_axes)
            ax = trial_axes(i); 
            oax = output_trial_axes(i); 
            delete(ax); 
            delete(oax); 
        end
        clear trial_axes h_rms h_rms_rat h_dRms h_ost h_ostref h_editost_ref audTAxis
        [trial_axes,h_rms,h_rms_rat,h_dRms,h_dRms_rat,h_ost,h_ostref,h_editost_ref,audTAxis] = new_trial_axes(y,p,trials,ostStatus,heuristic,ost_calc);
    
        clear output_trial_axes h_outputOst output_audTAxis
        [output_trial_axes,h_outputOst,output_audTAxis,h_formantsIn_1,h_formantsIn_2,h_formantsOut_1,h_formantsOut_2] = new_output_trial_axes(y,x,p,trackingFileDir,trackingFileName,trials,signalOut_calc); 
        
        if ~ismember(pcfTrial,trials)
            pcfTrial = min(trials); 
            set(hedit.pcfFromTrial,'String',num2str(pcfTrial)); 
            set(hslider.pcfFromTrial,'Value',pcfTrial); 
            load_new_pcfFromTrial
        end
        
        if ~ismember(ostTrial,trials)
            ostTrial = min(trials); 
            set(hedit.ostFromTrial,'String',num2str(ostTrial)); 
            set(hslider.ostFromTrial,'Value',ostTrial); 
            load_new_ostFromTrial
        end
        
        % Reset button colors for "recalculate these" if they haven't all been set
        if ~bAllOstRecalculated
            bAlert4calcOST = 1;
            set_alert4calcOST_if_true(bAlert4calcOST); 
        end
        set(hbutton.plotNewTrials, 'BackgroundColor', normal_bgcolor); 

    end




%% OUTPUT BUTTONS

% Button creation
horiz_orig = padL; 
vert_orig = padYButton; 

% Exit button
exitButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.recalculateWarp = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String','Exit',...
    'Units','Normalized','Position',exitButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@save_exit);
   

% Reset to default
vert_orig = vert_orig + buttonHeight + padYButton; 
resetAllDefaultsButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.recalculateWarp = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String','Reset all to original & apply',...
    'Units','Normalized','Position',resetAllDefaultsButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@reset_all_originals);
    function reset_all_originals(hObject,eventdata)
        fWaiting = waitbar(0.05, 'Resetting...'); 
       for i = 1:length(y)
           calcPcfLine{i} = y(i).pcfLine; 
           signalOut_calc{i} = y(i).signalOut; 
       end
       waitbar(0.1, fWaiting, 'Loading new PCF data...'); 
       load_new_pcfFromTrial
       close(fWaiting); 
       plot_new_trials
    end

vert_orig = vert_orig + buttonHeight + padYSmall; 
resetTrialDefaultsButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.recalculateWarp = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String','Reset trial to original & apply',...
    'Units','Normalized','Position',resetTrialDefaultsButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@reset_trial_originals);
    function reset_trial_originals(hObject,eventdata)
        calcPcfLine{pcfTrial} = y(pcfTrial).pcfLine; 
        load_new_pcfFromTrial
        recalculate_single_warp
    end



% Recalculate all
vert_orig = vert_orig + buttonHeight + padYButton; 
recalculateWarpButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.recalculateAllWarp = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String','Apply to all trials',...
    'Units','Normalized','Position',recalculateWarpButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@recalculate_all_warp);
    function recalculate_all_warp(hObject,eventdata)
        fWaiting = waitbar(0.1, 'Setting new PCF values...'); 
        % New version of set_pcf that can edit both time and space
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'ostStat_initial', ostStat_initial); % Actually I think this is bad if you change ostStat_initial
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'tBegin', tBegin); 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'rate1', rate1, 1); % Should this be 0? Should I add a checkbox/dialog? 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'dur1', dur1, 1); 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'durHold', durHold); 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'rate2', rate2); 
      
        % rk 2/11/2021 needs to be made flexible again
%         [ostStat_initial, 
        for i = 1:length(y)
            calcPcfLine{i} = [ostStat_initial tBegin rate1 dur1 durHold rate2]; 
        end
        waitbar(0.3, fWaiting, 'Calculating new signalOuts...'); 
        try
            signalOut_calc = calc_newAudapterData({y.signalIn},p.audapter_params,trackingFileDir,trackingFileName,'signalOut');         
            % Make sure that signalOut_calc is a cell before it gets sent into new_output_trial_axes (fix for when there is just
            % one trial) 
            if ~iscell(signalOut_calc)
                signalOut_calc = {signalOut_calc}; 
            end

            for i = 1:length(output_trial_axes)
                oax = output_trial_axes(i); 
                delete(oax); 
            end

            clear output_trial_axes h_outputOst output_audTAxis
            close(fWaiting); 
            [output_trial_axes,h_outputOst,output_audTAxis,h_formantsIn_1,h_formantsIn_2,h_formantsOut_1,h_formantsOut_2] = new_output_trial_axes(y,x,p,trackingFileDir,trackingFileName,trials,signalOut_calc); 
            set_pcf_alert4calcOST_if_true(0); 
        catch exception
            errorText = getReport(exception, 'basic', 'hyperlinks','off'); 
            outputOst = {y(trials).ost_stat}; 
            if contains(errorText, 'Unrecognized OST heuristic mode')
                message = sprintf([errorText '.\n\nOutput signal has not been recalculated. Change heuristic to do offline warping.']); 
            else
                message = sprintf(['Error in calculating new output. Location: recalculate_all_warp (you should probably tell Robin). \n\n ----- \n\n' errorText]); 
            end
            close(fWaiting)
            alert2mismatchMex = msgbox(message); 
        end
        
    end


% Recalculate single
vert_orig = vert_orig + buttonHeight + padYSmall; 
recalculateWarpButtonPos = [horiz_orig vert_orig buttonWidth buttonHeight]; 
hbutton.recalculateSingleWarp = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String','Apply to single trial',...
    'Units','Normalized','Position',recalculateWarpButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@recalculate_single_warp);
    function recalculate_single_warp(hObject,eventdata)
        fWaiting = waitbar(0.1,'Setting PCF parameters...'); 
        try
            set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'ostStat_initial', ostStat_initial); 
        catch
            set_pcf(trackingFileDir, trackingFileName, timeSpace, '1', 'ostStat_initial', ostStat_initial); % Placeholder... RK 02/12/2021 (it won't always be the first)
        end
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'tBegin', tBegin); 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'rate1', rate1, 1); % Should this be 0? Should I add a checkbox/dialog? 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'dur1', dur1, 1); 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'durHold', durHold); 
        set_pcf(trackingFileDir, trackingFileName, timeSpace, ostStat_initial, 'rate2', rate2); 
             
        waitbar(0.25,fWaiting,'Calculating new audapter data...')
        try
            [signalOut_calc{pcfTrial}, formantsIn_calc, formantsOut_calc] = calc_newAudapterData({y(pcfTrial).signalIn},p.audapter_params,trackingFileDir,trackingFileName,{'signalOut', 'fmts', 'sfmts'}); 
            if isfield(y, 'trial')
                titleTrialNo = y(pcfTrial).trial; 
            elseif isfield(y, 'token')
                titleTrialNo = y(pcfTrial).token; 
            else
                titleTrialNo = pcfTrial; 
            end
            waitbar(0.5,fWaiting,'Calculating new OST for signalOut...')
            % TKTKTKTKTKT is this wrong? calcOST for signalOut is being put into calcOST? 
    %         set_ost(trackingFileLoc, trackingFileName, ostStatus, heuristic, heurParam1, heurParam2); % Set working file to the current line's changes at least? Dunno
            ost_calc{pcfTrial} = calc_newAudapterData(signalOut_calc(pcfTrial),p.audapter_params,trackingFileDir,trackingFileName,'ost_stat'); 
      
            % For now I'm just clearing everything because I can't think of how to delete and put back in a single axis (clearing
            % variable/getting to the right axis...) 
            waitbar(0.75,fWaiting,'Replotting...')
            traxix = find(trials == pcfTrial); 
            axes(output_trial_axes(traxix)); % Set axes otherwise matlab thinks it's working with the waitbar 
            oax = output_trial_axes(traxix); 
            traxesPosition = oax.Position; 
            delete(oax);         
            h_outputOst(traxix) = []; 
            output_trial_axes(traxix) = axes(p.guidata.pcf_faxesPanel,'Position', traxesPosition);
            ax = output_trial_axes(traxix); 
            hold(ax,'off')
            cla(ax,'reset'); 

            axdat{1} = signalOut_calc{pcfTrial}; 
            params{1}.taxis = (0:(length(axdat{1})-1))/fs;

            % Spectrogram
            [s, f, t] = spectrogram(axdat{1}, 256, 192, 1024, fs);

            imagesc(ax, t, f, 10 * log10(abs(s)));

            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')

            ax.YDir = 'normal';

            ax.YLim = [0 6000]; 
            ax.XLim = [t(1) t(end)]; 
    %                 set(ax, 'YLim', [0, 6000]);
    %                 set(ax, 'XLim', [t(1), t(end)]);
            colormap(ax,flipud(gray));

    %         hold(ax,'on');
            % Audapter plots                

            hold on
            % OST status (plotted on spectrogram axis)
            outputOst = ost_calc{pcfTrial}; 
            % Formants  
            formantsIn_1 = formantsIn_calc(:, 1); 
            formantsIn_2 = formantsIn_calc(:, 2); 

            formantsOut_1 = formantsOut_calc(:, 1); 
            formantsOut_2 = formantsOut_calc(:, 2); 
            if sum(formantsOut_1) == 0, bOutputFormants = 0; else bOutputFormants = 1; end

            % Make NaNs so the plots look cleaner
            formantsIn_1(formantsIn_1 == 0) = NaN; 
            formantsIn_2(formantsIn_2 == 0) = NaN; 
            formantsOut_1(formantsOut_1 == 0) = NaN; 
            formantsOut_2(formantsOut_2 == 0) = NaN; 


            % Plot'em 
            frameDur = y(pcfTrial).params.frameLen / fs;
            rms = y(pcfTrial).rms(:,1); %  just to get audTAxis in output
            output_audTAxis{traxix} = 0 : frameDur : frameDur * (size(rms, 1) - 1);
            % Plot formants (note that these have to be on the spectrogram's scale) 
            h_formantsIn_1(pcfTrial) = scatter(output_audTAxis{traxix}, formantsIn_1, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsIn, ...
                'MarkerEdgeColor', p.plot_params.line_colors.formantsIn); 
            h_formantsIn_2(pcfTrial) = scatter(output_audTAxis{traxix}, formantsIn_2, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsIn, ...
                'MarkerEdgeColor', p.plot_params.line_colors.formantsIn); 

            % Output (make invisible if you didn't do any formant manipulations) 
            h_formantsOut_1(pcfTrial) = scatter(output_audTAxis{traxix}, formantsOut_1, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsOut, ...
                'MarkerEdgeColor', p.plot_params.line_colors.formantsOut); 
            h_formantsOut_2(pcfTrial) = scatter(output_audTAxis{traxix}, formantsOut_2, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsOut, ...
                'MarkerEdgeColor', p.plot_params.line_colors.formantsOut); 
            if ~bOutputFormants
                set(h_formantsOut_1(pcfTrial), 'visible', 'off'); 
                set(h_formantsOut_2(pcfTrial), 'visible', 'off'); 
            end

            yyaxis right % On these the multiplier doesn't need to be in maybe? 
            pause(1)
            h_outputOst(traxix) = plot(output_audTAxis{traxix}, outputOst, p.plot_params.line_colors.ost, 'Linewidth', 1.5); 
    %         set(output_trial_axes,'Title',['Trial ' num2str(pcfTrial)]); 
            title(['Trial ' num2str(titleTrialNo)]); 

            waitbar(1,fWaiting,'Done')
    %         pause(0.5)
            close(fWaiting)
            set_pcf_alert4calcOST_if_true(0); 
        catch exception
            errorText = getReport(exception, 'basic', 'hyperlinks','off'); 
            outputOst = {y(trials).ost_stat}; 
            if contains(errorText, 'Unrecognized OST heuristic mode')
                message = sprintf([errorText '.\n\nOutput signal has not been recalculated. Change heuristic to do offline warping.']); 
            else
                message = sprintf(['Error in calculating new output. Location: recalculate_single_warp (you should probably tell Robin). \n\n ----- \n\n' errorText]); 
            end
            close(fWaiting)
            alert2mismatchMex = msgbox(message); 
        end
        
    end

    function set_pcf_alert4calcOST_if_true(yes_true)
        bAlert4calcFx = yes_true;
        if bAlert4calcFx
            set(hbutton.recalculateSingleWarp,'BackgroundColor',badBGcolor);
            set(hbutton.recalculateAllWarp,'BackgroundColor',badBGcolor);
        else
            set(hbutton.recalculateSingleWarp,'BackgroundColor',normal_bgcolor);
            set(hbutton.recalculateAllWarp,'BackgroundColor',normal_bgcolor);
        end
    end



%% Parameter sliders and corresponding edit boxes

% % % durHold and rate2
% text labels
horiz_orig = padL; 
vert_orig = vert_orig + buttonHeight + padYSmall; 
durHoldTextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.durHold = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String','durHold',...
    'Units','Normalized','Position',durHoldTextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

horiz_orig = horiz_orig + padL*2 + editWidth; 
rate2TextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.rate2 = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String','rate2',...
    'Units','Normalized','Position',rate2TextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

% Sliders 
horiz_orig = padL; 
vert_orig = vert_orig + editHeight + padYSmall; 
durHoldSliderPos = [horiz_orig vert_orig sliderWidth sliderHeight]; 
hslider.durHold = uicontrol(p.guidata.pcf_buttonPanel,'Style','slider',...
    'Min',0,... 
    'Max',2,...
    'SliderStep', [0.01 0.1],...
    'Value',durHold, ... 
    'Units','Normalized','Position',durHoldSliderPos,...
    'Callback',@set_durHold_edit);
    function set_durHold_edit(hObject,eventdata)
        oldDurHold = durHold; 
       durHold = hslider.durHold.Value; 
       set(hedit.durHold,'String',num2str(durHold)); 
       set_pcf_alert4calcOST_if_true(oldDurHold ~= durHold); 
    end

horiz_orig = horiz_orig + padL*2 + sliderWidth; 
rate2SliderPos = [horiz_orig vert_orig sliderWidth sliderHeight]; 
hslider.rate2 = uicontrol(p.guidata.pcf_buttonPanel,'Style','slider',...
    'Min',0,... 
    'Max',5,...
    'SliderStep', [0.01 0.1],...
    'Value',rate2, ... 
    'Units','Normalized','Position',rate2SliderPos,...
    'Callback',@set_rate2_edit);
    function set_rate2_edit(hObject,eventdata)
        oldRate2 = rate2; 
       rate2 = hslider.rate2.Value; 
       set(hedit.rate2,'String',num2str(rate2)); 
       set_pcf_alert4calcOST_if_true(oldRate2 ~= rate2); 
    end

% Edit boxes
horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padYSmall;
durHoldEditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.durHold = uicontrol(p.guidata.pcf_buttonPanel,'Style','edit',...
    'String',num2str(durHold), ...
    'Units','Normalized','Position',durHoldEditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_durHold_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_durHold_slider(hObject,eventdata)
        oldDurHold = durHold; 
       durHold = str2double(hObject.String); 
       set(hslider.durHold,'Value',durHold);  
       set_pcf_alert4calcOST_if_true(oldDurHold ~= durHold); 
    end

horiz_orig = horiz_orig + sliderWidth + padL*2; 
rate2EditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.rate2 = uicontrol(p.guidata.pcf_buttonPanel,'Style','edit',...
    'String',num2str(rate2), ...
    'Units','Normalized','Position',rate2EditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_rate2_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_rate2_slider(hObject,eventdata)
        oldRate2 = rate2; 
       rate2 = str2double(hObject.String); 
       set(hslider.rate2,'Value',rate2);     
       set_pcf_alert4calcOST_if_true(oldRate2 ~= rate2); 
    end


% % % rate1 and dur1 
% text descriptors
horiz_orig = padL; 
vert_orig = vert_orig + padYSmall + editHeight; 
rate1TextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.rate1 = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String','rate1',...
    'Units','Normalized','Position',rate1TextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

horiz_orig = horiz_orig + sliderWidth + padL*2; 
dur1TextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.dur1 = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String','dur1',...
    'Units','Normalized','Position',dur1TextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

% Sliders 
horiz_orig = padL; 
vert_orig = vert_orig + editHeight + padYSmall; 
rate1SliderPos = [horiz_orig vert_orig sliderWidth sliderHeight]; 
hslider.rate1 = uicontrol(p.guidata.pcf_buttonPanel,'Style','slider',...
    'Min',0.01,... 
    'Max',0.99,...
    'SliderStep', [0.01 0.1],...
    'Value',rate1, ... 
    'Units','Normalized','Position',rate1SliderPos,...
    'Callback',@set_rate1_edit);
    function set_rate1_edit(hObject,eventdata)
        oldRate1 = rate1; 
       rate1 = hslider.rate1.Value; 
       set(hedit.rate1,'String',num2str(rate1)); 
       set_pcf_alert4calcOST_if_true(oldRate1 ~= rate1); 
    end

horiz_orig = horiz_orig + editWidth + padL*2; 
dur1SliderPos = [horiz_orig vert_orig sliderWidth sliderHeight]; 
hslider.dur1 = uicontrol(p.guidata.pcf_buttonPanel,'Style','slider',...
    'Min',0,... 
    'Max',2,...
    'SliderStep', [0.01 0.1],...
    'Value',dur1, ... 
    'Units','Normalized','Position',dur1SliderPos,...
    'Callback',@set_dur1_edit);
    function set_dur1_edit(hObject,eventdata)
        oldDur1 = dur1; 
       dur1 = hslider.dur1.Value; 
       set(hedit.dur1,'String',num2str(dur1)); 
       set_pcf_alert4calcOST_if_true(oldDur1 ~= dur1); 
    end

% Edit boxes
horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padYSmall;
rate1EditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.rate1 = uicontrol(p.guidata.pcf_buttonPanel,'Style','edit',...
    'String',num2str(rate1), ...
    'Units','Normalized','Position',rate1EditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_rate1_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_rate1_slider(hObject,eventdata)
        oldRate1 = rate1; 
       rate1 = str2double(hObject.String); 
       set(hslider.rate1,'Value',rate1);   
       set_pcf_alert4calcOST_if_true(oldRate1 ~= rate1); 
    end

horiz_orig = horiz_orig + editWidth + padL*2;
dur1EditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.dur1 = uicontrol(p.guidata.pcf_buttonPanel,'Style','edit',...
    'String',num2str(dur1), ...
    'Units','Normalized','Position',dur1EditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_dur1_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_dur1_slider(hObject,eventdata)
        oldDur1 = dur1; 
       dur1 = str2double(hObject.String); 
       set(hslider.dur1,'Value',dur1);  
       set_pcf_alert4calcOST_if_true(oldDur1 ~= dur1); 
    end

% % % ostStat_initial and tBegin
% text descriptors
horiz_orig = padL; 
vert_orig = vert_orig + editHeight + padYSmall; 
ostStatInitialTextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.ostStat_initial = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String','ostStat_initial',...
    'Units','Normalized','Position',ostStatInitialTextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

horiz_orig = horiz_orig + sliderWidth + padL*2; 
tBeginTextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.tBegin = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String','tBegin',...
    'Units','Normalized','Position',tBeginTextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);

% sliders
horiz_orig = padL; 
vert_orig = vert_orig + editHeight + padYSmall; 
ostStatInitialSliderPos = [horiz_orig vert_orig sliderWidth sliderHeight]; 
hslider.ostStat_initial = uicontrol(p.guidata.pcf_buttonPanel,'Style','slider',...
    'Min',min(str2double(ostList)),... % probably 0-1 is fine (only exception is if we use stretch/span)
    'Max',max(str2double(ostList)),...
    'SliderStep', [0.1 0.2],...
    'Value',ostStat_initial, ... % placeholder
    'Units','Normalized','Position',ostStatInitialSliderPos,...
    'Callback',@set_ostStatInitial_edit);
    function set_ostStatInitial_edit(hObject,eventdata)
        oldStat = ostStat_initial; 
        if hObject.Value ~= floor(hObject.Value)
            ostStat_initial = floor(hObject.Value); 
        else
            ostStat_initial = hObject.Value; 
        end
        set(hslider.ostStat_initial,'Value',ostStat_initial); 
        set(hedit.ostStat_initial,'String',num2str(ostStat_initial)); 
        set_pcf_alert4calcOST_if_true(oldStat ~= ostStat_initial);
    end

horiz_orig = horiz_orig + sliderWidth + padL*2;  
tBeginSliderPos = [horiz_orig vert_orig sliderWidth sliderHeight]; 
hslider.tBegin = uicontrol(p.guidata.pcf_buttonPanel,'Style','slider',...
    'Min',0,... 
    'Max',5,...
    'SliderStep', [0.01 0.1],...
    'Value',tBegin, ... 
    'Units','Normalized','Position',tBeginSliderPos,...
    'Callback',@set_tBegin_edit);
    function set_tBegin_edit(hObject,eventdata)
        oldtBegin = tBegin; 
       tBegin = hslider.tBegin.Value; 
       set(hedit.tBegin,'String',num2str(tBegin)); 
       set_pcf_alert4calcOST_if_true(oldtBegin ~= tBegin);
    end

% edit boxes
horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padYSmall;
ostStatInitialEditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.ostStat_initial = uicontrol(p.guidata.pcf_buttonPanel,'Style','edit',...
    'String',num2str(ostStat_initial), ...
    'Units','Normalized','Position',ostStatInitialEditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_ostStatInitial_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_ostStatInitial_slider(hObject,eventdata)
        oldStat = ostStat_initial; 
        newOstStat_initial = str2double(hObject.String); 
        if newOstStat_initial ~= floor(newOstStat_initial)
            newOstStat_initial = floor(newOstStat_initial); 
        end
        if newOstStat_initial > str2double(ostList{end})
            fprintf('OST status %d does not exist\n', newOstStat_initial)
            newOstStat_initial = max(ostList); 
        elseif newOstStat_initial <= 0
            fprintf('OST status must be a positive integer\n')
            newOstStat_initial = 1; 
        end
        ostStat_initial = newOstStat_initial; 
        set(hslider.ostStat_initial,'Value',ostStat_initial); 
        set(hObject,'String',num2str(ostStat_initial)); 
        set_pcf_alert4calcOST_if_true(oldStat ~= ostStat_initial);
    end

horiz_orig = horiz_orig + editWidth + padL*2;
tBeginEditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.tBegin = uicontrol(p.guidata.pcf_buttonPanel,'Style','edit',...
    'String',num2str(tBegin), ...
    'Units','Normalized','Position',tBeginEditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_tBegin_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_tBegin_slider(hObject,eventdata)
       tBegin = str2double(hObject.String); 
       set(hslider.tBegin,'Value',tBegin);         
    end

%% PCF settings for which trial
horiz_orig = padL; 
vert_orig = vert_orig + buttonHeight + padYBig;
pcfFromTrialSliderPos = [horiz_orig vert_orig buttonWidth*0.75 sliderHeight]; 
hslider.pcfFromTrial = uicontrol(p.guidata.pcf_buttonPanel,'Style','slider',...
    'Min',1,... 
    'Max',max(availableTrials),...
    'SliderStep', trialSliderStep,...
    'Value',min(trials), ...
    'Units','Normalized','Position',pcfFromTrialSliderPos,...
    'Callback',@set_pcfFromTrial_edit);
    function set_pcfFromTrial_edit(hObject, eventdata)
        newTrial = hObject.Value; 
        % don't allow non-integers 
        if floor(newTrial) ~= newTrial
            newTrial = floor(newTrial); 
            set(hslider.trials2display,'Value',newTrial); 
        end
        pcfTrial = newTrial;
        set(hedit.pcfFromTrial,'String',num2str(pcfTrial)); 
%         load_new_pcfFromTrial
    end

horiz_orig = horiz_orig*2 + buttonWidth*0.75; 
switchPcfFromTrialButtonPos = [horiz_orig vert_orig buttonWidth*0.2 sliderHeight]; 
hbutton.pcfFromTrial = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String','GO',...
    'Units','Normalized','Position',switchPcfFromTrialButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize/1.5,...
    'Callback',@load_new_pcfFromTrial);
    function load_new_pcfFromTrial(hObject,eventdata)
        if ~ismember(pcfTrial,trials)
            newMinTrial = pcfTrial; 
            newMaxTrial = pcfTrial + 8; 
            if newMaxTrial > max(availableTrials)
                newMaxTrial = max(availableTrials); 
            end
            set(hedit.firstTrial,'String',num2str(newMinTrial)); 
            set(hedit.lastTrial,'String',num2str(newMaxTrial)); 
            set(hslider.trials2display,'Value',newMinTrial); 
            trials = newMinTrial:newMaxTrial; 
            plot_new_trials
            set(htoggle.formantsOut, 'Value', sum(strcmp({h_formantsOut_1(1:end).Visible},'on')) > 0); 
        end
        if ~isfield(y, 'pcfLine')
            pcfLine = '2, 0.999, 0.5, 0.000, 0.000, 2'; %no timewarping; fills pcfLine
        elseif ~isempty(calcPcfLine{pcfTrial})
            pcfLine = calcPcfLine{pcfTrial};
        else
            pcfLine = y(pcfTrial).pcfLine;
        end
        
        % Again this should be made more flexible RK 2/9/2021
        if ischar(pcfLine)
            pcfComponents = strsplit(pcfLine,',');
            ostStat_initial = str2double(pcfComponents{1}); 
            tBegin = str2double(pcfComponents{2}); 
            rate1 = str2double(pcfComponents{3}); 
            dur1 = str2double(pcfComponents{4}); 
            durHold = str2double(pcfComponents{5}); 
            rate2 = str2double(pcfComponents{6}); 
        else
            ostStat_initial = pcfLine(1); 
            tBegin = pcfLine(2); 
            rate1 = pcfLine(3); 
            dur1 = pcfLine(4); 
            durHold = pcfLine(5); 
            rate2 = pcfLine(6); 
        end
        
        % Set edit fields
        set(hedit.ostStat_initial,'String',num2str(ostStat_initial)); 
        set(hedit.tBegin,'String',num2str(tBegin)); 
        set(hedit.rate1,'String',num2str(rate1)); 
        set(hedit.dur1,'String',num2str(dur1)); 
        set(hedit.durHold,'String',num2str(durHold)); 
        set(hedit.rate2,'String',num2str(rate2)); 
        
        % Set sliders
        set(hslider.ostStat_initial,'Value',ostStat_initial); 
        set(hslider.tBegin,'Value',tBegin); 
        set(hslider.rate1,'Value',rate1); 
        set(hslider.dur1,'Value',dur1); 
        set(hslider.durHold,'Value',durHold); 
        set(hslider.rate2,'Value',rate2);        

    end

horiz_orig = padL; 
vert_orig = vert_orig + sliderHeight + padYSmall; 
pcfFromTrialTextPos = [horiz_orig vert_orig editWidth editHeight]; 
htext.pcfFromTrial = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String','PCF from trial:',...
    'Units','Normalized','Position',pcfFromTrialTextPos,...
    'FontUnits','Normalized','FontSize',editFontSize*0.75);


horiz_orig = horiz_orig + editWidth + padL*2; 
pcfFromTrialEditPos = [horiz_orig vert_orig editWidth editHeight]; 
hedit.pcfFromTrial = uicontrol(p.guidata.pcf_buttonPanel,'Style','edit',...
    'String',num2str(pcfTrial), ...
    'Units','Normalized','Position',pcfFromTrialEditPos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@set_pcfFromTrial_slider,...
    'TooltipString','Default of 0 includes Praat preemph');
    function set_pcfFromTrial_slider(hObject,eventdata)
        newTrial = hObject.String; 
        pcfTrial = str2double(newTrial);
        if floor(pcfTrial) ~= pcfTrial
            fprintf('Can only accept positive integers\n')
            pcfTrial = ceil(pcfTrial);
        end
        % Make sure the trials are within the bounds of the available trials
        if pcfTrial > max(availableTrials) 
            fprintf('No trial number %d. Setting at last trial.\n', pcfTrial)
            pcfTrial = max(availableTrials);             
        elseif pcfTrial < min(availableTrials)
            fprintf('No trial number %d. Setting at first trial.\n', pcfTrial)
            pcfTrial = min(availableTrials);             
        end

        newTrial = num2str(pcfTrial); 

        set(hedit.pcfFromTrial,'String',newTrial); 
        set(hslider.pcfFromTrial,'Value',pcfTrial); 
        
    end

%% Formant toggle button 2021/01/28

horiz_orig = padL; 
vert_orig = vert_orig + buttonHeight + padYButton; 
formantsInTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.formantsIn = uicontrol(p.guidata.pcf_buttonPanel,'Style','togglebutton',...
    'String','formants IN',...
    'Value',sum(strcmp({h_formantsIn_1(1:end).Visible},'on')) > 0,...
    'BackgroundColor',p.plot_params.line_colors.formantsIn,...
    'Units','Normalized','Position',formantsInTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_formantsIn);
    function toggle_formantsIn(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_formantsIn_1)
                axes(output_trial_axes(traxix));
                set(h_formantsIn_1(traxix),'visible','on')
                set(h_formantsIn_2(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_formantsIn_1)
                axes(output_trial_axes(traxix));
                set(h_formantsIn_1(traxix),'visible','off')
                set(h_formantsIn_2(traxix),'visible','off')
            end
        end
    end

horiz_orig = horiz_orig + halfButtonWidth; 
formantsOutTogglePos = [horiz_orig vert_orig halfButtonWidth halfButtonHeight]; 
htoggle.formantsOut = uicontrol(p.guidata.pcf_buttonPanel,'Style','togglebutton',...
    'String','formants OUT',...
    'Value',sum(strcmp({h_formantsOut_1(1:end).Visible},'on')) > 0,...
    'BackgroundColor',p.plot_params.line_colors.formantsOut,...
    'Units','Normalized','Position',formantsOutTogglePos,...
    'FontUnits','Normalized','FontSize',editFontSize,...
    'Callback',@toggle_formantsOut);
    function toggle_formantsOut(hObject,eventdata)
        if hObject.Value 
            for traxix = 1:length(h_formantsOut_1)
                axes(output_trial_axes(traxix));
                set(h_formantsOut_1(traxix),'visible','on')
                set(h_formantsOut_2(traxix),'visible','on')
            end
        else 
            for traxix = 1:length(h_formantsOut_1)
                axes(output_trial_axes(traxix));
                set(h_formantsOut_1(traxix),'visible','off')
                set(h_formantsOut_2(traxix),'visible','off')
            end
        end
    end

%% Play all button
horiz_orig = padL; 
vert_orig = vert_orig + buttonHeight + padYButton; 

% playAllTextPos = [horiz_orig vert_orig buttonWidth*0.5 buttonHeight]; 
% htext.playAll = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
%     'String','Play all: ',...
%     'Units','Normalized','Position',playAllTextPos,...
%     'FontUnits','Normalized','FontSize',buttonFontSize); 

playAllInButtonPos = [horiz_orig vert_orig buttonWidth*0.42 buttonHeight]; 
hbutton.playAllIn = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String',[char(9654) ' all signalIn'],...
    'Units','Normalized','Position',playAllInButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize/1.5,...
    'Callback',@play_all_signalIn);
    function play_all_signalIn(hObject,eventdata)
        set(hbutton.playAllIn,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        for i = 1:length(trials)
            trial = trials(i); 
            set(htext.playingTrialNumber,'String',num2str(trial));             
            play_audio(y(trial).signalIn,fs); 
            pause(0.5)            
        end       
        set(hbutton.playAllIn,'BackgroundColor',normal_bgcolor);
        set(htext.playingTrialNumber,'String','---');  
        
    end

% vert_orig = vert_orig + buttonHeight + padYSmall; 
horiz_orig = horiz_orig + buttonWidth*0.42; 
playAllOutButtonPos = [horiz_orig vert_orig buttonWidth*0.42 buttonHeight]; 
hbutton.playAllOut = uicontrol(p.guidata.pcf_buttonPanel,'Style','pushbutton',...
    'String',[char(9654) ' all signalOut'],...
    'Units','Normalized','Position',playAllOutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize/1.5,...
    'Callback',@play_all_signalOut);
    function play_all_signalOut(hObject,eventdata)
        set(hbutton.playAllOut,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        for i = 1:length(trials)
            trial = trials(i); 
            set(htext.playingTrialNumber,'String',num2str(trial)); 
            if isempty(signalOut_calc{trial})
                play_audio(y(trial).signalOut,fs); 
            else
                play_audio(signalOut_calc{trial},fs); 
            end
            pause(0.5)      
            
        end       
        set(hbutton.playAllOut,'BackgroundColor',normal_bgcolor);
        set(htext.playingTrialNumber,'String','---');  
        
    end

horiz_orig = horiz_orig + buttonWidth*0.45; 
playingTrialNumberTextPos = [horiz_orig vert_orig-padYBig buttonWidth*0.1 buttonHeight]; 
htext.playingTrialNumber = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
    'String',' --- ',...
    'Units','Normalized','Position',playingTrialNumberTextPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize/1.5); 

% 
% vert_orig = vert_orig + buttonHeight + padYButton; 
% playingTrialTextPos = [horiz_orig vert_orig buttonWidth*0.6 buttonHeight]; 
% htext.playingTrial = uicontrol(p.guidata.pcf_buttonPanel, 'Style','text',...
%     'String','Playing trial: ',...
%     'Units','Normalized','Position',playingTrialTextPos,...
%     'FontUnits','Normalized','FontSize',buttonFontSize); 

% horiz_orig = horiz_orig + buttonWidth*0.75;  






%% Trial playback buttons
horiz_orig = padL; 
vert_orig = 0.31; 

% Trial 7
pcfTrial7InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial7in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial7InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial7in);
    function play_trial7in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(7); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial7OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial7out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial7OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial7out);
    function play_trial7out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(7); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end


% Trial 8
horiz_orig = horiz_orig + 0.18; 
pcfTrial8InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial8in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial8InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial8in);
    function play_trial8in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(8); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial8OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial8out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial8OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial8out);
    function play_trial8out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(8); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

% Trial 9
horiz_orig = horiz_orig + 0.18; 
pcfTrial9InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial9in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial9InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial9in);
    function play_trial9in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(9); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial9OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial9out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial9OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial9out);
    function play_trial9out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(9); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

% % % NEXT ROW
horiz_orig = padL; 
vert_orig = vert_orig + 0.33; 
% Trial 4
pcfTrial1InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial4in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial1InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial4in);
    function play_trial4in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(4); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial1OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial4out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial1OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial4out);
    function play_trial4out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(4); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

% Trial 5
horiz_orig = horiz_orig + 0.18; 
pcfTrial1InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial5in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial1InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial5in);
    function play_trial5in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(5); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial1OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial5out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial1OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial5out);
    function play_trial5out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(5); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

% Trial 6
horiz_orig = horiz_orig + 0.18; 
pcfTrial1InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial6in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial1InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial6in);
    function play_trial6in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(6); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial1OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial6out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial1OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial6out);
    function play_trial6out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(6); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end


% % % NEXT ROW 
horiz_orig = padL; 
vert_orig = vert_orig + 0.33; 
% Trial 1
pcfTrial1InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial1in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial1InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial1in);
    function play_trial1in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(1); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial1OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial1out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial1OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial1out);
    function play_trial1out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(1); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

% Trial 2
horiz_orig = horiz_orig + 0.18; 
pcfTrial1InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial2in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial1InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial2in);
    function play_trial2in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(2); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial1OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial2in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial1OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial2out);
    function play_trial2out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(2); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

% Trial 3
horiz_orig = horiz_orig + 0.18; 
pcfTrial1InButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial3in = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalIn'],...
    'Units','Normalized','Position',pcfTrial1InButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial3in);
    function play_trial3in(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(3); 
        play_audio(y(trial).signalIn,fs); 
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end

horiz_orig = horiz_orig + 0.15; 
pcfTrial1OutButtonPos = [horiz_orig vert_orig playbackButtonWidth playbackButtonHeight]; 
hbutton.playTrial3out = uicontrol(p.guidata.pcf_faxesPanel,'Style','pushbutton',...
    'String',[char(9654) ' signalOut'],...
    'Units','Normalized','Position',pcfTrial1OutButtonPos,...
    'FontUnits','Normalized','FontSize',buttonFontSize,...
    'Callback',@play_trial3out);
    function play_trial3out(hObject,eventdata)
        set(hObject,'BackgroundColor',goodBGcolor);
        fs = p.sigproc_params.fs; 
        trial = trials(3); 
        if isempty(signalOut_calc{trial})
            play_audio(y(trial).signalOut,fs); 
        else
            play_audio(signalOut_calc{trial},fs); 
        end
        set(hObject,'BackgroundColor',normal_bgcolor);        
    end




%% key press events ******
% marker_captured = 0;
% 
%     function key_press_func(src,event)
%         the_ax = cur_ax_from_curpt(ntAx,tAx);
%         the_axinfo = get(the_ax,'UserData');
%         if ~isempty(the_ax) && ~isempty(the_axinfo.h_tmarker_low)
%             switch(event.Key)
%                 case 'v' % if ampl_ax, set amplitude threshold for voicing (i.e., valid formants)
%                     ampl_thresh4voicing = get_ampl_thresh4voicing(the_ax,ntAx,tAx);
%                     set_ampl_thresh4voicing(ampl_thresh4voicing);
%                 case 'a' % add a user event
%                     add_user_event(the_ax,ntAx,tAx);
%                 case 'd' % delete a user event
%                     delete_user_event(the_ax,ntAx,tAx);
%                 case 'rightarrow' % advance tmarker_spec by one frame
%                     incdec_tmarker_spec(1,the_ax);
%                 case 'leftarrow'  % retreat tmarker_spec by one frame
%                     incdec_tmarker_spec(0,the_ax);
%                 case 'e' % expand
%                     expand_btw_ax_tmarkers(the_ax,tAx,fAx);
%                 case 'w' % widen
%                     widen_ax_view(the_ax,tAx,fAx);
%                 case 'h' % heighten
%                     heighten_ax(the_ax);
%                 case 'u' % unheighten = reduce
%                     unheighten_ax(the_ax);
%                 case 'c' % shortcut for "continue" button
%                     contprogram([],[]);
%                 otherwise
%                     fprintf('len(%d)\n',length(event.Key));
%                     fprintf('%d,',event.Key);
%                     fprintf('\n');
%                     fprintf('%c',event.Key);
%                     fprintf('\n');
%             end
%         end
%         
%         
%         function incdec_tmarker_spec(yes_inc,the_ax)
%             the_axinfo = get(the_ax,'UserData');
%             [t_low,t_spec,t_hi] = get_ax_tmarker_times(the_ax);
%             t_spec = incdec_t_spec(yes_inc,t_low,t_spec,t_hi,the_ax);
%             switch the_axinfo.type
%                 case 'spec'
%                     update_ax_tmarkers(spec_ax,t_low,t_spec,t_hi);
%                 otherwise
%                     update_ax_tmarkers(wave_ax,t_low,t_spec,t_hi);
%                     update_ax_tmarkers(gram_ax,t_low,t_spec,t_hi);
%                     update_ax_tmarkers(pitch_ax,t_low,t_spec,t_hi);
%                     update_ax_tmarkers(ampl_ax,t_low,t_spec,t_hi);
%                     update_spec_ax(spec_ax,gram_ax);
%             end
%         end
%         
%         
%         
%     end

%% when figure is deleted ****** need to update this 
    function delete_func(src,event)
        viewer_end_state = 1; 
%         iaxfr = 0;
%         viewer_end_state.spec_axinfo  = get(spec_ax,'UserData');  %iaxfr = iaxfr + 1; [axfracts.x(iaxfr),axfracts.y(iaxfr)] = get_axfract(spec_ax);
%         viewer_end_state.ampl_axinfo  = get(ampl_ax,'UserData');  iaxfr = iaxfr + 1; [axfracts.x(iaxfr),axfracts.y(iaxfr)] = get_axfract(ampl_ax);
%         viewer_end_state.pitch_axinfo = get(pitch_ax,'UserData'); iaxfr = iaxfr + 1; [axfracts.x(iaxfr),axfracts.y(iaxfr)] = get_axfract(pitch_ax);
%         viewer_end_state.gram_axinfo  = get(gram_ax,'UserData');  iaxfr = iaxfr + 1; [axfracts.x(iaxfr),axfracts.y(iaxfr)] = get_axfract(gram_ax);
%         viewer_end_state.wave_axinfo  = get(wave_ax,'UserData');  iaxfr = iaxfr + 1; [axfracts.x(iaxfr),axfracts.y(iaxfr)] = get_axfract(wave_ax);
%         axfracts.n = iaxfr;
%         p.plot_params.axfracts = axfracts;
%         is_good_trial = p.event_params.is_good_trial;
%         p.event_params = viewer_end_state.wave_axinfo.p.event_params;
%         p.event_params.is_good_trial = is_good_trial;
%         
%         
%         viewer_end_state.sigproc_params = p.sigproc_params;
%         viewer_end_state.plot_params = p.plot_params;
%         viewer_end_state.event_params = p.event_params;
    end
end

%%
% end of function audapter_viewer

%% Heuristic related stuff
function [heurunits, heurmin, heurmax, heursliderstep] = get_heuristicParams(heuristic)
   switch heuristic
       case 'ELAPSED_TIME'
            heurunits{1} = 's'; 
            heurunits{2} = ''; 
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 10; 
            heurmax(2) = 0.01; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.01/heur2range 0.01/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
        case 'INTENSITY_RISE_HOLD'
            heurunits{1} = 'RMS'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 5; 
            heurmax(2) = 1; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.001/heur1range 0.01/heur1range]; 
            heursliderstep(2,:) = [0.001/heur1range 0.01/heur2range]; 
            
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
        case 'INTENSITY_RISE_HOLD_POS_SLOPE'
            heurunits{1} = 'RMS'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 5; 
            heurmax(2) = 2; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2); 
            heursliderstep(1,:) = [0.001/heur1range 0.01/heur1range]; % 1/(max(availableTrials) - min(availableTrials)) 9/(max(availableTrials) - min(availableTrials))
            heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
        case 'POS_INTENSITY_SLOPE_STRETCH'
            heurunits{1} = 'frames'; 
            heurunits{2} = '?';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 20; 
            heurmax(2) = 5; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2); 
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.01/heur2range 0.1/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
        case 'NEG_INTENSITY_SLOPE_STRETCH_SPAN'
            heurunits{1} = 'frames'; 
            heurunits{2} = 'sum RMS';
            heurunits{3} = '--'; 
            heurmin(1) = 1;
            heurmin(2) = -10; 
            heurmax(1) = 20; 
            heurmax(2) = 0; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range];
            heursliderstep(2,:) = [0.01/heur2range 0.1/heur2range];
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
       case 'INTENSITY_SLOPE_BELOW_THRESH' % CWN add-on
           heurunits{1} = 'RMS slope';
           heurunits{2} = 's';
            heurunits{3} = '--'; 
           heurmin(1) = -5;
           heurmin(2) = 0;
           heurmax(1) = 5;
           heurmax(2) = 2;
           heur1range = heurmax(1) - heurmin(1);
           heur2range = heurmax(2) - heurmin(2);
           heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range];
           heursliderstep(2,:) = [0.01/heur2range 0.1/heur2range];
           % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 

       case 'INTENSITY_SLOPE_ABOVE_THRESH' % CWN add-on
           heurunits{1} = 'RMS slope';
           heurunits{2} = 's';
           heurunits{3} = '--';
           heurmin(1) = -5;
           heurmin(2) = 0;
           heurmax(1) = 5;
           heurmax(2) = 2;
           heur1range = heurmax(1) - heurmin(1);
           heur2range = heurmax(2) - heurmin(2);
           heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range];
           heursliderstep(2,:) = [0.01/heur2range 0.1/heur2range];
           % Third heuristic add
           heurmin(3) = NaN;
           heurmax(3) = NaN;
           heur3range = NaN;
           heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range];

        case 'INTENSITY_FALL'
            heurunits{1} = 'RMS'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 5; 
            heurmax(2) = 1; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
       case 'INTENSITY_BELOW_THRESH_NEG_SLOPE'  % CWN add-on
            heurunits{1} = 'RMS'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 5; 
            heurmax(2) = 1; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
        case 'INTENSITY_RATIO_RISE'
            heurunits{1} = 'RMS ratio'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 5; 
            heurmax(2) = 2; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.01/heur2range 0.1/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
        case 'INTENSITY_RATIO_FALL_HOLD'
            heurunits{1} = 'RMS ratio'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 2; 
            heurmax(2) = 2; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range];  
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
       case 'INTENSITY_RATIO_ABOVE_THRESH_WITH_RMS_FLOOR' % CWN add-on
           heurunits{1} = 'RMS ratio';
           heurunits{2} = 's';
            heurunits{3} = '--'; 
           heurmin(1) = 0;
           heurmin(2) = 0;
           heurmax(1) = 5;
           heurmax(2) = 2;
           heur1range = heurmax(1) - heurmin(1);
           heur2range = heurmax(2) - heurmin(2);
           heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range];
           heursliderstep(2,:) = [0.01/heur2range 0.1/heur2range]; 
           % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
           
       case 'INTENSITY_AND_RATIO_ABOVE_THRESH'  % CWN add-on
           heurunits{1} = 'RMS';
           heurunits{2} = 'RMS ratio';
            heurunits{3} = 's'; 
           heurmin(1) = 0;
           heurmin(2) = 0;
           heurmax(1) = 5;
           heurmax(2) = 5;
           heur1range = heurmax(1) - heurmin(1);
           heur2range = heurmax(2) - heurmin(2);
           heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range];
           heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range];
           % Third heuristic add
            heurmin(3) = 0; 
            heurmax(3) = 5;
            heur3range = heurmax(3) - heurmin(3);
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range];
       case 'INTENSITY_AND_RATIO_BELOW_THRESH'  % CWN add-on
           heurunits{1} = 'RMS';
           heurunits{2} = 'RMS ratio';
           heurunits{3} = 's';
           heurmin(1) = 0;
           heurmin(2) = 0;
           heurmax(1) = 5;
           heurmax(2) = 5;
           heur1range = heurmax(1) - heurmin(1);
           heur2range = heurmax(2) - heurmin(2);
           heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range];
           heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range];
           % Third heuristic add
           heurmin(3) = 0;
           heurmax(3) = 5;
           heur3range = heurmax(3) - heurmin(3);
           heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range];
        case 'INTENSITY_RATIO_SLOPE_ABOVE_THRESH' % CWN add-on
            heurunits{1} = 'RMS Ratio Slope'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = -5;
            heurmin(2) = 0; 
            heurmax(1) = 5; 
            heurmax(2) = 1; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range];   
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
        case 'INTENSITY_RATIO_SLOPE_BELOW_THRESH' % CWN add-on
            heurunits{1} = 'RMS Ratio Slope'; 
            heurunits{2} = 's';
            heurunits{3} = '--'; 
            heurmin(1) = -5;
            heurmin(2) = 0; 
            heurmax(1) = 5; 
            heurmax(2) = 1; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.01/heur1range 0.1/heur1range]; 
            heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
       case 'OST_END'
            heurunits{1} = ''; 
            heurunits{2} = '';
            heurunits{3} = '--'; 
            heurmin(1) = 0;
            heurmin(2) = 0; 
            heurmax(1) = 2; 
            heurmax(2) = 0.01; 
            heur1range = heurmax(1) - heurmin(1); 
            heur2range = heurmax(2) - heurmin(2);
            heursliderstep(1,:) = [0.001/heur1range 0.01/heur1range]; 
            heursliderstep(2,:) = [0.001/heur2range 0.01/heur2range]; 
            % Third heuristic add
            heurmin(3) = NaN; 
            heurmax(3) = NaN; 
            heur3range = NaN; 
            heursliderstep(3,:) = [0.01/heur3range 0.1/heur3range]; 
   end
        
end

%% Get line properties for RMS information
function [valMultipliers, lineVisibility, lineType] = get_rmsLineProperties(heuristic, rms, dRms, rms_rat, dRms_rat)

% RMS primary, RMS slope secondary 
rms_only = {'INTENSITY_RISE_HOLD' 'INTENSITY_FALL'}; 
rms_rmsSlope = {'INTENSITY_RISE_HOLD_POS_SLOPE' 'INTENSITY_BELOW_THRESH_NEG_SLOPE'}; 
rmsSlope_only = {'POS_INTENSITY_SLOPE_STRETCH' 'NEG_INTENSITY_SLOPE_STRETCH_SPAN' 'INTENSITY_SLOPE_BELOW_THRESH' 'INTENSITY_SLOPE_ABOVE_THRESH'}; 
ratio_only = {'INTENSITY_RATIO_RISE' 'INTENSITY_RATIO_FALL_HOLD' 'INTENSITY_RATIO_ABOVE_THRESH_WITH_RMS_FLOOR'}; 
ratioSlope_only = {'INTENSITY_RATIO_SLOPE_ABOVE_THRESH' 'INTENSITY_RATIO_SLOPE_BELOW_THRESH'}; 
ratio_rms = {'INTENSITY_AND_RATIO_ABOVE_THRESH' 'INTENSITY_AND_RATIO_BELOW_THRESH'}; 
ratio_rmsSlope = {}; 
miscHeuristics = {'ELAPSED_TIME'}; 

switch heuristic
    case rms_only
        % Multipliers so that the primary line shows up with the right units and others are scaled 
        valMultipliers.rms = 1; 
        valMultipliers.rms_rat = max(rms); 
        valMultipliers.dRms = max(rms); 
        valMultipliers.dRms_rat = 1/range(dRms_rat); 
        
        % Line visibility
        lineVisibility.rms = 'on'; 
        lineVisibility.rms_rat = 'off'; 
        lineVisibility.dRms = 'off'; 
        lineVisibility.dRms_rat = 'off'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '-'; 
        lineType.rms_rat = '-.'; 
        lineType.dRms = '--'; 
        lineType.dRms_rat = '-.'; 
    case rms_rmsSlope
        % Multipliers so that the primary line shows up with the right units and others are scaled 
        valMultipliers.rms = 1; 
        valMultipliers.rms_rat = 1/max(rms_rat); 
        valMultipliers.dRms = max(rms); 
        valMultipliers.dRms_rat = 1/max(dRms_rat); 
        
        % Line visibility
        lineVisibility.rms = 'on'; 
        lineVisibility.rms_rat = 'off'; 
        lineVisibility.dRms = 'on'; 
        lineVisibility.dRms_rat = 'off'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '-'; 
        lineType.rms_rat = '-.'; 
        lineType.dRms = '--'; 
        lineType.dRms_rat = '-.'; 
    case rmsSlope_only
        % Multipliers so that the primary line shows up with the right units and others are scaled 
        valMultipliers.rms = max(dRms)/max(rms); 
        valMultipliers.rms_rat = 1/max(rms_rat);  
        valMultipliers.dRms = 1; 
        valMultipliers.dRms_rat = 1/max(dRms_rat); 
        
        % Line visibility
        lineVisibility.rms = 'off'; 
        lineVisibility.rms_rat = 'off'; 
        lineVisibility.dRms = 'on'; 
        lineVisibility.dRms_rat = 'off'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '--'; 
        lineType.rms_rat = '-.'; 
        lineType.dRms = '-'; 
        lineType.dRms_rat = '-.'; 
        
    case ratio_only
        % Multipliers so that the primary line shows up with the right units and others are scaled 
        valMultipliers.rms = 1/min(abs(rms_rat));
        valMultipliers.rms_rat = 1; 
        valMultipliers.dRms = max(rms_rat); 
        valMultipliers.dRms_rat = 1/min(abs(rms_rat)); 
        
        % Line visibility
        lineVisibility.rms = 'off'; 
        lineVisibility.rms_rat = 'on'; 
        lineVisibility.dRms = 'off'; 
        lineVisibility.dRms_rat = 'off'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '-.'; 
        lineType.rms_rat = '-'; 
        lineType.dRms = '--'; 
        lineType.dRms_rat = '-.'; 
        
    case ratioSlope_only
        % Multipliers so that the primary line shows up with the right units and others are scaled 
        valMultipliers.rms = range(dRms_rat); 
        valMultipliers.rms_rat = range(dRms_rat); 
        valMultipliers.dRms = max(dRms_rat); 
        valMultipliers.dRms_rat = 1; 
        
        % Line visibility
        lineVisibility.rms = 'off'; 
        lineVisibility.rms_rat = 'off'; 
        lineVisibility.dRms = 'off'; 
        lineVisibility.dRms_rat = 'on'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '-.'; 
        lineType.rms_rat = '--';  
        lineType.dRms = '-.'; 
        lineType.dRms_rat = '-'; 
        
    case ratio_rms
        % Multipliers so that the primary line shows up with the right units and others are scaled 
        valMultipliers.rms = 1; 
        valMultipliers.rms_rat = max(rms); 
        valMultipliers.dRms = max(rms); 
        valMultipliers.dRms_rat = max(abs(rms)); 
        
        % Line visibility
        lineVisibility.rms = 'on'; 
        lineVisibility.rms_rat = 'on'; 
        lineVisibility.dRms = 'off'; 
        lineVisibility.dRms_rat = 'off'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '-'; 
        lineType.rms_rat = '--'; 
        lineType.dRms = '-.'; 
        lineType.dRms_rat = '-.'; 
        
    case miscHeuristics
        % Multipliers so that the primary line shows up with the right units and others are scaled 
        valMultipliers.rms = 1; 
        valMultipliers.rms_rat = 1/max(rms); 
        valMultipliers.dRms = 1/max(rms); 
        valMultipliers.dRms_rat = 1/max(rms); 
        
        % Line visibility
        lineVisibility.rms = 'on'; 
        lineVisibility.rms_rat = 'off'; 
        lineVisibility.dRms = 'off'; 
        lineVisibility.dRms_rat = 'off'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '-'; 
        lineType.rms_rat = '-.'; 
        lineType.dRms = '--'; 
        lineType.dRms_rat = '-.'; 
        
    case ratio_rmsSlope
        % Multipliers so that the primary line shows up with the right units and others are scaled reasonably
        valMultipliers.rms = 1/min(rms_rat); 
        valMultipliers.rms_rat = 1; 
        valMultipliers.dRms = range(rms_rat); 
        valMultipliers.dRms_rat = 1/min(abs(rms_rat)); 
        
        % Line visibility
        lineVisibility.rms = 'off'; 
        lineVisibility.rms_rat = 'on'; 
        lineVisibility.dRms = 'on'; 
        lineVisibility.dRms_rat = 'off'; 
        
        % Line types (primary = solid, secondary = dashed, others = dotted)
        lineType.rms = '-.'; 
        lineType.rms_rat = '-'; 
        lineType.dRms = '--'; 
        lineType.dRms_rat = '-.'; 
        
    otherwise
        
        warning('You probably misspelled something'); 
        
        
end

 
                
end

%% Create axes, or update when plotting new set of trials 
function [trial_axes,h_rms,h_rms_rat,h_dRms,h_dRms_rat,h_ost,h_ostref,h_osteditref,audTAxis] = new_trial_axes(y,p,trials,ostStatus,heuristic,ost_calc)
% Creates axes for plotting 9 trials, starting top left, moving right and down
% THIS IS SPECIFIC TO AUDAPTER_VIEWER
% y is the data structure

% I think this has to be put in all the embedded plotting functions as well
% as the main...?
warning('off','MATLAB:audiovideo:audioplayer:noAudioOutputDevice') 

    fWaitingIn = waitbar(0.4, 'Plotting signalIn...'); 
    % Set padding between axes (large) 
    traxesPad = 0.06; 
    traxesFontSize = 0.01;    
    traxesXSpan = 0.27; 
    traxesYSpan = 0.27; 
    
    fs = p.sigproc_params.fs; 
    name = p.plot_params.name;
    
    % Get the data for the trials you are plotting
    data2plot = y(trials); 
    if isfield(y, 'trial')
        titleTrialNos = [y(trials).trial]; 
    elseif isfield(y, 'token')
        titleTrialNos = [y(trials).token]; 
    else
        titleTrialNos = trials; 
    end
%     if length(data2plot) > 9, warning('Only plotting first nine trials'); end

    % Start at 10 and increment backwards so the trial axes are in the right order
    traxix = 0;     
    traxesYPos = 1 - traxesYSpan - 0.03; % A little extra padding on the bottom
    for i = 1:3 % 9 axes in 3 x 3 grid
        % Move YPos up if you're not on the bottom row
        if i > 1
        traxesYPos = traxesYPos - traxesYSpan - traxesPad;   
        end        
        traxesXPos = 0.03; 
        for j = 1:3
            % Move XPos over if you're not on the leftmost
            if j > 1
                traxesXPos = traxesXPos + traxesXSpan + traxesPad; 
            end
            traxix = traxix + 1;
            
            
            % Data to plot (only plot if you have enough, otherwise just create a blank axis)
            traxesPosition = [traxesXPos traxesYPos traxesXSpan traxesYSpan];
            trial_axes(traxix) = axes(p.guidata.faxesPanel,'Position', traxesPosition);
            if traxix <= length(data2plot)
                ax = trial_axes(traxix);
                axes(ax); 
                hold(ax,'off')
                cla(ax,'reset'); 
                axdat{1} = data2plot(traxix).signalIn; % hard-coding signalIn, for this tool probably only need in 
                params{1}.taxis = (0:(length(axdat{1})-1))/fs;
                
                % Spectrogram
                [s, f, t] = spectrogram(axdat{1}, 256, 192, 1024, fs);
                imagesc(ax, t, f, 10 * log10(abs(s)));
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
                ax.YDir = 'normal';
                ax.YLim = [0 6000]; 
                ax.XLim = [t(1) t(end)]; 
%                 set(ax, 'YLim', [0, 6000]);
%                 set(ax, 'XLim', [t(1), t(end)]);
                colormap(ax,flipud(gray));
                
                hold(ax,'on');
                % Audapter plots                
                % RMS
                rms = data2plot(traxix).rms(:,1); 
                
                % RMS ratio
                rms_rat = data2plot(traxix).rms(:,2) ./ rms; 
                
                % RMS slope
                dRms = data2plot(traxix).rms_slope; 
                
                % RMS ratio slope (CWN/RPK addition 5/17/2021)
                try
                    dRms_rat = data2plot(traxix).rms_ratio_slope; 
                catch
                    % If you are using a dataset that doesn't have rms_ratio_slope in it, use the "diff" function on the rms 
                    dRms_rat = diff([rms_rat(1); rms_rat]); 
                end
                
                % OST status (plotted on spectrogram axis)
                if nargin < 6 || isempty(ost_calc{trials(traxix)})
                    ost_stat = data2plot(traxix).ost_stat;
                else
                    ost_stat = ost_calc{trials(traxix)}; 
                end
                
                % Plot'em 
                frameDur = data2plot(traxix).params.frameLen / fs;
                audTAxis{traxix} = 0 : frameDur : frameDur * (size(rms, 1) - 1);
                
                h_ost(traxix) = plot(audTAxis{traxix}, ost_stat * p.ostMultiplier, p.plot_params.line_colors.ost, 'Linewidth', 1.5); 
                
                triggerIndex = find(p.eventNumbers == p.sigproc_params.triggerStatus); 
                if isempty(triggerIndex)
                    triggerLabel = ['ostStatus ' num2str(p.sigproc_params.triggerStatus)]; 
                else
                    triggerLabel = p.eventNames{triggerIndex}; 
                end
                h_ostref(traxix) = yline(p.sigproc_params.triggerStatus * p.ostMultiplier, ['-' p.plot_params.line_colors.ost_ref], triggerLabel); 
                
                ostIndex = find(p.eventNumbers == ostStatus); 
                if isempty(ostIndex)
                    statusLabel = ['ostStatus ' num2str(ostStatus)]; 
                else
                    statusLabel = p.eventNames{ostIndex}; 
                end
                h_osteditref(traxix) = yline(ostStatus * p.ostMultiplier, ['--' p.plot_params.line_colors.editost_ref], statusLabel); 
                if ostStatus == p.sigproc_params.triggerStatus
                    set(h_osteditref(traxix),'visible','off'); 
                end
                
                yyaxis right % RMS/RMS ratio on right
                
                % Plot lines, get visual properties
                [valMultipliers, lineVisibility, lineType] = get_rmsLineProperties(heuristic, rms, dRms, rms_rat, dRms_rat); 
                h_rms(traxix) = plot(audTAxis{traxix}, rms * valMultipliers.rms, [lineType.rms p.plot_params.line_colors.rms]); 
                set(h_rms(traxix),'visible',lineVisibility.rms)
                h_rms_rat(traxix) = plot(audTAxis{traxix}, rms_rat * valMultipliers.rms_rat, [lineType.rms_rat p.plot_params.line_colors.rms_rat]); 
                set(h_rms_rat(traxix),'visible',lineVisibility.rms_rat) 
                h_dRms(traxix) = plot(audTAxis{traxix}, dRms * valMultipliers.dRms, [lineType.dRms p.plot_params.line_colors.dRms]); 
                set(h_dRms(traxix),'visible',lineVisibility.dRms)
                h_dRms_rat(traxix) = plot(audTAxis{traxix}, dRms_rat * valMultipliers.dRms_rat, 'linestyle', lineType.dRms_rat, 'color', p.plot_params.line_colors.dRms_rat, 'marker', 'none'); 
                set(h_dRms_rat(traxix), 'visible', lineVisibility.dRms_rat); 
                
                params{1}.fs = p.sigproc_params.fs;
                params{1}.player_started = 0;
                params{1}.start_player_t = 0;
                params{1}.stop_player_t = 0;
                params{1}.current_player_t = 0;
                params{1}.inc_player_t = 0.01;
                h_player(traxix) = audioplayer(0.5*axdat{1}/max(abs(axdat{1})),fs); % the scaling of y is a bit of a hack to make audioplayer play like soundsc
                params{1}.h_player = h_player(traxix);
                params{1}.isamps2play_total = get(h_player(traxix),'TotalSamples');
%                 set(h_player,'StartFcn',@player_start);
%                 set(h_player,'StopFcn',@player_stop);
%                 set(h_player,'TimerFcn',@player_runfunc);
%                 set(h_player,'TimerPeriod',params{1}.inc_player_t);

%                 params{1}.taxis; 
                
                if ~isempty(ax.Title.String)
                    ax.Title.String = ''; 
                end
                title(['Trial ' num2str(titleTrialNos(traxix))]); 
            end % while traxix is at or below the number of data2plot trials     
            set(params{1}.h_player,'UserData',trial_axes(traxix)); % set the audioplayer UserData to the wave ax handle?
%             axinfo = new_axinfo('wave',params{1}.taxis,[],axdat,trial_axes(traxix),[],name,params{1}.taxis(1),params{1}.taxis(end),params,p);
%             set(trial_axes(traxix),'UserData',axinfo);


        end        
    end
    waitbar(1,fWaitingIn,'Done')
    pause(0.5)
    close(fWaitingIn)
end




%%
function [output_trial_axes,h_outputOst,output_audTAxis,h_formantsIn_1, h_formantsIn_2, h_formantsOut_1, h_formantsOut_2] = new_output_trial_axes(y,x,p,trackingFileDir,trackingFileName,trials,signalOut_calc)
% Creates axes for plotting 9 trials, starting top left, moving right and down
% THIS IS SPECIFIC TO AUDAPTER_VIEWER
% y is the data structure

warning('off','MATLAB:audiovideo:audioplayer:noAudioOutputDevice') 

    fWaiting = waitbar(0.4, 'Plotting signalOut...'); 
    ostList = get_ost(trackingFileDir, trackingFileName, 'list'); 
    maxOstYlim = str2double(ostList{end}) + 1; 
    % Set padding between axes (large) 
    traxesPad = 0.06; 
    traxesFontSize = 0.01;    
    traxesXSpan = 0.27; 
    traxesYSpan = 0.27; 
    
    fs = p.sigproc_params.fs; 
    name = p.plot_params.name;
    
    % Get the data for the trials you are plotting
    data2plot = y(trials); 
    if isfield(y, 'trial')
        titleTrialNos = [y(trials).trial]; 
    elseif isfield(y, 'token')
        titleTrialNos = [y(trials).token]; 
    else
        titleTrialNos = trials; 
    end
%     if length(data2plot) > 9, warning('Only plotting first nine trials'); end
    signal2calc = signalOut_calc(trials); 
    if ~iscell(signal2calc)
        signal2calc = {signal2calc}; 
    end
    for i = 1:length(trials) % Fill in with normal signalOut if the calcSignalOut is empty 
        trial = trials(i); 
        if isempty(signal2calc{i})
            signal2calc{i} = y(trial).signalOut; 
        end
    end
    
    % 6/2/2021 addition for new heuristic mismatches 
    try
        outputOst = calc_newAudapterData(signal2calc,p.audapter_params,trackingFileDir,trackingFileName,'ost_stat');
    catch exception
        errorText = getReport(exception, 'basic', 'hyperlinks','off'); 
        outputOst = {y(trials).ost_stat}; 
        if contains(errorText, 'Unrecognized OST heuristic mode')
            message = sprintf([errorText '.\n\nUsing input OST instead.']); 
        else
            message = sprintf(['Error in calculating output OST, using input OST instead. Location: new_output_trial_axes (you should probably tell Robin). \n\n ----- \n\n' errorText]); 
        end
        alert2mismatchMex = msgbox(message); 
    end
            
        
    if ~iscell(outputOst)
        outputOst = {outputOst}; 
    end

    % Start at 10 and increment backwards so the trial axes are in the right order
    traxix = 0;     
    traxesYPos = 1 - traxesYSpan - 0.03; % A little extra padding on the bottom
    for i = 1:3 % 9 axes in 3 x 3 grid
        % Move YPos up if you're not on the bottom row
        if i > 1
        traxesYPos = traxesYPos - traxesYSpan - traxesPad;   
        end        
        traxesXPos = 0.03; 
        for j = 1:3
            % Move XPos over if you're not on the leftmost
            if j > 1
                traxesXPos = traxesXPos + traxesXSpan + traxesPad; 
            end
            traxix = traxix + 1;
            
            
            % Data to plot (only plot if you have enough, otherwise just create a blank axis)
            traxesPosition = [traxesXPos traxesYPos traxesXSpan traxesYSpan];
            output_trial_axes(traxix) = axes(p.guidata.pcf_faxesPanel,'Position', traxesPosition);
            if traxix <= length(data2plot)
                ax = output_trial_axes(traxix); 
                axes(ax); 
                hold(ax,'off')
                cla(ax,'reset'); 
                % Which signalOut to use
                if nargin < 6 || isempty(signalOut_calc{trials(traxix)})
                    axdat{1} = data2plot(traxix).signalOut;
                else
                    axdat{1} = signalOut_calc{trials(traxix)}; 
                end
                params{1}.taxis = (0:(length(axdat{1})-1))/fs;
                
                % Spectrogram
                [s, f, t] = spectrogram(axdat{1}, 256, 192, 1024, fs);
                imagesc(ax, t, f, 10 * log10(abs(s)));
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
                ax.YDir = 'normal';
                
                ax.YLim = [0 6000]; 
                ax.XLim = [t(1) t(end)]; 
%                 set(ax, 'YLim', [0, 6000]);
%                 set(ax, 'XLim', [t(1), t(end)]);
                colormap(ax,flipud(gray));
                
                hold(ax,'on');
                % Audapter plots                
                                
                % OST status (plotted on spectrogram axis)
                ost_stat = outputOst{traxix}; 
                
                % Plot'em 
                frameDur = data2plot(traxix).params.frameLen / fs;
                rms = data2plot(traxix).rms(:,1); %  just to get audTAxis in output
                output_audTAxis{traxix} = 0 : frameDur : frameDur * (size(rms, 1) - 1);
                
                formantsIn_1 = data2plot(traxix).fmts(:, 1); 
                formantsIn_2 = data2plot(traxix).fmts(:, 2); 
                
                formantsOut_1 = data2plot(traxix).sfmts(:, 1); 
                formantsOut_2 = data2plot(traxix).sfmts(:, 2); 
                if sum(formantsOut_1) == 0, bOutputFormants = 0; else, bOutputFormants = 1; end
                
                % Make NaNs so the plots look cleaner
                formantsIn_1(formantsIn_1 == 0) = NaN; 
                formantsIn_2(formantsIn_2 == 0) = NaN; 
                formantsOut_1(formantsOut_1 == 0) = NaN; 
                formantsOut_2(formantsOut_2 == 0) = NaN; 
                
                % Plot formants (note that these have to be on the spectrogram's scale) 
                h_formantsIn_1(traxix) = scatter(output_audTAxis{traxix}, formantsIn_1, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsIn, ...
                    'MarkerEdgeColor', p.plot_params.line_colors.formantsIn); 
                h_formantsIn_2(traxix) = scatter(output_audTAxis{traxix}, formantsIn_2, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsIn, ...
                    'MarkerEdgeColor', p.plot_params.line_colors.formantsIn); 
                
                % Output (make invisible if you didn't do any formant manipulations) 
                h_formantsOut_1(traxix) = scatter(output_audTAxis{traxix}, formantsOut_1, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsOut, ...
                    'MarkerEdgeColor', p.plot_params.line_colors.formantsOut); 
                h_formantsOut_2(traxix) = scatter(output_audTAxis{traxix}, formantsOut_2, p.plot_params.scatter_size, 'MarkerFaceColor', p.plot_params.line_colors.formantsOut, ...
                    'MarkerEdgeColor', p.plot_params.line_colors.formantsOut); 
                if ~bOutputFormants
                    set(h_formantsOut_1(traxix), 'visible', 'off'); 
                    set(h_formantsOut_2(traxix), 'visible', 'off'); 
                end
                
                
                yyaxis right % On these the multiplier doesn't need to be in maybe?                 
                h_outputOst(traxix) = plot(output_audTAxis{traxix}, ost_stat, p.plot_params.line_colors.ost, 'Linewidth', 1.5); 
                set(gca, 'ylim', [0 maxOstYlim]); 
                set(gca, 'ytick', 0:2:maxOstYlim); % integer ylim
                
                
                params{1}.fs = p.sigproc_params.fs;
                params{1}.player_started = 0;
                params{1}.start_player_t = 0;
                params{1}.stop_player_t = 0;
                params{1}.current_player_t = 0;
                params{1}.inc_player_t = 0.01;
                h_player(traxix) = audioplayer(0.5*axdat{1}/max(abs(axdat{1})),fs); % the scaling of y is a bit of a hack to make audioplayer play like soundsc
                params{1}.h_player = h_player(traxix);
                params{1}.isamps2play_total = get(h_player(traxix),'TotalSamples');
%                 set(h_player,'StartFcn',@player_start);
%                 set(h_player,'StopFcn',@player_stop);
%                 set(h_player,'TimerFcn',@player_runfunc);
%                 set(h_player,'TimerPeriod',params{1}.inc_player_t);

%                 params{1}.taxis; 
                
                if ~isempty(ax.Title.String)
                    ax.Title.String = ''; 
                end
                title(['Trial ' num2str(titleTrialNos(traxix))]); 
            end % while traxix is at or below the number of data2plot trials     
            set(params{1}.h_player,'UserData',output_trial_axes(traxix)); % set the audioplayer UserData to the wave ax handle?
%             axinfo = new_axinfo('wave',params{1}.taxis,[],axdat,trial_axes(traxix),[],name,params{1}.taxis(1),params{1}.taxis(end),params,p);
%             set(trial_axes(traxix),'UserData',axinfo);

        end        
    end
    waitbar(1, fWaiting, 'Done');
    pause(0.5)
    close(fWaiting)
end




%% audioplayer callback functions ******



function play_from_wave_ax(wave_ax)
[start_player_t,duh,stop_player_t] = get_ax_tmarker_times(wave_ax);
wave_axinfo = get(wave_ax,'UserData');
fs = wave_axinfo.params{1}.fs;
isamps2play_total = wave_axinfo.params{1}.isamps2play_total;
h_player = wave_axinfo.params{1}.h_player;
current_player_t = start_player_t;
isamps2play_start = round(fs*start_player_t); if isamps2play_start < 1, isamps2play_start = 1; end
isamps2play_stop  = round(fs*stop_player_t);   if isamps2play_stop  > isamps2play_total, isamps2play_stop  = isamps2play_total; end
isamps2play = [isamps2play_start isamps2play_stop];
wave_axinfo.params{1}.current_player_t = current_player_t;
set(wave_ax,'UserData',wave_axinfo);
playblocking(h_player,isamps2play);
end

function player_start(hObject,eventdata)
wave_ax = get(hObject,'UserData');
wave_axinfo = get(wave_ax,'UserData');
h_tmarker_play = wave_axinfo.h_tmarker_play;
current_player_t = wave_axinfo.params{1}.current_player_t;
update_tmarker(h_tmarker_play,current_player_t);
set(h_tmarker_play,'Visible','on');
wave_axinfo.params{1}.player_started = 0;
set(wave_ax,'UserData',wave_axinfo);
% fprintf('player started\n');
end

function player_stop(hObject,eventdata)
wave_ax = get(hObject,'UserData');
wave_axinfo = get(wave_ax,'UserData');
h_tmarker_play = wave_axinfo.h_tmarker_play;
update_tmarker(h_tmarker_play,get_tmarker_time(wave_axinfo.h_tmarker_low));
set(h_tmarker_play,'Visible','off');
% fprintf('player stopped\n');
end

function player_runfunc(hObject,eventdata)
wave_ax = get(hObject,'UserData');
wave_axinfo = get(wave_ax,'UserData');
fs = wave_axinfo.params{1}.fs;
player_started = wave_axinfo.params{1}.player_started;
[start_player_t,duh,stop_player_t] = get_ax_tmarker_times(wave_ax);
isamp_playing = get(hObject,'CurrentSample');
current_player_t = isamp_playing/fs;
if current_player_t < start_player_t
    if ~player_started
        current_player_t = start_player_t;
    else
        current_player_t = stop_player_t;
    end
else
    player_started = 1;
end
wave_axinfo.params{1}.player_started = player_started;
update_tmarker(wave_axinfo.h_tmarker_play,current_player_t);
set(wave_ax,'UserData',wave_axinfo);
% fprintf('player running(%d)\n',isamp_playing);
end

%% get default param structs ******
function [plot_params] = get_plot_params()
plot_params.hzbounds4plot = []; % get from sigproc params
plot_params.name = 'signal';
plot_params.axfracts = [];
plot_params.yes_gray = 1;
plot_params.thresh_gray = 0;
plot_params.max_gray = 1;
fig_params = get_fig_params;
plot_params.line_colors = fig_params.line_colors; 
plot_params.scatter_size = fig_params.scatter_size; 
plot_params.figpos = fig_params.figpos_default;
end

function [event_params] = get_event_params()
event_params = struct('event_names', [], ...
    'event_times', [], ...
    'user_event_name_prefix','uev', ...
    'user_event_names', [], ...
    'user_event_times', [], ...
    'is_good_trial', 1);
end

function [sigproc_params] = get_sigproc_params()
sigproc_params = struct('fs', 11025, ...
    'ms_framespec_gram', 'broadband', ...
    'ms_framespec_form', 'narrowband', ...
    'nfft', 4096, ...
    'nlpc', 11, ...
    'nformants', 3, ...
    'preemph', 0.95, ...
    'pitchlimits', [50 300], ...
    'ampl_thresh4voicing', 0, ...
    'nlpc_choices', 7:20, ...
    'preemph_range', [-2 3]);
end

%% get figure params (used to be global vars) ******
function [fig_params] = get_fig_params()

fig_params.line_colors.ost = 'w'; 
fig_params.line_colors.ost_ref = 'r';
fig_params.line_colors.editost_ref = 'y';
fig_params.line_colors.rms = 'c'; 
fig_params.line_colors.rms_rat = 'g'; 
fig_params.line_colors.dRms = 'm'; 
fig_params.line_colors.dRms_rat = [0.95 0.6 0.3]; 
% {'b','r','g','k','c','m'}; % colors for more formants than you'll ever use

fig_params.line_colors.formantsIn = 'c'; 
fig_params.line_colors.formantsOut = 'm'; 

fig_params.scatter_size = 5; 

fig_params.yax_fact = 0.05;
fig_params.tmarker_init_border = 0.025;

fig_params.axborder_xl = 0.075;
fig_params.axborder_xr = 0.05;
fig_params.axborder_yl = 0.02;
fig_params.axborder_yu = 0.075;

fig_params.figborder_xl = 0;
fig_params.figborder_xr = 0;
fig_params.figborder_yl = 0.05;
fig_params.figborder_yu = 0.01;

fig_params.ax_heighten_inc = 0.1;
fig_params.wave_viewer_logshim = 1; % makes 20*log10(0 + wave_viewer_logshim) = 0
fig_params.default_tmarker_width = 2;
fig_params.max_dist_fract2del_event = 0.03; % must be within 3% of ax_tlims of event marker to delete it
fig_params.formant_marker_width = 4;

fig_params.title_pos = [0.01 0.8 0];
fig_params.figpos_default = [.01 .045 .98 .85]; % fullscreen-ish, in normalized units

end