function [ ] = gen_reaper_f0data(exptName,snum,subdir,frange)
%GEN_REAPER_F0DATA  Run reaper pitch tracker on all trials of a subject.
%   GEN_REAPER_F0DATA(EXPTNAME,SNUM,SUBDIR) runs the reaper pitch tracker
%   on all trials of SNUM's acoustic data. Data are converted to wav files
%   if necessary. Reaper writes out .f0 files which are then read in and
%   saved as reaperdata.mat in the subject's directory.

if nargin < 3, subdir = []; end
if nargin < 4, frange = []; end

dataPath = getAcoustSubjPath(exptName,snum,subdir);
load(fullfile(dataPath,'data.mat'));

% write out wav files (if not already there)
if ~exist(fullfile(dataPath,'wavs'),'dir') || isempty(ls(fullfile(dataPath,'wavs')));
    fprintf('Writing wav files... ');
    gen_wavs_from_datastruct(exptName,snum,subdir);
    fprintf('done.\n');
else
    fprintf('wav files exist.\n')
end

% run reaper on wavs
parpool;
fprintf('Running reaper on %d wav files.\n',length(data))
if ~isempty(frange)
fprintf('Calculating f0 tracks between %d and %d Hz.\n',frange(1),frange(2))
end
parfor i=1:length(data)
    filenamestr = fullfile(dataPath,'wavs',sprintf('%03d',i));
    [status,res] = gen_reaper_f0track(filenamestr,frange);
    if status
        fprintf('Failed to write %s.f0: %s',filenamestr,res)
        continue;
    end
end
parpool close;

fprintf('Importing reaper outfile files... ')
for i=1:length(data)
    filenamestr = fullfile(dataPath,'wavs',sprintf('%03d',i));
    reaperdata(i) = read_reaper_f0track(filenamestr); %#ok<AGROW,NASGU>
end

savefile = fullfile(dataPath,'reaperdata.mat');
save(savefile,'reaperdata');
fprintf('saved as %s.\n',savefile)