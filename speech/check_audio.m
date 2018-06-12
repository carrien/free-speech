function check_audio(dataPath,trialinds)
% DATA = CHECK_AUDIO(dataPath,trialinds)
% Function cycles through trials to check that participant said correct
% word


if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2, trialinds = []; end

%% create GUI
f = figure('Visible','on','Units','Normalized','Position',[.1 .1 .8 .8]);

UserData = guihandles(f);
UserData.f =f;

% load data
UserData.dataPath = dataPath;
load(fullfile(dataPath,'data.mat'),'data');
UserData.data = data;
load(fullfile(dataPath,'expt.mat'),'expt');
UserData.expt = expt;
if exist(fullfile(dataPath,'dataVals.mat'),'file')
    load(fullfile(dataPath,'dataVals.mat'),'dataVals');
    UserData.dataVals = dataVals;
else
    for i = 1:UserData.expt.ntrials
        UserData.dataVals(i).bExcl = 0;
    end
end


% pick trials
if isempty(trialinds)
    reply = input('Start trial? [1]: ','s');
    if isempty(reply), reply = '1'; end
    startTrial = sscanf(reply,'%d');
    UserData.trials2Track = startTrial:length(data);
else
    UserData.trials2Track = trialinds;
end
UserData.trialIndex = [1:9] - 9;

%setup GUI
UserData.bgHeight = 8;
UserData.bgWidth = 6;
UserData.bgHeightUnit = 1/(2*UserData.bgHeight+3);
UserData.bgWidthUnit = 1/(5*UserData.bgWidth+6);



%create play and continue buttons
xPos = (1+(UserData.bgWidth+1)*(5-0.9))*UserData.bgWidthUnit;
yPos = 1-(UserData.bgHeight+2+UserData.bgHeight*1/3+2/18)*UserData.bgHeightUnit;
ySpan = UserData.bgHeight*UserData.bgHeightUnit*.3;
xSpan = UserData.bgWidth*UserData.bgWidthUnit*.8;
UserData.hplay = uicontrol('Style','pushbutton','String','Play All',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.15,...
'Callback',@playAll);

xPos = (1+(UserData.bgWidth+1)*(5-0.55))*UserData.bgWidthUnit;   
xSpan = UserData.bgWidth*UserData.bgWidthUnit*.375;
yPos = 1-(UserData.bgHeight+2+UserData.bgHeight*2/3+1/18)*UserData.bgHeightUnit;
UserData.hcont = uicontrol('Style','pushbutton','String','>>',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.15,...
'Callback',@goToNextSet);

xPos = (1+(UserData.bgWidth+1)*(5-.9))*UserData.bgWidthUnit;   
xSpan = UserData.bgWidth*UserData.bgWidthUnit*.375;
yPos = 1-(UserData.bgHeight+2+UserData.bgHeight*2/3+1/18)*UserData.bgHeightUnit;
UserData.hback = uicontrol('Style','pushbutton','String','<<',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.15,...
'Callback',@goToLastSet);

xPos = (1+(UserData.bgWidth+1)*(5-0.55))*UserData.bgWidthUnit;
yPos = 1-(UserData.bgHeight+2+UserData.bgHeight)*UserData.bgHeightUnit;
xSpan = UserData.bgWidth*UserData.bgWidthUnit*.375;
UserData.hplay = uicontrol('Style','pushbutton','String','End',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.15,...
'Callback',@endSession);

xPos = (1+(UserData.bgWidth+1)*(5-0.9))*UserData.bgWidthUnit;
yPos = 1-(UserData.bgHeight+2+UserData.bgHeight)*UserData.bgHeightUnit;
xSpan = UserData.bgWidth*UserData.bgWidthUnit*.375;
UserData.hsave = uicontrol('Style','pushbutton','String','Save',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.15,...
'Callback',@saveData);

guidata(f,UserData)
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
    save(fullfile(UserData.dataPath,'dataVals.mat'),'dataVals'); %save datVals structure
    if ~exist(fullfile(UserData.dataPath,'trials'),'dir')
        mkdir(fullfile(UserData.dataPath,'trials'))
    end
    for i = 1:length(dataVals) %save individual files
        if dataVals(i).bExcl
            try load(fullfile(UserData.dataPath,'trials',sprintf('%d.mat',i)));
                trialparams.event_params.is_good_trial = 0;
                save(fullfile(UserData.dataPath,'trials',sprintf('%d.mat',i)),'sigmat','trialparams')
            catch
                fprintf('Trial %d has not been analyzed yet\n',i)
                trialparams.event_params.is_good_trial = 0;
                save(fullfile(UserData.dataPath,'trials',sprintf('%d.mat',i)),'trialparams')
            end
            fprintf('Trial %d saved.\n',i)
        end
    end
    msgbox('Data Saved!','');
end

function playAll(src,evt)
    UserData = guidata(src);
    for i = 1:length(UserData.currTrials)
        soundsc(UserData.data(UserData.currTrials(i)).signalIn,UserData.data(UserData.currTrials(i)).params.sr)
        oldBG = UserData.bg(i).BackgroundColor;
        UserData.bg(i).BackgroundColor = [1 1 0];
        pause(length(UserData.data(UserData.currTrials(i)).signalIn)./UserData.data(UserData.currTrials(i)).params.sr + .025)
        UserData.bg(i).BackgroundColor = oldBG;
    end
