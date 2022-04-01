function [inds] = get_exptInds(expt,elements)
%GET_EXPTINDS  Calculate indices of trial types for an expt object.
%   GET_EXPTINDS(EXPT,ELEMENTS)
%  EXPT: required.
%  ELEMENTS: optional. Cell array of strings. If provided, function will
%    make fields in expt.inds with the strings from ELEMENTS. If left
%    empty, function will search EXPT for fields named X and allX and make
%    fields in expt.inds using X.

%% determine which elements to put in inds
if nargin < 2 || isempty(elements)
    elements = cell(0, 1);

    % get names of fields in expt
    fields = fieldnames(expt);

    % loop over fields that contain 'all'
    for fIx = find(contains(fields, 'all'))'

        % only consider fields that begin with 'all' and then have an uppercase
        % letter immediately after (eg, 'allWords')
        if length(fields{fIx}) > 3 && matches(fields{fIx}(1:3), 'all') && isstrprop(fields{fIx}(4), 'upper')

            % get the version of the field name without 'all' at the start (eg, 'words')
            element = sprintf('%s%s', lower(fields{fIx}(4)), fields{fIx}(5:end));

            % check if a field exists with that name
            element_ix = find(matches(fields, element));
            if element_ix

                % make sure the contents of that field could become field names
                % in expt.inds. For example, fields whose contents are
                % numeric such as [0] cannot be a field name.
                try
                    if isvarname(expt.(fields{element_ix}) {1})     % eg, expt.(words){1} = 'bed' --> OK
                        elements(length(elements)+1) = fields(element_ix);
                    end
                catch
                end
            end
        end
    end
end

%% generate inds
allElements = cell(1, length(elements));

for ie=1:length(elements)
    allElements{ie} = sprintf('all%s%s',upper(elements{ie}(1)),elements{ie}(2:end));
    for ia=1:length(expt.(elements{ie}))
        inds.(elements{ie}).(expt.(elements{ie}){ia}) = find(expt.(allElements{ie}) == ia);
    end
end
