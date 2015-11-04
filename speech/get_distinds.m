function [distinds_all,dist_all] = get_distinds(fdata)
%GET_DISTINDS Sort trial indices by increasing distance from center.

units = fieldnames(fdata);
for un = 1:length(units)    % units = hz, mels, dB
    if isfield(fdata.(units{un}),'a')
        fdata.(units{un}) = rmfield(fdata.(units{un}),'a');
    end
end
vowels = fieldnames(fdata.(units{1}));

% get ntrials
ntrials = 0;
ntrials_per_v = zeros(1,length(vowels));
for v = 1:length(vowels)
    ntrials_per_v(v) = length(fdata.(units{1}).(vowels{v}).first50ms.dist);
    ntrials = ntrials + ntrials_per_v(v);
end
fprintf('ntrials = %d\n',ntrials)

% sort trialinds by distance
for un = 1:length(units)
    for v = 1:length(vowels)
        [~,distinds.(units{un}).(vowels{v})] = sort(fdata.(units{un}).(vowels{v}).first50ms.dist);
        vowelinds = union(fdata.(units{un}).(vowels{v}).first50ms.center50,fdata.(units{un}).(vowels{v}).first50ms.periph50);
        distinds_all.(units{un})(v:length(vowels):ntrials_per_v(v)*length(vowels)) = vowelinds(distinds.(units{un}).(vowels{v}));
        dist_all.(units{un})(vowelinds) = fdata.(units{un}).(vowels{v}).first50ms.dist;
    end
    % get rid of zeros introduced from unequal trialnums across conditions
    distinds_all.(units{un}) = distinds_all.(units{un})(find(distinds_all.(units{un})));
end