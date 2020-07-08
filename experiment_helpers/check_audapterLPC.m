function expt = check_audapterLPC(dataPath)
% DATA = CHECK_AUDIO(dataPath,trialinds)
%Check that the LPC order used by Audapter is correctly tracking formants.
%Update order if needed. 
%Inputs:
%   dataPath: path where data.mat and expt.mat are. Default is current
%   directory

if nargin < 1 || isempty(dataPath), dataPath = cd; end

%% create GUI
f = figure('Visible','off','Units','Normalized','Position',[.05 .1 .9 .8]);
set(f,'Tag', 'check_LPC','HandleVisibility','on');

UserData = guihandles(f);

UserData.f =f;

% load data
UserData.dataPath = dataPath;
load(fullfile(dataPath,'data.mat'),'data');
if ~exist(fullfile(dataPath,'data_uncorrectedLPC.mat'))
    save(fullfile(dataPath,'data_uncorrectedLPC.mat'),'data') %save original data
end
UserData.data = data;
load(fullfile(dataPath,'expt.mat'),'expt');
UserData.expt = expt;
if ~isfield(UserData.expt,'bExcl')
    UserData.expt.bExcl = zeros(1,UserData.expt.ntrials);
end
UserData.nVowels = length(fields(UserData.expt.inds.vowels));

%create variable to track if trial status is changed by user
UserData.statusChange = zeros(1,UserData.expt.ntrials);

%setup GUI
UserData.xPosMax = 0.975;
plotMargin = 0.025;

% create panel for F1/F2 plot
plotPanelXPos = plotMargin;
plotPanelXSpan = 0.4 - plotMargin/2 - plotPanelXPos;
plotPanelYSpan = 0.95;
plotPanelYPos = UserData.xPosMax - plotPanelYSpan;
plotPanelPos = [plotPanelXPos plotPanelYPos plotPanelXSpan plotPanelYSpan];
UserData.plotPanelF1F2 = uipanel(UserData.f,'Units','Normalized','Position',...
            plotPanelPos,...
            'Tag','formant_plots','Visible','on');
vowels = fields(UserData.expt.inds.vowels);
for i = 1:UserData.nVowels
    vow = vowels{i};
    UserData.trial2plot.(vow) = []; %initialize trial selection
end
UserData.F1F2ax = axes(UserData.plotPanelF1F2);

% create panel for formant track
plotPanelXPos = 0.4+plotMargin/2;
plotPanelXSpan = 0.8 - plotMargin/2 - plotPanelXPos;
plotPanelYSpan = 0.95;
plotPanelYPos = UserData.xPosMax - plotPanelYSpan;
plotPanelPos = [plotPanelXPos plotPanelYPos plotPanelXSpan plotPanelYSpan];
UserData.plotPanelTracks = uipanel(UserData.f,'Units','Normalized','Position',...
            plotPanelPos,...
            'Tag','formant_plots','Visible','on');
UserData.nRowsTracks = ceil(UserData.nVowels/2);
for i = 1:UserData.nVowels
    UserData.hsubTracks(i) = subplot(UserData.nRowsTracks,2,i,'Parent',UserData.plotPanelTracks);
end

%create LPC order drop down menu
UserData.nLPC = data(1).params.nLPC;

xPos = 0.8+plotMargin;
xSpan = UserData.xPosMax-plotMargin/2-xPos;
yPos = 0.4+plotMargin/2;
ySpan = 0.6-plotMargin/2-yPos;
LPCoptions = {'10','11','12','13','14','15','16','17','18','19','20'};
UserData.LPCdrop = uicontrol(UserData.f,...
    'Style','popupmenu',...
    'Units','Normalized',...
    'Position',[xPos,yPos,xSpan,ySpan],...
    'String',LPCoptions,...
    'Value',find(strcmp(LPCoptions,num2str(UserData.nLPC))),...
    'FontUnits','Normalized','FontSize',0.2,...
    'Callback',@changeLPC);

yPos = 0.6-plotMargin/2;
UserData.LPCtext = uicontrol(UserData.f,...
    'Style','text',...
    'Units','Normalized',...
    'Position',[xPos,yPos,xSpan,ySpan],...
    'String','LPC order:',...
    'FontUnits','Normalized','FontSize',0.2);

