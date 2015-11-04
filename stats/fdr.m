function varargout = fdr(p,alpha,varargin)
% [h,q] = fdr(p,[dim]);
    
    ip = inputParser;
    ip.addRequired('p',@isnumeric);
    ip.addRequired('alpha',@isscalar);
    ip.addOptional('dim',1,@isscalar);
    
    ip.parse(p,alpha,varargin{:});
    dim = ip.Results.dim;
    
    if(dim == 2)
        p = p';
    end
    
    q = zeros(size(p));
    h = zeros(size(p));
    
    for cc = 1:size(p,2),
        % just do vector now
        [sp,ri] = sort(p(:,cc));
        [nil,ri] = sort(ri);
        r = (1:size(p,1))';
        h0 = sp < r / size(p,1) * alpha;
        if(any(h0))
            h(r <= max(r(h0)),cc)=1;
            h(:,cc) = h(r(ri),cc);
        end
        
        if(nargout == 2)
            q(:,cc) = size(p,dim) .* sp ./ r;
            jj = size(q,1);
            for ii = size(q,dim):-1:1
                q(ii,cc) = min(q(ii,cc),q(jj,cc));
                if(q(ii,cc) <= q(jj,cc))
                    jj = ii;
                end
            end
            q(:,cc) = q(r(ri),cc);
        end
    end
    
    varargout = {h,q};