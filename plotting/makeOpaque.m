function [] = makeOpaque(handle)
%MAKEOPAQUE   Remove transparency from a figure.
%   MAKEOPAQUE(H) loops through the children of figure H and sets the
%   opacity alpha values to 1, making it suitable for saving as an EPS.

if nargin < 1, handle = gcf; end

for h=1:length(handle)
    if ~isempty(get(handle(h),'children'))
        children = get(handle(h),'children');
        for ch=1:length(children)
            if isprop(children(ch),'FaceAlpha') % patch
                set(children(ch),'FaceAlpha',1);
                set(children(ch),'EdgeAlpha',1);
            end
            if isprop(children(ch),'MarkerFaceAlpha') % scatter
                set(children(ch),'MarkerFaceAlpha',1);
                set(children(ch),'MarkerEdgeAlpha',1);
            end
            if isa(children(ch),'matlab.graphics.chart.primitive.Line') % line
                children(ch).Color = children(ch).Color; % revert to 3-element vector
            elseif isa(children(ch),'matlab.graphics.primitive.Rectangle') % rectangle/ellipse
                children(ch).FaceColor = children(ch).FaceColor; % revert to 3-element vector
            end
            makeOpaque(children(ch))
        end
    end
end
