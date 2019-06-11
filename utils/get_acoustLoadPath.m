function [dataPath] = get_acoustLoadPath(exptName,sid,varargin)
%GET_ACOUSTLOADPATH  Get acoustic load path for given experiment/subject.

if nargin < 2 || isempty(sid) % need 'isempty' here because '[]' is numeric
    sid = [];
elseif isnumeric(sid)
    sid = sprintf('sp%03d',sid);
elseif ~ischar(sid)
    error('Subject ID must be a number or character string.')
end

dataPath = get_exptLoadPath(exptName,'acousticdata',sid,varargin{:});
