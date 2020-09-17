function [] = track_signalOut_from_signalIn(acousticDP,outputfolder)


if nargin<1 || isempty(acousticDP), acousticDP = cd; end
if nargin<2 || isempty(outputfolder), outputfolder='trials_out'; end
outputDP = fullfile(acousticDP,outputfolder);
if ~exist(outputDP)
    mkdir(outputDP)
end

load(fullfile(acousticDP,'data.mat'))

for d = 1:length(data)
    y = data(d).signalOut;
    fs = data(d).params.sr;
    
    tr2load = [num2str(d) '.mat'];
    load(fullfile(acousticDP,'trials',tr2load),'trialparams') % not sigmat
    %trialparams.sigproc_params.ampl_thresh4voicing=0; % seems to be a tracking problem
    sigproc_params = trialparams.sigproc_params;
    % take the rest from waverunner
    
    savefile = fullfile(outputDP,tr2load);
    tracks = wave_proc(y,sigproc_params); % run tracker
    sigmat = tracks;
    save(savefile,'sigmat','trialparams');
end

gen_dataVals_stress(acousticDP,outputfolder)

