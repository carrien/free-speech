function [sig_std] = calcci(signal)
% Calculate CI at each time point of a signal (each observation is a column
% vector; each row is a timepoint).

sig_std = zeros(size(signal,1),1);
for t = 1:size(signal,1)
    sig = signal(t,:); sig = sig(~isnan(sig)); % remove NaNs
    if length(sig) == 1  % if only one non-NaN observation
        muhat = sig;
        muci = NaN;
    else [muhat,~,muci] = normfit(sig);
    end
    if ~isnan(muci), sig_std(t) = abs(muci(1)-muhat);
    else sig_std(t) = NaN;
    end
end