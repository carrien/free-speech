function se=nanste(x)
% Code written by Shanqing Cai. Originally from github.com/shanqing-cai/commonmcode

x1=x(~isnan(x));
se=ste(x1);    
return
