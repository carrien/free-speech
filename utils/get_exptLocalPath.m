function [exptPath] = get_exptLocalPath(exptName,varargin)
%GET_EXPTLOCALPATH Return path to experiment folder
%   GET_EXPTLOCALPATH(EXPTNAME,VARARGIN)
%       Return the path to the local machine's Documents/experiments
%       folder, appending the provided EXPTNAME and any additional 
%       subfolders specified by VARARGIN.
%       
%       ARGUMENTS:
%           EXPTNAME - character array containing name of experiment
%           VARARGIN - one or more extra character array arguments to be
%           added to the path, used to specify subfolders of the experiment
%           folder.
%           
%       OUTPUT:
%           EXPTPATH - full path as joined together via fullfile()
%
%       NOTE: If you are setting up an experiment running script for the
%       lab, you should probably be using get_exptSavePath.m instead.

if nargin < 1, exptName = []; end

if ispc
    basePath = 'C:\Users\Public\Documents\experiments\';    
elseif ismac
    basePath = '/Users/Shared/Documents/experiments';
elseif isunix
    error('Unix not supported currently!')
end
exptPath = fullfile(basePath,exptName,varargin{:});