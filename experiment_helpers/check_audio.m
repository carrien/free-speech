function check_audio(dataPath,trialinds,bSort,nTrials,stringType, buffertype)
% DATA = CHECK_AUDIO(dataPath,trialinds)
% Function cycles through trials to check that participant said correct
% word. Inputs:
%   dataPath: path where data.mat and expt.mat are. Default is current
%   directory
%   trialinds: index of trials to analyze. Default is all trials.
%   bSort: sort trials by word (1) or don't (0). Default is 0. (currently
%   not implemented)
%   nTrials: how many trials to analyze at a time. Default is 10
%   buffertype: which field to use from data struct. Only tested with
%     signalIn or signalOut. (default: signalIn)

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialinds = []; end
if nargin < 3 || isempty(bSort), bSort = 0; end
if nargin < 4 || isempty(nTrials), nTrials = 10; end
if nargin < 5 || isempty(stringType), stringType = 'listWords'; end
if nargin < 6 || isempty(buffertype), buffertype = 'signalIn'; end

% set trial folder
if strcmp(buffertype, 'signalIn')
    trialfolder = 'trials';
else
    trialfolder = sprintf('trials_%s', buffertype);    
    %trialfolderSigIn = 'trials';   %CWN TODO Don't think I need this
end

%% create GUI
f = figure('Visible','off','Units','Normalized','Position',[.1 .1 .8 .8]);
set(f, 'WindowKeyPressFcn', @KeyPress)

UserData = guihandles(f);

UserData.f =f;
UserData.nTrials = nTrials;
UserData.bSort = bSort;
UserData.stringType = stringType;
UserData.buffertype = buffertype;
UserData.trialfolder = trialfolder;

% load data
UserData.dataPath = dataPath;
load(fullfile(dataPath,'data.mat'),'data');
UserData.data = data;
load(fullfile(dataPath,'expt.mat'),'expt');
UserData.expt = expt;
    % only update dataVals.bExcl based on signalIn
if exist(fullfile(dataPath,'dataVals.mat'),'file') && strcmp(buffertype, 'signalIn') 
    UserData.bDataVals = 1;
    load(fullfile(dataPath,'dataVals.mat'),'dataVals');
    UserData.dataVals = dataVals;
else
    UserData.bDataVals = 0;
    for i = 1:UserData.expt.ntrials
        UserData.dataVals(i).bExcl = 0;
    end
    if exist(fullfile(dataPath,trialfolder),'dir')
        [~,sortedFilenames] = get_sortedTrials(fullfile(dataPath,trialfolder));
        for i = 1:length(sortedFilenames)
            load(fullfile(dataPath,trialfolder,sortedFilenames{i}))
            fileNameParts = strsplit(sortedFilenames{i},'.');
            trialIndex = str2double(fileNameParts{1});
            if ~isfield(trialparams,'event_params') || trialparams.event_params.is_good_trial
                UserData.dataVals(trialIndex).bExcl = 0;
            else
                UserData.dataVals(trialIndex).bExcl = 1;
            end
        end
    end
end

%create variable to track if trial status is changed by user
UserData.statusChange = zeros(1,UserData.expt.ntrials);

% pick trials
UserData.trialIndex = [1:nTrials] - nTrials;

if bSort
    [~,UserData.trials2Track] = sort(UserData.expt.allWords);
    disp('Sorting by word. Using all trials.')
elseif isempty(trialinds)
        reply = input('Start trial? [1]: ','s');
        if isempty(reply), reply = '1'; end
        startTrial = sscanf(reply,'%d');
        UserData.trials2Track = startTrial:length(data);
else
    UserData.trials2Track = trialinds;
end


%setup GUI
UserData.bgHeight = 8;
UserData.bgWidth = 6;
UserData.nColumns = 5;
UserData.nRows = ceil(UserData.nTrials/UserData.nColumns); 
UserData.bgHeightUnit = 1/(UserData.nRows*UserData.bgHeight+UserData.nRows+2);
UserData.bgWidthUnit = 1/(UserData.nColumns*UserData.bgWidth+UserData.nColumns+1);



%create play and continue buttons
xPos = 0.1;
yPos = 1-UserData.bgHeightUnit;
ySpan = 0.9*UserData.bgHeightUnit;
xSpan = 0.2;
UserData.hplay = uicontrol('Style','pushbutton','String','Play All',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.3,...
'Callback',@playAll);

xPos = 0.4;   
xSpan = 0.095;
UserData.hback = uicontrol('Style','pushbutton','String','<<',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.3,...
'Callback',@goToLastSet);

xPos = 0.505;   
xSpan = 0.095;
UserData.hcont = uicontrol('Style','pushbutton','String','>>',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.3,...
'Callback',@goToNextSet);

xPos = 0.7;
xSpan = 0.095;
UserData.hsave = uicontrol('Style','pushbutton','String','Save',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.3,...
'Callback',@saveData);

xPos = .805;
xSpan = .095;
UserData.hexit = uicontrol('Style','pushbutton','String','Exit',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.3,...
'Callback',@endSession);

guidata(f,UserData)

goToNextSet(f)
f.Visible = 'On';
end

