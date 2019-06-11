function [dataPath] = get_acoustSavePath(exptName,sid,varargin)
%GET_ACOUSTSAVEPATH  Get acoustic save path for given experiment/subject.

if nargin < 2 || isempty(sid) % need 'isempty' here because '[]' is numeric
    sid = [];
elseif isnumeric(sid)
    sid = sprintf('sp%03d',sid);
elseif ~ischar(sid)
    error('Subject ID must be a number or character string.')
end

dataPath = get_exptSavePath(exptName,'acousticdata',sid,varargin{:});