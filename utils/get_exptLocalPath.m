function [exptPath] = get_exptLocalPath(exptName,varargin)

if nargin < 1, exptName = []; end

if ispc
    basePath = 'C:\Users\Public\Documents\experiments\';    
elseif ismac
    basePath = '/Users/Shared/Documents/experiments';
elseif isunix
    error('Unix not supported currently!')
end
exptPath = fullfile(basePath,exptName,varargin{:});