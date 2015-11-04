function nfigs = getnfigs()
%GETNFIGS  Returns max figure number on screen.

nfigs = max(get(0,'children'));
if nfigs
else nfigs = 0;
end