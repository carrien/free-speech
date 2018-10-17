function [dataPaths] = get_acoustLocalPaths(exptName,svec,varargin)
%GET_ACOUSTLOCALPATHS  Get path to acoustic data for multiple subjects.

dataPaths = cell(1,length(svec));

for s=1:length(svec)
    if isnumeric(svec)
        dataPaths{s} = get_acoustLocalPath(exptName,svec(s),varargin{:});
    else
        dataPaths{s} = get_acoustLocalPath(exptName,svec{s},varargin{:});
    end
end

% if single subject, return string instead of cell array
if length(dataPaths)==1
    dataPaths = dataPaths{1};
end

end

function [subjPath] = get_acoustLocalPath(exptName,sid,varargin)
%GET_ACOUSTLOCALPATH  Get path to acoustic data for given subject/experiment.

if nargin < 2 || isempty(sid) % need 'isempty' here because '[]' is numeric
    sid = [];
elseif isnumeric(sid)
    sid = sprintf('s%02d',sid);
elseif ~ischar(sid)
    error('Subject ID must be a number or character string.')
end

subjPath = get_exptPath(exptName,'acousticdata',sid,varargin{:});
end

