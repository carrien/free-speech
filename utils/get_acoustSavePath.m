function [dataPath] = get_acoustSavePath(exptName,sid,varargin)
%GET_ACOUSTSAVEPATH  Get acoustic local path for given experiment/subject.
%   GET_ACOUSTSAVEPATH(EXPTNAME,SID,VARARGIN)
%       Wrapper for the get_exptSavePath function that returns the path 
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

if nargin < 2 || isempty(sid) % need 'isempty' here because '[]' is numeric
    sid = [];
elseif isnumeric(sid)
    sid = sprintf('sp%03d',sid);
elseif ~ischar(sid)
    error('Subject ID must be a number or character string.')
end

dataPath = get_exptSavePath(exptName,'acousticdata',sid,varargin{:});