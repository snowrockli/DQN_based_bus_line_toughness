function result=sue_fee_dd(cell,i,j,tte,tta,dt)
alfa=0.88;%���չ�̶ܳ�
beita=0.88;%����ƫ�ó̶�
lamada1=0.2;%���չ��ϵ��������ʱ�䣩
lamada2=0.33;%���չ��ϵ��������ʱ�䣩
u0=tte+(tta-tte)/2;
rdt=(dt-1)*10;%����ʱ�任��
for k=1:cell{i,j}.route_num
    if rdt+cell{i,j}.bus_travel_time(k,dt)>=tte&&rdt+cell{i,j}.bus_travel_time(k,dt)<u0
        futillity(k)=lamada1*(rdt+cell{i,j}.bus_travel_time(k,dt)-tte)^alfa;%����
    elseif rdt+cell{i,j}.bus_travel_time(k,dt)>=u0&&rdt+cell{i,j}.bus_travel_time(k,dt)<=tta
        futillity(k)=lamada1*(tta-rdt-cell{i,j}.bus_travel_time(k,dt))^alfa;%����
    elseif rdt+cell{i,j}.bus_travel_time(k,dt)<tte%����̫��
        futillity(k)=-lamada2*(tte-rdt-cell{i,j}.bus_travel_time(k,dt))^beita;
    elseif rdt+cell{i,j}.bus_travel_time(k,dt)>tta%����̫��
        futillity(k)=-lamada2*(rdt+cell{i,j}.bus_travel_time(k,dt)-tta)^beita;
    end
end
result=sum(futillity(:));
return