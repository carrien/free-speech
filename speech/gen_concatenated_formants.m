function [formantMatrix] = gen_concatenated_formants(dataVals, conds_to_analyze)
%This function takes the F1 and F2 values from dataVals, eliminates the
%NaN trials, and concatenates all of the trials that were passed as parameters.
%   An example conds_to_analyze parameter = expt.inds.conds.baseline2 or expt.inds.conds.hold(201:240)
F1 = [];
F2 = [];
%vowels to look for list:
vowels = {'IY','IH','EH','AE','AA','AH','OW','UW','EY','UH','ER','AO','AW','AY','OY'};
%Not sure if we are including the 'ER' vowel?
%Should I include these vowels too? 'EYStart' 'AHStart' 'UWStart' 'IYStart' 'EHStart' 'AEStart' 'UHStart' 'spnStart'
%These were included in gen_dataVals_from_wave_viewer^
token = [dataVals.token];
for idx = conds_to_analyze
    itrial = find(token == idx);
    if ~isempty(itrial)
        for i = 1:length(dataVals(itrial).segment)
            for v = 1:length(vowels)
                if strcmp(vowels{v}, dataVals(itrial).segment{1, i}) == 1
                    F1_vals = dataVals(itrial).f1{1, i};
                    F2_vals = dataVals(itrial).f2{1, i};
                    F1_vals(isnan(F1_vals)) = [];
                    F2_vals(isnan(F2_vals)) = [];
                    F1 = [F1;F1_vals];
                    F2 = [F2;F2_vals];
                    break
                end
            end
        end
    end
end
formantMatrix = [F1 F2];
end

