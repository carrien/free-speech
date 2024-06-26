function expt = check_audapterLPC(dataPath, params)
% EXPT = CHECK_AUDAPTERLPC(dataPath)
%Check that the LPC order used by Audapter is correctly tracking formants.
%Update LPC order if needed. 
%Inputs:
%   dataPath: path where data.mat and expt.mat are. Default is current
%   directory

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(params), params = struct; end

defaultParams.refPointCalcMethod = 'mean';
defaultParams.defaultPointSelected = 'far';
params = set_missingFields(params, defaultParams, 0);

%% create GUI
f = figure('Visible','off','Units','Normalized','Position',[.05 .1 .9 .8]);
set(f,'Tag', 'check_LPC','HandleVisibility','on');

UserData = guihandles(f);

UserData.f =f;

% global settings
UserData.refPointCalcMethod = params.refPointCalcMethod;
UserData.defaultPointSelected = params.defaultPointSelected;
UserData.formantTrackVisibility = 'on';
UserData.vowelBoundsVisibility = 'on';

% load data
UserData.dataPath = dataPath;
load(fullfile(dataPath,'data.mat'),'data');
if ~exist(fullfile(dataPath,'data_uncorrectedLPC.mat'), 'file')
    save(fullfile(dataPath,'data_uncorrectedLPC.mat'),'data') %save original data
end
load(fullfile(dataPath,'expt.mat'),'expt');
if length(data) < expt.ntrials
    warning('Experiment has %d trials but only %d data trials found. Using trials 1-%d.',expt.ntrials,length(data),length(data))
end
UserData.data = data;
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

%create panel for LPC info
plotPanelXPos = 0.8+plotMargin;
plotPanelXSpan = UserData.xPosMax-plotMargin/2-plotPanelXPos;
plotPanelYSpan = 0.15 + plotMargin/2;
plotPanelYPos = 0.78 - plotMargin/2 - plotPanelYSpan; 

plotPanelPos = [plotPanelXPos plotPanelYPos plotPanelXSpan plotPanelYSpan];
UserData.lpcPanel = uipanel(UserData.f,'Units','Normalized','Position',...
            plotPanelPos,...
            'Tag','lpc_info','Visible','on');


%create LPC order drop down menu
UserData.nLPC = data(1).params.nLPC;

xPos = 0.05;
xSpan = 0.95 - xPos;
yPos = 0.25;
ySpan = 0.25;
LPCoptions = {'10','11','12','13','14','15','16','17','18','19','20'};
UserData.LPCdrop = uicontrol(UserData.lpcPanel,...
    'Style','popupmenu',...
    'Units','Normalized',...
    'Position',[xPos,yPos,xSpan,ySpan],...
    'String',LPCoptions,...
    'Value',find(strcmp(LPCoptions,num2str(UserData.nLPC))),...
    'FontUnits','Normalized','FontSize',0.75,...
    'Callback',@changeLPC);

yPos = 0.65;
UserData.LPCtext = uicontrol(UserData.lpcPanel,...
    'Style','text',...
    'Units','Normalized',...
    'Position',[xPos,yPos,xSpan,ySpan],...
    'String','LPC order:',...
    'FontUnits','Normalized','FontSize',0.75);

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

%create panel for displaying reference point (mean vs median)
xPos = 0.8+plotMargin;
xSpan = UserData.xPosMax-plotMargin/2-xPos;
yPos = 0.4;
ySpan = 0.15;
UserData.refPointPanel = uipanel(UserData.f,'Units','Normalized','Position',...
            [xPos,yPos,xSpan,ySpan],...
            'Tag','refPointPanel','Visible','on');

UserData.refPointTextCtr = uicontrol(UserData.refPointPanel,'style','text',...
            'String','Reference point',...
            'Units','Normalized','Position',[.1 .65 .8 .25],...
            'FontUnits','Normalized','FontSize',.75);

refPointOptions = {'mean' 'median'};
UserData.refPointCalcCtr = uicontrol(UserData.refPointPanel,...
    'Style','popupmenu',...
    'Units','Normalized',...
    'Position',[.1, .25, .8, .30],...
    'String',refPointOptions,...
    'Value',find(strcmp(refPointOptions,UserData.refPointCalcMethod)),...
    'FontUnits','Normalized','FontSize',0.75,...
    'Callback',@updateReferenceMarker);
        
        
