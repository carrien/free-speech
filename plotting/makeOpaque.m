function [] = makeOpaque(handle)
%MAKEOPAQUE   Remove transparency from a figure.
%   MAKEOPAQUE(H) loops through the children of figure H and sets the
%   opacity alpha values to 1, making it suitable for saving as an EPS.

if nargin < 1, handle = gcf; end

for h=1:length(handle)
    if ~isempty(get(handle(h),'children'))
        children = get(handle(h),'children');
        for ch=1:length(children)
            if isprop(children(ch),'FaceAlpha')
                set(children(ch),'FaceAlpha',1);
                set(children(ch),'EdgeAlpha',1);
            end
            makeOpaque(children(ch))
        end
    end
end