%get figure positions
function [fig aH] = setAxesPositions(pX, pY, w, h)

%[fig aH] = setAxesPositions(pX, pY, w, h, margin)   A. Orsborn
%
%Creates a single figure with axes, whose positions/sizes specified by pX, pY, w, and h
%
%input: pX - vector of x-positions for axes (# axes x 1)
%       pY - vector of y-positions for axes (# axes x 1)
%       w  - vector of axes widths (x-length) (# axes x 1)
%       h  - vector of axes heights (y-length) (# axes x 1)
%
%output: fig - figure #
%        aH  - axes handles for all axes in fig (# axes x )



edgeOffset = 0.5;

nP = length(pX);
if ~isequal(nP, length(pY))
    error('pX and pY must be same size')
end
if ~isequal(nP, length(w), length(h))
    error('w and h must be same size as pX/pY')
end


%get screen-size & figure
scrnsz = get(0,'screensize');
fig = figure('Position',[scrnsz(1)+30 scrnsz(2)+30 scrnsz(3:4).*(3.5/4)],'units','pixels');

% Set dots per inch
dpi = 96;

pos = zeros(nP,4);
aH  = nan(nP,1);
for i=1:nP
    
    pos(i,:) = [pX(i)+edgeOffset pY(i)+edgeOffset w(i) h(i)].*dpi;
    aH(i)    = axes('units','pixels','position',pos(i,:));

end

    