%create panel for displaying warnings
xPos = 0.8+plotMargin;
xSpan = UserData.xPosMax-plotMargin/2-xPos;
yPos = 0.8+plotMargin/2;
ySpan = UserData.xPosMax-yPos;
UserData.warnPanel = uipanel(UserData.f,'Units','Normalized','Position',...
            [xPos,yPos,xSpan,ySpan],...
            'Tag','warn_panel','Visible','on');

UserData.warnText = uicontrol(UserData.warnPanel,'style','text',...
            'String',[],...
            'Units','Normalized','Position',[.1 .1 .8 .8],...
            'FontUnits','Normalized','FontSize',.3);
        
        
%create OK button
yPos = 0.2+plotMargin/2;   
ySpan = 0.4 - plotMargin/2-yPos;
UserData.hOK = uicontrol(UserData.f,'Style','pushbutton','String','OK',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.3,...
'Callback',@OK);

%create toggle formants button
UserData.toggle_formant = uicontrol(UserData.plotPanelTracks,'Style','pushbutton',...
    'String','toggle formants',...
    'Units','Normalized','Position',[.05 0 .425 .05],...
    'FontUnits','Normalized','FontSize',0.5,...
    'Callback',@toggleFormants);

%create toggle formants button
UserData.toggle_formant = uicontrol(UserData.plotPanelTracks,'Style','pushbutton',...
    'String','toggle vowel bounds',...
    'Units','Normalized','Position',[.525 0 .425 .05],...
    'FontUnits','Normalized','FontSize',0.5,...
    'Callback',@toggleVowelBounds);

%create exclude data button
UserData.toggle_formant = uicontrol(UserData.plotPanelF1F2,'Style','pushbutton',...
    'String','exclude/include trial',...
    'Units','Normalized','Position',[.2 0 .6 .05],...
    'FontUnits','Normalized','FontSize',0.5,...
    'Callback',@toggleIncludeData);

guidata(f,UserData)

f.Visible = 'On';

updatePlots(UserData.f)
end