function endSession(src,evt)
    UserData = guidata(src);
    answer = questdlg('Save data and exit?', ...
	'Exit GUI', ...
	'Cancel (do not exit)','Save and exit','Exit without saving','Cancel (do not exit)');
    switch answer
        case 'Save and exit'
            saveData(src)
            close(UserData.f)
        case 'Exit without saving'
            close(UserData.f)
    end
end

function saveData(src,evt)
    UserData = guidata(src);
    dataVals = UserData.dataVals;
    if UserData.bDataVals
        save(fullfile(UserData.dataPath,'dataVals.mat'),'dataVals'); %save datVals structure
    end
    if ~exist(fullfile(UserData.dataPath,UserData.trialfolder),'dir')
        mkdir(fullfile(UserData.dataPath,UserData.trialfolder))
    end
    for i = 1:length(dataVals) %save individual files
        if UserData.statusChange(i)
            try load(fullfile(UserData.dataPath,UserData.trialfolder,sprintf('%d.mat',i)));
                if UserData.dataVals(i).bExcl
                    trialparams.event_params.is_good_trial = 0;
                else
                    trialparams.event_params.is_good_trial = 1;
                end
                save(fullfile(UserData.dataPath,UserData.trialfolder,sprintf('%d.mat',i)),'sigmat','trialparams')
            catch
                if UserData.dataVals(i).bExcl
                    trialparams.event_params.is_good_trial = 0;
                else
                    trialparams.event_params.is_good_trial = 1;
                end
                save(fullfile(UserData.dataPath,UserData.trialfolder,sprintf('%d.mat',i)),'trialparams')
            end
            fprintf('Trial %d saved.\n',i)

        end
    end
    msgbox('Data Saved!','');
end

function playAll(src,evt)
    UserData = guidata(src);
    for i = 1:length(UserData.currTrials)
        signal = UserData.data(UserData.currTrials(i)).(UserData.buffertype);
        if isfield(UserData.data(UserData.currTrials(i)).params,'fs')
            fs = UserData.data(UserData.currTrials(i)).params.fs;
        else
            fs = UserData.data(UserData.currTrials(i)).params.sr;
        end
        soundsc(signal,fs)
        oldBG = UserData.bg(i).BackgroundColor;
        UserData.bg(i).BackgroundColor = [1 1 0];
        pause(length(signal)./fs + .025)
        UserData.bg(i).BackgroundColor = oldBG;
    end
end

function goToNextSet(src,evt)
    UserData = guidata(src);
    trials2Go = length(UserData.trials2Track) - UserData.trialIndex(end);
    
    UserData.trialIndex = UserData.trialIndex+UserData.nTrials;    
    if trials2Go > UserData.nTrials
        UserData.currTrials = UserData.trials2Track(UserData.trialIndex);
        guidata(src,UserData);
        plotTrials(src)
    elseif trials2Go > 0
        UserData.currTrials = UserData.trials2Track(UserData.trialIndex(1)):UserData.trials2Track(end);
        guidata(src,UserData);
        plotTrials(src)
    end
    UserData.hback.BackgroundColor = [0.94 0.94 0.94]; %set back button to default color
    if trials2Go <= 0
        endSession(src)
    end
    
end

function goToLastSet(src,evt)
    UserData = guidata(src);
    temp_index = UserData.trialIndex-UserData.nTrials;
    trialsFinished = temp_index(end);
    if trialsFinished > 0
        UserData.trialIndex = UserData.trialIndex-UserData.nTrials;
        UserData.currTrials = UserData.trials2Track(UserData.trialIndex);
        guidata(src,UserData);
        plotTrials(src)
    else
        src.BackgroundColor = [0.6 0.6 0.6];
        guidata(src,UserData);
    end
    
end

