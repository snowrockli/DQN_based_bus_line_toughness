function cell=multi_agent_neural_CPT_dt(t_e,dt,i,j,cell,OD,N_agent_length,theita_l_so,shutdown)
if i~=j
    input_num=cell{i,j}.route_num+1;%�������Ԫ����
    hidden_layer_num=2*input_num+1;%��������Ԫ����
    output_num=cell{i,j}.route_num+1;%�������Ԫ����
    if t_e==1
        for ii=1:N_agent_length
            for jj=1:N_agent_length
                cell{i,j}.cell{ii,jj}.risk=rand;%����̬��
                %========������з�ʽѡ�����========================
                [cell{i,j}.cell{ii,jj}.bus_utility,cell{i,j}.cell{ii,jj}.metro_utility]=f_utility(cell,i,j,ii,jj,dt);%����ǰ��Ч��
                
                cell{i,j}.cell{ii,jj}.input=[cell{i,j}.cell{ii,jj}.bus_utility(1:end),cell{i,j}.cell{ii,jj}.metro_utility];%�����������
                cell{i,j}.cell{ii,jj}.W1=-1+(1+1)*rand(input_num,hidden_layer_num);%�������������֮��Ȩ��
                cell{i,j}.cell{ii,jj}.W2=-1+(1+1)*rand(hidden_layer_num,output_num);%��������������Ȩ��
                cell{i,j}.cell{ii,jj}.output=cell{i,j}.cell{ii,jj}.input*cell{i,j}.cell{ii,jj}.W1*cell{i,j}.cell{ii,jj}.W2;%����������
                %========sigmoid������һ��========
                cell{i,j}.cell{ii,jj}.sig_output=1./(1+exp(-cell{i,j}.cell{ii,jj}.output));%sigmoid����
                cell{i,j}.cell{ii,jj}.sum_sig=sum(cell{i,j}.cell{ii,jj}.sig_output);
                cell{i,j}.cell{ii,jj}.new_output=cell{i,j}.cell{ii,jj}.sig_output./cell{i,j}.cell{ii,jj}.sum_sig;%���ʺ�Ϊ1
                for ss=1:output_num
                    q_cell(ss,ii,jj)=cell{i,j}.cell{ii,jj}.new_output(ss);
                end
            end
        end
        %========�������=============
        if ismember(i,shutdown)==1||ismember(j,shutdown)==1%����ͣ�˵�״��
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
    %=========ÿ��Ԫ���������ߣ�Ԥ��Ч��==========
    cell{i,j}.agent_utility=0;
    for ii=1:N_agent_length
        for jj=1:N_agent_length
            cell{i,j}.cell{ii,jj}.input=[cell{i,j}.cell{ii,jj}.bus_utility(1:end),cell{i,j}.cell{ii,jj}.metro_utility];%�����������
            for s=1:output_num
                cell{i,j}.cell{ii,jj}.fee(s)=cell{i,j}.cell{ii,jj}.input(s)*cell{i,j}.cell{ii,jj}.new_output(s);%��Ȩ����Ч��
            end
            cell{i,j}.cell{ii,jj}.g_fee=sum(cell{i,j}.cell{ii,jj}.fee);%�����ܳ���Ч��
            cell{i,j}.agent_utility=cell{i,j}.agent_utility+cell{i,j}.cell{ii,jj}.g_fee;
        end
    end
    %=========ѧϰ������ѧϰ��Χ�ľ��飩=================
    for ii=2:N_agent_length-1
        for jj=2:N_agent_length-1
            %======�ռ���Χ��Ϣ=====
            i_index=1;
            for pp=ii-1:ii+1
                for qq=jj-1:jj+1
                    cell{i,j}.cell{ii,jj}.experience(i_index,:)=[cell{i,j}.cell{pp,qq}.g_fee,pp,qq];
                    i_index=i_index+1;
                end
            end
            %========��λ����Χ��õľ���=========
            cell{i,j}.cell{ii,jj}.best=find(cell{i,j}.cell{ii,jj}.experience==max(cell{i,j}.cell{ii,jj}.experience(:,1)));
            best_index=cell{i,j}.cell{ii,jj}.best;
            best_x=cell{i,j}.cell{ii,jj}.experience(best_index,2);
            best_y=cell{i,j}.cell{ii,jj}.experience(best_index,3);
            %=======ѧϰ���������յ㡢Ԫ��������Ȩ�ظ��£�==============
            cell{i,j}.cell{ii,jj}.risk=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.risk+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.risk;
            cell{i,j}.cell{ii,jj}.W1=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.W1+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.W1;
            cell{i,j}.cell{ii,jj}.W2=(1-theita_l_so)*cell{i,j}.cell{ii,jj}.W2+theita_l_so*cell{i,j}.cell{best_x(1),best_y(1)}.W2;
            %=======������з�ʽѡ�����=======
            cell{i,j}.cell{ii,jj}.output=cell{i,j}.cell{ii,jj}.input*cell{i,j}.cell{ii,jj}.W1*cell{i,j}.cell{ii,jj}.W2;%����������
            %========sigmoid������һ��========
            cell{i,j}.cell{ii,jj}.sig_output=1./(1+exp(-cell{i,j}.cell{ii,jj}.output));%sigmoid����
            cell{i,j}.cell{ii,jj}.sum_sig=sum(cell{i,j}.cell{ii,jj}.sig_output);
            cell{i,j}.cell{ii,jj}.new_output=cell{i,j}.cell{ii,jj}.sig_output./cell{i,j}.cell{ii,jj}.sum_sig;%���ʺ�Ϊ1
            
        end
    end
    for ii=1:N_agent_length
        for jj=1:N_agent_length
            for ss=1:output_num
                q_cell(ss,ii,jj)=cell{i,j}.cell{ii,jj}.new_output(ss);
            end 
        end
    end
    %========�������=============
    if ismember(i,shutdown)==1||ismember(j,shutdown)==1%����ͣ�˵�״��
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
