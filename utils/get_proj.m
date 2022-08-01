function [proj] = get_proj(vec)
%GET_PROJ  Get projection
%   Detailed explanation goes here

magShift = sqrt(vec(1)^2 + vec(2)^2);

proj = dot([diff1 diff2],-vec)/magShift;

end
