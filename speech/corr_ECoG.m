% neuralY: channels x timepoints x trials (concatenated)
% neuralBySyll: channels x timepoints x trials, ordered by syll produced
% distBySyll: 

words = fieldnames(fmtdata.mels);
nchans = 256;

for word = 1:length(words)
    w = words{word};
    for t=1:stoptime
        [r(t,word) p(t,word)] = corr(fmtdata.mels.(w).first50ms.dist,neuraldata);
    end;
end

%%
% make figure with tight subplot
figure;
ha = tight_subplot(ceil(sqrt(nchans)),ceil(sqrt(nchans)),0.005);

r = zeros(nt,nchans); p = zeros(nt,nchans);

for syl = 1:length(wlist)
    inds = find(labs == syl);
end

for ch = 1:size(neuralY,1)
    for t = 1:size(neuralY,2)
        [r(t,ch) p(t,ch)] = corr(fmtdata.mels.zee.first50ms.dist',squeeze(zee_neuralY(ch,t,:)));
    end
end

distBySyll = [];
neuralBySyll = [];
for w = 1:length(wlist)
    word = lower(wlist{w});
    w_neuralY = neuralY(:,:,labs==w);
    if ~strcmp(word,'hoo')
        distBySyll = [distBySyll fmtdata.mels.(word).mid50p_noNaN.dist];
        neuralBySyll = cat(3,neuralBySyll,w_neuralY);
    end
end

% plot correlation 
for ch=1:length(ha)
[r(t,ch) p(t,ch)] = corr(distBySyll',squeeze(neuralBySyll(ch,t,:)));
plot(ha(ch),r(:,ch))
end

for ch=1:length(ha)
plot(ha(ch),p(:,ch),'r')
end