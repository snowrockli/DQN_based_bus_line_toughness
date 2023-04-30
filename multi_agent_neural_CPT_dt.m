function cell=multi_agent_neural_CPT_dt(t_e,dt,i,j,cell,OD,N_agent_length,theita_l_so,shutdown)
if i~=j
    input_num=cell{i,j}.route_num+1;%输入层神经元数量
    hidden_layer_num=2*input_num+1;%隐含层神经元数量
    output_num=cell{i,j}.route_num+1;%输出层神经元数量
    if t_e==1
        for ii=1:N_agent_length
            for jj=1:N_agent_length
                cell{i,j}.cell{ii,jj}.risk=rand;%风险态度
                %========计算出行方式选择概率========================
                [cell{i,j}.cell{ii,jj}.bus_utility,cell{i,j}.cell{ii,jj}.metro_utility]=f_utility(cell,i,j,ii,jj,dt);%计算前景效用
                
                cell{i,j}.cell{ii,jj}.input=[cell{i,j}.cell{ii,jj}.bus_utility(1:end),cell{i,j}.cell{ii,jj}.metro_utility];%神经网络的输入
                cell{i,j}.cell{ii,jj}.W1=-1+(1+1)*rand(input_num,hidden_layer_num);%输入层与隐含层之间权重
                cell{i,j}.cell{ii,jj}.W2=-1+(1+1)*rand(hidden_layer_num,output_num);%隐含层与输出层间权重
                cell{i,j}.cell{ii,jj}.output=cell{i,j}.cell{ii,jj}.input*cell{i,j}.cell{ii,jj}.W1*cell{i,j}.cell{ii,jj}.W2;%神经网络的输出
                %========sigmoid函数归一化========
                cell{i,j}.cell{ii,jj}.sig_output=1./(1+exp(-cell{i,j}.cell{ii,jj}.output));%sigmoid函数
                cell{i,j}.cell{ii,jj}.sum_sig=sum(cell{i,j}.cell{ii,jj}.sig_output);
                cell{i,j}.cell{ii,jj}.new_output=cell{i,j}.cell{ii,jj}.sig_output./cell{i,j}.cell{ii,jj}.sum_sig;%概率和为1
                for ss=1:output_num
                    q_cell(ss,ii,jj)=cell{i,j}.cell{ii,jj}.new_output(ss);
                end
            end
        end
        %========计算客流=============
        if ismember(i,shutdown)==1||ismember(j,shutdown)==1%出现停运的状况
            cell{i,j}.metro_q(dt)=0;
            for ss=1:output_num-1
                pro_q_cell(ss)=mean(mean(q_cell(ss,:,:)));
            end
            sigema_q_cell=sum(pro_q_cell);
            for ss=1:output_num-1
                cell{i,j}.bus_q(ss,dt)=OD(i,j)*cell{i,j}.wd(dt)*mean(mean(q_cell(ss,:,:)))/sigema_q_cell;
            end
        else
            cell{i,j}.metro_q(dt)=mean(mean(q_cell(output_num,:,:)))*cell{i,j}.wd(dt)*OD(i,j);
            for ss=1:output_num-1
                cell{i,j}.bus_q(ss,dt)=mean(mean(q_cell(ss,:,:)))*cell{i,j}.wd(dt)*OD(i,j);
            end
        end
    end
    %=========每个元胞（出行者）预测效用==========
    cell{i,j}.agent_utility=0;
    for ii=1:N_agent_length
        for jj=1:N_agent_length
            cell{i,j}.cell{ii,jj}.input=[cell{i,j}.cell{ii,jj}.bus_utility(1:end),cell{i,j}.cell{ii,jj}.metro_utility];%神经网络的输入
            for s=1:output_num
                cell{i,j}.cell{ii,jj}.fee(s)=cell{i,j}.cell{ii,jj}.input(s)*cell{i,j}.cell{ii,jj}.new_output(s);%加权出行效用
            end
            cell{i,j}.cell{ii,jj}.g_fee=sum(cell{i,j}.cell{ii,jj}.fee);%估计总出行效用
            cell{i,j}.agent_utility=cell{i,j}.agent_utility+cell{i,j}.cell{ii,jj}.g_fee;
        end
    end
    %=========学习进化（学习周围的经验）=================
    for ii=2:N_agent_length-1
        for jj=2:N_agent_length-1
            %======收集周围信息=====
            i_index=1;
            for pp=ii-1:ii+1
                for qq=jj-1:jj+1
                    cell{i,j}.cell{ii,jj}.experience(i_index,:)=[cell{i,j}.cell{pp,qq}.g_fee,pp,qq];
                    i_index=i_index+1;
                end
            end
            %========定位到周围最好的经验=========
            cell{i,j}.cell{ii,jj}.best=find(cell{i,j}.cell{ii,jj}.experience==max(cell{i,j}.cell{ii,jj}.experience(:,1)));
            best_index=cell{i,j}.cell{ii,jj}.best;
            best_x=cell{i,j}.cell{ii,jj}.experience(best_index,2);
            best_y=cell{i,j}.cell{ii,jj}.experience(best_index,3);
            %=======学习交互（参照点、元胞神经网络权重更新）==============
            cell{i,j}.cell{ii,jj}.risk=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.risk+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.risk;
            cell{i,j}.cell{ii,jj}.W1=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.W1+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.W1;
            cell{i,j}.cell{ii,jj}.W2=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.W2+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.W2;
            %=======计算出行方式选择概率=======
            cell{i,j}.cell{ii,jj}.output=cell{i,j}.cell{ii,jj}.input*cell{i,j}.cell{ii,jj}.W1*cell{i,j}.cell{ii,jj}.W2;%神经网络的输出
            %========sigmoid函数归一化========
            cell{i,j}.cell{ii,jj}.sig_output=1./(1+exp(-cell{i,j}.cell{ii,jj}.output));%sigmoid函数
            cell{i,j}.cell{ii,jj}.sum_sig=sum(cell{i,j}.cell{ii,jj}.sig_output);
            cell{i,j}.cell{ii,jj}.new_output=cell{i,j}.cell{ii,jj}.sig_output./cell{i,j}.cell{ii,jj}.sum_sig;%概率和为1
            
        end
    end
    for ii=1:N_agent_length
        for jj=1:N_agent_length
            for ss=1:output_num
                q_cell(ss,ii,jj)=cell{i,j}.cell{ii,jj}.new_output(ss);
            end 
        end
    end
    %========计算客流=============
    if ismember(i,shutdown)==1||ismember(j,shutdown)==1%出现停运的状况
        cell{i,j}.metro_q(dt)=0;
        for ss=1:output_num-1
            pro_q_cell(ss)=mean(mean(q_cell(ss,:,:)));
        end
        sigema_q_cell=sum(pro_q_cell);
        for ss=1:output_num-1
            cell{i,j}.bus_q(ss,dt)=OD(i,j)*cell{i,j}.wd(dt)*mean(mean(q_cell(ss,:,:)))/sigema_q_cell;
        end
    else
        cell{i,j}.metro_q(dt)=mean(mean(q_cell(output_num,:,:)))*cell{i,j}.wd(dt)*OD(i,j);
        for ss=1:output_num-1
            cell{i,j}.bus_q(ss,dt)=mean(mean(q_cell(ss,:,:)))*cell{i,j}.wd(dt)*OD(i,j);
        end
    end
end
end
