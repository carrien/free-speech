function [dataVals,firstnans] = gen_dataVals_from_audalign2(audmatfile)
%GEN_DATAVALS_FROM_AUDALIGN2  Transform formantY data into fdata struct.

vowellist = {'a' 'i' 'u'};
fmtlist = {'f0' 'f1' 'f2' 'f3' 'f4'};
startInd = 57; %51;
bStopAtFirstNan = 1;

load(fullfile(getAcoustSubjPath('ecogCV'),audmatfile));
for i=1:size(formantY,3)
    for f=1:length(fmtlist)
        ftrack = formantY(f,startInd:end,i)'; %#ok<*COLND>
        if bStopAtFirstNan
            naninds = find(isnan(ftrack));
            if ~isempty(naninds)
                firstnans(i,f) = naninds(1);
                dataVals(i).(fmtlist{f}) = ftrack(1:naninds(1)-70);
            else
                firstnans(i,f) = NaN;
                dataVals(i).(fmtlist{f}) = ftrack;
            end
        else
            dataVals(i).(fmtlist{f}) = formantY(f,startInd:end,i)';
        end
    end
    dataVals(i).syllname = lower(wlist{labs(i)});
    dataVals(i).word = labs(i);
    dataVals(i).vowel = find(strcmp(syll2ipa(dataVals(i).syllname),vowellist));
    dataVals(i).int = ones(184,1);
    dataVals(i).dur = OffsetTimes(i) - OnsetTimes(i);
end