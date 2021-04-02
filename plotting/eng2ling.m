function [ ] = eng2ling(ax)
%ENG2LING  Converts between "engineering" and "linguistics" vowel spaces.
%   ENG2LING(AX)

if nargin < 1, ax = gca; end

% reverse x-axis
if strcmp(ax.XDir,'normal')
    ax.XDir = 'reverse';
else
    ax.XDir = 'normal';
end

% reverse y-axis
if strcmp(ax.YDir,'normal')
    ax.YDir = 'reverse';
else
    ax.YDir = 'normal';
end

% flip x and y axes
[az,el] = view;
if az==0 && el==90
    view(ax,90,-90);
elseif az==90 && el==-90
    view(ax,0,90);
end
