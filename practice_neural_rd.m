%==================出发时间、出行方式配流（基于元胞神经网络模型）=======
clc
clear
close all
OD_demand(:,:,1)=xlsread('OD.xlsx','demand');%OD需求矩阵
OD=OD_demand(:,:,1);
TT_metro=xlsread('OD.xlsx','metro_time');%OD间地铁运行时间矩阵
DIS=xlsread('OD.xlsx','distance');%OD间距离;
bus_fare=xlsread('OD.xlsx','bus_fare');%OD间公交票价
metro_fare=xlsread('OD.xlsx','metro_fare');%OD间地铁票价
shutdown=[2,4,10];%停运的地铁站（可调节）
t_e=1;
t_T=10;
M=5;%每天5个出发时刻
tte=20;%早到时间
tta=60;%上班时间
[num_station,~]=size(OD);%站点数量
num_line=2;%最大公交线路数量（一条既有线，一条机动线）
theita=1.5;%效用感知系数

kesei=0.1;%非交互效用系数
capacity_bus=500;%拥挤阈值
capacity_metro=1000;%拥挤阈值
N_agent_length=5;%元胞空间边长

theita_l_so=0.7;%交互水平
%==============公交线路======================
x_route(1,1:num_station)=1;%既有公交线是站站都停
%x_route(2,1:num_station)=[1,0,1,0,1,0,0,0,0,0];%机动线路（元胞神经网络）
x_route(2,1:num_station)=[1,1,0,1,0,0,0,0,0,1];%仅接驳停运站点
%x_route(2,1:num_station)=[1,1,1,1,1,1,1,1,1,1];
%x_route(2,1:num_station)=[1,0,0,0,1,1,0,0,0,0];%机动线路（logit）
for i=1:num_line
    k_0=0;
    for j=1:num_station
        if x_route(i,j)~=0
            k_0=k_0+1;
            route(i,k_0)=j;%记录站点编号
        end
    end
end
[num_route,~]=size(route);
%============发车频率（依据实际数据获得）=========
f_metro=5;
for i=1:num_line
    f_route(i)=7;
end
%===========================线路初始化===============
for i=1:num_station
    for j=1:num_station
        cell{i,j}.route_num=0;%线路数量
        cell{i,j}.agent_utility=0;
        cell{i,j}.route=[];
        cell{i,j}.route_length=[];
        cell{i,j}.bus_travel_time=[];
        cell{i,j}.metro_travel_time=[];
        cell{i,j}.bus_wait_time=[];
        cell{i,j}.metro_wait_time=[];
        cell{i,j}.bus_fare=[];
        cell{i,j}.metro_fare=[];
        cell{i,j}.real_route=[];
        cell{i,j}.direction=[];
        cell{i,j}.bus_fee=[];
        cell{i,j}.metro_fee=[];
        cell{i,j}.departure_fee=[];
        cell{i,j}.wd=[];
        cell{i,j}.wr=[];
        %=========确定每个OD间线路数量与名称============
        for k=1:num_route
            if ismember(i,route(k,:))&&ismember(j,route(k,:))&&(i~=j)
                cell{i,j}.route_num=cell{i,j}.route_num+1;
                cell{i,j}.route=[cell{i,j}.route,k];%添加线路名称
                cell{i,j}.i_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),i));%定位起点在线路中的位置
                cell{i,j}.j_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),j));%定位终点在线路中的位置
                if cell{i,j}.i_locate(cell{i,j}.route_num,1)<cell{i,j}.j_locate(cell{i,j}.route_num,1)%方向
                    cell{i,j}.direction(cell{i,j}.route_num,1)=1;%上行
                else
                    cell{i,j}.direction(cell{i,j}.route_num,1)=-1;%下行
                end
            end
        end
        %==============计算每个OD间的实际路径==============
        cell{i,j}.real_route=zeros(cell{i,j}.route_num,num_station);
        for k=1:cell{i,j}.route_num
            if cell{i,j}.direction(k)==1%上行实际的路径
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1));
            elseif cell{i,j}.direction(k)==-1%下行实际的路径
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1));
            end
        end
        %===========初始化选择概率=================
        [cell{i,j}.wr,cell{i,j}.wd]=rand_r_d(cell,i,j,M);
    end
