%=======================强化学习线网韧性恢复================
clc
clear
close all
OD_demand(:,:,1)=xlsread('OD.xlsx','demand');%OD需求矩阵

TT_metro=xlsread('OD.xlsx','metro_time');%OD间地铁运行时间矩阵
DIS=xlsread('OD.xlsx','distance');%OD间距离;
bus_fare=xlsread('OD.xlsx','bus_fare');%OD间公交票价
metro_fare=xlsread('OD.xlsx','metro_fare');%OD间地铁票价
T_DQN=400;%强化学习迭代次数
t_learn=100;%从经验回放集合中选取样本的时间
gama=0.8;%强化学习率
epsilon(1)=0.3;%搜索策略
basic_num=50;%从经验回放集合中选取的样本数量
A=[-7,-1,0,1,7];%线网调整动作空间
D=[];%经验回放集合
D_train=[];%Q值训练集合
%====================初始化韧性恢复策略========
shutdown=[2,4,10];%停运的地铁站（可调节）
%R_line(1,:)=ones(1,size(OD_demand,2)-1);
R_line(1,:)=[0,0,0,0,0,0,1,0,1];
length_R=size(OD_demand,2)-1;%优化的线路长度
%====================初始化神经网络============
num_sample=T_DQN;
S_A=rand(num_sample,5);%输入状态和动作
Q=rand(num_sample,1);%输出Q值
net=newff(S_A',Q',11,{'logsig','purelin','traingd'});
net.trainParam.showWindow = 0;%是否展示窗口
%===========计算初始状态===============
t=1;
OD=OD_demand(:,:,1);
[S_mt,S_sf,R_re]=f_value_rd(R_line,t,OD,TT_metro,DIS,bus_fare,metro_fare,shutdown);
S_ro=bin2dec(char(R_line(1,:)+'0'));%二进制01矩阵转为十进制
S_ro_max=bin2dec(char([1,1,1,1,1,1,1,1,1]+'0'));
S_ro_min=1;
%=============迭代训练=====================
for t=1:T_DQN
    %===========输入状态，输出Q值================
    if t==1
        STATE=[S_mt/10,S_sf/100,S_ro/100,sum(R_line(1,:))];%状态(标准化)
    else
        STATE=[S_mt/10,S_sf/100,S_ro/100,sum(R_line(t-1,:))];%状态(标准化)
    end
    for a_n=1:length(A)
        x_S_A(:,a_n)=[STATE,a_n]';%状态+动作
        y_Q(a_n)=sim(net,x_S_A(:,a_n)); %不同动作的Q值
    end
    %===========选择动作============
    if rand<epsilon(t)
        i_star=randi([1,length(A)],1,1);%随机选择
        i_select=i_star(1);
    else
        i_star=find(y_Q==max(y_Q));%选Q值最大的
        i_select=i_star(randi([1,length(i_star)],1,1));%选出来的动作编号
    end
    epsilon(t+1)=epsilon(t)-0.001;
    %===============执行选择的动作，得到新的状态==============
    S_ro_new=S_ro+A(i_select);
    if S_ro_new>=S_ro_max||S_ro_new<=S_ro_min
        S_ro_new=S_ro;
    end
    S_ro_new_2=dec2bin(S_ro_new);%十进制转化为二进制
    R_line_temp=str2num(S_ro_new_2(:))';%新的停站方案二进制表示
    %==============二进制数变成长度一致的数组，前面填充0=======
    if length(R_line_temp)<length_R
        R_line(t,1:end-length(R_line_temp))=0;
        R_line(t,end-length(R_line_temp)+1:end)=R_line_temp;
    else
        R_line(t,:)=R_line_temp;
    end
    %===============计算新的状态和奖励值=================
    [S_mt_new,S_sf_new,R_re_new]=f_value_rd(R_line,t,OD,TT_metro,DIS,bus_fare,metro_fare,shutdown);
    NEW_STATE=[S_mt_new/10,S_sf_new/100,S_ro_new/100,sum(R_line(t,:))];%新的状态
    D(t,:)=[STATE,i_select,R_re_new,NEW_STATE];
    S_mt=S_mt_new;S_sf=S_sf_new;S_ro=S_ro_new;%更新状态
    %===============从经验回放集合中选取一些样本====================
    D_train_temp=[];
    if t>=t_learn%判断记忆池里的数据是否足够
        c=randperm(numel(1:t));%重新打乱顺序
        m=basic_num;%选出m个经验
        for i=1:m
            D_train_temp(i,1:size(STATE,2)+1)=D(c(i),1:size(STATE,2)+1);
            STATE_next=D(c(i),size(STATE,2)+3:end);%下一个状态
            for a_n=1:length(A)
                x_next_S_A(:,a_n)=[STATE_next,a_n]';
                y_next_Q(a_n)=sim(net,x_next_S_A(:,a_n)); %不同动作的Q值
            end
            max_Q=max(y_next_Q);
            D_train_temp(i,size(STATE,2)+2)=D(c(i),size(STATE,2)+2)+gama*max_Q;%更新Q值
        end
        %===============更新Q值训练集=================
        [D_train_num,~]=size(D_train);
        if isempty(D_train)==1
            D_train=D_train_temp;
        else
            for i=1:m
                for j=1:D_train_num
                    if isequal(D_train_temp(i,1:size(STATE,2)+1),D_train(j,1:size(STATE,2)+1))==1
                        D_train(j,size(STATE,2)+2)=D_train_temp(i,size(STATE,2)+2);%与训练集里既有状态一样的，更新Q值
                    end
                end
            end
            for i=1:m
                if ismember(D_train_temp(i,1:size(STATE,2)+1),D_train(:,1:size(STATE,2)+1),'rows')==0
                    [D_train_num,~]=size(D_train);
                    D_train(D_train_num+1,:)=D_train_temp(i,:);%新的状态和动作，直接添加
                end
            end
        end
        %D_train=unique(D_train,'rows');
        net = train(net,D_train(:,1:size(STATE,2)+1)',D_train(:,size(STATE,2)+2)');
        net.trainParam.goal =1e-5;% 1e-5;
        net.trainParam.epochs = 300;
        net.trainParam.lr = 0.05;
        net.trainParam.showWindow = 0;%是否展示窗口
    end
end

%x_10=bin2dec(char([1 1 1 1 0 0 1 1 1]+'0'));%二进制01矩阵转为十进制
%x_2_char=dec2bin(x_10);
%x_2=str2num(x_2_char(:))';%十进制转为二进制01矩阵