F=[0,0,0];
for i=1:num_station
    for j=1:num_station
        if i~=j
            for k=1:cell{i,j}.route_num%线路流量
                for dt=1:5
                    bus_q(k,dt)=cell{i,j}.bus_q(k,dt);
                end
                F(cell{i,j}.route(k))=F(cell{i,j}.route(k))+sum(bus_q(k,:));
            end
            for dt=1:5
                metro_q(dt)=cell{i,j}.metro_q(dt);
            end
            F(cell{i,j}.route_num+1)=F(cell{i,j}.route_num+1)+sum(metro_q(:));
            for d=1:5%出发时间流量
                F_d(i,j,d)=cell{i,j}.wd(d);
            end
        end
    end
end
F_d_d=[mean(mean(F_d(:,:,1))),mean(mean(F_d(:,:,2))),mean(mean(F_d(:,:,3))),mean(mean(F_d(:,:,4))),mean(mean(F_d(:,:,5)))];
DD=F.*F_d_d';%出行矩阵
%============画图==========
x=1:5;
y=1:3;
z=DD';
figure
mesh(x,y,z);
set(gca,'XTickLabel',{'8:00','8:10','8:20','8:30','8:40'});
view(135,35);%方位角
xlabel('departure time');ylabel('route');zlabel('traffic flow');