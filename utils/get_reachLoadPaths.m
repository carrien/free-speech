function [dataPaths] = get_reachLoadPaths(exptName,svec,varargin)
%GET_ACOUSTLOADPATHS  Get load paths for multiple subjects in an experiment.
%   DATAPATHS = GET_ACOUSTLOADPATHS(EXPTNAME,SVEC,VARARGIN) returns the
%   cell array DATAPATHS of load paths to data for multiple subjects in an
%   experiment. SVEC can either be a vector of numerical IDs or a cell
%   array of character IDs.

dataPaths = cell(1,length(svec));

for s=1:length(svec)
    if isnumeric(svec)
        dataPaths{s} = get_reachLoadPath(exptName,svec(s),varargin{:});
    else
        dataPaths{s} = get_reachLoadPath(exptName,svec{s},varargin{:});
    end
end

% if single subject, return string instead of cell array
if length(dataPaths)==1
    dataPaths = dataPaths{1};
end