function OK(src,evt)
    UserData = guidata(src);
    answer = questdlg('Save LPC order and exit?', ...
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

function changeLPC(src,evt)
    UserData = guidata(src);
    
    %set warning
    set(UserData.warnPanel,'HighlightColor','yellow')
    outstring = textwrap(UserData.warnText,{'Loading data...'});
    set(UserData.warnText,'String',outstring)

    % set UserData.nLPC
    UserData.nLPC = str2double(cell2mat(UserData.LPCdrop.String(UserData.LPCdrop.Value)));
    
    % check for existing tracks
    tmp_audapter_dir = fullfile(UserData.dataPath,'tmp_audapter');
    trackfile = fullfile(tmp_audapter_dir,sprintf('nlpc%d.mat',UserData.nLPC));
    if ~exist(tmp_audapter_dir,'dir')
        mkdir(tmp_audapter_dir);
    end
    if exist(trackfile,'file')
        % load tracks
        fprintf('Loading nLPC = %d... ',UserData.nLPC);
        load(trackfile,'data')
        fprintf('Done.\n');
    else
        % run Audapter offline
        fprintf('Running Audapter with nLPC = %d...\n',UserData.nLPC);
        for d = 1:length(UserData.data)
            p.nlpc = UserData.nLPC;
            p.gender = UserData.expt.gender;
            data(d) = audapter_runFrames(UserData.data(d),p);
        end
        % save tracks
        fprintf('Saving %s\n',trackfile);
        save(trackfile,'data');
        fprintf('Done.\n');
    end
    
    UserData.data = data;
    
    guidata(src,UserData)  
    
    updatePlots(src)
    
    set(UserData.warnText,'String',[])
    set(UserData.warnPanel,'HighlightColor',[1 1 1])

end

function updatePlots(src)
    UserData = guidata(src);

    %calculate f1 and f2 for all trials
    ntrials = length(UserData.data);
    f1s = NaN(1,ntrials);
    f2s = NaN(1,ntrials);
    for i = 1:ntrials
        ftrackSamps = find(UserData.data(i).fmts(:,1)>0);
        ftrack = UserData.data(i).fmts(ftrackSamps,:);
        ftrackLength = length(ftrack(:,1));
        if ftrackLength > 4
            p25 = round(ftrackLength/4);
            p50 = round(ftrackLength/2);
            f1s(i) = mean(ftrack(p25:p50,1));
            f2s(i) = mean(ftrack(p25:p50,2));
        else
            f1s(i) = NaN;
            f2s(i) = NaN;
        end
    end
    
    %plot F1/F2 scatter
    delete(UserData.F1F2ax)
    UserData.F1F2ax = axes(UserData.plotPanelF1F2);

    hold off
    vowels = fields(UserData.expt.inds.vowels);
    plotColors = [.9 0 0; 0 0.8 0; 0 0 1; 0.91 0.41 0.17]; 
    for i = 1:UserData.nVowels
        vow = vowels{i};     
        for j = 1:length(f1s(UserData.expt.inds.vowels.(vow)))
            if UserData.expt.bExcl(UserData.expt.inds.vowels.(vow)(j))
%                 color2plot = [0.6 0.6 0.6];
                color2plot = plotColors(i,:)*0.5;
                markerShape = 'x';
            else
                color2plot = plotColors(i,:);
                markerShape = 'o';
            end
            UserData.scatterPlot.(vow)(j) = plot(f1s(UserData.expt.inds.vowels.(vow)(j)),...
            f2s(UserData.expt.inds.vowels.(vow)(j)),...
            markerShape,'MarkerEdgeColor',color2plot);
            hold on
            set(UserData.scatterPlot.(vow)(j),'ButtonDownFcn',{@pickTrial,vow,j,i})
        end
        currTrials = UserData.expt.inds.vowels.(vow);
        currTrials = currTrials(~UserData.expt.bExcl(currTrials));
        plot(nanmean(f1s(currTrials)),...
            nanmean(f2s(currTrials)),...
            '+','MarkerEdgeColor',plotColors(i,:));
    end
    hold off
    set(UserData.plotPanelF1F2,'FontUnits','normalized','FontSize',.025)
    xlabel('F1','FontUnits','normalized','FontSize',.05)
    ylabel('F2','FontUnits','normalized','FontSize',.05)
    
    %plot individual formant tracks
    for i = 1:UserData.nVowels
        vow = vowels{i};
        %first, select which trials to plot
        if ~isempty(UserData.trial2plot.(vow))
            trialInd = UserData.trial2plot.(vow);
        else
            currF1s = f1s(UserData.expt.inds.vowels.(vow));
            currF2s = f2s(UserData.expt.inds.vowels.(vow));
            meanF1 = nanmean(currF1s);
            meanF2s = nanmean(currF2s);
            dists = sqrt((currF1s-meanF1).^2+(currF2s-meanF2s).^2);
            [~,trialInd] = max(dists);
            UserData.trial2plot.(vow) = trialInd;
        end
        trial2plot = UserData.expt.inds.vowels.(vow)(trialInd);
        
        %then, plot it
        subplot(UserData.hsubTracks(i));
        cla(UserData.hsubTracks(i))
        ySpec = my_preemph(UserData.data(trial2plot).signalIn,1);
%         ySpec = UserData.data(trial2plot).signalIn;
        show_spectrogram(ySpec, UserData.data(trial2plot).params.sr, 'noFig');
        tAxis = 0 : UserData.data(trial2plot).params.frameLen : UserData.data(trial2plot).params.frameLen * (size(UserData.data(trial2plot).fmts, 1) - 1);        
        if UserData.expt.bExcl(UserData.expt.inds.vowels.(vow)(trialInd))
            color2plot = plotColors(i,:)*0.5;
        else
            color2plot = plotColors(i,:);
        end
        UserData.formantTracks.(vow) = plot(tAxis/UserData.data(trial2plot).params.sr,UserData.data(trial2plot).fmts(:,1:2), 'Color',color2plot,'LineWidth',3);
        
        %plot ost
        framedur = 1 / UserData.data(trial2plot).params.sr*UserData.data(trial2plot).params.frameLen; %get frame duration
        offset = [floor(0.05 / framedur) floor(0.01 / framedur)];
        vowelFrames = find(UserData.data(trial2plot).ost_stat == 2); % get indices to vowel
        vowelFrames = vowelFrames(1)-offset(1):vowelFrames(end)-offset(2); %account for offset in ost tracking
        vowMidPoint = (vowelFrames(1)+vowelFrames(end))./2;
        vowLength = length(vowelFrames);
        vowMidOns = floor(vowMidPoint-vowLength/4);
        vowMidOffs = floor(vowMidPoint+vowLength/4);
        UserData.vowelBounds.(vow)(1) = vline(vowelFrames(1)*framedur,'k');
        UserData.vowelBounds.(vow)(2) = vline(vowelFrames(end)*framedur,'k');
        UserData.vowelBounds.(vow)(3) = vline(vowMidOns*framedur,'c');
        UserData.vowelBounds.(vow)(4) = vline(vowMidOffs*framedur,'c');
        set(UserData.vowelBounds.(vow)(3),'LineWidth',2)
        set(UserData.vowelBounds.(vow)(4),'LineWidth',2)
        title(vow,'FontUnits','normalized','FontSize',0.1)
        
        %highlight selected token
        set(UserData.scatterPlot.(vow)(trialInd),'MarkerFaceColor',plotColors(i,:));
    end
    if isfield(UserData,'selTrial')
        set(UserData.scatterPlot.(vowels{UserData.selTrial.vow})(UserData.selTrial.trial),'MarkerSize',12);
    end
    guidata(src,UserData)
end

function pickTrial(src,evt,vow,j,i)
    UserData = guidata(src);
    UserData.trial2plot.(vow) = j;
    UserData.selTrial.vow = i;
    UserData.selTrial.trial = j;
    guidata(src,UserData)
    updatePlots(src.Parent.Parent)
end

function toggleFormants(src,evt)
    UserData = guidata(src);
    vowels = fields(UserData.expt.inds.vowels);
    for i = 1:UserData.nVowels
        vow = vowels{i};
        for j = 1:length(UserData.formantTracks.(vow))
            if strcmp(UserData.formantTracks.(vow)(j).Visible,'on')
                set(UserData.formantTracks.(vow)(j),'Visible','off')
            else
                set(UserData.formantTracks.(vow)(j),'Visible','on')
            end
        end
    end
    guidata(src,UserData)
end

function toggleVowelBounds(src,evt)
    UserData = guidata(src);
    vowels = fields(UserData.expt.inds.vowels);
    for i = 1:UserData.nVowels
        vow = vowels{i};
        for j = 1:length(UserData.vowelBounds.(vow))
            if strcmp(UserData.vowelBounds.(vow)(j).Visible,'on')
                set(UserData.vowelBounds.(vow)(j),'Visible','off')
            else
                set(UserData.vowelBounds.(vow)(j),'Visible','on')
            end
        end
    end
    guidata(src,UserData)
end

function toggleIncludeData(src,evt)
    UserData = guidata(src);
    vowels = fields(UserData.expt.inds.vowels);
    try
        vow = vowels{UserData.selTrial.vow};
        iTrial = UserData.expt.inds.vowels.(vow)(UserData.selTrial.trial); %this is the selected trial
        if UserData.expt.bExcl(iTrial)
            UserData.expt.bExcl(iTrial) = 0;
        else
            UserData.expt.bExcl(iTrial) = 1;
        end
        guidata(src,UserData)
        updatePlots(src.Parent.Parent)
    catch
        warndlg('Please select a trial')
    end
end

function saveData(src)
    % save LPC
    UserData = guidata(src);
    LPCfile = fullfile(UserData.dataPath,'nlpc.mat');
    nlpc = UserData.nLPC;
    fprintf('Saving chosen LPC order... ');
    save(LPCfile,'nlpc')
    fprintf('Done.\n');
    
    fprintf('Saving data with chosen LPC order... ');
    data = UserData.data;
    save(fullfile(UserData.dataPath,'data'),'data')
    fprintf('Done.\n');
    
    fprintf('Saving expt file... ');
    expt = UserData.expt;
    save(fullfile(UserData.dataPath,'expt'),'expt')
    fprintf('Done.\n');

    % cleanup temp files
    tmp_audapter_dir = fullfile(UserData.dataPath,'tmp_audapter');
    if exist(tmp_audapter_dir,'dir')
        fprintf('Removing temp files... ');
        rmdir(tmp_audapter_dir,'s');
        fprintf('Done.\n');
    end
end
