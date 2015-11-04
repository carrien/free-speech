function [data] = gen_acousticdata_fusp(dataPath,nblocks,savePath)
%GEN_ACOUSTICDATA_FUSP  Generates matlab-readable data from a fusp run.
%   GEN_ACOUSTICDATA_FUSP(DATAPATH,NBLOCKS,SAVEPATH) extracts inbuffer
%   (microphone) and outbuffer (headphone) signals for a single fusp run.
%   DATAPATH is the dataset directory (e.g., expr/speak/); NBLOCKS is the
%   number of blocks (e.g. block0-block5 --> n = 6). The signals are saved
%   to a struct array called data.mat in SAVEPATH.
%
%CN 5/2011

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(nblocks)
    exprparams = load(fullfile(dataPath,'exprparams.mat'));
    nblocks = exprparams.nblocks;
end
if nargin < 3 || isempty(savePath), savePath = dataPath; end

savefile = fullfile(savePath,'data.mat');
bSave = savecheck(savefile);
if ~bSave, data = []; return; end

% get vec hists
currdir = pwd;
cd(dataPath) % must be in experiment subdir for get_vec_hist to find files
for nb=1:nblocks
    vechist_in(nb) = get_vec_hist6('inbuffer',3,nb); % 1-indexed blocks
    vechist_out(nb) = get_vec_hist6('outbuffer',3,nb); %#ok<*AGROW>
end
if ~exist('exprparams','var'), exprparams = load('exprparams.mat'); end
cd(currdir)

ntrials = vechist_in(nb).ntrials; % assumes same number of trials per block

for nb = 1:nblocks  % for each block
    for nt = 1:ntrials;  % for each trial
        n = nt+ntrials*(nb-1);
        data(n).params.fs = exprparams.fs;
        if isfield(exprparams,'nlpc')
            data(n).params.nlpc = exprparams.nlpc;
        end 
        data(n).signalIn = plot_vec_hist6(vechist_in(nb),nt);
        data(n).signalOut = plot_vec_hist6(vechist_out(nb),nt);
    end
end

if ~exist(savePath,'dir')
   mkdir(savePath); 
end
save(savefile,'data');