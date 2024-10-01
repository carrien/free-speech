function [] =  forcedAlignment(params)
% FORCEDALIGNMENT Runs the Montreal Forced Aligner on speech data
%   FORCEDALIGNMENT(params)
%
%   Generates .wav and .lab files for trials in a folder, then runs the
%   aligner on those files. Speech data must be in data.mat format.
%
%   By default this function runs MFA version 3. It also supports version 1
%
%   INPUT ARGUMENTS: `params` should be a struct. Default values are
%       in the `defaultParams` variable. These are the supported fields:
%   * version. MFA version number
%   * wordlist. A cell array of strings. The word which MFA will attempt to
%       align to on each trial. If empty, see exptfield param.
%   * exptfield. If wordlist is empty, this supplies the wordlist in the
%       format expt.(exptfield)
%   * trialNums. Which trial numbers to process.
%   * dataPath. The directory with data.mat and expt.mat speech
%       data. Output files will becomes subfolders in this folder.
%   * genfilesOrAlign. Can be 'gen', 'align', or 'both'. If 'gen', function
%       will generate AudioData TextGrid files only. If 'align', function
%       will only run MFA on existing TextGrid files. If 'both', function
%       will generate TextGrid files and run MFA on them.
%
%   These fields relate to the install location of MFA on your computer:
%   * cmdLocation. Filepath to cmd.exe
%   * activatePath. Filepath to Python's activate.bat
%   * alignerLocation. The filepath to the aligner
%
%   These fields relate to running MFA on other languages or dictionaries:
%   * dictionary. The name of the MFA dictionary to use.
%   * language. The name of the MFA language to use.

% 2024-10 Chris Naber compiled into one function. Previous programming by
%   Nick Comeau, Sarah Bakst, Robin Karlin, Lana Hantzsch and Chris Naber

%% set parameters
defaultParams.version = 3;
defaultParams.dataPath = pwd;
defaultParams.cmdLocation = '%windir%\System32\cmd.exe';
defaultParams.activatePath = fullfile('C:\ProgramData\miniconda3\Scripts\activate.bat');
defaultParams.exptfield = 'listWords';
defaultParams.wordlist = [];
defaultParams.genfilesOrAlign = 'both';
if nargin < 1, params = []; end
params = set_missingFields(params, defaultParams, 0);

% load data
fprintf('Loading data... ');
load(fullfile(params.dataPath,'data.mat'), 'data');
load(fullfile(params.dataPath,'expt.mat'), 'expt');
fprintf('done.\n');

% set wordlist
if isempty(params.wordlist)
    params.wordlist = expt.(params.exptfield);
else
    % You specified `wordlist` already. It should be a cell array of strings
end

% finish setting params
defaultParams.trialNums = 1:length(data);
switch params.version
    case 1
        defaultParams.dictionary = 'librispeech-lexicon.txt';
        defaultParams.language = 'english';
        defaultParams.alignerLocation = 'C:\Users\Public\Documents\software\montreal-forced-aligner';
    case 3
        defaultParams.dictionary = 'english_us_arpa';
        defaultParams.language = 'english_us_arpa';
        defaultParams.alignerLocation = 'C:\Users\Public\Documents\software\.conda\envs\aligner';
end
params = set_missingFields(params, defaultParams, 0);

%% make folders
prealignFolder = fullfile(params.dataPath,'PreAlignment');
if ~exist(prealignFolder, 'dir')
    mkdir(prealignFolder)
end
postalignFolder = fullfile(params.dataPath,'PostAlignment');
if ~exist(postalignFolder, 'dir')
    mkdir(postalignFolder)
end

%% get sampling rate
if isfield(data(1).params,'sr')
    sampleRate = data(1).params.sr;
else
    sampleRate = data(1).params.fs;
end

if params.version == 1 && sampleRate < 16000
    error('MFA version 1 doesn''t work with sampling rates lower than 16 kHz.')
