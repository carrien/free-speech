function bGoodTrial = check_rmsThresh(data,params,subAxis)
% Takes a data file from Audapter and checks the amplitude of that signal
% against certain parmeters. Primarily, it checks if the calculated
% RMS value is above a certain threshold (rmsThresh). It also displays
% information about acceptable RMS values on the subAxis. `params` controls
% how the RMS value is calculated, and how values are displayed on the plot.
%
% Input arguments:
%   * data. The output data structure from Audapter
%   * params. Can be a struct (new format) or double (historical format).
%       If `params` is a STRUCT: It can contain the following fields
%         which affect the amplitude calculation:
%           * checkMethod. If 'mean', the RMS value is calculated as the mean
%              RMS during the vowel. If 'peak', the RMS value is the peak RMS.
%           * limits. A 2x2 array structured like this:
%                  [GoodLow, GoodHi;
%                   WarnLow, WarnHi]
%              In check_rmsThresh, an area is shaded green between the low
%              and hi Good limits, and an area is shaded yellow between Warn limits.
%          * rmsThresh. If the RMS value is below rmsThresh, the output
%              parameter bGoodTrial will be 0. This parameter is overridden by
%              the 2nd input param `rmsThresh`, if that input param is used.
%       If `params` is a DOUBLE: params will be interpreted as
%         the value of the field rmsThresh (see above).
%   * subAxis. If a graphics object is included in the 3rd input parameter,
%       the mean RMS and OST values are plotted.
%

if nargin < 2
    params.checkMethod = 'peak';
elseif isnumeric(params)
    rmsThresh = params;
    params = struct;
    params.checkMethod = 'peak';
    params.rmsThresh = rmsThresh;
end
if nargin < 3, subAxis = []; end

defaultParams.checkMethod = 'mean';
defaultParams.limits = [0.037, 0.100; 0 0];
defaultParams.rmsThresh = 0.037;
params = set_missingFields(params, defaultParams, 0);

%% find rmsValue
switch params.checkMethod
    case 'peak'
        [rmsValue, onset] = max(data.rms(:,1));
        offset = onset;
    case 'mean'     
        % if OST onset and offset exist, use that
        if any(data.ost_stat == 4)
            % Finding the last instance of status 1 implies the next status
            % was 2 (the next event)
            onset = 1 + find(data.ost_stat == 1, 1, 'last');
            offset = 1 + find(data.ost_stat == 3, 1, 'last');
            rmsValue = mean(data.rms(onset:offset, 1));

        % if no ost tracking, use RMS data to find onset/offset
        elseif any(data.rms(:, 1) > 0.03)
            % These values are more lax versions of the settings
            % in free-speech\experiment_helpers\measureFormants.ost. They
            % are relatively imprecise and would benefit from more nuance in the future.
            onset = find(data.rms > 0.03, 1, 'first') + 5;
            offset = find(data.rms(:, 1)<0.03 & data.rms(:, 1)>0.02 & data.rms_slope<0, 1, 'first') - 5;
            if isempty(offset)
                offset = min(onset+10,length(data.rms));
            end
            rmsValue = mean(data.rms(onset:offset, 1));

        % can't determine rms mean, because no ost-based vowel found, and RMS too low
        else
            rmsValue = NaN;
        end
end % of switch/case
    
%% set bGoodTrial
if rmsValue > params.rmsThresh
    bGoodTrial = 1;
else
    bGoodTrial = 0;
end

%% plot
if isgraphics(subAxis)
    % plot Good and Warn shaded regions
    subplot(subAxis)
    tAxis = 0 : data.params.frameLen : data.params.frameLen * (size(data.fmts, 1) - 1);
    yyaxis left
    plot(tAxis/data.params.sr,data.rms(:,1));
    ylim([0 0.1])
    xlim([0 tAxis(end)/data.params.sr])

    yGood = [params.limits(1,1) params.limits(1,1) params.limits(1,2) params.limits(1,2)];
    yWarn = [params.limits(2,1) params.limits(2,1) params.limits(2,2) params.limits(2,2)];

    colorWarn = [1,   1,   0.3];
    colorGood = [0.4, 1,   0.4];

    xPatchShade = [0, length(data.rms), length(data.rms), 0];

    patch(xPatchShade,yWarn,colorWarn, 'FaceAlpha', 0.3, 'EdgeColor', 'none')
    patch(xPatchShade,yGood,colorGood, 'FaceAlpha', 0.3, 'EdgeColor', 'none')

    % plot a bar whose x position is vowel onset/offset, and y position is rmsValue
    if ~isnan(rmsValue) && ~isempty(onset) && ~isempty(offset)
        hold on;
        xRMS = [onset offset] / length(data.rms) * max(tAxis) / data.params.sr;  %convert from frames to milliseconds
        switch params.checkMethod
            case 'peak'
                plot(xRMS(1), rmsValue, 'om', 'LineWidth', 2);
            otherwise
                plot(xRMS, [rmsValue, rmsValue], '-m', 'LineWidth', 2.2);
        end
        hold off;
    end

    % set title
    if bGoodTrial
        title({'',''})
    else
        title({'';'Amplitude below threshold!'})
    end

    %% plot OST status
    yyaxis right
    plot(tAxis/data.params.sr,data.ost_stat);
    ylim([0 max(data.ost_stat + 2)]);

end % of subplot conditional

end % of function
