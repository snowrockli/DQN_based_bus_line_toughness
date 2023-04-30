function [S_mt,S_sf,S_c,R_re]=f_value(R_line,t,OD,TT_metro,DIS,bus_fare,metro_fare,shutdown)
t_e=1;
t_T=8;
[num_station,~]=size(OD);%վ������
num_line=2;%��󹫽���·������һ�������ߣ�һ�������ߣ�
theita=1.5;%Ч�ø�֪ϵ��
kesei=0.1;%�ǽ���Ч��ϵ��
capacity_bus=500;%ӵ����ֵ
capacity_metro=1000;%ӵ����ֵ
%==============������·======================
x_route(1,1:num_station)=1;%���й�������վվ��ͣ
x_route(2,1:num_station)=[1,R_line(t,:)];%������·
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
%============��ʼ�ݻ�===================
while t_e<=t_T
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
            %===========�����г�ʱ�䡢�ȴ�ʱ�䡢Ʊ��=================
            for k=1:cell{i,j}.route_num
                %============Ʊ��==============
                cell{i,j}.bus_fare(k)=bus_fare(i,j);%Ʊ��
                %===========�г�ʱ��==================
                cell{i,j}.bus_travel_time(k)=0;
                non_zero=cell{i,j}.real_route(k,(find(cell{i,j}.real_route(k,:)~=0)));%��ȡʵ����·
                for kk=1:length(non_zero)-1
                    if t_e==1
                        cell{i,j}.bus_travel_time(k)=cell{i,j}.bus_travel_time(k)+TT_metro(non_zero(kk),non_zero(kk+1))*1.4;%��·�г�ʱ��
                    else
                        cell{i,j}.bus_travel_time(k)=cell{i,j}.bus_travel_time(k)+TT_metro(non_zero(kk),non_zero(kk+1))*1.4*(1+0.15*(cell{i,j}.bus_crowd(k)/(f_route(cell{i,j}.route(k))*capacity_bus))^4);%��·�г�ʱ��
                    end
                end
                %==========�ȴ�ʱ��=============
                if t_e==1
                    cell{i,j}.bus_wait_time(k)=1/f_route(cell{i,j}.route(k));%�����ȴ�ʱ��
                else
                    cell{i,j}.bus_wait_time(k)=cell{i,j}.bus_crowd(k)/(f_route(cell{i,j}.route(k))*capacity_bus);%�����ȴ�ʱ��
                end
            end
            %===========�����г�ʱ�䡢�ȴ�ʱ�䡢Ʊ��=================
            cell{i,j}.metro_travel_time=TT_metro(i,j);%�����г�ʱ��
            cell{i,j}.metro_fare=metro_fare(i,j);%����Ʊ��
            if i~=j
                if t_e==1
                    cell{i,j}.metro_wait_time=1/f_metro;%�����ȴ�ʱ��
                else
                    cell{i,j}.metro_wait_time=cell{i,j}.metro_q/(f_metro*capacity_metro);%�����ȴ�ʱ��
                end
            end
            %===========���������з��û�Ч��=====================
            if i~=j
                %========�������������==================
                for k=1:cell{i,j}.route_num
                    cell{i,j}.bus_fee(k)=kesei*cell{i,j}.bus_travel_time(k)+kesei*cell{i,j}.bus_wait_time(k)+kesei*cell{i,j}.bus_fare(k);
                end
                %========�����������==================
                cell{i,j}.metro_fee=kesei*cell{i,j}.metro_travel_time+kesei*cell{i,j}.metro_wait_time+kesei*cell{i,j}.metro_fare;
            end
            %===============����ѡ��ͬ���з�ʽ������=====================
            if i~=j
                if ismember(i,shutdown)==1||ismember(j,shutdown)==1%����ͣ�˵�״��
                    %========ѡ�������������=========
                    cell{i,j}.metro_q=0;
                    %========ѡ�񹫽���������===========
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_q(k)=OD(i,j)*exp(-theita*cell{i,j}.bus_fee(k))/sum(exp(-theita*cell{i,j}.bus_fee(:)));
                    end
                else
                    %========ѡ�������������=========
                    cell{i,j}.metro_q=OD(i,j)*exp(-theita*cell{i,j}.metro_fee)/(sum(exp(-theita*cell{i,j}.bus_fee(:)))+exp(-theita*cell{i,j}.metro_fee));
                    %========ѡ�񹫽���������===========
                    for k=1:cell{i,j}.route_num
                        cell{i,j}.bus_q(k)=OD(i,j)*exp(-theita*cell{i,j}.bus_fee(k))/(sum(exp(-theita*cell{i,j}.bus_fee(:)))+exp(-theita*cell{i,j}.metro_fee));
                    end
                end
            end
        end
    end
    %     flow_bus(t_e)=cell{3,4}.bus_q(1);
    %     if t_e>1
    %         q_var(t_e)=abs(flow_bus(t_e)-flow_bus(t_e-1))/flow_bus(t_e-1);%���������
    %     end
    %=============����ÿ����·��ʹ�����===========
    q=zeros(num_station,num_station,num_route);
    for ii=1:num_station
        for jj=1:num_station
            for k=1:num_route
                if ii==jj
                    q(ii,jj,k)=0;
                else
                    if isempty(find(cell{ii,jj}.route==k))==1
                        q(ii,jj,k)=0;
                    else
                        q(ii,jj,k)=cell{ii,jj}.bus_q(find(cell{ii,jj}.route==k));
                    end
                end
            end
        end
    end
    %===========����ÿ��·�ε�ӵ���̶ȣ����У�================
    for k=1:size(route,1)
        for ii=1:size(route,2)-1
            if route(k,ii)*route(k,ii+1)==0
                crowd(k,ii,1)=0;%����
            else
                if ii==1
                    crowd(k,ii,1)=0;
                    for jj=ii+1:size(route,2)
                        if route(k,jj)~=0
                            crowd(k,ii,1)=crowd(k,ii,1)+q(route(k,ii),route(k,jj),k);
                        end
                    end
                else
                    q_hou=0;
                    q_qian=0;
                    for jj=ii+1:size(route,2)
                        if route(k,jj)~=0
                            q_hou=q_hou+q(route(k,ii),route(k,jj),k);
                        end
                    end
                    for jj=1:ii
                        if route(k,jj)~=0
                            q_qian=q_qian+q(route(k,jj),route(k,ii),k);
                        end
                    end
                    crowd(k,ii,1)=crowd(k,ii-1,1)+q_hou-q_qian;
                end
            end
        end
    end
    %===========����ÿ��·�ε�ӵ���̶ȣ����У�================
    for k=1:size(route,1)
        for ii=size(route,2):-1:2
            if route(k,ii)*route(k,ii-1)==0
                crowd(k,ii-1,2)=0;%����
            else
                if ii==size(route,2)
                    crowd(k,ii-1,2)=0;
                    for jj=ii-1:-1:1
                        if route(k,jj)~=0
                            crowd(k,ii-1,2)=crowd(k,ii-1,2)+q(route(k,ii),route(k,jj),k);
                        else
                            crowd(k,ii-1,2)=0;
                        end
                    end
                else
                    q_hou=0;
                    q_qian=0;
                    for jj=1:ii-1
                        if route(k,jj)~=0
                            q_hou=q_hou+q(route(k,ii),route(k,jj),k);
                        end
                    end
                    for jj=ii:size(route,2)
                        if route(k,jj)~=0
                            q_qian=q_qian+q(route(k,jj),route(k,ii),k);
                        end
                    end
                    crowd(k,ii-1,2)=crowd(k,ii,2)+q_hou-q_qian;
                end
            end
        end
    end
    %==================����ÿ��OD���ӵ����===================
    for i=1:num_station
        for j=1:num_station
            for k=1:cell{i,j}.route_num
                if cell{i,j}.direction(k)==1
                    cell{i,j}.bus_crowd(k)=sum(crowd(cell{i,j}.route(k),cell{i,j}.i_locate(k):cell{i,j}.j_locate(k)-1,1));
                elseif cell{i,j}.direction(k)==-1
                    cell{i,j}.bus_crowd(k)=sum(crowd(cell{i,j}.route(k),cell{i,j}.j_locate(k):cell{i,j}.i_locate(k)-1,2));
                end
            end
        end
    end
    %=============����ÿ���ݻ��������Իָ����̣����г�ʱ����ȴ�ʱ��==============
    for i=1:num_station
        for j=1:num_station
            if i~=j
                for k=1:cell{i,j}.route_num
                    t_w_time(k,t_e)=cell{i,j}.bus_travel_time(k)+cell{i,j}.bus_wait_time(k)+cell{i,j}.metro_wait_time+cell{i,j}.metro_travel_time;%�г�ʱ��+�ȴ�ʱ��
                end
                t_time(i,j,t_e)=mean(t_w_time(:,t_e));%վ��ij������·����ƽ���г�ʱ��+�ȴ�ʱ��
            else
                t_time(i,j,t_e)=0;
            end
        end
    end
    
    t_e=t_e+1;
end
%======================����״̬������=================
for i=1:num_line
    cost(i)=f_route(i)*10;%�����ɱ�
end
for i=1:num_station
    for j=1:num_station
        if i~=j
%             for k=1:cell{i,j}.route_num
%                 t_w_time(k)=cell{i,j}.bus_travel_time(k)+cell{i,j}.bus_wait_time(k)+cell{i,j}.metro_wait_time+cell{i,j}.metro_travel_time;%�г�ʱ��+�ȴ�ʱ��
%             end
%            t_time(i,j)=mean(t_w_time);
%            efficiency(i,j)=DIS(i,j)/t_time(i,j);%����
%            efficiency(i,j)=DIS(i,j)/t_time(i,j,t_T);%����
            efficiency(i,j)=DIS(i,j)/mean(t_time(i,j,:));%����
        else
            %t_time(i,j)=0;
            efficiency(i,j)=0;
        end
    end
end
f(1)=x;
%f(2)=mean(mean(t_time));
f(2)=-mean(mean(efficiency));
f(3)=sum(cost(:));
end