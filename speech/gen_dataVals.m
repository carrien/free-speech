function [] = gen_dataVals(exptName,subdirname,snum,trialdir,excl)
%GEN_DATAVALS  Scrape subject trial files for data and save.
%   GEN_DATAVALS(EXPTNAME,SUBDIRNAME,SNUM,TRIALDIR,EXCL) scrapes the files
%   of a single subject (SNUM) from that subject's TRIALDIR directory and
%   collects formant data into a single mat file.
%
%CN 3/2010

if nargin < 5, excl = []; end
if nargin < 4 || isempty(trialdir), trialdir = 'trials'; end

dataPath = getAcoustSubjPath(exptName,snum,subdirname,'formant_analysis');
trialPath = fullfile(dataPath,trialdir); % e.g. trials; trials_default
W = what(trialPath);
matFiles = [W.mat];

% Strip off '.mat' and sort
filenums = zeros(1,length(matFiles));
for i = 1:length(matFiles)
    [~, name, ext] = fileparts(matFiles{i});
    filenums(i) = str2double(name);
end
sortedfiles = sort(filenums);

% Toss out exclusions
goodfiles = setdiff(sortedfiles,excl);

% Append '.mat' and load
for i = 1:length(goodfiles)
    filename = [num2str(goodfiles(i)) ext];
    load(fullfile(trialPath,filename));
    dataVals(i) = sigmat; %#ok<NASGU,AGROW> Each dataVal is a struct array of f0/f1/f2/dur etc.
end

savefile = fullfile(dataPath,sprintf('dataVals%s.mat',trialdir(7:end)));
bSave = savecheck(savefile);
if bSave, save(savefile, 'dataVals'); end