function se=nanste(x)
% Code written by Shanqing Cai. Originally from github.com/shanqing-cai/commonmcode. Also in the blab-lab/audapter_matlab repo

x1=x(~isnan(x));
se=ste(x1);    
return
