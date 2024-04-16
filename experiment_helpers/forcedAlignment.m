function [] =  forcedAlignment(dataPath,exptfield, trialNums)%, language)

%% LANGUAGE FLAG IN PROGRESS; don't use the French dictionary. 'oe' - 'neuf'

%% If this file is moved or re-named, you will need to fix free-speech/experiment helpers/get_gitPath.m


% % FORCEDALIGNMENT Use the montreal forced aligner on experiment data
% %   FORCEDALIGNMENT(DATAPATH,EXPTFIELD)
% %   Generates WAV and TXT files for each data value in the DATAPATH
% %   directory's data.mat file, then runs the aligner on those files.
% %   This path must contain a file called data.mat with each trial n stored
% %   in data(n). Needs expt.mat to make txt file. EXPTFIELD is the parameter
% %   that corresponds to the word being said in the WAV file. (ex. Stroop
% %   expriements may need to use the color rather than the word shown to
% %   the participant)

%  ---> Indicates a line of code that is commented out
% %  ---> Indicates a comment

% % Handle various user-given arguments
% % TODO: Allow for the manual indication of pre/post alignment folder
% % locations via input arguments
dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = cd; end


fprintf('Loading data... ');
% % load data
load(fullfile(dataPath,'data.mat'), 'data');
load(fullfile(dataPath,'expt.mat'), 'expt');
fprintf('done.\n');

if nargin < 2 || isempty(exptfield)
    wordlist = expt.words(expt.allWords);
elseif iscell(exptfield)
    wordlist = exptfield;
elseif isfield(expt, exptfield)
    wordlist = expt.(exptfield);
end

if nargin < 3 || isempty(trialNums)
    trialNums = 1:length(data);
end


%if nargin < 3 || isempty(language), language = 'english'; end
% % Determine whether or not the script is being run on a Mac or PC,
% % set the correct expected location of the montreal forced aligner files.

if ismac
    alignerLocation = '/Applications/montreal-forced-aligner';
elseif ispc
    alignerLocation = 'C:\Users\Public\Documents\software\montreal-forced-aligner';
end

% % Handle the incorrect placement of the aligner/dictionary files during installation

if ~exist(alignerLocation, 'dir')
    disp("The montreal-forced-aligner folder has not been placed in the proper directory on this machine, the script will now exit");
    return
else
    %    if strcmpi(language, 'french')
    %        dictionary = fullfile(alignerLocation,'fr.dict.txt');
    %    elseif strcmpi(language,'german')
    %        dictionary = fullfile(alignerLocation,'de.dict.txt');
    %    else
    dictionary = fullfile(alignerLocation,'librispeech-lexicon.txt');
    %    end
    if ~exist(dictionary, 'file')
        disp("The librispeech-lexicon dictionary file has not been placed in the montreal-forced-aligner folder, the script will now exit");
        return
    end
end

% % Create variables that hold the locations to:
% %     - A folder for the generated WAV/LAB files (called "PreAlignment")
% %     - The executable mfa_align file that performs the alignment
% %     - A folder for the generated TEXTGRID files (called "PostAlignment")

filename = fullfile(dataPath,'PreAlignment');
if ~exist(filename, 'dir')
    mkdir(filename)
end
outputLocation = fullfile(dataPath,'PostAlignment');
if ~exist(outputLocation, 'dir')
    mkdir(outputLocation)
end
executableLocation = fullfile(alignerLocation,'bin','mfa_align');


% % Create a WAV and TXT file for each data value, srFLAG is a sentinel value
% % for handling the case where the sample rate is < 16000 but the user wants to continue
% % TODO: Should we even allow this?
srFlag = false;

for i=1:length(trialNums)
    % iTrial and i are identical except when trialNums was passed in.
    % Then, i is the loop position. iTrial is the trial number.
    iTrial = trialNums(i); 

    word = upper(string(wordlist(i)));
    modifiedTxtName = fullfile(filename,sprintf('%s%d%s','AudioData_',iTrial,'.lab'));
    fid = fopen(modifiedTxtName,'wt');
    fprintf(fid,'%s',word);
    fclose(fid);
    
    % %      Depending on the experiment, the parameter for the sample rate may be
    % %      named differently, check for that here
    signalData = data(iTrial).signalIn;
    if isfield(data(iTrial).params,'sr')
        sampleRate = data(iTrial).params.sr;
    else
        sampleRate = data(iTrial).params.fs;
    end
    
    
    % %      Figure out what the user wants to do if the sample rate is
    % %      unsupported
    % %      TODO: Maybe try to incorporate the data validator here? If not here,
    % %      maybe try to validate the data prior to even running the script?
    
    if sampleRate < 16000 && srFlag == false
        prompt = 'Sample rate is less than 16000, may have issues running these files through the aligner, try anyway? y / n ';
        response = input(prompt);
        if strcmp(response,'y')
            srFlag = true;
            modifiedWavName = fullfile(filename,sprintf('%s%d%s','AudioData_',iTrial,'.wav'));
            audiowrite(modifiedWavName,signalData,sampleRate);
            continue
            
        elseif strcmp(response,'n')
            disp("Cleaning up and Exiting script...");
            return
        end
    end
    modifiedWavName = fullfile(filename,sprintf('%s%d%s','AudioData_',iTrial,'.wav'));
    audiowrite(modifiedWavName,signalData,sampleRate);
    % %      TODO: Display percent complete?
end

% % At least in windows, another conditional for mac?
command = sprintf('%s %s %s %s %s',executableLocation , filename, dictionary, 'english', outputLocation); %language
system(command)

% % TODO: check whether or not the TextGrids were properly created?
% % end the alignment part of the script

% % Clean up
% % TODO: Delete wav/text files folder (prealignment)
% % rmdir(filenameChar)?

disp("The TextGrid files have been successfully created and are located in the PostAlignment folder");
return

end % % EOF
