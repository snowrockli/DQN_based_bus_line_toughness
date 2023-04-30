function [S_mt,S_sf,R_re]=f_value_rd(R_line,t,OD,TT_metro,DIS,bus_fare,metro_fare,shutdown)
t_e=1;
t_T=8;
M=5;%ÿ��5������ʱ��
tte=20;%�絽ʱ��
tta=60;%�ϰ�ʱ��
[num_station,~]=size(OD);%վ������
num_line=2;%��󹫽���·������һ�������ߣ�һ�������ߣ�
theita=1.5;%Ч�ø�֪ϵ��
kesei=0.1;%�ǽ���Ч��ϵ��
capacity_bus=500;%ӵ����ֵ
capacity_metro=1000;%ӵ����ֵ
N_agent_length=5;%Ԫ���ռ�߳�
theita_l_so=0.7;%����ˮƽ
%==============������·======================
x_route(1,1:num_station)=1;%���й�������վվ��ͣ
x_route(2,1:num_station)=[1,R_line(t,:)];%������·
T_stop=0.5*sum(R_line(t,:));%ͣվ�ķѵ�ʱ��
for i=1:num_line
    k_0=0;
    for j=1:num_station
        if x_route(i,j)~=0
            k_0=k_0+1;
            route(i,k_0)=j;%��¼վ����
        end
    end
end
[num_route,~]=size(route);
%============����Ƶ�ʣ�����ʵ�����ݻ�ã�=========
f_metro=5;
for i=1:num_line
    f_route(i)=7;
end
%===========================��·��ʼ��===============
for i=1:num_station
    for j=1:num_station
        cell{i,j}.route_num=0;%��·����
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
        %=========ȷ��ÿ��OD����·����������============
        for k=1:num_route
            if ismember(i,route(k,:))&&ismember(j,route(k,:))&&(i~=j)
                cell{i,j}.route_num=cell{i,j}.route_num+1;
                cell{i,j}.route=[cell{i,j}.route,k];%�����·����
                cell{i,j}.i_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),i));%��λ�������·�е�λ��
                cell{i,j}.j_locate(cell{i,j}.route_num,1)=find(ismember(route(k,:),j));%��λ�յ�����·�е�λ��
                if cell{i,j}.i_locate(cell{i,j}.route_num,1)<cell{i,j}.j_locate(cell{i,j}.route_num,1)%����
                    cell{i,j}.direction(cell{i,j}.route_num,1)=1;%����
                else
                    cell{i,j}.direction(cell{i,j}.route_num,1)=-1;%����
                end
            end
        end
        %==============����ÿ��OD���ʵ��·��==============
        cell{i,j}.real_route=zeros(cell{i,j}.route_num,num_station);
        for k=1:cell{i,j}.route_num
            if cell{i,j}.direction(k)==1%����ʵ�ʵ�·��
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.i_locate(k,1):cell{i,j}.j_locate(k,1));
            elseif cell{i,j}.direction(k)==-1%����ʵ�ʵ�·��
                cell{i,j}.route_length(k)=size(route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1)),2);
                cell{i,j}.real_route(k,1:cell{i,j}.route_length(k))=route(cell{i,j}.route(k),cell{i,j}.j_locate(k,1):cell{i,j}.i_locate(k,1));
            end
        end
        %===========��ʼ��ѡ�����=================
        [cell{i,j}.wr,cell{i,j}.wd]=rand_r_d(cell,i,j,M);
    end
