function [bus,metro]=f_utility(cell,i,j,ii,jj,dt)
rou=0.5;%出行可靠性的要求,整体风险态度
dn=5;%置信区间等分数
cl=0.98;%置信水平
fai1=0.2;%地铁变异系数
fai2=0.3;%公交变异系数
alfa=0.88;%风险规避程度
beita=0.88;%风险偏好程度
lamada=2.25;%风险规避系数
%===========划分小区间============
for k=1:cell{i,j}.route_num
    g(k)=cell{i,j}.bus_fee(k,dt);%公交费用
    XGMG(k)=abs(fai1*g(k));%计算方差
    AG(k)=g(k)-sqrt(XGMG(k))*norminv(0.5+0.5*cl,0,1);%计算置信区间(左边界)
    BG(k)=g(k)+sqrt(XGMG(k))*norminv(0.5+0.5*cl,0,1);%计算置信区间（右边界）
end
g(k+1)=cell{i,j}.metro_fee(dt);%地铁费用
XGMG(k+1)=abs(fai2*g(k+1));%计算方差
AG(k+1)=g(k+1)-sqrt(XGMG(k+1))*norminv(0.5+0.5*cl,0,1);%计算置信区间(左边界)
BG(k+1)=g(k+1)+sqrt(XGMG(k+1))*norminv(0.5+0.5*cl,0,1);%计算置信区间（右边界）
for k=1:cell{i,j}.route_num+1
    for kk=0:dn
        x(k,kk+1)=AG(k)+kk*(BG(k)-AG(k))/dn;%小区间边界
    end
    for kk=0:dn-1
        xx(k,kk+1)=AG(k)+(2*kk+1)*(BG(k)-AG(k))/(2*dn);%小区间中值
        px(k,kk+1)=normcdf(x(k,kk+2),g(k),sqrt(XGMG(k)))-normcdf(x(k,kk+1),g(k),sqrt(XGMG(k)));%概率分布
    end
    rp(k)=g(k)+sqrt(XGMG(k))*norminv(rou,0,1);%出行预算
end
%=============计算效用===========================
%=============设定参照点===========
cell{i,j}.cell{ii,jj}.u0=min(rp)+cell{i,j}.cell{ii,jj}.risk*(max(rp)-min(rp));
%=============计算前景效用=========
u0=cell{i,j}.cell{ii,jj}.u0;
for k=1:cell{i,j}.route_num+1
    for kk=1:dn
        if xx(k,kk)<=u0
            vg(k,kk)=(u0-xx(k,kk))^alfa;%收益
        else
            vg(k,kk)=-lamada*(xx(k,kk)-u0)^beita;%损失
        end
    end
    if xx(k,1)>=u0
        kkstar=1;
    elseif xx(k,dn)<=u0
        kkstar=dn;
    end
    for kk=2:dn
        if vg(k,kk-1)>=0&&vg(k,kk)<0
            kkstar=kk;%记录参考点之后的第一个位置
        end
    end
    Futility(k,1)=0;
    for kk=kkstar:dn
        wp(k,1)=wwww(sum(px(k,kk:dn)))-wwww(sum(px(k,kk+1:dn)));
        Futility(k,1)=Futility(k,1)+vg(k,kk)*wp(k,1);%损失
    end
    Futility(k,2)=0;
    for kk=1:kkstar-1
        wp(k,2)=wwww(sum(px(k,1:kk)))-wwww(sum(px(k,1:kk-1)));
        Futility(k,2)=Futility(k,2)+vg(k,kk)*wp(k,2);%收益
    end
    f_u(k)=Futility(k,1)+Futility(k,2);%地铁前景效用
end
bus=f_u(1:cell{i,j}.route_num);
metro=f_u(cell{i,j}.route_num+1);
end
