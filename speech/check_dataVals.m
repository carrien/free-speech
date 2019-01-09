function errors = check_dataVals(dataPath,bCalc,dataVals)
%check formant data for errors and return trial numbers where errors are
%detected. Types of errors:
%             * jumpTrials in F1/F2 trajectory
%             * NaN values in F1 trajectory
%             * tracking obviously wrong F1
%             * durations under 100 ms
%             * durations over 1 s
%             * early trials (first sample is above threshold)
%             * late trials (last sample is above threshold)
% inputs (optional):dataPath: path where data to check is located 
%                       [snum/subdir]. Function reads from current directory 
%                       if not specified
%                   yesCalc:  option to calculate dataVals using
%                       gen_dataVals_from_wave_viewer function (1) or not (0).
%                       Defualt is 0 if not specified.
%                   dataVals: dataVals stored as a variable
%
% rewritten to include GUI JAN 2019

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(bCalc), bCalc = 1; end

%% create GUI
f = figure('Visible','on','Units','Normalized','Position',[.1 .1 .8 .8]);

UserData = guihandles(f);
UserData.dataPath = dataPath;
UserData.f = f;


%% create warning field in GUI
UserData.xPosMax = 0.975;

% create warning text area
warnPanelXPos = 0.575;
warnPanelXSpan = 0.125;
warnPanelYSpan = 0.11;
warnPanelYPos = UserData.xPosMax-warnPanelYSpan;
warnPanelPos = [warnPanelXPos warnPanelYPos warnPanelXSpan warnPanelYSpan];
UserData.warnPanel= uipanel(UserData.f,'Units','Normalized','Position',...
            warnPanelPos,'Title',' alerts ',...
            'Tag','warn_panel','TitlePosition','CenterTop',...
            'FontSize',0.02,'FontUnits','Normalized','Visible','on');

UserData.warnText = uicontrol(UserData.warnPanel,'style','text',...
            'String',[],...
            'Units','Normalized','Position',[.1 .1 .8 .8],...
            'FontUnits','Normalized','FontSize',.3);
        
%% load data if needed
if nargin < 3
    [dataVals,expt] = load_dataVals(UserData,dataPath,bCalc);
else
    load(fullfile(dataPath,'expt')); 
end
UserData.dataVals = dataVals;
UserData.expt = expt;
UserData.errors = get_dataVals_errors(UserData,dataVals);

%% create other buttons
% create panel for plots
plotPanelXPos = 0.175;
plotPanelXSpan = 1 - 0.025 - plotPanelXPos;
plotPanelYPos = UserData.xPosMax - 0.95;
plotPanelYSpan = 0.815;
plotPanelPos = [plotPanelXPos plotPanelYPos plotPanelXSpan plotPanelYSpan];
UserData.plotPanel = uipanel(UserData.f,'Units','Normalized','Position',...
            plotPanelPos,...
            'Tag','formant_plots','Visible','on');
 % create action buttons
actionPanelXPos = 0.725;
actionPanelXSpan = 0.25;
actionPanelYSpan = 0.11;
actionPanelYPos = UserData.xPosMax-actionPanelYSpan;
actionPanelPos = [actionPanelXPos actionPanelYPos actionPanelXSpan actionPanelYSpan]; 
UserData.actionPanel = uipanel(UserData.f,'Units','Normalized','Position',...
            actionPanelPos,'Title',' actions ',...
            'Tag','trial_sel','TitlePosition','CenterTop',...
            'FontSize',0.02,'FontUnits','Normalized','Visible','on');

trialTypes = {'launch_GUI', 'reload_dataVals'};
nActionTypes = length(trialTypes);

actionButtonYSep = 0.05;
actionButtonXSep = 0.05;
actionButtonYSpan = 1 - 2*actionButtonYSep;
actionButtonYPos = actionButtonYSep;
actionButtonXSpan = (1 - actionButtonYSep*(nActionTypes+1))/nActionTypes;
for iButton = 1: nActionTypes
    ABname = strcat('AB_', trialTypes(iButton));
    actionButtonXPos = actionButtonXSep*iButton + actionButtonXSpan*(iButton-1);
    actionButtonPos = [actionButtonXPos actionButtonYPos actionButtonXSpan actionButtonYSpan];
    UserData.(ABname{1}) = uicontrol(UserData.actionPanel,...
        'Style','pushbutton','String',trialTypes(iButton),...
        'Units','Normalized','Position',actionButtonPos,...
        'FontUnits','Normalized','FontSize',0.3);
