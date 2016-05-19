function [ ] = merge_logfile(dataPath,infilenames,outfilename)
%MERGE_LOGFILE  Merge two logfiles in Matlab struct format.
%   MERGE_LOGFILE(DATAPATH,INFILENAMES,OUTFILENAME) loads the Matlab struct
%   files listed in INFILENAMES and merges them into a single struct file
%   with consecutive numbering, saving it as OUTFILENAME in the same
%   DATAPATH.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(infilenames), infilenames = {'exptlog1' 'exptlog2'}; end
if nargin < 3 || isempty(outfilename), outfilename = 'exptlog'; end

baselog = fullfile(dataPath,infilenames{1});
load(baselog);

for bl=2:length(infilenames)
    ntrials = length(exptlog);
    log2merge = load(fullfile(dataPath,infilenames{bl}));
    for tr=1:length(log2merge.exptlog)
        log2merge.exptlog(tr).trialNum = log2merge.exptlog(tr).trialNum + ntrials;
    end
    exptlog(end+1:end+length(log2merge.exptlog)) = log2merge.exptlog;
end

savefile = fullfile(dataPath,sprintf('%s.mat',outfilename));
bSave = savecheck(savefile);
if bSave
    save(savefile,'exptlog')
    fprintf('Saved marged logfile as %s\n',savefile)
end
