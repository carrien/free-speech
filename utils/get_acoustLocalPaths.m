function [dataPaths] = get_acoustLocalPaths(exptName,svec,varargin)
%GET_ACOUSTLOCALPATHS  Get local path for multiple subjects in an experiment.
%   DATAPATHS = GET_ACOUSTLOCALPATHS(EXPTNAME,SVEC,VARARGIN) returns the
%   cell array DATAPATHS of local paths to data for multiple subjects in an
%   experiment. SVEC can either be a vector of numerical IDs or a cell
%   array of character IDs.

dataPaths = cell(1,length(svec));

for s=1:length(svec)
    if isnumeric(svec)
        dataPaths{s} = get_acoustLocalPath(exptName,svec(s),varargin{:});
    else
        dataPaths{s} = get_acoustLocalPath(exptName,svec{s},varargin{:});
    end
end

% if single subject, return string instead of cell array
if length(dataPaths)==1
    dataPaths = dataPaths{1};
end