end
set(UserData.AB_launch_GUI,'CallBack',@launch_GUI)
set(UserData.AB_reload_dataVals,'CallBack',@reload_dataVals)

%generate other buttons
UserData = generate_menus(UserData);

guidata(f,UserData);

end

function launch_GUI(src,evt)
    UserData = guidata(src);
    errorField = UserData.errorPanel.SelectedObject.String{1};
    trialset = UserData.errors.(errorField);
    audioGUI(UserData.dataPath,trialset,[],[],0)
end

function reload_dataVals(src,evt)
    UserData = guidata(src);
    delete(UserData.errorPanel)
    delete(UserData.groupPanel)
    delete(UserData.trialPanel)
    if isfield(UserData,'htracks')
        delete(UserData.hsub);
        UserData = rmfield(UserData,'htracks');
        UserData = rmfield(UserData,'hsub');
    end
    [UserData.dataVals,UserData.expt] = load_dataVals(UserData,UserData.dataPath,1);
    UserData.errors = get_dataVals_errors(UserData,UserData.dataVals);
    UserData = generate_menus(UserData);
    guidata(src,UserData);
end

function errors = get_dataVals_errors(UserData,dataVals)
    outstring = textwrap(UserData.warnText,{'Checking for errors'});
    set(UserData.warnText,'BackgroundColor','red','String',outstring)
    
    %set thresholds for errors
    shortThresh = .1; %(<200 ms)
    longThresh = 1; %(> 1 s)
    jumpThresh = 200; %in Hz, upper limit for sample-to-sample change to detect jumpTrials in F1 trajectory
    wrongFThresh = [200 1000]; %acceptable range of possible F1 values

    badTrials = [];
    shortTrials = [];
    longTrials = [];
    nanFTrials = [];
    jumpF1Trials = [];
    jumpF2Trials = [];
    wrongFTrials = [];
    earlyTrials = [];
    lateTrials = [];
    goodTrials = [];

    for i = 1:length(dataVals)
        if dataVals(i).bExcl
            badTrials = [badTrials dataVals(i).token];
        elseif dataVals(i).dur < shortThresh %check for too short trials
            shortTrials = [shortTrials dataVals(i).token];
        elseif dataVals(i).dur > longThresh %check for too long trials
            longTrials = [longTrials dataVals(i).token];
        elseif find(isnan(dataVals(i).f1(2:end))) %check if there are NaN values in formant tracks, excepting 1st sample
            nanFTrials = [nanFTrials dataVals(i).token];
        elseif max(abs(diff(dataVals(i).f1)))>jumpThresh || max(abs(diff(dataVals(i).f2)))>jumpThresh %check for trials with F1/F2 jumps
            if max(abs(diff(dataVals(i).f1)))>jumpThresh %check for trials with F1 jumps
                jumpF1Trials = [jumpF1Trials dataVals(i).token];
            elseif max(abs(diff(dataVals(i).f2)))>jumpThresh %check for trials with F2 jumps
                jumpF2Trials = [jumpF2Trials dataVals(i).token];
            end
        elseif any(dataVals(i).f1 < wrongFThresh(1)) || any(dataVals(i).f1 > wrongFThresh(2)) %check if wrong formant is being tracked for F1
            wrongFTrials = [wrongFTrials dataVals(i).token];
        elseif dataVals(i).ampl_taxis(1) < .0001
            earlyTrials = [earlyTrials dataVals(i).token];
        elseif dataVals(i).ampl_taxis(end) > 1.5
            lateTrials = [lateTrials dataVals(i).token];
        else
            goodTrials = [goodTrials dataVals(i).token];
        end
    end

    errors.badTrials = badTrials;
    errors.shortTrials = shortTrials;
    errors.longTrials = longTrials;
    errors.nanFTrials = nanFTrials;
    errors.jumpF1Trials = jumpF1Trials;
    errors.jumpF2Trials = jumpF2Trials;
    errors.wrongFTrials = wrongFTrials;
    errors.earlyTrials = earlyTrials;
    errors.lateTrials = lateTrials;
    errors.goodTrials = goodTrials;
    
    set(UserData.warnText,'String',[],'BackgroundColor',[0.9400    0.9400    0.9400])
