function [dataPath] = get_acoustLocalPath(exptName,sid,varargin)
%GET_ACOUSTLOCALPATH  Get acoustic local path for given experiment/subject.
%   GET_ACOUSTLOCALPATH(EXPTNAME,SID,VARARGIN)
%       Wrapper for the get_exptLocalPath function that returns the path 
%       to the local machine's acousticdata folder for an
%       experiment EXPTNAME. Can specify a speaker number SID and 
%       subfolders with VARARGIN.
%       
%       ARGUMENTS:
%           EXPTNAME - character array containing name of experiment
%           SID - speaker number, either as 'sp###' or just the number
%           VARARGIN - one or more extra character array arguments to be
%           added to the path, used to specify subfolders of the experiment
%           folder.
%           
%       OUTPUT:
%           EXPTPATH - full path as joined together via fullfile()
%
%       NOTE: If you are setting up an experiment running script for the
%       lab, you should probably be using get_acoustSavePath.m instead.

if nargin < 2 || isempty(sid) % need 'isempty' here because '[]' is numeric
    sid = [];
elseif isnumeric(sid)
    sid = sprintf('sp%03d',sid);
elseif ~ischar(sid)
    error('Subject ID must be a number or character string.')
end

dataPath = get_exptLocalPath(exptName,'acousticdata',sid,varargin{:});