%create OK button
%yPos = 0.2+plotMargin/2;   
%ySpan = 0.4 - plotMargin/2-yPos;
yPos = 0.025 + plotMargin;
ySpan = 0.225 - plotMargin/2 - yPos;
UserData.hOK = uicontrol(UserData.f,'Style','pushbutton','String','OK',...
'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],...
'FontUnits','Normalized','FontSize',0.3,...
'Callback',@OK);

%create change OSTs button (launches audapter_viewer)
%yPos = 0.2+plotMargin/2;   
%ySpan = 0.25 - plotMargin/2-yPos;
yPos = 0.250 + plotMargin/2;
ySpan = 0.350 - plotMargin/2 - yPos;
UserData.toggle_formant = uicontrol(UserData.f,'Style','pushbutton',...
    'String','change OSTs',...
    'Units','Normalized','Position',[xPos,yPos,xSpan,ySpan],... 
    'FontUnits','Normalized','FontSize',0.35,...
    'Callback',@goto_audapter_viewer);

%create toggle formants button
UserData.toggle_formant = uicontrol(UserData.plotPanelTracks,'Style','pushbutton',...
    'String','toggle formants',...
    'Units','Normalized','Position',[.05 0 .425 .05],...
    'FontUnits','Normalized','FontSize',0.5,...
    'Callback',@toggleFormants);

%create toggle vowel bounds button
UserData.toggle_formant = uicontrol(UserData.plotPanelTracks,'Style','pushbutton',...
    'String','toggle vowel bounds',...
    'Units','Normalized','Position',[.525 0 .425 .05],...
    'FontUnits','Normalized','FontSize',0.5,...
    'Callback',@toggleVowelBounds);

%create exclude data button
UserData.toggle_formant = uicontrol(UserData.plotPanelF1F2,'Style','pushbutton',...
    'String','exclude/include trial',...
    'Units','Normalized','Position',[0.25 0 .5 .05],...
    'FontUnits','Normalized','FontSize',0.5,...
    'Callback',@toggleIncludeData);

%create play audio button
UserData.toggle_formant = uicontrol(UserData.plotPanelF1F2,'Style','pushbutton',...
    'String','Play',...
    'Units','Normalized','Position',[.8 0 .15 .05],... 
    'FontUnits','Normalized','FontSize',0.35,...
    'Callback',@playSelectedTrial);


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
    set(UserData.warnText,'String',outstring);
    drawnow;

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
            p.nLPC = UserData.nLPC;
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
    drawnow;

end

function updateReferenceMarker(src, ~)
    UserData = guidata(src);

    UserData.refPointCalcMethod = cell2mat(UserData.refPointCalcCtr.String(UserData.refPointCalcCtr.Value));

    guidata(src,UserData)
    updatePlots(src)
end

function playSelectedTrial(src, ~)
    UserData = guidata(src);
    if isfield(UserData, 'selTrial')
        vowels = fields(UserData.expt.inds.vowels);
        vow = vowels{UserData.selTrial.vow};
        iTrial = UserData.expt.inds.vowels.(vow)(UserData.selTrial.trial);
        
        y = UserData.data(iTrial).signalIn;
        fs = UserData.data(iTrial).params.sRate;
        sound(y, fs);
    else
        warndlg('Please select a trial')
    end
end

