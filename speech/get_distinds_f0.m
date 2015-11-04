function [distinds_all,dist_all] = get_distinds_f0(fdata)
%GET_DISTINDS Sort trial indices by increasing distance from center.

freqs = fieldnames(fdata);
for fr = 1:length(freqs)
    if isfield(fdata.(freqs{fr}),'a')
        fdata.(freqs{fr}) = rmfield(fdata.(freqs{fr}),'a');
    end
end
vowels = fieldnames(fdata.(freqs{1}));
for fr = 1:length(freqs)
    for v = 1:length(vowels)
        if isfield(fdata.(freqs{fr}).(vowels{v}).first50ms.dist,'f0')
            fdata.(freqs{fr}).(vowels{v}).first50ms.dist = rmfield(fdata.(freqs{fr}).(vowels{v}).first50ms.dist,'f0');
        end
        if isfield(fdata.(freqs{fr}).(vowels{v}).first50ms.dist,'f1')
            fdata.(freqs{fr}).(vowels{v}).first50ms.dist = rmfield(fdata.(freqs{fr}).(vowels{v}).first50ms.dist,'f1');
        end
        if isfield(fdata.(freqs{fr}).(vowels{v}).first50ms.dist,'f2')
            fdata.(freqs{fr}).(vowels{v}).first50ms.dist = rmfield(fdata.(freqs{fr}).(vowels{v}).first50ms.dist,'f2');
        end
    end
end
dists = fieldnames(fdata.(freqs{1}).(vowels{1}).first50ms.dist);

% get ntrials
ntrials = 0;
for v = 1:length(vowels)
    ntrials = ntrials + length(fdata.mels.(vowels{v}).first50ms.dist.f0_int);
end

% sort trialinds by distance
for v = 1:length(vowels)
    for d = 1:length(dists)
        for fr = 1:length(freqs)
            [~,distinds.(freqs{fr}).(vowels{v}).(dists{d})] = sort(fdata.(freqs{fr}).(vowels{v}).first50ms.dist.(dists{d}));
            vowelinds.(dists{d}) = union(fdata.(freqs{fr}).(vowels{v}).first50ms.center50.(dists{d}),fdata.(freqs{fr}).(vowels{v}).first50ms.periph50.(dists{d}));
            distinds_all.(freqs{fr}).(dists{d})(v:length(vowels):ntrials) = vowelinds.(dists{d})(distinds.(freqs{fr}).(vowels{v}).(dists{d}));
            dist_all.(freqs{fr}).(dists{d})(vowelinds.(dists{d})) = fdata.(freqs{fr}).(vowels{v}).first50ms.dist.(dists{d});
        end
    end
end