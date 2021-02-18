function [] = gen_incomplete_datafile(subjectPath)
%function to generate data.mat file, when subject did not complete full
%experiment

%find temp directory
tempdirs = regexp(genpath(subjectPath),'[^;]*temp_trials','match')';
tempdirs = char(tempdirs);

%find last trial saved
trialnums = get_sortedTrials(tempdirs);
lastTrial = trialnums(end);

%get all data
alldata = struct;
    for i = 1:lastTrial
        load(fullfile(tempdirs,sprintf('%d.mat',i)))
        names = fieldnames(data);
        for j = 1:length(names)
            alldata(i).(names{j}) = data.(names{j});
        end
    end
  
    % save data
    fprintf('Saving data... ')
    clear data
    data = alldata;
    save(fullfile(subjectPath,'data.mat'), 'data')
    fprintf('saved.\n')
    
%delete temp directory?
end