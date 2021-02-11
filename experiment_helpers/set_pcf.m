function [varargout] = set_pcf(audFileLoc,audFileName,timeSpace,ostStatus,param,targetVal,varargin)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% MAJOR VERSION CHANGE RPK 10/21/2020
%
% This script allows editing of a single line in the PCF file. Specifically
% this will only ever edit the working version of a file. 
% 
% The line you are editing must be a warping specification (either temporal or
% spectral). You can only edit one parameter of the line at a time. 
% 
% - Previously only able to edit single time warping event :: changing to allow: 
% --- Any time warping event (not just a single line. Still have to do one time warping event at once)
% --- Any formant-related shift in the second half of a PCF file (again still have to do it one at a time)
%
% Input arguments:
% 1.) audFileLoc (formerly exptName): name of the folder (path from current-studies) where the PCF is found,
% e.g. 'experiment_helpers', 'timeAdapt'. Defaults to 'experiment-helpers'
% **** NOTE THIS WILL PROBABLY HAVE TO BE CHANGED BASED ON WHERE WE END UP PUTTING THE DEFAULT measureFormants
% PCF AND OSTs
% 
% 2.) audFileName (formerly word): name of the PCF file that is being used. Do NOT include Working.pcf, only
% the main name (e.g. measureFormants, sapper). Defaults to 'measureFormants'
% 
% 3.) timeSpace (new addition): whether you are editing the time events or the formant (space) events, options
% 'time' and 'space'. Default is 'time' because under this roof we default to temporal concerns
%
% 4.) ostStatus (new addition): the OST status that you would like to change the parameter for. IS A DOUBLE IN
% ALMOST ALL CASES. 
% --- New feature RPK 10/22/2020: If you have a timewarping line that is specified ONLY by tBegin (i.e., it is
% not triggered by an OST status), specify its number in the order of time warping events (e.g. it's the
% second time warping event) as a string: '2' 
% --- Note that while you can change the ostStat_initial of any time warping line that is triggered by an OST
% event, you cannot change a tBegin-specified line to be triggered by an OST. 
% 
% 5.) param (preserved): the parameter that you would like to change
% --- time warping options: ostStat_initial, tBegin, rate1, dur1, durHold, rate2, perturb
% ----- *** perturb is a CALCULATED value that is "how much perturbation would you like to create?" You can
% get the same amount of perturbation (e.g. 60 ms) via multiple combinations of rate1 and dur1 so you have to
% specify which of those two (rate1/dur1) you want to alter in order to produce the desired perturb, using
% varargin (see below). 
% --- formant warping options: stat (NOT RECOMMENDED), pitchShift, gainShift, fmtPertAmp, fmtPertPhi
% 
% 6.) targetVal (preserved): the value you would like to change that parameter to (note that this is somewhat
% complicated for time warping events, see descriptions beow. Straightforward for formant perturbation.)
%
% 7.) varargin (preserved): For time warping events only 
% - If you set param 'perturb' to targetVal 0.050, varargin will specify how you want to change it: via 'dur1' or via
% 'rate1'. If you change it via 'dur1', rate1 will be unchanged, and vice versa. THE VALUE 0.050 WILL NOT NECESSARILY SHOW UP
% IN THE PCF DUE TO MATH
% - If you set param 'rate1' or 'dur1' to targetVal 0.050, with varargin you specify whether or not you want to maintain
% the current perturbation (1 or 0) 
% --- if you don't want to (0), targetVal will simply be entered in as the new value
% 
% Order of arguments in function: "in AUDFILELOC/AUDFILENAMEWorking.pcf, I want to edit the TIME/SPACE
% information for OSTSTATUS. I want to set PARAM at TARGETVAL (by changing DUR1/RATE1  /// and DO/DO NOT
% change the other relevant parameter)"
%
% e.g. 
%
% set_pcf('timeAdapt', 'sapper', 'time', 4, 'perturb', 0.060, 'dur1')
% --- change sapperWorking.pcf, which is in timeAdapt/, target the time warping section, line that has OST
% status 4, change perturbation to 0.060 by changing dur1
% 
% set_pcf('timeAdapt', 'sapper', 'time', '2', 'durHold', 0.1)
% --- change sapperWorking.pcf, which is in timeAdapt, target the time warping section, line that is the
% second time warping event and NOT specified by an OST but rather tBegin only, change durHold to 0.1
%
% set_pcf('morphAdapt', 'bedhead', 'space', 4, 'fmtPertAmp', 100)
% --- change bedhead.pcf, which is in morphAdapt/, target the space warping section, line that has OST status
% 4, change pertAmp parameter to 100 
%
% Output is a new working PCF with new values (saved under audFileNameWorking.pcf) 
%
% Originally a nested function in run_sAdapt_audapter
% originated as timeAdapt_pcfEdit by CWN 
% transfer to refreshTimeWarpPCF by RPK
% split to set_pcf_timeAdapt by RPK 
% massive version change by RPK 
%
% last edit RPK 2020/10/27
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dbstop if error 

