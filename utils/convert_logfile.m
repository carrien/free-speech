function [ ] = convert_logfile(dataPath)
%CONVERT_LOGFILE  Convert JSON logfile to Matlab struct array.
%   CONVERT_LOGFILE(DATAPATH) loads a JSON object found in DATAPATH
%   containing experiment stimulus and timing information and converts it
%   to a matfile, saving it as exptlog.mat in the same DATAPATH.

%M = loadjson(fullfile(dataPath,'exptlog.txt'));
M = loadjson(fullfile(dataPath,'exptlog.json'));

fieldns = fieldnames(M);
trialfield = fieldns{2};

for tr=1:length(M.(trialfield))
    trialinfo = M.(trialfield){tr};
    if ~isfield(trialinfo,'uttStartTime'), trialinfo.uttStartTime = []; end
    if ~isfield(trialinfo,'duration'), trialinfo.duration = []; end
    exptlog(tr) = trialinfo;
end

savefile = fullfile(dataPath,'exptlog.mat');
save(savefile,'exptlog')
fprintf('Saved %s\n',savefile)

end