end
%==========================开始演化=========================
while t_e<=t_T
    dt=1;
    q=zeros(num_station,num_station,num_line,M);%路段实时流量矩阵
    while dt<=M%每一时间段
        for i=1:num_station
            for j=1:num_station
                %===========公交行程时间、等待时间、票价=================
                for k=1:cell{i,j}.route_num
                    %============票价==============
                    cell{i,j}.bus_fare(k)=bus_fare(i,j);%票价
                    %===========行程时间==================
                    cell{i,j}.bus_travel_time(k,dt)=0;
                    non_zero=cell{i,j}.real_route(k,(find(cell{i,j}.real_route(k,:)~=0)));%提取实际线路
                    for kk=1:length(non_zero)-1
                        if t_e==1
                            cell{i,j}.bus_travel_time(k,dt)=cell{i,j}.bus_travel_time(k,dt)+TT_metro(non_zero(kk),non_zero(kk+1))*1.4;%线路行程时间
                        else
                            cell{i,j}.bus_travel_time(k,dt)=cell{i,j}.bus_travel_time(k,dt)+TT_metro(non_zero(kk),non_zero(kk+1))*1.4*(1+0.15*(cell{i,j}.bus_crowd(k,dt)/(f_route(cell{i,j}.route(k))*capacity_bus))^4);%线路行程时间
                        end
                    end
                    %==========等待时间=============
                    if t_e==1
                        cell{i,j}.bus_wait_time(k,dt)=1/f_route(cell{i,j}.route(k));%公交等待时间
                    else
                        cell{i,j}.bus_wait_time(k,dt)=cell{i,j}.bus_crowd(k,dt)/(f_route(cell{i,j}.route(k))*capacity_bus);%公交等待时间
                    end
                end
                %===========地铁行程时间、等待时间、票价=================
                cell{i,j}.metro_travel_time=TT_metro(i,j);%地铁行程时间
                cell{i,j}.metro_fare=metro_fare(i,j);%地铁票价
                if i~=j
                    if t_e==1
                        cell{i,j}.metro_wait_time(dt)=1/f_metro;%地铁等待时间
                    else
                        cell{i,j}.metro_wait_time(dt)=cell{i,j}.metro_q(dt)/(f_metro*capacity_metro);%地铁等待时间
                    end
                end
                %===========计算广义出行费用或活动效用=====================
                if i~=j
                    %========公交车广义费用==================
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_fee(k,dt)=kesei*cell{i,j}.bus_travel_time(k,dt)+kesei*cell{i,j}.bus_wait_time(k,dt)+kesei*cell{i,j}.bus_fare(k);
                    end
                    %========地铁广义费用==================
                    cell{i,j}.metro_fee(dt)=kesei*cell{i,j}.metro_travel_time+kesei*cell{i,j}.metro_wait_time(dt)+kesei*cell{i,j}.metro_fare;
                    %========出发时间效用===================
                    cell{i,j}.departure_fee(dt)=sue_fee_dd(cell,i,j,tte,tta,dt);
                    %===================计算选择不同运输方式的人数============================
                    %%%%%%%%%%%%%%%%%%%%%%%元胞神经网络累积前景效用分流%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %cell=multi_agent_neural_CPT_dt(t_e,dt,i,j,cell,OD,N_agent_length,theita_l_so,shutdown);
                    %%%%%%%%%%%%%%%%%%%%%%%logit模型累积前景效用分流%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    cell=logit_CPT_dt(dt,i,j,cell,OD,theita,shutdown);
                    bus_q(i,j)=mean(cell{i,j}.bus_q(:,dt));%检查收敛性
                end
            end
        end
        %============检查收敛性==============
        if t_e==1
            q_var(t_e)=0;
        else
            bus_qq(t_e)=mean(mean(bus_q(:,:)));%检查收敛性
            q_var(t_e)=abs(bus_qq(t_e)-bus_qq(t_e-1))/max(bus_qq(1:t_e));%检查收敛性
        end
        %=============计算每条线路的使用情况(更新实时路段流量)===============
        q=zeros(num_station,num_station,num_line,M);%2条线路，5个出发时间
        for ii=1:num_station
            for jj=1:num_station
                for k=1:num_line
                    if ii==jj
                        q(ii,jj,k,dt)=0;
                    elseif t_e>1
                        if isempty(find(cell{ii,jj}.route==k))==1
                            q(ii,jj,k,dt)=0;
                        else
                            q(ii,jj,k,dt)=cell{ii,jj}.bus_q(find(cell{ii,jj}.route==k),dt);
                            %===========后续持续占用路径==============
                            travel_time_int=floor(cell{ii,jj}.bus_travel_time(find(cell{ii,jj}.route==k),dt)/10);%行程时间取整
                            for iii=1:travel_time_int
                                if dt+iii<=M
                                    q(ii,jj,k,dt+iii)=cell{ii,jj}.bus_q(find(cell{ii,jj}.route==k),dt);
                                end
                            end
                        end
                    end
                end
            end
        end
        %===========计算每个路段的拥挤程度（上行）================
        for k=1:size(route,1)
            for ii=1:size(route,2)-1
                if route(k,ii)*route(k,ii+1)==0
                    crowd(k,ii,dt,1)=0;%上行
                else
                    if ii==1
                        crowd(k,ii,dt,1)=0;
                        for jj=ii+1:size(route,2)
                            if route(k,jj)~=0
                                crowd(k,ii,dt,1)=crowd(k,ii,dt,1)+q(route(k,ii),route(k,jj),k,dt);
                            end
                        end
                    else
                        q_hou=0;
                        q_qian=0;
                        for jj=ii+1:size(route,2)
                            if route(k,jj)~=0
                                q_hou=q_hou+q(route(k,ii),route(k,jj),k,dt);
                            end
                        end
                        for jj=1:ii
                            if route(k,jj)~=0
                                q_qian=q_qian+q(route(k,jj),route(k,ii),k,dt);
                            end
                        end
                        crowd(k,ii,dt,1)=crowd(k,ii-1,dt,1)+q_hou-q_qian;
                    end
                end
            end
        end
        %===========计算每个路段的拥挤程度（下行）================
        for k=1:size(route,1)
            for ii=size(route,2):-1:2
                if route(k,ii)*route(k,ii-1)==0
                    crowd(k,ii-1,dt,2)=0;%下行
                else
                    if ii==size(route,2)
                        crowd(k,ii-1,dt,2)=0;
                        for jj=ii-1:-1:1
                            if route(k,jj)~=0
                                crowd(k,ii-1,dt,2)=crowd(k,ii-1,dt,2)+q(route(k,ii),route(k,jj),k,dt);
                            else
                                crowd(k,ii-1,dt,2)=0;
                            end
                        end
                    else
                        q_hou=0;
                        q_qian=0;
                        for jj=1:ii-1
                            if route(k,jj)~=0
                                q_hou=q_hou+q(route(k,ii),route(k,jj),k,dt);
                            end
                        end
                        for jj=ii:size(route,2)
                            if route(k,jj)~=0
                                q_qian=q_qian+q(route(k,jj),route(k,ii),k,dt);
                            end
                        end
                        crowd(k,ii-1,dt,2)=crowd(k,ii,dt,2)+q_hou-q_qian;
                    end
                end
            end
        end
        %==================计算每个OD间的拥挤度===================
        for i=1:num_station
            for j=1:num_station
                for k=1:cell{i,j}.route_num
                    if cell{i,j}.direction(k)==1
                        cell{i,j}.bus_crowd(k,dt)=sum(crowd(cell{i,j}.route(k),cell{i,j}.i_locate(k):cell{i,j}.j_locate(k)-1,dt,1));
                    elseif cell{i,j}.direction(k)==-1
                        cell{i,j}.bus_crowd(k,dt)=sum(crowd(cell{i,j}.route(k),cell{i,j}.j_locate(k):cell{i,j}.i_locate(k)-1,dt,2));
                    end
                end
            end
        end
        dt=dt+1;
    end
    %===============计算选择不同出发时间的人数=====================
    for i=1:num_station
        for j=1:num_station
            if i~=j
                for dt=1:M
                    cell{i,j}.wd(dt)=exp(theita*kesei*cell{i,j}.departure_fee(dt))/sum(exp(theita*kesei*cell{i,j}.departure_fee(:)));
                end
            end
        end
    end
    %===============统计连续的行程时间===============
    for i=1:num_station
        for j=1:num_station
            if i==j
                t_time(i,j,t_e)=0;
                efficiency(i,j,t_e)=0;
            else
                for k=1:cell{i,j}.route_num
                    for dt=1:M
                        t_w_time(k,dt)=cell{i,j}.bus_travel_time(k,dt)+cell{i,j}.bus_wait_time(k,dt)+cell{i,j}.metro_wait_time(dt)+cell{i,j}.metro_travel_time;
                    end
                end
                t_time(i,j,t_e)=mean(mean(t_w_time(:,:)));%行程时间
                efficiency(i,j,t_e)=DIS(i,j)/t_time(i,j,t_e);%韧性
            end
        end
    end
    t_e=t_e+1;
end
%=======统计效用========
S_utility=0;
for i=1:num_station
    for j=1:num_station
        S_utility=S_utility+cell{i,j}.agent_utility/(N_agent_length^2);%元胞神经网络
        %==================logit模型===========
%         if i~=j
%             for k=1:cell{i,j}.route_num
%                 route_utility(k)=(sum(cell{i,j}.bus_q(k,:))/OD(i,j))*sum(cell{i,j}.bus_cpt_utility(k,:));
%             end
%             S_utility(i,j)=sum(route_utility(:))+(sum(cell{i,j}.metro_q(:))/OD(i,j))*sum(cell{i,j}.metro_cpt_utility(:));
%         end
    end
end
S_mutility=S_utility/((num_station-1)^2);%元胞神经网络
%S_mutility=sum(sum(S_utility(:,:)))/((num_station-1)^2);
%===================记录行程时间、断面流量、奖励值（韧性）=======
%============行程时间===========
S_mt=mean(mean(t_time(:,:,t_T)));
%====================断面流量==============
S_sf=mean(mean(mean(mean(crowd))));
%===================韧性=================
R_re=mean(mean(mean(efficiency)));
