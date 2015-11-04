function [f1,f2] = get_fmtsBySyll_multiblock(blockvec)
%GET_FMTSBYSYLL_MULTIBLOCK  Transform audevnt data into formant struct.

dataPath = fullfile(getExptPath('ecogCV'),'EC2_FB_encd');
f1.all = [];
offset = 5;

for b=1:length(blockvec)
    load(fullfile(dataPath,sprintf('EC2_B%d',blockvec(b)),sprintf('EC2_B%d_ptch_frmnt_evnt',blockvec(b))));
    for i=1:length(audevnt)
        syllname = audevnt(i).Note2(1:end-1);
        startind = round(audevnt(i).StartTime2*audevnt(i).fs);
        stopind = round(audevnt(i).StopTime2*audevnt(i).fs);
        stopind = min(stopind,size(audevnt(i).Acoustic_Data,1));
        f1trace = audevnt(i).Acoustic_Data(startind:stopind,2);
        f2trace = audevnt(i).Acoustic_Data(startind:stopind,3);
        if ~isfield(f1.all,syllname)
            f1.all.(syllname) = f1trace;
            f2.all.(syllname) = f2trace;
            f1.mean.(syllname) = nanmean(f1trace);
            f2.mean.(syllname) = nanmean(f2trace);
            f1.first50ms.(syllname) = nanmean(f1trace(1+offset:audevnt(i).fs/20+offset));
            f2.first50ms.(syllname) = nanmean(f2trace(1+offset:audevnt(i).fs/20+offset));
            f1.mid50p.(syllname) = nanmean(midnperc(f1trace,50));
            f2.mid50p.(syllname) = nanmean(midnperc(f2trace,50));
        else
            f1.all.(syllname) = nancat(f1.all.(syllname),f1trace);
            f2.all.(syllname) = nancat(f2.all.(syllname),f2trace);
            f1.mean.(syllname) = nancat(f1.mean.(syllname),nanmean(f1trace));
            f2.mean.(syllname) = nancat(f2.mean.(syllname),nanmean(f2trace));
            f1.first50ms.(syllname) = nancat(f1.first50ms.(syllname),nanmean(f1trace(1+offset:audevnt(i).fs/20+offset)));
            f2.first50ms.(syllname) = nancat(f2.first50ms.(syllname),nanmean(f2trace(1+offset:audevnt(i).fs/20+offset)));
            f1.mid50p.(syllname) = nancat(f1.mid50p.(syllname),nanmean(midnperc(f1trace,50)));
            f2.mid50p.(syllname) = nancat(f2.mid50p.(syllname),nanmean(midnperc(f2trace,50)));
        end
    end
    
end