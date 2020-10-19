function [exptPath] = get_exptSavePath(exptName,varargin)

if nargin < 1, exptName = []; end

basePath = 'C:\Users\Public\Documents\experiments\';
exptPath = fullfile(basePath,exptName,varargin{:});