function [ ] = gen_resampledData(dataPaths)
%GEN_RESAMPLEDDATA  Generate resampled data for multiple subject paths.

if ischar(dataPaths), dataPaths = {dataPaths}; end

fs = 11025;

for dP = 1:length(dataPaths)
    dataPath = dataPaths{dP};
    filePath = fullfile(dataPath,'data.mat');
    origPath = fullfile(dataPath,'data_orig.mat');
    success = copyfile(filePath,origPath);
    if success
        fprintf('Copied %s to %s.\n',filePath,origPath)
        rec = load(filePath);
        data = resample_data(rec.data,fs);
        save(filePath,'data');
        fprintf('Saved new %d-Hz file %s.\n',fs,filePath)
    else
        warning('Could not copy %s.',filePath)
    end
end
