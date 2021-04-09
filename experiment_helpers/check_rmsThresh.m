function bGoodTrial = check_rmsThresh(data,rmsThresh,subAxis)

if nargin < 3, subAxis = []; end

max_rms = max(data.rms(:,1));
if max_rms > rmsThresh %&& length(find(ost == 2)) > (offset(2) + 1)
    bGoodTrial = 1;
else
    bGoodTrial = 0;
end

if subAxis
    subplot(subAxis)
    tAxis = 0 : data.params.frameLen : data.params.frameLen * (size(data.fmts, 1) - 1);
    yyaxis left
    plot(tAxis/data.params.sr,data.rms(:,1));
    ylim([0 0.1])
    xlim([0 tAxis(end)/data.params.sr])
    hline(rmsThresh,'k',':');
    yyaxis right
    plot(tAxis/data.params.sr,data.ost_stat);
    if ~bGoodTrial
        title({'';'Amplitude below threshold!'})
    else
        title({'',''})
    end %of GoodTrial conditional
    
end % of subplot conditional

end %of function
