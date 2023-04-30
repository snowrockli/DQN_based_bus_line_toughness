function [bus,metro]=f_utility(cell,i,j,ii,jj,dt)
rou=0.5;%���пɿ��Ե�Ҫ��,�������̬��
dn=5;%��������ȷ���
cl=0.98;%����ˮƽ
fai1=0.2;%��������ϵ��
fai2=0.3;%��������ϵ��
alfa=0.88;%���չ�̶ܳ�
beita=0.88;%����ƫ�ó̶�
lamada=2.25;%���չ��ϵ��
%===========����С����============
for k=1:cell{i,j}.route_num
    g(k)=cell{i,j}.bus_fee(k,dt);%��������
    XGMG(k)=abs(fai1*g(k));%���㷽��
    AG(k)=g(k)-sqrt(XGMG(k))*norminv(0.5+0.5*cl,0,1);%������������(��߽�)
    BG(k)=g(k)+sqrt(XGMG(k))*norminv(0.5+0.5*cl,0,1);%�����������䣨�ұ߽磩
end
g(k+1)=cell{i,j}.metro_fee(dt);%��������
XGMG(k+1)=abs(fai2*g(k+1));%���㷽��
AG(k+1)=g(k+1)-sqrt(XGMG(k+1))*norminv(0.5+0.5*cl,0,1);%������������(��߽�)
BG(k+1)=g(k+1)+sqrt(XGMG(k+1))*norminv(0.5+0.5*cl,0,1);%�����������䣨�ұ߽磩
for k=1:cell{i,j}.route_num+1
    for kk=0:dn
        x(k,kk+1)=AG(k)+kk*(BG(k)-AG(k))/dn;%С����߽�
    end
    for kk=0:dn-1
        xx(k,kk+1)=AG(k)+(2*kk+1)*(BG(k)-AG(k))/(2*dn);%С������ֵ
        px(k,kk+1)=normcdf(x(k,kk+2),g(k),sqrt(XGMG(k)))-normcdf(x(k,kk+1),g(k),sqrt(XGMG(k)));%���ʷֲ�
    end
    rp(k)=g(k)+sqrt(XGMG(k))*norminv(rou,0,1);%����Ԥ��
end
%=============����Ч��===========================
%=============�趨���յ�===========
cell{i,j}.cell{ii,jj}.u0=min(rp)+cell{i,j}.cell{ii,jj}.risk*(max(rp)-min(rp));
%=============����ǰ��Ч��=========
u0=cell{i,j}.cell{ii,jj}.u0;
for k=1:cell{i,j}.route_num+1
    for kk=1:dn
        if xx(k,kk)<=u0
            vg(k,kk)=(u0-xx(k,kk))^alfa;%����
        else
            vg(k,kk)=-lamada*(xx(k,kk)-u0)^beita;%��ʧ
        end
    end
    if xx(k,1)>=u0
        kkstar=1;
    elseif xx(k,dn)<=u0
        kkstar=dn;
    end
    for kk=2:dn
        if vg(k,kk-1)>=0&&vg(k,kk)<0
            kkstar=kk;%��¼�ο���֮��ĵ�һ��λ��
        end
    end
    Futility(k,1)=0;
    for kk=kkstar:dn
        wp(k,1)=wwww(sum(px(k,kk:dn)))-wwww(sum(px(k,kk+1:dn)));
        Futility(k,1)=Futility(k,1)+vg(k,kk)*wp(k,1);%��ʧ
    end
    Futility(k,2)=0;
    for kk=1:kkstar-1
        wp(k,2)=wwww(sum(px(k,1:kk)))-wwww(sum(px(k,1:kk-1)));
        Futility(k,2)=Futility(k,2)+vg(k,kk)*wp(k,2);%����
    end
    f_u(k)=Futility(k,1)+Futility(k,2);%����ǰ��Ч��
end
bus=f_u(1:cell{i,j}.route_num);
metro=f_u(cell{i,j}.route_num+1);
end
