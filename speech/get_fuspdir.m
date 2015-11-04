function [dataPaths] = get_fuspdir(exptName,snum,prefix,suffix)
%GET_FUSPDIR  Get path to fusp experiment directory.
%   GET_FUSPDIR(EXPTNAME,SNUM,PREFIX,SUFFIX) returns fusp experiment paths
%   that match a given experiment EXPTNAME and subject number SNUM.  PREFIX
%   and SUFFIX are optional arguments that define strings to match before
%   and after the subject number, respectively.

if nargin < 3 || isempty(prefix), prefix = []; end
if nargin < 4 || isempty(suffix), suffix = []; end

acoustPath = getAcoustSubjPath(exptName);
dirstruct = dir(fullfile(acoustPath,'rawfusp',sprintf('*%s*%02d%s*',prefix,snum,suffix)));

if isempty(dirstruct)
    error('No matching directories found.')
end
fprintf('%d matching directories found.\n',length(dirstruct));
fuspdir = {dirstruct.name};

dataPaths = cell(1,length(fuspdir));
for i=1:length(fuspdir)
    dataPaths{i} = fullfile(getAcoustSubjPath(exptName),'rawfusp',fuspdir{i},'speak');
end