function plotTrials(src)
    UserData = guidata(src);
    nTrialsCurr = length(UserData.currTrials);
    if isfield(UserData,'bg')
        delete(UserData.bg)
    end
    for iBg = 1:nTrialsCurr
        xIndex = mod(iBg,UserData.nColumns);
        if xIndex == 0, xIndex = UserData.nColumns;end
        yIndex = floor((iBg-1)/UserData.nColumns)+1;
        yTop = UserData.nRows*UserData.bgHeight+UserData.nRows+2;
        xPos = (1+(UserData.bgWidth+1)*(xIndex-1))*UserData.bgWidthUnit;
        yPos = (yTop-1-(1+UserData.bgHeight)*(yIndex))*UserData.bgHeightUnit;
        xSpan = UserData.bgWidth*UserData.bgWidthUnit;
        ySpan = UserData.bgHeight*UserData.bgHeightUnit;
        UserData.bg(iBg) = uipanel('Units','Normalized','Position',...
            [xPos,yPos,xSpan,ySpan],'Title',num2str(UserData.currTrials(iBg)),...
            'Tag',num2str(iBg),'TitlePosition','CenterTop',...
            'FontSize',0.02,'FontUnits','Normalized','Visible','off');
    end

    fontDispSize = 0.3;
    for iBg = 1:nTrialsCurr
        UserData.htxt(iBg) = uicontrol(UserData.bg(iBg),'Style','pushbutton',...
        'Units','Normalized','Position',[.1 .775 .8 .2],...
        'String',UserData.expt.(UserData.stringType)(UserData.currTrials(iBg)),'FontUnits','Normalized',...
        'FontSize',fontDispSize,'Visible','off',...
        'Callback',@toggleBExcl);
    
        if UserData.dataVals(UserData.currTrials(iBg)).bExcl
            UserData.htxt(iBg).BackgroundColor = [0.85 0.3 0.3];
        else
            UserData.htxt(iBg).BackgroundColor = [0.3 0.85 0.3];
        end
        
        
        UserData.haxes(iBg) = axes(UserData.bg(iBg),'Units','Normalized',...
        'Position',[.1 .275 .8 .425],'Box','on','Visible','off');

        axes(UserData.haxes(iBg))
        currSig = UserData.data(UserData.currTrials(iBg)).(UserData.buffertype);
        plot(currSig,'k')
        set(UserData.haxes(iBg),'XTick',[],'YTick',[])
        if max(abs(currSig)) < 0.5
            ylim([-.5 .5])
        else
            ylim([-max(abs(currSig)) max(abs(currSig))])
        end
        
        dispID = iBg;
        if dispID == 10, dispID = 0;end
        UserData.hreplay(iBg) = uicontrol(UserData.bg(iBg),'Style','pushbutton',...
        'Units','Normalized','Position',[.1 .025 .8 .2],...
        'String',sprintf('replay [%d]',dispID),'FontUnits','Normalized','FontSize',.4,...
        'Visible','off','Callback',@replayTrial);
    end
    
    for iBg = 1:nTrialsCurr
        UserData.bg(iBg).Visible = 'On';
        UserData.htxt(iBg).Visible = 'On';
        UserData.haxes(iBg).Visible = 'On';
        UserData.hreplay(iBg).Visible = 'On';
    end
    guidata(src,UserData);
end

function replayTrial(src,evt)
    UserData = guidata(src);
    trialNumber = str2num(src.Parent.Title);
    tagNumber = str2num(src.Parent.Tag);
    signal = UserData.data(trialNumber).(UserData.buffertype);
    if isfield(UserData.data(trialNumber).params,'fs')
        fs = UserData.data(trialNumber).params.fs;
    else
        fs = UserData.data(trialNumber).params.sr;
    end
    soundsc(signal,fs)
    
    oldBG = UserData.bg(tagNumber).BackgroundColor;
    UserData.bg(tagNumber).BackgroundColor = [1 1 0];
    pause(length(signal)./fs + .025)
    UserData.bg(tagNumber).BackgroundColor = oldBG;
    UserData.lastTargetTrial = tagNumber;
end

function toggleBExcl(src,evt)
    UserData = guidata(src);
    trialNumber = str2double(src.Parent.Title);
    tagNumber = str2double(src.Parent.Tag);
    if UserData.dataVals(trialNumber).bExcl
        UserData.dataVals(trialNumber).bExcl = 0;
        src.BackgroundColor = [0.3 0.85 0.3];
    else
        UserData.dataVals(trialNumber).bExcl = 1;
        src.BackgroundColor = [0.85 0.3 0.3];
    end
    UserData.lastTargetTrial = tagNumber;
    UserData.statusChange(trialNumber) = 1;
    guidata(src,UserData);

end

function KeyPress(src, evt)
 % determine the key that was pressed 
 UserData = guidata(src);
 keyPressed = evt.Key;
 if contains('1234567890',keyPressed)
     targetTrial = str2double(keyPressed);
     if targetTrial == 0 
         if strcmp(evt.Character,'0')
             targetTrial = 10;
         else
            return
         end
     end
     uicontrol(UserData.htxt(targetTrial));
     toggleBExcl(UserData.htxt(targetTrial));
     UserData = guidata(src);
     UserData.lastTargetTrial = targetTrial;
 elseif strcmp(keyPressed,'a')
     uicontrol(UserData.hplay)
     playAll(UserData.hplay)
     UserData = guidata(src);
 elseif strcmp(keyPressed,'p')
     if isfield(UserData,'lastTargetTrial')
         uicontrol(UserData.htxt(UserData.lastTargetTrial));
         replayTrial(UserData.htxt(UserData.lastTargetTrial));
         UserData = guidata(src);
     else
         msgbox('No trial selected!','');
     end
 elseif strcmp(keyPressed,'s')
     uicontrol(UserData.hsave)
     saveData(UserData.hplay)
     UserData = guidata(src);
 elseif strcmp(keyPressed,'e')
     uicontrol(UserData.hexit)
     endSession(UserData.hplay)
 elseif strcmp(keyPressed,'leftarrow')
     uicontrol(UserData.hback)
     goToLastSet(UserData.hback)
     UserData = guidata(src);
 elseif strcmp(keyPressed,'rightarrow')
     uicontrol(UserData.hcont)
     goToNextSet(UserData.hcont)
     UserData = guidata(src);
 end
 if ~strcmp(keyPressed,'e')
     guidata(src,UserData);
 end
end