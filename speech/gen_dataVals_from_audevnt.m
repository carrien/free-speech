function [dataVals] = gen_dataVals_from_audevnt(blockvec)
%GEN_DATAVALS_FROM_AUDEVNT  Transform audevnt data into fdata struct.

dataPath = fullfile(getExptPath('ecogCV'),'EC2_FB_encd');
dataVals = [];
wordlist = {};
vowellist = {'a' 'i' 'u'};

for b=1:length(blockvec)
    load(fullfile(dataPath,sprintf('EC2_B%d',blockvec(b)),sprintf('EC2_B%d_ptch_frmnt_evnt',blockvec(b))));
    Note2s = {audevnt.Note2};
    wordlist = unique([wordlist Note2s]);
end
for b=1:length(blockvec)
    load(fullfile(dataPath,sprintf('EC2_B%d',blockvec(b)),sprintf('EC2_B%d_ptch_frmnt_evnt',blockvec(b))));
    for i=1:length(audevnt)
        startind = round(audevnt(i).StartTime2*audevnt(i).fs);
        stopind = round(audevnt(i).StopTime2*audevnt(i).fs);
        stopind = min(stopind,size(audevnt(i).Acoustic_Data,1));
        
        dataVals(end+1).f0 = audevnt(i).Acoustic_Data(startind:stopind,1); %#ok<*AGROW>
        dataVals(end+1).f1 = audevnt(i).Acoustic_Data(startind:stopind,2);
        dataVals(end+1).f2 = audevnt(i).Acoustic_Data(startind:stopind,3);
        dataVals(end+1).f3 = audevnt(i).Acoustic_Data(startind:stopind,4);
        dataVals(end+1).f4 = audevnt(i).Acoustic_Data(startind:stopind,5);
        
        syllname = audevnt(i).Note2(1:end-1);
        tf = strncmp(syllname,wordlist,length(syllname));
        dataVals(end+1).word = find(tf);
        dataVals(end+1).vowel = find(strcmp(syll2ipa(syllname),vowellist));
        dataVals(end+1).block = blockvec(b);
    end
end