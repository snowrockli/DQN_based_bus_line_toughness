%=======================ǿ��ѧϰ�������Իָ�================
clc
clear
close all
OD_demand(:,:,1)=xlsread('OD.xlsx','demand');%OD�������

TT_metro=xlsread('OD.xlsx','metro_time');%OD���������ʱ�����
DIS=xlsread('OD.xlsx','distance');%OD�����;
bus_fare=xlsread('OD.xlsx','bus_fare');%OD�乫��Ʊ��
metro_fare=xlsread('OD.xlsx','metro_fare');%OD�����Ʊ��
T_DQN=400;%ǿ��ѧϰ��������
t_learn=100;%�Ӿ���طż�����ѡȡ������ʱ��
gama=0.8;%ǿ��ѧϰ��
epsilon(1)=0.3;%��������
basic_num=50;%�Ӿ���طż�����ѡȡ����������
A=[-7,-1,0,1,7];%�������������ռ�
D=[];%����طż���
D_train=[];%Qֵѵ������
%====================��ʼ�����Իָ�����========
shutdown=[2,4,10];%ͣ�˵ĵ���վ���ɵ��ڣ�
%R_line(1,:)=ones(1,size(OD_demand,2)-1);
R_line(1,:)=[0,0,0,0,0,0,1,0,1];
length_R=size(OD_demand,2)-1;%�Ż�����·����
%====================��ʼ��������============
num_sample=T_DQN;
S_A=rand(num_sample,5);%����״̬�Ͷ���
Q=rand(num_sample,1);%���Qֵ
net=newff(S_A',Q',11,{'logsig','purelin','traingd'});
net.trainParam.showWindow = 0;%�Ƿ�չʾ����
%===========�����ʼ״̬===============
t=1;
OD=OD_demand(:,:,1);
[S_mt,S_sf,R_re]=f_value_rd(R_line,t,OD,TT_metro,DIS,bus_fare,metro_fare,shutdown);
S_ro=bin2dec(char(R_line(1,:)+'0'));%������01����תΪʮ����
S_ro_max=bin2dec(char([1,1,1,1,1,1,1,1,1]+'0'));
S_ro_min=1;
%=============����ѵ��=====================
for t=1:T_DQN
    %===========����״̬�����Qֵ================
    if t==1
        STATE=[S_mt/10,S_sf/100,S_ro/100,sum(R_line(1,:))];%״̬(��׼��)
    else
        STATE=[S_mt/10,S_sf/100,S_ro/100,sum(R_line(t-1,:))];%״̬(��׼��)
    end
    for a_n=1:length(A)
        x_S_A(:,a_n)=[STATE,a_n]';%״̬+����
        y_Q(a_n)=sim(net,x_S_A(:,a_n)); %��ͬ������Qֵ
    end
    %===========ѡ����============
    if rand<epsilon(t)
        i_star=randi([1,length(A)],1,1);%���ѡ��
        i_select=i_star(1);
    else
        i_star=find(y_Q==max(y_Q));%ѡQֵ����
        i_select=i_star(randi([1,length(i_star)],1,1));%ѡ�����Ķ������
    end
    epsilon(t+1)=epsilon(t)-0.001;
    %===============ִ��ѡ��Ķ������õ��µ�״̬==============
    S_ro_new=S_ro+A(i_select);
    if S_ro_new>=S_ro_max||S_ro_new<=S_ro_min
        S_ro_new=S_ro;
    end
    S_ro_new_2=dec2bin(S_ro_new);%ʮ����ת��Ϊ������
    R_line_temp=str2num(S_ro_new_2(:))';%�µ�ͣվ���������Ʊ�ʾ
    %==============����������ɳ���һ�µ����飬ǰ�����0=======
    if length(R_line_temp)<length_R
        R_line(t,1:end-length(R_line_temp))=0;
        R_line(t,end-length(R_line_temp)+1:end)=R_line_temp;
    else
        R_line(t,:)=R_line_temp;
    end
    %===============�����µ�״̬�ͽ���ֵ=================
    [S_mt_new,S_sf_new,R_re_new]=f_value_rd(R_line,t,OD,TT_metro,DIS,bus_fare,metro_fare,shutdown);
    NEW_STATE=[S_mt_new/10,S_sf_new/100,S_ro_new/100,sum(R_line(t,:))];%�µ�״̬
    D(t,:)=[STATE,i_select,R_re_new,NEW_STATE];
    S_mt=S_mt_new;S_sf=S_sf_new;S_ro=S_ro_new;%����״̬
    %===============�Ӿ���طż�����ѡȡһЩ����====================
    D_train_temp=[];
    if t>=t_learn%�жϼ������������Ƿ��㹻
        c=randperm(numel(1:t));%���´���˳��
        m=basic_num;%ѡ��m������
        for i=1:m
            D_train_temp(i,1:size(STATE,2)+1)=D(c(i),1:size(STATE,2)+1);
            STATE_next=D(c(i),size(STATE,2)+3:end);%��һ��״̬
            for a_n=1:length(A)
                x_next_S_A(:,a_n)=[STATE_next,a_n]';
                y_next_Q(a_n)=sim(net,x_next_S_A(:,a_n)); %��ͬ������Qֵ
            end
            max_Q=max(y_next_Q);
            D_train_temp(i,size(STATE,2)+2)=D(c(i),size(STATE,2)+2)+gama*max_Q;%����Qֵ
        end
        %===============����Qֵѵ����=================
        [D_train_num,~]=size(D_train);
        if isempty(D_train)==1
            D_train=D_train_temp;
        else
            for i=1:m
                for j=1:D_train_num
                    if isequal(D_train_temp(i,1:size(STATE,2)+1),D_train(j,1:size(STATE,2)+1))==1
                        D_train(j,size(STATE,2)+2)=D_train_temp(i,size(STATE,2)+2);%��ѵ���������״̬һ���ģ�����Qֵ
                    end
                end
            end
            for i=1:m
                if ismember(D_train_temp(i,1:size(STATE,2)+1),D_train(:,1:size(STATE,2)+1),'rows')==0
                    [D_train_num,~]=size(D_train);
                    D_train(D_train_num+1,:)=D_train_temp(i,:);%�µ�״̬�Ͷ�����ֱ�����
                end
            end
        end
        %D_train=unique(D_train,'rows');
        net = train(net,D_train(:,1:size(STATE,2)+1)',D_train(:,size(STATE,2)+2)');
        net.trainParam.goal =1e-5;% 1e-5;
        net.trainParam.epochs = 300;
        net.trainParam.lr = 0.05;
        net.trainParam.showWindow = 0;%�Ƿ�չʾ����
    end
end

%x_10=bin2dec(char([1 1 1 1 0 0 1 1 1]+'0'));%������01����תΪʮ����
%x_2_char=dec2bin(x_10);
%x_2=str2num(x_2_char(:))';%ʮ����תΪ������01����