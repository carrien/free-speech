function [distinds,dists] = get_distinds_1vowel(fdata)
%GET_DISTINDS_1VOWEL Test function -- to deprecate?

units = fieldnames(fdata);
for un = 1:length(units)    % units = hz, mels, dB
    if isfield(fdata.(units{un}),'a')
        fdata.(units{un}) = rmfield(fdata.(units{un}),'a');
    end
end

conds = fieldnames(fdata.(units{1}));
for cond = 1:length(conds)
    c = conds{cond};
    for un = 1:length(units)
        dists.(units{un}).(c) = fdata.(units{un}).(c).first50ms.dist;
        [~,distinds.(units{un}).(c)] = sort(dists.(units{un}).(c));
        condinds = union(fdata.(units{un}).(c).first50ms.center50,fdata.(units{un}).(c).first50ms.periph50);
        dist_trialInds.(units{un}).(c) = condinds(distinds.(units{un}).(c));
        dist_allTrials.(units{un})(condinds) = fdata.(units{un}).(c).first50ms.dist;
    end
end    


%% old code
% vowels = fieldnames(fdata.(units{1}));
% 
% % get ntrials
% ntrials = 0;
% for v = 1:length(vowels)
%     ntrials = ntrials + length(fdata.(units{1}).(vowels{v}).first50ms.dist);
% end
% disp(ntrials)
% 
% % sort trialinds by distance
% for v = 1:length(vowels)
%     for un = 1:length(units)
%     [~,distinds.(units{un}).(vowels{v})] = sort(fdata.(units{un}).(vowels{v}).first50ms.dist);
%     vowelinds = union(fdata.(units{un}).(vowels{v}).first50ms.center50,fdata.(units{un}).(vowels{v}).first50ms.periph50);
%     distinds_all.(units{un})(v:length(vowels):ntrials) = vowelinds(distinds.(units{un}).(vowels{v}));
%     dist_all.(units{un})(vowelinds) = fdata.(units{un}).(vowels{v}).first50ms.dist;
%     end
% end