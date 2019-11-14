function [T] = get_datatable(data,fact)
%GET_DATATABLE  Convert data and factors to a table.
%   GET_DATATABLE(DATA,FACT)

measures = fieldnames(data);
nmeasures = length(measures);
lengths = zeros(1,nmeasures);
for m = 1:nmeasures
    measname = measures{m};
    lengths(m) = length(data.(measname));
    if m > 1 && lengths(m) ~= lengths(m-1)
        error('Mismatch between %s (length %d) and previous values (length %d).',measname, lengths(m), lengths(m-1))
    end
end
nObs = unique(lengths);

factors = fieldnames(fact);
nfactors = length(factors);
for f = 1:nfactors
    factname = factors{f};
    factval = fact.(factname);
    if isnumeric(factval) % if a number
        if length(factval)==1
            data.(factname) = factval*ones(nObs,1);
        elseif iscolumn(factval) && length(factval)==nObs
            data.(factname) = factval;
        elseif isrow(factval) && length(factval)==nObs
            data.(factname) = factval';
        else
            error('Length of factor is %d. Factor must either be a single element or have the same number of elements as the data to be added (length: %d).',length(factval),nObs);
        end
    elseif ischar(factval)
        C = cell(nObs,1);
        C(:) = {factval};
        data.(factname) = C;
    elseif iscell(factval)
        if length(factval)==1
            C = cell(nObs,1);
            C(:) = factval;
            data.(factname) = C;
        elseif iscolumn(factval) && length(factval)==nObs
            data.(factname) = factval;
        elseif isrow(factval) && length(factval)==nObs
            data.(factname) = factval';
        else
            error('Length of factor is %d. Factor must either be a single element or have the same number of elements as the data to be added (length: %d).',length(factval),nObs);
        end
    end
end

T = struct2table(data);

end
