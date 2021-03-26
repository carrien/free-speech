function [Tables] = validate_exptSetup(dataPath, groupings, bInterpret)
% Tallies up the number of trials in various pairs of experimental
%   groupings, such as condition, word, color, etc. Used to validate that
%   trials were correctly distributed among groupings.
%
% INPUT ARGUMENTS:
%   dataPath. The file location of the expt.mat file to evaluate. Defaults
%     to the current directory.
%   groupings. A cell array of strings, where each string is the name of a
%     field in expt.inds that you want to evaluate. Defaults to use all
%     fields in expt.inds.
%   bInterpret. A binary flag for if you want to print information to the
%     screen about how to interpret your results. Defaults to 1 (print
%     results).
%
% OUTPUT ARGUMENTS:
%   Tables. Returns a cell array where each cell is a table of paired
%     groupings.
%
% v1 2021-03 CWN


warnStruct = warning; % collect current warning settings
warning('off', 'MATLAB:table:RowsAddedExistingVars'); % turn off table-related warning


if nargin < 1 || isempty(dataPath), dataPath = pwd; end
load(fullfile(dataPath,'expt.mat'), 'expt');
if nargin < 2 || isempty(groupings), groupings = fieldnames(expt.inds)'; end
if nargin < 3 || isempty(bInterpret), bInterpret = 1; end

perms = nchoosek(groupings, 2);
Tables = cell(1, size(perms, 1)); %preallocate

for permIx = 1:size(perms, 1)
    perm1 = perms{permIx, 1};   %string, eg, 'conds'
    perm2 = perms{permIx, 2};   
    
    % make matrix comparing trial numbers for perm1 and perm2
    dataAsMat = zeros(length(expt.(perm1))+1, length(expt.(perm2))+1); % preallocate
    for i = 1:length(expt.(perm1))
        for j = 1:length(expt.(perm2))
            dataAsMat(i, j) = length(intersect(expt.inds.(perm1).(expt.(perm1){i}), ...
                expt.inds.(perm2).(expt.(perm2){j})));
        end
        % get subtotals for perm1
        dataAsMat(i, end) = length(expt.inds.(perm1).(expt.(perm1){i}));
    end
    
    % get subtotals for perm2
    for j = 1:length(expt.(perm2))
        dataAsMat(end, j) = length(expt.inds.(perm2).(expt.(perm2){j}));
    end
    
    % Make sure subtotals add up to grand total (expt.ntrials) properly
    dataAsMat(end) = expt.ntrials;
    if      expt.ntrials ~= sum(dataAsMat(end, 1:end-1)) || ...
            expt.ntrials ~= sum(dataAsMat(1:end-1, end)) || ...
            sum(dataAsMat(end, 1:end-1)) ~= sum(dataAsMat(1:end-1, end))
        warning('Subtotals between two variables being compared don''t match.')
    end
    
    % initialize table. Insert matrix data into table format
    T = table;
    T.Variables = dataAsMat;
    
    % assign name to rows
    rowNames = [expt.(perm1), {'Total'}]; %eg, {'noShift' 'shiftIH' 'shiftAE' 'Total'}
    T.Properties.RowNames = rowNames;
    
    % rename columns
    for i = 1:length(expt.(perm2))
        T.Properties.VariableNames{i} = expt.(perm2){i};
    end
    T.Properties.VariableNames{end} = 'Total';
    
    % Add description (relevant for output argument Tables)
    T.Properties.Description = sprintf('%s (%s). %s and %s.', expt.snum, expt.name, perm1, perm2);
    
    %print it!
    fprintf('\nTable comparing %s and %s:\n', perm1, perm2)
    disp(T);
    
    Tables{permIx} = T;
end

% print how to interpret data
if bInterpret
    fprintf(['\n\n==========  How to interpret your results:  ==========\n' ...
        ' To read a table, each cell in the table represents the number of trials\n' ...
        '  that match on the row grouping and column grouping. (For example, if the\n' ...
        '  two groupings are WORDS and CONDS, the top left cell tells you\n' ...
        '  how many trials showed the first word in expt.words AND used the first\n' ...
        '  condition in expt.conds.\n\n']);
    fprintf([' Note that to interpret this data properly, you must first have an\n' ...
        '  understanding of what your data SHOULD look like.\n\n']);
    fprintf([' Depending on the type of experiment, you may want all of the numbers in a \n' ...
        '  particular row or column to be identical. (For example, within a particular \n' ...
        '  condition, you probably want to have each word be presented the same number \n' ...
        '  of times as any other word.) If that is what you want to be happening in\n' ...
        '  your experiment, just check that the number of trials in a row/column \n' ...
        '  is consistent.\n\n'])
    fprintf([' Note that this function can only compare data groupings that are \n' ...
        '  indexed within the `expt.inds` structure. If your experiment has \n' ...
        '  some type of manipulation with multiple categories (other than \n' ...
        '  `words` and `conds`), you should strongly consider adding that grouping\n' ...
        '  to the `expt.inds` structure.\n\n']);
end

% revert to previous warning settings
warning(warnStruct); 


end