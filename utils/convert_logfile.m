function [ ] = convert_logfile(dataPath,infilename,outfilename)
%CONVERT_LOGFILE  Convert JSON logfile to Matlab struct array.
%   CONVERT_LOGFILE(DATAPATH) loads a JSON object found in DATAPATH
%   containing experiment stimulus and timing information and converts it
%   to a matfile, saving it as exptlog.mat in the same DATAPATH.

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(infilename), infilename = 'exptlog'; end
if nargin < 3 || isempty(outfilename), outfilename = infilename; end

jsonfile = sprintf('%s.json',infilename);
M = loadjson(fullfile(dataPath,jsonfile));

for tr=1:length(M)
    exptlog(tr) = M{tr}; %#ok<AGROW,NASGU>
end

savefile = fullfile(dataPath,sprintf('%s.mat',outfilename));
save(savefile,'exptlog')
fprintf('Saved %s\n',savefile)

end