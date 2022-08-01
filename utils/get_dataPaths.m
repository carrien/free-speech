function [dataPaths] = get_dataPaths(exptName)
%GET_DATAPATHS Get data paths for a given experiment.
%   GET_DATAPATHS(EXPTNAME)

dataPaths = feval(sprintf('get_dataPaths_%s',exptName));

end
