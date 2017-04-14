function [fps] = sort_files(filepaths,suffix_delimiter)
%SORT_FILES  Sort filenames by suffixes, allowing for missing zero suffix.

if nargin < 2, suffix_delimiter = '-'; end

nfiles = length(filepaths);
fps = cell(1,nfiles);

for f=1:nfiles
    [~,fname] = fileparts(filepaths{f}); % get filename
    bSuffixFound = 0; % start looking for suffix in this filename
    for ff=1:nfiles-1 % highest numerical suffix
        suffix = sprintf('%s%d',suffix_delimiter,ff);
        if strfind(fname,suffix)
            if isempty(fps{ff+1})
                fps{ff+1} = filepaths{f};
                bSuffixFound = 1;
            else
                error('Multiple filenames contain the suffix %s',suffix);
            end
        end
    end
    if ~bSuffixFound
        if isempty(fps{1})
            fps{1} = filepaths{f};
        else
            error('Multiple filenames contain the suffix %s',suffix);
        end
    end
end
