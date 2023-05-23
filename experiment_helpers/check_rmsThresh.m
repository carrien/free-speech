function bGoodTrial = check_rmsThresh(data,rmsThresh,subAxis,params)

if nargin < 3, subAxis = []; end
if nargin < 4
    params = struct;
end
defaultParams = get_rmsThresh_defaults('main');
params = set_missingFields(params, defaultParams, 0);

if nargin < 2 || isempty(rmsThresh)
    rmsThresh = params.targetRMS;
end

if isgraphics(subAxis)
    %% plot Good and Warn shaded regions
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

    %% If evaluating based on peak amplitude, do that
    if params.bUsePeak
        if max(data.rms(:,1)) > params.rmsThresh
            bGoodTrial = 1;
            title({'',''})
        else
            bGoodTrial = 0;
            title({'';'Amplitude below threshold!'})
        end
        return;
    end

    %% determine onset and offset
    % if OST onset and offset exist, use that
    if any(data.ost_stat == 4)
        % Finding the last instance of status 0 implies that the next status
        % was 1, and did eventually successfully become status 2.
        onset = 1 + find(data.ost_stat == 0, 1, 'last');
        offset = 1 + find(data.ost_stat == 2, 1, 'last');

    % if no ost tracking, use RMS data to find onset/offset
    elseif ~any(data.ost_stat >= 1) && any(data.rms(:, 1) > 0.03)
        onset = find(data.rms > 0.01, 1, 'first') + 5;
        offset = find(data.rms(:, 1)<0.03 & data.rms(:, 1)>0.02 & data.rms_slope<0, 1, 'first') - 5;

        % use middle 80%
        onset = floor(onset + ((offset-onset)/10));
        offset = ceil(offset - ((offset-onset)/10));

    % can't determine rms mean, because no ost-based vowel found, and RMS too low
    else
        onset = [];
        offset = [];
        rms_mean = NaN;
    end

    %% plot amplitude data
    %plot mean RMS during vowel as a bar whose x position is vowel onset/offset, and y position is mean RMS
    if ~isempty(onset) && ~isempty(offset)
        xPatchRMS = [onset offset offset onset];
        xPatchRMS = xPatchRMS / length(data.ost_stat) * max(tAxis) / data.params.sr;  %convert from frames to milliseconds
        rms_mean = mean(data.rms(onset:offset, 1));
        yPatchRMS = [rms_mean-0.0007, rms_mean-0.0007, rms_mean+0.0007, rms_mean+0.0007];

        % plot the bar
        hold on;
        patch(xPatchRMS, yPatchRMS, 'm', 'EdgeColor', 'none');
        hold off;

        % plot OST status
        yyaxis right
        plot(tAxis/data.params.sr,data.ost_stat);
        ylim([0 max(data.ost_stat + 2)]);
    end

    %% set title and bGoodTrial
    if rms_mean > rmsThresh
        bGoodTrial = 1;
        title({'',''})
    else
        bGoodTrial = 0;
        title({'';'Amplitude below threshold!'})
    end
    
end % of subplot conditional

end % of function