end

function goToNextSet(src,evt)
    UserData = guidata(src);
    UserData.trialIndex = UserData.trialIndex+9;    
    trials2Go = length(UserData.trials2Track) - UserData.trialIndex(end);
    if trials2Go > 9
        UserData.currTrials = UserData.trials2Track(UserData.trialIndex);
        guidata(src,UserData);
        plotTrials(src)
    elseif trials2Go > 0
        UserData.currTrials = UserData.trials2Track(UserData.trialIndex(1)):UserData.trials2Track(end);
        guidata(src,UserData);
        plotTrials(src)
    else
        endSession(src)
    end
    UserData.hback.BackgroundColor = [0.94 0.94 0.94]; %set back button to default color
end

function goToLastSet(src,evt)
    UserData = guidata(src);
    temp_index = UserData.trialIndex-9;
    trialsFinished = temp_index(end);
    if trialsFinished > 0
        UserData.trialIndex = UserData.trialIndex-9;
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
    
    for iBg = 1:5
        xPos = (1+(UserData.bgWidth+1)*(iBg-1))*UserData.bgWidthUnit;
        yPos = 1-(UserData.bgHeight+1)*UserData.bgHeightUnit;
        xSpan = UserData.bgWidth*UserData.bgWidthUnit;
        ySpan = UserData.bgHeight*UserData.bgHeightUnit;
        UserData.bg(iBg) = uipanel('Units','Normalized','Position',...
            [xPos,yPos,xSpan,ySpan],'Title',num2str(UserData.currTrials(iBg)),...
            'Tag',num2str(iBg));
    end
    for iBg = 6:9
        xPos = (1+(UserData.bgWidth+1)*(iBg-5-1))*UserData.bgWidthUnit;
        yPos = 1-(UserData.bgHeight*2+2)*UserData.bgHeightUnit;
        xSpan = UserData.bgWidth*UserData.bgWidthUnit;
        ySpan = UserData.bgHeight*UserData.bgHeightUnit;
        UserData.bg(iBg) = uipanel('Units','Normalized','Position',...
            [xPos,yPos,xSpan,ySpan],'Title',num2str(UserData.currTrials(iBg)),...
            'Tag',num2str(iBg));
    end

    fontDispSize = 0.3;
    for iBg = 1:9
        UserData.htxt(iBg) = uicontrol(UserData.bg(iBg),'Style','pushbutton',...
        'Units','Normalized','Position',[.1 .775 .8 .2],...
        'String',UserData.expt.listWords(UserData.currTrials(iBg)),'FontUnits','Normalized',...
        'FontSize',fontDispSize,...
        'Callback',@toggleBExcl);
    
        if UserData.dataVals(UserData.currTrials(iBg)).bExcl
            UserData.htxt(iBg).BackgroundColor = [0.85 0.3 0.3];
        else
            UserData.htxt(iBg).BackgroundColor = [0.3 0.85 0.3];
        end
        UserData.hreplay(iBg) = uicontrol(UserData.bg(iBg),'Style','pushbutton',...
        'Units','Normalized','Position',[.1 .025 .8 .2],...
        'String','replay','FontUnits','Normalized','FontSize',.4,...
        'Callback',@replayTrial);
        
        UserData.haxes(iBg) = axes(UserData.bg(iBg),'Units','Normalized',...
        'Position',[.1 .275 .8 .425],'Box','on');

        axes(UserData.haxes(iBg))
        currSig = UserData.data(UserData.currTrials(iBg)).signalIn;
        plot(currSig,'k')
        set(UserData.haxes(iBg),'XTick',[],'YTick',[])
        if max(currSig) < 0.5
            ylim([-.5 .5])
        else
            ylim([-max(currSig) max(currSig)])
        end

    end
   
    guidata(src,UserData);
end

function replayTrial(src,evt)
    UserData = guidata(src);
    trialNumber = str2num(src.Parent.Title);
    tagNumber = str2num(src.Parent.Tag);
    soundsc(UserData.data(trialNumber).signalIn,UserData.data(trialNumber).params.sr)
    
    oldBG = UserData.bg(tagNumber).BackgroundColor;
    UserData.bg(tagNumber).BackgroundColor = [1 1 0];
    pause(length(UserData.data(trialNumber).signalIn)./UserData.data(trialNumber).params.sr + .025)
    UserData.bg(tagNumber).BackgroundColor = oldBG;
end

function toggleBExcl(src,evt)
    UserData = guidata(src);
    trialNumber = str2num(src.Parent.Title);
    if UserData.dataVals(trialNumber).bExcl
        UserData.dataVals(trialNumber).bExcl = 0;
        src.BackgroundColor = [0.3 0.85 0.3];
    else
        UserData.dataVals(trialNumber).bExcl = 1;
        src.BackgroundColor = [0.85 0.3 0.3];
    end
    guidata(src,UserData);

end