function updatePlots(src)
    UserData = guidata(src);

    %calculate f1 and f2 for all trials
    ntrials = length(UserData.data);
    f1s = NaN(1,ntrials);
    f2s = NaN(1,ntrials);
    bWarn = 1;
    
    for i = 1:ntrials      
        %use ost status to plot vowels
        if isfield(UserData.data(i), 'calcOST') && ~isempty(UserData.data(i).calcOST)
            vowelFrames = find(UserData.data(i).calcOST == 2 | UserData.data(i).calcOST == 3); % get indices to vowel, as set by audapter_viewer
        elseif isfield(UserData.data(i), 'ost_calc') && ~isempty(UserData.data(i).ost_calc)
            vowelFrames = find(UserData.data(i).ost_calc == 2 | UserData.data(i).ost_calc == 3); % get indices to vowel, as set by audapter_viewer
        else
            vowelFrames = find(UserData.data(i).ost_stat == 2 | UserData.data(i).ost_stat == 3); % get indices to vowel, from initial audapter run
        end
        if ~isempty(vowelFrames)
            %use ost status to plot vowels if possible
            framedur = 1 / UserData.data(i).params.sr*UserData.data(i).params.frameLen; %get frame duration
            offset = [floor(0.05 / framedur) floor(0.01 / framedur)];
            vowelFrames = vowelFrames(1)-offset(1):vowelFrames(end)-offset(2); %account for offset in ost tracking
            vowelFmts = UserData.data(i).fmts(vowelFrames,:);
            f1s(i) = median(midnperc(vowelFmts(:,1),50), 'omitnan');
            f2s(i) = median(midnperc(vowelFmts(:,2),50), 'omitnan');
        else
            if bWarn
                warning('Expected OST statuses not found! Using audapter formant track length to estimate vowel midpoint')
            end
            bWarn = 0;
            % use old method(mean betweeen 25-50% formant track length)
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
    end
    
    %% plot F1/F2 scatter
    delete(UserData.F1F2ax)
    UserData.F1F2ax = axes(UserData.plotPanelF1F2, 'Position', [0.13 0.13 0.775 0.815]);

    hold off
    vowels = fields(UserData.expt.inds.vowels);
    
    %Set up colors. Using varycolor allows for any number of vowels
    plotColors = varycolor(UserData.nVowels);
    
    for v = 1:UserData.nVowels
        vow = vowels{v};
        vowTrials = intersect(UserData.expt.inds.vowels.(vow),1:length(f1s));
        for i = 1:length(f1s(vowTrials))
            if UserData.expt.bExcl(vowTrials(i))
                color2plot = plotColors(v,:)*0.5;
                markerShape = 'x';
            else
                color2plot = plotColors(v,:);
                markerShape = 'o';
            end
            UserData.scatterPlot.(vow)(i) = plot(f1s(vowTrials(i)),f2s(vowTrials(i)),...
                markerShape,'MarkerEdgeColor',color2plot);
            hold on
            set(UserData.scatterPlot.(vow)(i),'ButtonDownFcn',{@pickTrial,vow,i,v})
        end
        goodTrials = vowTrials(~UserData.expt.bExcl(vowTrials));
        if strcmp(UserData.refPointCalcMethod, 'median')
            currF1s = f1s(goodTrials);
            currF2s = f2s(goodTrials);
            medianF1s = median(currF1s, 'omitnan');
            medianF2s = median(currF2s, 'omitnan');
            dists = sqrt((currF1s-medianF1s).^2+(currF2s-medianF2s).^2);
            [~, trialInd] = min(dists);
            plusSignObj = plot(currF1s(trialInd),currF2s(trialInd),...
                '+','MarkerEdgeColor',plotColors(v,:),'MarkerSize', 15);
            
            % save selected trial to expt
            exptTrialInd = goodTrials(trialInd);
            UserData.expt.selectedTrials.(vow) = exptTrialInd;
        else %assume mean
            plusSignObj = plot(mean(f1s(goodTrials), 'omitnan'),mean(f2s(goodTrials), 'omitnan'),...
                '+','MarkerEdgeColor',plotColors(v,:),'MarkerSize', 15);

            % scrub selectedTrials (only used with median reference point)
            if isfield(UserData.expt, 'selectedTrials')
                UserData.expt = rmfield(UserData.expt, 'selectedTrials');
            end
        end
        uistack(plusSignObj, "bottom")
    end
    hold off
    set(UserData.plotPanelF1F2,'FontUnits','normalized','FontSize',.025)
    xlabel('F1','FontUnits','normalized','FontSize',.05)
    ylabel('F2','FontUnits','normalized','FontSize',.05)
    
    %% plot individual formant tracks
    for v = 1:UserData.nVowels
        vow = vowels{v};
        vowTrials = intersect(UserData.expt.inds.vowels.(vow),1:length(f1s));
        %first, select which trials to plot
        if ~isempty(UserData.trial2plot.(vow))
            trialInd = UserData.trial2plot.(vow);
        else
            currF1s = f1s(vowTrials);
            currF2s = f2s(vowTrials);
            if strcmp(UserData.refPointCalcMethod, 'median')
                referenceF1s = median(currF1s, 'omitnan');
                referenceF2s = median(currF2s, 'omitnan');
            else
                referenceF1s = mean(currF1s, 'omitnan');
                referenceF2s = mean(currF2s, 'omitnan');
            end
            dists = sqrt((currF1s-referenceF1s).^2+(currF2s-referenceF2s).^2);
            if strcmp(UserData.defaultPointSelected, 'far')
                [~,trialInd] = max(dists);
            else % assume 'near'
                [~,trialInd] = min(dists);
            end
            UserData.trial2plot.(vow) = trialInd;
        end
        trial2plot = vowTrials(trialInd);
        
        %then, plot it
        subplot(UserData.hsubTracks(v));
        cla(UserData.hsubTracks(v))
        ySpec = my_preemph(UserData.data(trial2plot).signalIn,1);
