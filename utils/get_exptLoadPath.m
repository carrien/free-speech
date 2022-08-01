function [exptPath] = get_exptLoadPath(exptName,varargin)

if nargin < 1, exptName = []; end

if ispc
    basePath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\';
elseif ismac
    basePath = '/Volumes/smng/experiments/';
    if ~isfolder(basePath)
        basePath = '/Volumes/wc/experiments/';
    end
elseif isunix
    basePath = '/mnt/smng/experiments/'; %% placeholder
else
    basePath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\'; %% placeholder
end

exptPath = fullfile(basePath,exptName,varargin{:});
