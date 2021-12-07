function [] = gen_sigInOutWavs(dataPath)
%GEN_SIGINOUTWAVS generate wav files for the signalIn and signalOut from a
%data.mat
%   GEN_SIGINOUTWAVS(DATAPATH)
%       Given a DATAPATH containing a data.mat file, this function uses
%       MATLAB's audiowrite to write the data's signalIn and signalOut
%       fields to .wav files. Prompts the user for the location to save the
%       files, creating folders 'signalIn' and 'signalOut' inside.
%
%       TODO: just need to test that this works properly on a mac. 

%% default arguments
if nargin < 1 || isempty(dataPath)
    warning('No dataPath provided, using current MATLAB working directory');
    dataPath = cd; 
end %attempt to load data from current directory


%% load data.mat, set up useful values
load(fullfile(dataPath,'data.mat'),'data');

%find sample rate of data.
if isfield(data(1).params,'sr')
    sampleRate = data(1).params.sr;
else
    sampleRate = data(1).params.fs;
end

%find default save path
user = getenv('USERNAME');
if ispc
    defaultPath = fullfile('C:\Users',user);
elseif ismac
    defaultPath = fullfile('/Users',user);
end

%let user choose the save path
fprintf('\nPlease select the folder where the wav files should be saved\n');
savePath =  uigetdir(defaultPath,'Select the folder where the Wav files should be saved:');
mkdir(savePath,'signalIn');
mkdir(savePath,'signalOut');
sigInPath = fullfile(savePath,'signalIn');
sigOutPath = fullfile(savePath,'signalOut');

%% main loop over trials to write wav files
for trialNum = 1:length(data)
   sigIn = data(trialNum).signalIn;
   sigOut = data(trialNum).signalOut;
   sigInWavfile = fullfile(sigInPath,sprintf('signalIn_%03d.wav',trialNum));
   sigOutWavfile = fullfile(sigOutPath,sprintf('signalOut_%03d.wav',trialNum));
   audiowrite(sigInWavfile,sigIn,sampleRate);
   audiowrite(sigOutWavfile,sigOut,sampleRate);
end

%tell user where the files were written
fprintf('\nWrote %d trials to wav files. \n\nStored signalIn and signalOut in %s \nand %s respectively.\n', length(data), sigInPath, sigOutPath);

