function [] =  forcedAlignment(params)
% TODO header

% 2024-10 CWN compiled into one function

%% set parameters
defaultParams.version = 3;
defaultParams.dataPath = pwd;
defaultParams.cmdLocation = '%windir%\System32\cmd.exe';
defaultParams.activatePath = fullfile('C:\ProgramData\miniconda3\Scripts\activate.bat');
defaultParams.exptfield = 'listWords';
defaultParams.wordlist = [];
defaultParams.genfilesOrAlign = 'both';
if ismac
    defaultParams.alignerLocation = '/Applications/montreal-forced-aligner';
elseif ispc
    defaultParams.alignerLocation = 'C:\Users\Public\Documents\software\montreal-forced-aligner';
end
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
        defaultParams.dictionary = 'english_us_arpa';
        defaultParams.language = 'english_us_arpa';
    case 3
        defaultParams.dictionary = 'librispeech-lexicon.txt';
        defaultParams.language = 'english';
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
            disp("The montreal-forced-aligner folder has not been placed in the proper directory on this machine, the script will now exit");
            return
        else
            dictionaryPath = fullfile(params.alignerLocation,params.dictionary);
            if ~exist(dictionaryPath, 'file')
                fprintf('Couldn''t find file %s. Exiting script.\n', dictionaryPath);
                return
            end
        end

        % make AudioData files
        makeAudioData

        % run forced aligner
        executableLocation = fullfile(params.alignerLocation,'bin','mfa_align');
        command = sprintf('%s %s %s %s %s',executableLocation , prealignFolder, dictionaryPath, params.language, postalignFolder);
        system(command)

        % user message
        fprintf('Generated TextGrid files')

    case 2
        %% MFA version 2
        disp('MFA version 2 not supported.')
        return
    case 3
        %% MFA version 3

        activateDir = fileparts(params.activatePath);
        if ~exist(activateDir, 'dir')
            prompt = sprintf('The aligner environment does not appear to be configured correctly in %s. Try to align anyway?', activateDir);
            response = askNChoiceQuestion(prompt,{'y' 'n'});
            if strcmpi(response,'n')
                fprintf('See the KB doc on installing MFA for instructions on setting up the aligner conda environment \n')
                return
            end
        end

        % make AudioData files
        makeAudioData

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
        for i = 1:length(trialNums)
            % make lab file
            iTrial = trialNums(i);

            word = upper(string(params.wordlist(i)));
            modifiedTxtName = fullfile(filename,sprintf('%s%d%s','AudioData_',iTrial,'.lab'));
            fid = fopen(modifiedTxtName,'wt');
            fprintf(fid,'%s',word);
            fclose(fid);

            %make wav file
            modifiedWavName = fullfile(prealignFolder,sprintf('%s%d%s','AudioData_',i,'.wav'));
            audiowrite(modifiedWavName,signalData,sampleRate);
        end
    end


end %EOF