%         ySpec = UserData.data(trial2plot).signalIn;
        show_spectrogram(ySpec, UserData.data(trial2plot).params.sr, 'noFig');
        tAxis = 0 : UserData.data(trial2plot).params.frameLen : UserData.data(trial2plot).params.frameLen * (size(UserData.data(trial2plot).fmts, 1) - 1);        
        if UserData.expt.bExcl(vowTrials(trialInd))
            color2plot = plotColors(v,:)*0.5;
        else
            color2plot = plotColors(v,:);
        end
        UserData.formantTracks.(vow) = plot(tAxis/UserData.data(trial2plot).params.sr,UserData.data(trial2plot).fmts(:,1:2), 'Color',color2plot,'LineWidth',3);
        set(UserData.formantTracks.(vow),'Visible',UserData.formantTrackVisibility);
        
        %plot ost
        framedur = 1 / UserData.data(trial2plot).params.sr*UserData.data(trial2plot).params.frameLen; %get frame duration
        offset = [floor(0.05 / framedur) floor(0.01 / framedur)];
        if isfield(UserData.data(trial2plot), 'calcOST') && ~isempty(UserData.data(trial2plot).calcOST)
            vowelFrames = find(UserData.data(trial2plot).calcOST == 2 | UserData.data(trial2plot).calcOST == 3); % get indices to vowel, as set by audapter_viewer
        elseif isfield(UserData.data(trial2plot), 'ost_calc') && ~isempty(UserData.data(trial2plot).ost_calc)
            vowelFrames = find(UserData.data(trial2plot).ost_calc == 2 | UserData.data(trial2plot).ost_calc == 3); % get indices to vowel, as set by audapter_viewer
        else
            vowelFrames = find(UserData.data(trial2plot).ost_stat == 2 | UserData.data(trial2plot).ost_stat == 3); % get indices to vowel, from initial audapter run
        end
        if ~isempty(vowelFrames)
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
            set(UserData.vowelBounds.(vow),'Visible',UserData.vowelBoundsVisibility);
        else    
            set(UserData.warnPanel,'HighlightColor','yellow');
            outstring = textwrap(UserData.warnText,sprintf("Missing OST trigger: trial %d of %s", trialInd, vow));
            set(UserData.warnText,'String',outstring, 'FontSize', 0.25, 'Position', [0.05 0.05 .9 .9]);
            drawnow;
        end
        title(vow,'FontUnits','normalized','FontSize',0.1)
        
        %highlight selected token
        set(UserData.scatterPlot.(vow)(trialInd),'MarkerFaceColor',plotColors(v,:));
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
                UserData.formantTrackVisibility = 'off';
            else
                set(UserData.formantTracks.(vow)(j),'Visible','on')
                UserData.formantTrackVisibility = 'on';
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
                UserData.vowelBoundsVisibility = 'off';
            else
                set(UserData.vowelBounds.(vow)(j),'Visible','on')
                UserData.vowelBoundsVisibility = 'on';
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

function goto_audapter_viewer(src,evt)
    UserData = guidata(src);
    audapter_viewer(UserData.data, UserData.expt);
    
    % wait until audapter_viewer closes
    hGui = findobj('Tag','audapter_viewer');
    uiwait(hGui);
    
    % Make sure UserData.data gets ost_calc field
    load(fullfile(UserData.dataPath, 'data.mat'), 'data');
    UserData.data = data;
    
    % clear pre-existing nLPC trackfiles
    tmp_audapter_dir = fullfile(UserData.dataPath,'tmp_audapter');
    if exist(tmp_audapter_dir, 'dir')
        rmdir(tmp_audapter_dir, 's')
    end
    
    guidata(src, UserData)
    updatePlots(src.Parent)
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
