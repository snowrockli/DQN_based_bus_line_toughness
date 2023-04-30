function [wr,wd]=rand_r_d(cell,i,j,M)
for k=1:cell{i,j}.route_num+1
    randr(k)=rand;
end
for k=1:M
    randd(k)=rand;
end
randxigemar=sum(randr(:));
randxigemad=sum(randd(:));
for k=1:cell{i,j}.route_num+1
    wr(k)=randr(k)/randxigemar;
end
for k=1:M
    wd(k)=randd(k)/randxigemad;
end
return