end
%==========================��ʼ�ݻ�=========================
while t_e<=t_T
    dt=1;
    q=zeros(num_station,num_station,num_line,M);%·��ʵʱ��������
    while dt<=M%ÿһʱ���
        for i=1:num_station
            for j=1:num_station
                %===========�����г�ʱ�䡢�ȴ�ʱ�䡢Ʊ��=================
                for k=1:cell{i,j}.route_num
                    %============Ʊ��==============
                    cell{i,j}.bus_fare(k)=bus_fare(i,j);%Ʊ��
                    %===========�г�ʱ��==================
                    cell{i,j}.bus_travel_time(k,dt)=0;
                    non_zero=cell{i,j}.real_route(k,(find(cell{i,j}.real_route(k,:)~=0)));%��ȡʵ����·
                    for kk=1:length(non_zero)-1
                        if t_e==1
                            cell{i,j}.bus_travel_time(k,dt)=cell{i,j}.bus_travel_time(k,dt)+TT_metro(non_zero(kk),non_zero(kk+1))*1.4;%��·�г�ʱ��
                        else
                            cell{i,j}.bus_travel_time(k,dt)=cell{i,j}.bus_travel_time(k,dt)+TT_metro(non_zero(kk),non_zero(kk+1))*1.4*(1+0.15*(cell{i,j}.bus_crowd(k,dt)/(f_route(cell{i,j}.route(k))*capacity_bus))^4);%��·�г�ʱ��
                        end
                    end
                    %==========�ȴ�ʱ��=============
                    if t_e==1
                        cell{i,j}.bus_wait_time(k,dt)=1/f_route(cell{i,j}.route(k));%�����ȴ�ʱ��
                    else
                        cell{i,j}.bus_wait_time(k,dt)=cell{i,j}.bus_crowd(k,dt)/(f_route(cell{i,j}.route(k))*capacity_bus);%�����ȴ�ʱ��
                    end
                end
                %===========�����г�ʱ�䡢�ȴ�ʱ�䡢Ʊ��=================
                cell{i,j}.metro_travel_time=TT_metro(i,j);%�����г�ʱ��
                cell{i,j}.metro_fare=metro_fare(i,j);%����Ʊ��
                if i~=j
                    if t_e==1
                        cell{i,j}.metro_wait_time(dt)=1/f_metro;%�����ȴ�ʱ��
                    else
                        cell{i,j}.metro_wait_time(dt)=cell{i,j}.metro_q(dt)/(f_metro*capacity_metro);%�����ȴ�ʱ��
                    end
                end
                %===========���������з��û�Ч��=====================
                if i~=j
                    %========�������������==================
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_fee(k,dt)=kesei*cell{i,j}.bus_travel_time(k,dt)+kesei*cell{i,j}.bus_wait_time(k,dt)+kesei*cell{i,j}.bus_fare(k);
                    end
                    %========�����������==================
                    cell{i,j}.metro_fee(dt)=kesei*cell{i,j}.metro_travel_time+kesei*cell{i,j}.metro_wait_time(dt)+kesei*cell{i,j}.metro_fare;
                    %========����ʱ��Ч��===================
                    cell{i,j}.departure_fee(dt)=sue_fee_dd(cell,i,j,tte,tta,dt);
                    %===================����ѡ��ͬ���䷽ʽ������============================
                    %%%%%%%%%%%%%%%%%%%%%%%Ԫ���������ۻ�ǰ��Ч�÷���%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %cell=multi_agent_neural_CPT_dt(t_e,dt,i,j,cell,OD,N_agent_length,theita_l_so,shutdown);
                    %%%%%%%%%%%%%%%%%%%%%%%logitģ���ۻ�ǰ��Ч�÷���%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    cell=logit_CPT_dt(dt,i,j,cell,OD,theita,shutdown);
                end
            end
        end
        %=============����ÿ����·��ʹ�����(����ʵʱ·������)===============
        q=zeros(num_station,num_station,num_line,M);%2����·��5������ʱ��
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
                            %===========��������ռ��·��==============
                            travel_time_int=floor(cell{ii,jj}.bus_travel_time(find(cell{ii,jj}.route==k),dt)/10);%�г�ʱ��ȡ��
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
        %===========����ÿ��·�ε�ӵ���̶ȣ����У�================
        for k=1:size(route,1)
            for ii=1:size(route,2)-1
                if route(k,ii)*route(k,ii+1)==0
                    crowd(k,ii,dt,1)=0;%����
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
        %===========����ÿ��·�ε�ӵ���̶ȣ����У�================
        for k=1:size(route,1)
            for ii=size(route,2):-1:2
                if route(k,ii)*route(k,ii-1)==0
                    crowd(k,ii-1,dt,2)=0;%����
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
        %==================����ÿ��OD���ӵ����===================
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
    %===============����ѡ��ͬ����ʱ�������=====================
    for i=1:num_station
        for j=1:num_station
            if i~=j
                for dt=1:M
                    cell{i,j}.wd(dt)=exp(theita*kesei*cell{i,j}.departure_fee(dt))/sum(exp(theita*kesei*cell{i,j}.departure_fee(:)));
                end
            end
        end
    end
    %===============ͳ���������г�ʱ��===============
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
                t_time(i,j,t_e)=mean(mean(t_w_time(:,:)));
                efficiency(i,j,t_e)=DIS(i,j)/(t_time(i,j,t_e)+T_stop);%����
            end
        end
    end
    t_e=t_e+1;
end
%===================��¼�г�ʱ�䡢��������������ֵ�����ԣ�=======
%============�г�ʱ��===========
S_mt=mean(mean(t_time(:,:,t_T)));
%====================��������==============
S_sf=mean(mean(mean(mean(crowd))));
%===================����=================
R_re=mean(mean(mean(efficiency)));

end