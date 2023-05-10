function bGoodTrial = check_rmsThresh(data,rmsThresh,subAxis,params)

if nargin < 3, subAxis = []; end
if nargin < 4
    params = struct;
end
params = set_missingField(params, 'targetRMS', 0.039);
params = set_missingField(params, 'limGoodUpper', params.targetRMS + 0.005, 0);
params = set_missingField(params, 'limGoodLower', params.targetRMS - 0.005, 0);
params = set_missingField(params, 'limWarnUpper', params.targetRMS + 0.009, 0);
params = set_missingField(params, 'limWarnLower', params.targetRMS - 0.009, 0);

if nargin < 2 || isempty(rmsThresh)
    rmsThresh = params.limWarnLower;
end

if isgraphics(subAxis)
    subplot(subAxis)
    tAxis = 0 : data.params.frameLen : data.params.frameLen * (size(data.fmts, 1) - 1);
    yyaxis left
    plot(tAxis/data.params.sr,data.rms(:,1));
    ylim([0 0.1])
    xlim([0 tAxis(end)/data.params.sr])

    yGood = [params.limGoodLower params.limGoodLower params.limGoodUpper params.limGoodUpper];
    yWarn = [params.limWarnLower params.limWarnLower params.limWarnUpper params.limWarnUpper];

    colorWarn = [1,   1,   0.3];
    colorGood =  [0.4, 1,   0.4];

    xPatchShade = [0, length(data.ost_stat), length(data.ost_stat), 0];

    patch(xPatchShade,yWarn,colorWarn, 'FaceAlpha', 0.3, 'EdgeColor', 'none')
    patch(xPatchShade,yGood,colorGood, 'FaceAlpha', 0.3, 'EdgeColor', 'none')

    % if OST onset and offset exist, use that
    if any(data.ost_stat == 4)
        % Finding the last instance of status 0 implies that the next status
        % was 1, and did eventually successfully become status 2.
        onset = 1 + find(data.ost_stat == 0, 1, 'last');
        offset = 1 + find(data.ost_stat == 2, 1, 'last');
    
    % if no ost tracking, use RMS data to find onset/offset
    elseif ~any(data.ost_stat >= 1) && any(data.rms(:, 1) > 0.03) 
        onset = find(data.rms > 0.01, 1, 'first') + 5;
        offset = find(data.rms(:, 1)<0.03 & data.rms(:, 1)>0.02 & data.rms_slope<0, 1, 'last') - 5;

        % lob off 10% on each side
        onset = floor(onset + ((offset-onset)/10));
        offset = ceil(offset - ((offset-onset)/10));
    
    % can't determine rms mean, because no ost-based vowel found
    else 
        onset = [];
        offset = [];
        rms_mean = NaN;
    end

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

    if rms_mean > rmsThresh
        bGoodTrial = 1;
        title({'',''})
    else
        bGoodTrial = 0;
        title({'';'Amplitude below threshold!'})
    end
    
end % of subplot conditional

end %of function
