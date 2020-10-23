function [exptPath] = get_exptLoadPath_mac(exptName,varargin)

if nargin < 1, exptName = []; end

basePath = '/Volumes/smng/experiments/';
exptPath = fullfile(basePath,exptName,varargin{:});