%% Set up argument defaults, basic information

if nargin < 1 || isempty(audFileLoc), audFileLoc = 'experiment_helpers'; end % this will have to be updated whenever we decide where to put measureFormantsWorking.pcf
if nargin < 2 || isempty(audFileName), audFileName = 'measureFormants'; end
if nargin < 3 || isempty(timeSpace), timeSpace = 'time'; end

%% File and editing information

% CWN 9/11/19 Note that this function only edits the Working copy of an OST.
% Call refreshWorkingCopy from the source function if needed before calling
% this function.

if strcmp(audFileName, 'measureFormants') || strcmp(audFileLoc, 'experiment_helpers') % So theoretically you could be doing some OTHER PCF file that is in experiment_helpers
    exptDir = fullfile(get_gitPath, 'free-speech', audFileLoc); % could potentially hard-code this to experiment_helpers but... 
else
    exptDir = fullfile(get_gitPath, 'current-studies', audFileLoc); % ['C:\Users\Public\Documents\software\current-studies\' audFileLoc]; 
end

pcfName = [audFileName 'Working.pcf']; 
pcfFile = fullfile(exptDir,pcfName);

% If a working copy doesn't exist, make one
if exist(pcfFile,'file') ~= 2
    refreshWorkingCopy(audFileLoc, audFileName,'pcf');
end

% Open file
fid = fopen(pcfFile,'r');

% Load file line by line into structure finfo
tline = fgetl(fid);
i = 1;
clear finfo
finfo{i} = tline;
% Gets the first line into split_finfo
split_tline = strsplit(tline, ' '); 
firstChars{i} = split_tline{1}; 
splitFinfo_ascii{i} = double(firstChars{i}); 
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    finfo{i} = tline;
    
    % Split line on space. Section header lines will be a single integer. 
    if tline ~= -1 % the end is this numeric and can't split
        split_tline = strsplit(tline, ' '); 
        firstChars{i} = split_tline{1}; 
        splitFinfo_ascii{i} = double(firstChars{i}); 
    end
end

% Close file
fclose(fid);

% Find which lines demarcate the beginning of the timewarping sections and the spatial warping sections
% Should be a line that has a single integer. Have to convert to ascii to verify that is not '4,' (for
% example, as str2double on that produces 4, which is an integer) and to also include '10' which is more than
% a single character

c = 1; 
for ix = 1:length(splitFinfo_ascii)
    bAllDigits = splitFinfo_ascii{ix} <= 57 & splitFinfo_ascii{ix} >= 48; % all characters in the split section have to be digits (no commas, no #, etc.) 
    if bAllDigits
        demarcaterIx(c) = ix; 
        c = c+1;
    end
end

% Abort if you don't have two sections. 
if length(demarcaterIx) ~= 2
    warning('Something is wrong with your PCF file. Incorrect number of warping sections. Stopping script.')
return
end

% Get line ranges for the time/space sections
switch timeSpace
    case 'time'
        nTimeEvents = str2double(firstChars{demarcaterIx(1)}); % Find number of time events
        startLine = demarcaterIx(1) + 1; % editable information starts on the next line
        endLine = startLine + (nTimeEvents - 1); % and this section will end after nTimeEvent lines
    case 'space'
        nWarpOsts = str2double(firstChars{demarcaterIx(2)}); % Find number of OST events
        startLine = demarcaterIx(2) + 1; 
        endLine = startLine + (nWarpOsts - 1); 
end


% Find the line that matches the ost status you're trying to edit
fileLines = startLine:endLine;
if ischar(ostStatus)
    if strcmp(timeSpace, 'time')
        lineloc = startLine + (str2double(ostStatus) - 1); 
        if lineloc < startLine || lineloc > endLine
            warning('You''ve specified time warp line %s but there are only %d time events. Stopping script.', ostStatus, nTimeEvents)
            return
        end
        components = strsplit(finfo{lineloc},','); 
    else
        warning('Specifying OST status as a string is reserved for time warping lines with no OST status trigger. Option ''space'' chosen; stopping script.')
        return
    end

else
    for i = 1:length(fileLines)
        warplines{i} = strsplit(finfo{fileLines(i)},',');
        ostOfComponent = str2double(warplines{i}{1}); 
        if ostOfComponent == ostStatus
            lineloc = fileLines(i); 
            components = warplines{i}; 
            break
        elseif i == length(fileLines) && ostOfComponent ~= ostStatus
            warning('You are trying to edit the perturbation for an OST status that does not exist. Stopping script.')
            return
        end
    end

end


%% Editing

switch timeSpace
    case 'time'
        if length(components) == 5
            % If specified via tBegin, only 5 components so the indices will be different
            % set up structure with the different component indices
            paramsList = {'tBegin', 'rate1', 'dur1', 'durHold', 'rate2'}; 
            paramIx.tBegin = 1;
            paramIx.rate1 = 2;
            paramIx.dur1 = 3;
            paramIx.durHold = 4;
            paramIx.rate2 = 5;
            
            % Initialize new components by copying
            newComponents{paramIx.tBegin} = components{paramIx.tBegin};
            newComponents{paramIx.rate1} = components{paramIx.rate1};
            newComponents{paramIx.dur1} = components{paramIx.dur1};
            newComponents{paramIx.durHold} = components{paramIx.durHold};
            newComponents{paramIx.rate2} = components{paramIx.rate2};
            
        elseif length(components) == 6
            % OST status-headed lines have 6 components
            % set up structure with the different component indices
            if ischar(ostStatus)
                fprintf('Six components found. Interpreting ostStatus as an ordinal number, not the ostStatus number!\n') 
            end
            paramsList = {'ostStat_initial', 'tBegin', 'rate1', 'dur1', 'durHold', 'rate2'}; 
            paramIx.ostStat_initial = 1;
            paramIx.tBegin = 2;
            paramIx.rate1 = 3;
            paramIx.dur1 = 4;
            paramIx.durHold = 5;
            paramIx.rate2 = 6;     
            
            % Initialize new components by copying
            newComponents{paramIx.ostStat_initial} = components{paramIx.ostStat_initial};
            newComponents{paramIx.tBegin} = components{paramIx.tBegin};
            newComponents{paramIx.rate1} = components{paramIx.rate1};
            newComponents{paramIx.dur1} = components{paramIx.dur1};
            newComponents{paramIx.durHold} = components{paramIx.durHold};
            newComponents{paramIx.rate2} = components{paramIx.rate2};
            % At the end you just string them all together and then the only things that are different are the ones you
            % changed
            
        else
            warning('Something has gone horribly wrong; incorrect number of PCF line components. Stopping script')
            return
        end
        
            if strcmp(param,'perturb')
                % If you're editing the overall perturbation tell me how you want to accomplish this (by changing dur1 or rate1)
                if strcmp(param, 'perturb') && ~isempty(varargin)
                    paramToChange = varargin{1}; 
                else
                    paramToChange = input('Which parameter would you like to change in order to enact the perturbation? \nrate1 OR dur1: ','s');         
                end

                if strcmp(paramToChange, 'rate1'), otherParam = 'dur1'; end
                if strcmp(paramToChange, 'dur1'), otherParam = 'rate1'; end

                newValue = calcPertValue(paramToChange,param,targetVal,otherParam,str2double(components{paramIx.(otherParam)})); 
                if strcmp(paramToChange, 'rate1') && newValue >= 1
                    newValue = 0.999; % rate must always be under 1 otherwise it'll error 
                end
                newComponents{paramIx.(paramToChange)} = sprintf('%.3f',newValue);
                varargout{1} = newComponents{paramIx.(paramToChange)}; 

            elseif strcmp(param,'rate1') || strcmp(param,'dur1')
                % Give me the "other" param (the one you're not changing) 
                if strcmp(param, 'rate1'), otherParam = 'dur1'; end
                if strcmp(param, 'dur1'), otherParam = 'rate1'; end

                % Check if they've already specified whether or not they would like to maintain perturbation 
                if ~isempty(varargin)
                    keepTotalPerturb = varargin{1};
                else 
                    keepTotalPerturb = input(['Do you want to keep the overall perturbation the same? This would also change ' otherParam...
                    '. \ny/n: '],'s'); 
                end

                if strcmp(keepTotalPerturb,'y') % then you'll have to calculate the new "otherParam" to keep overall perturbation the same
                    currentPerturb = calcPertValue('perturb','dur1',str2double(components{paramIx.dur1}),'rate1',str2double(components{paramIx.rate1}));
                    newComponents{paramIx.(otherParam)} = sprintf('%.3f',calcPertValue(otherParam, 'perturb',currentPerturb, param,targetVal));
                    varargout{1} = newComponents{paramIx.(otherParam)}; 
                end

                % Now change the one you actually meant to change (this has to happen in either case) 
                newComponents{paramIx.(param)} = sprintf('%.3f',targetVal); 

            else % Everything else (durHold, rate2, tBegin...) can just be entered straight in with no other calcs
                if strcmp(param,'ostStat_initial')
                    newComponents{paramIx.(param)} = sprintf('%.0f', targetVal); 
                else
                    newComponents{paramIx.(param)} = sprintf('%.3f',targetVal); % no change
                end
            end
        
    case 'space'
        
        % set up structure with the different component indices
        paramIx.stat = 1;
        paramIx.pitchShift = 2;
        paramIx.gainShift = 3;
        paramIx.fmtPertAmp = 4;
        paramIx.fmtPertPhi = 5;

        % Initialize new components by copying
        newComponents{paramIx.stat} = components{paramIx.stat};
        newComponents{paramIx.pitchShift} = components{paramIx.pitchShift};
        newComponents{paramIx.gainShift} = components{paramIx.gainShift};
        newComponents{paramIx.fmtPertAmp} = components{paramIx.fmtPertAmp};
        newComponents{paramIx.fmtPertPhi} = components{paramIx.fmtPertPhi};

        % Put in new value for desired parameter
        newComponents{paramIx.(param)} = sprintf(' %.3f',targetVal); 
        
end
        
finfo{lineloc} = strjoin(newComponents,', ');   % test change rk 2/8/2021

% Write to working file
fid = fopen(pcfFile,'w');
for i = 1:numel(finfo)
    if finfo{i+1} == -1
        fprintf(fid,'%s', finfo{i});
        break
    else
        fprintf(fid,'%s\n', finfo{i});
    end
end
fclose(fid);

end