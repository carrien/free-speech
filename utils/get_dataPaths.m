function [dataPaths] = get_dataPaths(exptName,svec,varargin)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

dataPaths = cell(1,length(svec));
for s=1:length(svec)
    sid = sprintf('s%02d',svec(s));
    dataPaths{s} = getAcoustSubjPath(exptName,sid,varargin{:});
end

% if single subject, return string instead of cell array
if length(dataPaths)==1
    dataPaths = dataPaths{1};
end