function [] = gen_dataVals_from_audapterdata(dataPath,trialdir,OSTtarget, bSaveCheck)
%GEN_DATAVALS_FROM_AUDAPTERDATA create dataVals from audapter
%   GEN_DATAVALS_FROM_AUDAPTERDATA(DATAPATH,TRIALDIR,BSAVECHECK) use
%   data.mat audpater fmts and sfmts to create dataVals


if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trialdir), trialdir = 'trials'; end
if nargin < 3, OSTtarget = []; end
if nargin < 4 || isempty(bSaveCheck), bSaveCheck = 1; end


savefile = fullfile(dataPath,sprintf('dataVals%s_audapter.mat',trialdir(7:end)));
if bSaveCheck
    bSave = savecheck(savefile);
else
    bSave = 1;
end
if ~bSave, return; end


load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,'data.mat'));
dataVals = struct([]);
shortTracks = [];

% set onset and offset thresholds
onsetThresh = .04;
offsetThresh = .04;


for trialnum = 1:length(data)
    if isempty(OSTtarget)
        % find onset using threshold for rms
        rms = data(trialnum).rms(:,1);
        onsetInd = min(find(rms > onsetThresh));  % finds onsetInd: firt index in rms that is above onsetThresh
        offsetInd = min(find(rms(onsetInd+1:end) < offsetThresh)) + onsetInd;  % finds offsetInd: first index after onsetInd+1 that is below offsetThresh 
    else
        ost = data(trialnum).ost_stat;
        OSTinterval = find(ost == OSTtarget);
        onsetInd = OSTinterval(1);
        offsetInd = OSTinterval(end);
    end
    % find onset and offset times
    t_intervals = (data(trialnum).intervals)./data(trialnum).params.sr;  % convert intervals from samples to seconds
    onset_time = t_intervals(onsetInd);
    offset_time = t_intervals(offsetInd);
    
    
    %     dataVals(i).f0 = sigmat.pitch(onsetIndf0:offsetIndf0)';                     % f0 track from onset to offset
    dataVals(trialnum).f1 = data(trialnum).fmts(onsetInd:offsetInd,1);                  % f1 track from onset to offset
    dataVals(trialnum).f2 = data(trialnum).fmts(onsetInd:offsetInd,2);                  % f2 track from onset to offset
    dataVals(trialnum).f3 = data(trialnum).fmts(onsetInd:offsetInd,3);
    dataVals(trialnum).int = data(trialnum).rms(onsetInd:offsetInd,1);                   % intensity (rms amplitude) track from onset to offset
    %     dataVals(trialnum).pitch_taxis = sigmat.pitch_taxis(onsetInd:offsetInd)';      % pitch time axis
    dataVals(trialnum).ftrack_taxis = t_intervals(onsetInd:offsetInd);    % formant time axis
    %     dataVals(trialnum).ampl_taxis = sigmat.ampl_taxis(onsetIndAmp:offsetIndAmp)';      % amplitude time axis
    dataVals(trialnum).dur = offset_time - onset_time;                                 % duration
    dataVals(trialnum).word = expt.allWords(trialnum);                                 % numerical index to word list (e.g. 2)
    dataVals(trialnum).vowel = expt.allVowels(trialnum);                               % numerical index to vowel list (e.g. 1)
    if isfield(expt,'allColors')
        dataVals(trialnum).color = expt.allColors(trialnum);                           % numerical index to color list (e.g. 1)
    end
    dataVals(trialnum).cond = expt.allConds(trialnum);                                 % numerical index to condition list (e.g. 1)
    dataVals(trialnum).token = trialnum;                                               % trial number (e.g. 22)
    dataVals(trialnum).bExcl = 0;                                                      % binary variable: 1 = exclude trial, 0 = don't exclude trial
    
    % warn about short tracks
    if sum(~isnan(dataVals(trialnum).f1)) < 20
        shortTracks = [shortTracks dataVals(trialnum).token];
        warning('Short formant track: trial %d',dataVals(trialnum).token);
    end
end

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(data),savefile)

end