end

function [dataVals,expt] = load_dataVals(UserData,dataPath,bCalc)
    if bCalc
        msg = 'Regenerating and loading dataVals';
    else
        msg = 'Loading dataVals';
    end
    outstring = textwrap(UserData.warnText,{msg});
    set(UserData.warnText,'BackgroundColor','red','String',outstring)
    %if yesCalc == 1, generate dataVals
    if bCalc
        gen_dataVals_from_wave_viewer(dataPath);
    end
    load(fullfile(dataPath,'dataVals'))
    load(fullfile(dataPath,'expt'))
    set(UserData.warnText,'String',[],'BackgroundColor',[0.9400    0.9400    0.9400])
end

function UserData = generate_menus(UserData)
    % create error type buttons
    errorPanelXPos = 0.025;
    errorPanelXSpan = 0.125;
    errorPanelYSpan = 0.95;
    errorPanelYPos = UserData.xPosMax - errorPanelYSpan;
    errorPanelPos = [errorPanelXPos errorPanelYPos errorPanelXSpan errorPanelYSpan]; 
    UserData.errorPanel = uibuttongroup(UserData.f,'Units','Normalized','Position',...
                errorPanelPos,'Title',' error types ',...
                'Tag','error_types','TitlePosition','CenterTop',...
                'FontSize',0.02,'FontUnits','Normalized','Visible','on',...
                'SelectedObject',[],'SelectionChangedFcn',@update_plots);

    errorTypes = fieldnames(UserData.errors);
    errorTypes(strcmp(errorTypes,'badTrials')) = []; %remove badTrials from list
    nErrorTypes = length(errorTypes);

    errorButtonYSep = 0.01;
    errorButtonXSep = 0.05;
    errorButtonXSpan = 1 - 2*errorButtonXSep;
    errorButtonXPos = errorButtonXSep;
    errorButtonYSpan = (1 - errorButtonYSep*(nErrorTypes+1))/nErrorTypes;
    for iButton = 1: nErrorTypes
        EBname = strcat('EB_', errorTypes(iButton));
        errorButtonYPos = 1 - errorButtonYSep*iButton - errorButtonYSpan*iButton;
        errorButtonPos = [errorButtonXPos errorButtonYPos errorButtonXSpan errorButtonYSpan];
        UserData.(EBname{1}) = uicontrol(UserData.errorPanel,...
            'Style','togglebutton','String',errorTypes(iButton),...
            'Units','Normalized','Position',errorButtonPos,...
            'FontUnits','Normalized','FontSize',0.3);
        if ~isempty(UserData.errors.(errorTypes{iButton}))
            set(UserData.(EBname{1}),'ForegroundColor',[0 0.7 0]);
        end
    end

    % create sort selection buttons
    groupPanelXPos = 0.175;
    groupPanelXSpan = 0.15;
    groupPanelYSpan = 0.11;
    groupPanelYPos = UserData.xPosMax - groupPanelYSpan;

    groupPanelPos = [groupPanelXPos groupPanelYPos groupPanelXSpan groupPanelYSpan]; 
    UserData.groupPanel = uipanel(UserData.f,'Units','Normalized','Position',...
                groupPanelPos,'Title',' group by: ',...
                'Tag','group_by','TitlePosition','CenterTop',...
                'FontSize',0.02,'FontUnits','Normalized','Visible','on');
    groupTypes = fields(UserData.dataVals);
    %remove known fields to get grouping types
        groupTypes(strcmp(groupTypes,'f0')) = [];
        groupTypes(strcmp(groupTypes,'f1')) = [];
        groupTypes(strcmp(groupTypes,'f2')) = [];
        groupTypes(strcmp(groupTypes,'int')) = [];
        groupTypes(strcmp(groupTypes,'pitch_taxis')) = [];
        groupTypes(strcmp(groupTypes,'ftrack_taxis')) = [];
        groupTypes(strcmp(groupTypes,'ampl_taxis')) = [];
        groupTypes(strcmp(groupTypes,'dur')) = [];
        groupTypes(strcmp(groupTypes,'cond')) = [];
        groupTypes(strcmp(groupTypes,'token')) = [];
        groupTypes(strcmp(groupTypes,'bExcl')) = [];
    groupButtonYSep = 0.05;
    groupButtonXSep = 0.05;
    groupButtonYSpan = 1 - 2*groupButtonYSep;
    groupButtonYPos = groupButtonYSep;
    groupButtonXSpan = 1 - 2*groupButtonXSep;
    groupButtonXPos = groupButtonXSep;
    groupButtonPos = [groupButtonXPos groupButtonYPos groupButtonXSpan groupButtonYSpan];
    if ismac
        groupFontSize = 0.2;
    else
        groupFontSize = 0.3;
    end
    UserData.groupSel = uicontrol(UserData.groupPanel,'style','popup',...
        'string',groupTypes,...
        'Units','Normalized','Position',groupButtonPos,...
        'FontUnits','Normalized','FontSize',groupFontSize,...
        'Callback',@update_plots);


    % create trial selection buttons
    trialPanelXPos = 0.35;
    trialPanelXSpan = 0.2;
    trialPanelYSpan = 0.11;
    trialPanelYPos = UserData.xPosMax-trialPanelYSpan;
    trialPanelPos = [trialPanelXPos trialPanelYPos trialPanelXSpan trialPanelYSpan]; 
    UserData.trialPanel = uibuttongroup(UserData.f,'Units','Normalized','Position',...
                trialPanelPos,'Title',' trial selection ',...
                'Tag','trial_sel','TitlePosition','CenterTop',...
                'FontSize',0.02,'FontUnits','Normalized','Visible','on');

    trialTypes = {'all_trials', 'select_trial'};
    nTrialTypes = length(trialTypes);

    trialButtonYSep = 0.05;
    trialButtonXSep = 0.05;
    trialButtonYSpan = 1 - 2*trialButtonYSep;
    trialButtonYPos = trialButtonYSep;
    trialButtonXSpan = (1 - trialButtonYSep*(nTrialTypes+1))/nTrialTypes;
    for iButton = 1: nTrialTypes
        TBname = strcat('TB_', trialTypes(iButton));
        trialButtonXPos = trialButtonXSep*iButton + trialButtonXSpan*(iButton-1);
        trialButtonPos = [trialButtonXPos trialButtonYPos trialButtonXSpan trialButtonYSpan];
        UserData.(TBname{1}) = uicontrol(UserData.trialPanel,...
            'Style','togglebutton','String',trialTypes(iButton),...
            'Units','Normalized','Position',trialButtonPos,...
            'FontUnits','Normalized','FontSize',0.3);
    end
