function [var] = calc_var(expt,fmtdata)
%CALC_VAR  Calculate variance across trials.

conds = expt.conds;
vowels = expt.vowels;
colors = {[.9 .9 .9] [.5 .5 .5] [0 0 0]};
mycolors = {colors{expt.allConds(1)} colors{expt.allConds(length(expt.allConds)/2)} colors{expt.allConds(end)}};
stopplot = 79;

for c = 1:length(conds)
    figure;
        f1 = fmtdata.mels.(vowels{v}).traces.f1;
        f2 = fmtdata.mels.(vowels{v}).traces.f2;
        arr = nan(1, stopplot); %length(f1));
        for t = 1:stopplot
            f1t = f1(t,:);
            f2t = f2(t,:);
            % calc variance
            var.(conds{c}).(vowels{v}).f1(t) = nanvar(f1t);
            var.(conds{c}).(vowels{v}).f2(t) = nanvar(f2t);
            nsamp(t) = sum(~isnan(f1t));
            % calc area of ellipse
            if sum(~isnan(f1t)) > 1;
                [~,ar,~] = FitEllipse(f1t, f2t);
                var.(conds{c}).(vowels{v}).area(t) = ar;
            else
                var.(conds{c}).(vowels{v}).area(t) = NaN;
            end
            % calc sum of squared distance from 2D median
            medf1 = nanmedian(f1t);
            medf2 = nanmedian(f2t);
            if v == 2,
                'stop';
            end
            clear dist;
            for d = 1:length(f1t)
                dist(d) = (f1t(d)-medf1)^2 + (f2t(d)-medf2)^2;
            end
            var.(conds{c}).(vowels{v}).distsum(t) = nanmean(dist);
        end
        %plot(var.(conds{c}).(vowels{v}).f1,'b');
        %plot(var.(conds{c}).(vowels{v}).f2,'r');
        figure(v)
        plot(0:.003:.003*(stopplot-1),var.(conds{c}).(vowels{v}).area,'Color',mycolors{c},'LineWidth',2);
        hold on;
        figure(v+3)
        plot(0:.003:.003*(stopplot-1),var.(conds{c}).(vowels{v}).distsum,'--','Color',mycolors{c},'LineWidth',2);
        hold on;
        %plot(0:.003:.003*(stopplot-1),nsamp*10000,'c')
    end
    figure(v)
    title(vowels{v});
    legend(conds)
    figure(v+3)
    title(vowels{v});
    legend(conds)
end

