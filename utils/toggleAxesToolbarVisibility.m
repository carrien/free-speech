function toggleAxesToolbarVisibility(state, handles)
%TOGGLEAXESTOOLBARVISIBILITY Set visibility of toolbars for axes/figures.
% Useful for hiding the three dots toolbar menu from figures.
%
% TOGGLEAXESTOOLBARVISIBILITY(STATE) sets toolbar visibility to STATE ('on'/'off')
% for axes in the specified `handles`, or if empty, all axes in all figures.
% TOGGLEAXESTOOLBARVISIBILITY(STATE, HANDLES) where HANDLES can be:
%   - figure handles: applies to all axes in those figures
%   - axes handles: applies only to those axes
%   - empty: applies to all axes in all figures
%
% STATE defaults to 'off'.

%% input arg handling
if nargin < 1 || isempty(state)
    state = 'off';
end
state = validatestring(lower(state), {'on','off'});

% Normalize handles input: if empty -> operate on all figures later
if nargin < 2 || isempty(handles)
    handles = [];
else
    handles = handles(:).';
    handles = handles(isgraphics(handles));  % Keep only valid graphics handles
end

%% Determine handle type: assume provided handles are either all figures or all axes
if isempty(handles)
    % operate on all axes in all figures
    figHandles = findall(0, 'Type', 'figure');
    axHandles = [];
else
    % look to first element in `handles` to see if user supplied figures or axes handles
    if isgraphics(handles(1), 'figure')
        figHandles = handles;
        axHandles = [];
    else
        % treat as axes
        figHandles = [];
        axHandles = handles;
    end
end

%% Update axes
% If AXES handles explicitly provided, set only those
if ~isempty(axHandles)
    for ax_handle = axHandles
        try
            if isprop(ax_handle, 'Toolbar') && isprop(ax_handle.Toolbar, 'Visible')
                ax_handle.Toolbar.Visible = state;
            elseif isprop(ax_handle, 'Toolbar') && ~isprop(ax_handle.Toolbar, 'Visible')
                % some versions may accept setting Toolbar directly to 'on'/'off' - attempt
                try ax_handle.Toolbar = state; catch; end
            else
                % Fallback: nothing to do for this axis
            end
        catch
            warning('Couldn''t set toolbar visibility for an axis.');
        end
    end
    return; % end
end


% If here, we're dealing with FIGURES (either all figures or specified)
% Loop over each figure in figHandles, then loop over each axes within that figure
% Using try/catch since these settings have changed between MATLAB versions
if strcmp(state, 'on')
    stateForFigToolbar = 'figure';
else
    stateForFigToolbar = 'none';
end
for h_fig = figHandles
    allaxes_handles = findall(h_fig, 'Type', 'axes');
    for ax_handle = allaxes_handles.'
        try
            if isprop(ax_handle, 'Toolbar') && isprop(ax_handle.Toolbar, 'Visible')
                ax_handle.Toolbar.Visible = state;
            elseif isprop(ax_handle, 'Toolbar')
                try ax_handle.Toolbar = state; catch; end
            else
                % If axes don't have toolbar, try figure-level toolbar setting once per figure
                if isprop(h_fig, 'Toolbar') || isprop(h_fig, 'toolbar')
                    if isprop(h_fig, 'Toolbar')
                        try h_fig.Toolbar = stateForFigToolbar; catch; end
                    else
                        try set(h_fig, 'toolbar', stateForFigToolbar); catch; end
                    end
                    break;
                end
            end
        catch
            % ignore individual axis failures and continue
        end
    end
end

end %EOF