end

function update_plots(src,evt)
    UserData = guidata(src);
    errorField = UserData.errorPanel.SelectedObject.String{1};
    trialset = UserData.errors.(errorField);
    grouping = UserData.groupSel.String{UserData.groupSel.Value};
    if isfield(UserData,'htracks')
        delete(UserData.hsub);
        UserData = rmfield(UserData,'htracks');
        UserData = rmfield(UserData,'hsub');
    end
    if isfield(UserData,'noPlotMessage')
        delete(UserData.noPlotMessage);
        UserData = rmfield(UserData,'noPlotMessage');
    end
    if isempty(trialset)
        UserData.noPlotMessage = uicontrol(UserData.plotPanel,'style','text',...
            'String','No data to plot',...
            'Units','Normalized','Position',[.1 .4 .8 .2],...
            'FontUnits','Normalized','FontSize',0.3);
    else
        outstring = textwrap(UserData.warnText,{'Plotting data'});
        set(UserData.warnText,'BackgroundColor','red','String',outstring)
        pause(0.0001)
        [UserData.htracks,UserData.hsub] = plot_rawFmtTracks(UserData.dataVals,grouping,trialset,UserData.plotPanel,UserData.expt);
        set(UserData.warnText,'String',[],'BackgroundColor',[0.9400    0.9400    0.9400])
    end
    guidata(src,UserData);
end
    