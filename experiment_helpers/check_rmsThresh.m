function bGoodTrial = check_rmsThresh(data,rmsThresh,subAxis)

if nargin < 3, subAxis = []; end

max_rms = max(data.rms(:,1));
if max_rms > rmsThresh %&& length(find(ost == 2)) > (offset(2) + 1)
    bGoodTrial = 1;
else
    bGoodTrial = 0;
end

if isgraphics(subAxis)
    subplot(subAxis)
    tAxis = 0 : data.params.frameLen : data.params.frameLen * (size(data.fmts, 1) - 1);
    yyaxis left
    plot(tAxis/data.params.sr,data.rms(:,1));
    ylim([0 0.1])
    xlim([0 tAxis(end)/data.params.sr])
    hline(0.030, [0.7 0.7 0], '-')
    hline(0.035, [0 0.7 0],'-')
    hline(0.043, [0 0.7 0],'-')
    hline(0.048, [0.7 0.7 0], '-')
    
    onset = find(data.ost_stat == 2, 1);
    offset = find(data.ost_stat == 4, 1);
    midpoint_frame = floor(mean([onset offset]));
    midpoint_rel = midpoint_frame / length(data.ost_stat) * max(tAxis) / data.params.sr;
    rms_mean = mean(data.rms(onset:offset, 1));
    hold on;
    plot(midpoint_rel, rms_mean, 'o', 'Color', 'm')
    hold off;

    yyaxis right
    plot(tAxis/data.params.sr,data.ost_stat);

    if ~bGoodTrial
        title({'';'Amplitude below threshold!'})
    else
        title({'',''})
    end %of GoodTrial conditional
    
end % of subplot conditional

end %of function
