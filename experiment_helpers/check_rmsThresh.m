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
%           * checkMethod. If 'peak_window', the RMS value is the mean RMS
%               during a period centered on the peak. If 'peak',
%               the RMS value is the absolute peak RMS.
%           * limits. A 2x2 array structured like this:
%                  [GoodLow, GoodHi;
%                   WarnLow, WarnHi]
%              In check_rmsThresh, an area is shaded green between the low
%              and hi Good limits, and an area is shaded yellow between Warn limits.
%          * rmsThresh. If the RMS value is below rmsThresh, the output
%              parameter bGoodTrial will be 0.
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

defaultParams.checkMethod = 'peak_window';
defaultParams.limits = [0.037, 0.100; 0 0];
defaultParams.peakBufferSecs = 0.1;
defaultParams.rmsThresh = 0.037;
params = set_missingFields(params, defaultParams, 0);

%% find rmsValue
switch params.checkMethod
    case 'peak'
        [rmsValue, onset] = max(data.rms(:,1));
        offset = onset;
    case 'peak_window'
        % onset and offset are some number of ms before and after the peak.
        % rmsValue is the mean RMS between onset and offset.
        frameLenInSecs = data.params.frameLen/data.params.sRate;
        peakBufferNFrames = round(params.peakBufferSecs/frameLenInSecs);
        [~, peak] = max(data(1).rms(:, 1));
        onset = peak-peakBufferNFrames;
        if onset < 1
            onset = 1;
        end
        offset = peak+peakBufferNFrames;
        if offset > length(data.rms)
            offset = length(data.rms);
        end
        rmsValue = mean(data.rms(onset:offset, 1));
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
