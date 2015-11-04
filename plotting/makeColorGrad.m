function [gradient] = makeColorGrad(len,varargin)

if nargin > 2
    color1 = varargin{1};
    color2 = varargin{2};
else
    color1 = [1 0 0];
    color2 = [0 1 0];
end

gradient = zeros(len,3);
for i=1:3
    if color1(i) < color2(i)
        gradient(:,i) = (color1(i):1/(len-1):color2(i))';
    elseif color1(i) > color2(i)
        gradient(:,i) = (color1(i):-1/(len-1):color2(i))';
    elseif color1(i) == color2(i)
        gradient(:,i) = color1(i);
    else error('Colors must be represented as [r g b] values between 0 and 1.')
    end
end