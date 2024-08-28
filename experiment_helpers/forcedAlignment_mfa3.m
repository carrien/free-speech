function [] =  forcedAlignment_mfa3(dataPath,exptfield,genfilesOrAlign,language,dictionary)
% FORCEDALIGNMENT_MFA3.0 Use the montreal forced aligner (v3.0+) on experiment data
%   FORCEDALIGNMENT_MFA3.0(DATAPATH,EXPTFIELD,ALIGNONLY, LANGUAGE)
%
%   Generates WAV and LAB files for each data value in the DATAPATH directory's data.mat file, then runs the aligner on those
%   files.
% 
%   This path must contain a file called data.mat with each trial n stored in data(n). Needs expt.mat to make txt file. 
% 
%   Input arguments: 
%       1 dataPath      the folder that you are getting data and expt from. Defaults to pwd. Assumes that you will have (or
%       create) pre-alignment files in a subfolder called PreAlignment, and puts post-alignment label files in subfolder
%       called PostAlignment. 
% 
%       2 exptfield     the field in expt that you want to use to label the file, e.g. listWords or listStimulusText.
%       Defaults to listWords 
% 
%       3 genfilesOrAlign     'gen', 'align', or 'both'. Generate alignment structures, align already made structures, or
%       both. 
%
%       4 language      language that you want to use. Defaults to english_us_arpa
% 
%       5 dictionary    dictionary that you want to use. Defaults to whatever language is. 
% 
%   Outputs: 
%       - files in PostAlignment folder in dataPath with alignments
% 
% Note: this is written for NeSST Lab setup, which may differ from SMNG. 
%   - Python version is 3.11. There were some irreconcilable errors with 3.12 (was the most recent Python version at the
%   time, 4/9/2024). 
%   - MFA version is 3.0.2
%   

%% 

activater = fullfile('C:\ProgramData\miniconda3\Scripts\activate.bat');
cmdLocation = '%windir%\System32\cmd.exe'; 
activateLocation = fileparts(activater); 
if ~exist(activateLocation, 'dir')
        prompt = sprintf('The aligner environment does not appear to be configured correctly in %s. Try to align anyway?', activateLocation);
        response = askNChoiceQuestion(prompt,{'y' 'n'});
        if strcmpi(response,'n')
            fprintf('See the KB doc on installing MFA for instructions on setting up the aligner conda environment \n')
            return
        end
end

%  Determine whether or not the script is being run on a Mac or PC,
%  set the correct expected location of the montreal forced aligner files.
% I don't know if this is actually necessary? 
if ismac
    alignerLocation = '/Applications/montreal-forced-aligner'; % THIS IS NOT UPDATED. I HAVE NO MACS
elseif ispc
    alignerLocation = 'C:\Users\Public\Documents\software\.conda\envs\aligner';
end

%  Handle various user-given arguments
dbstop if error
if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(genfilesOrAlign), genfilesOrAlign = 'both'; end
if nargin < 4 || isempty(language), language = 'english_us_arpa'; end % this might be a new update 
if nargin < 5 || isempty(dictionary), dictionary = language; end

% Load expt file and establish list of stimuli
load(fullfile(dataPath,'expt.mat'), 'expt');
if nargin < 2 || isempty(exptfield), exptfield = 'listWords'; end 
wordlist = expt.(exptfield);

%% Create variables that hold the locations to:
%      - A folder for the generated WAV/LAB files (called "PreAlignment")
%      - The executable mfa_align file that performs the alignment
%      - A folder for the generated TEXTGRID files (called "PostAlignment")

prealignTag = 'PreAlignment'; 
postalignTag = 'PostAlignment'; 

prealignFolder = fullfile(dataPath,prealignTag);
if ~exist(prealignFolder, 'dir')
    mkdir(prealignFolder)
end
outputLocation = fullfile(dataPath,postalignTag);
if ~exist(outputLocation, 'dir')
    mkdir(outputLocation)
end

%% Create a WAV and TXT file for each data value
if ~strcmp(genfilesOrAlign, 'align')
    fprintf('Loading data... \n');
    % % load data
    load(fullfile(dataPath,'data.mat'), 'data');
    fprintf('Finished loading data.\n')
    
    % Depending on the experiment, the parameter for the sample rate may be
    % named differently, check for that here and provide a warning if it
    % is lower than 16000. NOTE: this may not have an effect on the quality of
    % the alignment, but sample rates below 16000 were not compatible with the
    % old aligner so it might be worth noting.
    if isfield(data(1).params,'sr')
        sampleRate = data(1).params.sr;
    else
        sampleRate = data(1).params.fs;
    end
    
    % NOTE: this should not cause issues in MFA 2.0+, but I am not
    % sure how a low sampling rate influences the alignment quality
    % yet.
    if sampleRate < 16000
        warning('FYI, the sample rate of this data is less than 16000');
    end
    
    for i=1:length(data)
        word = upper(string(wordlist(i)));
        signalData = data(i).signalIn;
        
        %create lab file
        modifiedTxtName = fullfile(prealignFolder,sprintf('%s%d%s','AudioData_',i,'.lab'));
        fid = fopen(modifiedTxtName,'wt');
        fprintf(fid,'%s',word);
        fclose(fid);
        
        %create wav file
        modifiedWavName = fullfile(prealignFolder,sprintf('%s%d%s','AudioData_',i,'.wav'));
        audiowrite(modifiedWavName,signalData,sampleRate);
    end
end

%%
% Set up and run python mfa align command
% NOTE THIS IS A REALLY JANKY WAY TO DO THIS BUT I DO NOT KNOW HOW TO DO IT BETTER
if ~strcmp(genfilesOrAlign, 'gen')
    fprintf('Calling conda to run MFA... \n');
    
    % Get current directory so you can return to it 
    currentDir = pwd; 
    
    % Then change working directory to the datapath 
    cd(dataPath); 
    
    % Create the mfa command and then copy it to the clipboard so the user can paste it in 
    mfaCommand = sprintf('%s ./%s %s %s ./%s', 'mfa align --clean', prealignTag, language, dictionary, postalignTag); 
    clipboard('copy', mfaCommand); 
    warning(sprintf(['The alignment command has been copied to your clipboard. \n' ...
        'When the CMD interface appears in the MATLAB Command Window, paste the command into the command window and hit enter.\n'...
        'When alignment is complete, type exit, and hit enter'])); 
    fprintf('\n\n')
    ack = askNChoiceQuestion('Enter Y to acknowledge:', {'y' 'Y'}, 0); 
    
    % Run system command
    systemCommand = sprintf('%s %s %s %s', cmdLocation, '"/K"', activater, alignerLocation); 
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



end % % EOF