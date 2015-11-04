function [] = gen_acousticdata_fusp_varFx(snum,word)
exptName = 'vin';
noises = [0 450 900];
if isempty(word)
    subdirname = 'all';
else subdirname = word(2:end);
end

for i = 1:length(noises)
    dirs{i} = fullfile(getAcoustSubjPath(exptName),'rawfusp',...
        get_fuspdir(exptName,snum,sprintf('%s_%d',word,noises(i))),'speak');
end
savePath = getAcoustSubjPath(exptName,snum,subdirname);

gen_acousticdata_fusp_merge(dirs,[],savePath);
gen_expt_file(exptName,snum,dirs,savePath);