end

switch params.version
    case 1
        %% MFA version 1
        % check for files
        if ~exist(params.alignerLocation, 'dir')
            fprintf('Ending script early. No montreal-forced-aligner folder at %s\n', params.alignerLocation);
            return
        else
            dictionaryPath = fullfile(params.alignerLocation,params.dictionary);
            if ~exist(dictionaryPath, 'file')
                fprintf('Couldn''t find file %s. Exiting script.\n', dictionaryPath);
                return
            end
        end

        % generate AudioData files
        fprintf('Generating AudioData files... ')
        makeAudioData
        fprintf('done.\n')

        % run forced aligner
        executableLocation = fullfile(params.alignerLocation,'bin','mfa_align');
        command = sprintf('%s %s %s %s %s',executableLocation , prealignFolder, dictionaryPath, params.language, postalignFolder);
        system(command)

        % user message
        fprintf('Generated TextGrid files.\n')

    case 2
        %% MFA version 2
        disp('MFA version 2 not supported.')
        return
    case 3
        %% MFA version 3
        % check for aligner install location
        activateDir = fileparts(params.activatePath);
        if ~exist(activateDir, 'dir')
            prompt = sprintf('The aligner environment does not appear to be configured correctly in %s. Try to align anyway?', activateDir);
            response = askNChoiceQuestion(prompt,{'y' 'n'});
            if strcmpi(response,'n')
                fprintf('See the KB doc on installing MFA for instructions on setting up the aligner conda environment \n')
                return
            end
        end

        % generate AudioData files
        fprintf('Generating AudioData files... ')
        makeAudioData
        fprintf('done.\n')

        % run forced aligner
        fprintf('Calling conda to run MFA... \n');

        % Get current directory so you can return to it
        currentDir = pwd;

        % Then change working directory to the datapath
        cd(params.dataPath);

        % Create the mfa command and then copy it to the clipboard so the user can paste it in
        mfaCommand = sprintf('%s ./%s %s %s ./%s', 'mfa align --clean', 'PreAlignment', params.language, params.dictionary, 'PostAlignment');
        clipboard('copy', mfaCommand);
        warning(sprintf(['The alignment command has been copied to your clipboard. \n' ...
            'When the CMD interface appears in the MATLAB Command Window, paste the command into the command window and hit enter.\n'...
            'When alignment is complete, type exit, and hit enter'])); %#ok<SPWRN>
        fprintf('\n\n')
        askNChoiceQuestion('Enter Y to acknowledge:', {'y' 'Y'}, 0);

        % Run system command
        systemCommand = sprintf('%s %s %s %s', params.cmdLocation, '"/K"', params.activatePath, params.alignerLocation);
        systemOutput = system(systemCommand);

        % Back in Matlab
        fprintf('Conda call completed. Returned to Matlab.\n');
        cd(currentDir)

        if ~systemOutput
            disp("Check the console output and PostAlignment folder to be sure that your TextGrid files have been successfully created.");
        else
            disp("There was an error. Please read the error message carefully.");
        end
end

    function [] = makeAudioData()
        % iTrial and i are identical except when trialNums was passed in.
        % Then, i is the loop position. iTrial is the trial number.
        for i = 1:length(params.trialNums)
            % make lab file
            iTrial = params.trialNums(i);

            word = upper(string(params.wordlist(i)));
            modifiedTxtName = fullfile(prealignFolder,sprintf('%s%d%s','AudioData_',iTrial,'.lab'));
            fid = fopen(modifiedTxtName,'wt');
            fprintf(fid,'%s',word);
            fclose(fid);

            %make wav file
            modifiedWavName = fullfile(prealignFolder,sprintf('%s%d%s','AudioData_',iTrial,'.wav'));
            signalData = data(iTrial).signalIn;
            audiowrite(modifiedWavName,signalData,sampleRate);
        end
    end


end %EOF
