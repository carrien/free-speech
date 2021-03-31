function [shortPath] = shortenPath(path)
%SHORTENPATH  Replace long path prefixes with shortened form.

shortPath = path;

prefixes = {'\\wcs-cifs.waisman.wisc.edu\wc\smng\'};
for p = 1:length(prefixes)
    prefix = prefixes{p};
    if startsWith(path,prefix)
        shortPath(1:length(prefix)) = 'smng\';
    end
end
