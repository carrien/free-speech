
function [ProjPoint,major,minor] = ellipse_proj(vector, q)
%% get the projected point to major/minor axis of fitted ellipse 
% vector: major axis of the fitted ellipe
% q: point in F1-F2 space
% output, major/minor, the distance between projected point to major/minor
% axis
p0 = vector(1,:); % the center of an ellipse
p1 = vector(2,:);
a = [-q(1)*(p1(1)-p0(1)) - q(2)*(p1(2)-p0(2)); ...
    -p0(2)*(p1(1)-p0(1)) + p0(1)*(p1(2)-p0(2))]; 
b = [p1(1) - p0(1), p1(2) - p0(2);...
    p0(2) - p1(2), p1(1) - p0(1)];
ProjPoint = -(b\a)';
d1 = pdist2(q, p0);
d2 = pdist2(q, p1);
d  = pdist2(p0, p1);
t1 = ((d1*d1 - d2*d2)/d) + d;
t1 = t1/2;
major= pdist2(ProjPoint,p0);
minor = pdist2(ProjPoint,q);
end

