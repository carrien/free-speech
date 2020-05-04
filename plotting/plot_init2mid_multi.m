function [multi,meandist_init_all, meandist_mid_all] = plot_init2mid_multi(data2plot,p,multi,meandist_init_all,meandist_mid_all)
%PLOT_INIT2MID_MULTI  Plot initial to midpoint data with options for normalizing
% and plotting multiple subject's overlaid. Assumes you've called
% PLOT_CENTERING wrapper with desired arguments.
%
%   PLOT_INIT2MID reads in PLOTDATA values from the PLOT_CENTERING wrapper and plots
%   them with respect to the median at both the beginning (first50ms) and
%   middle (mid50p) of each trial. P is a structure of plotting parameters and
%                      
%                      FMTDATA:
%                      CONDINDS:
%                      NTILE:
%                      P:
%                      BNORM: determines whether or not the data should be normalized.
%
%NC 4/2020

    overlayColor = [.5 .5 .5];

cnds = fieldnames(data2plot.(p.units));
for c = 1:length(cnds)
    %% Compute plotting values
    %First and middle points
    first = data2plot.(p.units).(cnds{c}).first50ms;
    mid = data2plot.(p.units).(cnds{c}).mid50p;
    
    %Quantiles for defining center and periphery
    if p.ntile < 3
        ntiles = median(first.dist);
    else
        ntiles = quantile(first.dist,p.ntile-1);
    end
    cen = first.dist < ntiles(1); % or meddist
    pph = first.dist > ntiles(end);
    
    midd = setdiff(1:length(first.dist),union(cen,pph));
    fpph = find(pph);
    fcen = find(cen);
    
    % F1,F2 in initial time window (all trials)
    initf1 = first.rawavg.f1;
    initf1med = first.med.f1;
    initf1norm = initf1 - initf1med;
    initf2 = first.rawavg.f2;
    initf2med = first.med.f2;
    initf2norm = initf2 - initf2med;
    
    % F1,F2 in mid time window (all trials)
    midf1 = mid.rawavg.f1;
    midf1med = mid.med.f1;
    midf1norm = midf1 - midf1med;
    midf2 = mid.rawavg.f2;
    midf2med = mid.med.f2;
    midf2norm = midf2 - midf2med;
    
    % store init and final dists
    dists_init.(cnds{c}).pph = sqrt(initf1norm(pph).^2 + initf2norm(pph).^2); % per-trial distance to median (init)
    dists_mid.(cnds{c}).pph = sqrt(midf1norm(pph).^2 + midf2norm(pph).^2);    % per-trial distance to median (mid)
    dists_init.(cnds{c}).cen = sqrt(initf1norm(cen).^2 + initf2norm(cen).^2);
    dists_mid.(cnds{c}).cen = sqrt(midf1norm(cen).^2 + midf2norm(cen).^2);
    dists_init.(cnds{c}).midd = sqrt(initf1norm(midd).^2 + initf2norm(midd).^2);
    dists_mid.(cnds{c}).midd = sqrt(midf1norm(midd).^2 + midf2norm(midd).^2);
    
    % calc mean dist for plotting
    meandist_init.pph = nanmean(dists_init.(cnds{c}).pph); % average distance to median (init)
    meandist_mid.pph = nanmean(dists_mid.(cnds{c}).pph);   % average distance to median (mid)
    meandist_init.cen = nanmean(dists_init.(cnds{c}).cen);
    meandist_mid.cen = nanmean(dists_mid.(cnds{c}).cen);
    meandist_init.midd = nanmean(dists_init.(cnds{c}).midd);
    meandist_mid.midd = nanmean(dists_mid.(cnds{c}).midd);
    
    %% main plotting
    
    figure(multi(c))
    hold on;
    % plot initial formants (open circles)
    plot(initf1norm(pph),initf2norm(pph),'o', 'Color',p.pphColor)
    % plot mid formants (dots)
    plot(midf1norm(pph),midf2norm(pph),'k.')
    % plot lines from initial to mid
    for i=1:length(fpph)
        plot([initf1norm(fpph(i)) midf1norm(fpph(i))], ...
            [initf2norm(fpph(i)) midf2norm(fpph(i))], 'Color',overlayColor)
    end
    
    % store per-subject per-condition average distance
    meandist_init_all{c} = [meandist_init_all{c} meandist_init.pph];
    meandist_mid_all{c} = [meandist_mid_all{c} meandist_mid.pph];
end

end