function [] =  forcedAlignment_mfa2(dataPath,exptfield,alignOnly,language)
% FORCEDALIGNMENT_MFA2.0 Use the montreal forced aligner (v2.0+) on experiment data
%   FORCEDALIGNMENT_MFA2.0(DATAPATH,EXPTFIELD,ALIGNONLY, LANGUAGE)
%   Generates WAV and LAB files for each data value in the DATAPATH
%   directory's data.mat file, then runs the aligner on those files.
%   This path must contain a file called data.mat with each trial n stored
%   in data(n). Needs expt.mat to make txt file. EXPTFIELD is the parameter
%   that corresponds to the word being said in the WAV file. (ex. Stroop
%   expriements may need to use the color rather than the word shown to
%   the participant). ALIGNONLY is a boolean variable for skipping the
%   input lab/wav generation if those files already exist. LANGUAGE is used
%   to specify which model and dictionary the mfa function call should use.
%   (May need to download the model and dict for your language of interest
%   first, see KB doc and MFA documentation).

%Set up correct python env
user = getenv('USERNAME'); %TODO: change this to public if we install for everyone on lab machines.
pyloc = fullfile('C:\Users\',user,'\Anaconda3\envs\aligner');
if ~exist(pyloc, 'dir')
        prompt = sprintf('The aligner environment does not appear to be configured correctly in %s. Try to align anyway? (y/n) ', pyloc);
        response = input(prompt,'s');
        while ~strcmpi(response, {'y','n'})
            response = input('Please provide y for yes or n for no: ','s');
        end
        if strcmpi(response,'n')
            fprintf('See the KB doc on installing MFA for instructions on setting up the aligner conda environment \n')
            return
        end
end

%  Determine whether or not the script is being run on a Mac or PC,
%  set the correct expected location of the montreal forced aligner files.
if ismac
    alignerLocation = '/Applications/montreal-forced-aligner';
elseif ispc
    alignerLocation = '\\wcs-cifs\wc\smng\montreal-forced-aligner';
end

%  Handle various user-given arguments
dbstop if error
if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(alignOnly), alignOnly = 0; end
if nargin < 4 || isempty(language)
    dictionary = fullfile(alignerLocation,'librispeech-lexicon.txt');
    language = 'english';
else
    dictionary = language;
end

% Load expt file and establish list of stimuli
load(fullfile(dataPath,'expt.mat'), 'expt');
if nargin < 2 || isempty(exptfield)
    wordlist = expt.words(expt.allWords);
else
    wordlist = expt.(exptfield);
end

%% Create variables that hold the locations to:
%      - A folder for the generated WAV/LAB files (called "PreAlignment")
%      - The executable mfa_align file that performs the alignment
%      - A folder for the generated TEXTGRID files (called "PostAlignment")

filename = fullfile(dataPath,'PreAlignment');
if ~exist(filename, 'dir')
    mkdir(filename)
end
outputLocation = fullfile(dataPath,'PostAlignment');
if ~exist(outputLocation, 'dir')
    mkdir(outputLocation)
end

%% Create a WAV and TXT file for each data value
if ~alignOnly
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
        modifiedTxtName = fullfile(filename,sprintf('%s%d%s','AudioData_',i,'.lab'));
        fid = fopen(modifiedTxtName,'wt');
        fprintf(fid,'%s',word);
        fclose(fid);
        
        %create wav file
        modifiedWavName = fullfile(filename,sprintf('%s%d%s','AudioData_',i,'.wav'));
        audiowrite(modifiedWavName,signalData,sampleRate);
    end
end

% Set up and run python mfa align command
%TODO: This has only been tested on windows?
fprintf('Calling conda to run MFA... \n');
command = sprintf('conda activate aligner & mfa align --clean %s %s %s %s ', filename, dictionary, language, outputLocation);
system(command)
fprintf('Conda call completed. Returned to Matlab.\n');

disp("Check the console output and PostAlignment folder to be sure that your TextGrid files have been successfully created.");
return

end % % EOF


