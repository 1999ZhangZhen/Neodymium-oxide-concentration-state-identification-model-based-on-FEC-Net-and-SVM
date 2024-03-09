%%  ��ջ�������
warning off             % �رձ�����Ϣ
close all               % �رտ�����ͼ��
clear                   % ��ձ���
clc                     % ���������

%%  ����ʱ�������ļ���
currentDateTime = datestr(now, 'yyyymmdd_HHMMSS');
outputFolder = fullfile(pwd, currentDateTime);
mkdir(outputFolder);

%%  ��������
res = xlsread('FEC-Net_ALL_data.xlsx');
% res = xlsread('UNet_ALL_data.xlsx');

%%  ����ѵ�����Ͳ��Լ�
temp = randperm(length(res));
rate = 0.80;
P_train=res(temp(1: int16(length(res) * rate)), 1: 12)';
T_train=res(temp(1: int16(length(res) * rate)), 13)';
M = size(P_train, 2);
train_data = [P_train', T_train']; % ��P_train��T_trainƴ�ӳ�һ������
train_data_filename = fullfile(outputFolder, 'train_data.xlsx');
xlswrite(train_data_filename, train_data, 1, 'A1'); 

P_test=res(temp(int16(length(res) * rate) + 1: end), 1: 12)';
T_test=res(temp(int16(length(res) * rate) + 1: end), 13)';
N = size(P_test, 2);
test_data = [P_test', T_test']; % ��P_train��T_trainƴ�ӳ�һ������
test_data_filename = fullfile(outputFolder, 'test_data.xlsx');
xlswrite(test_data_filename, test_data, 1, 'A1');
%%  ���ݹ�һ��
[p_train, ps_input] = mapminmax(P_train, 0, 1);
p_test = mapminmax('apply', P_test, ps_input );
t_train = T_train;
t_test  = T_test ;

tongyimodelFilename = fullfile(outputFolder, 'ps_input.mat');
save(tongyimodelFilename, 'ps_input');
%%  ת������Ӧģ��
p_train = p_train'; p_test = p_test';
t_train = t_train'; t_test = t_test';

%%  ����ģ��
c = 15.0;      % �ͷ�����
g = 0.06;      % �������������
cmd = ['-t 2', '-c', num2str(c), '-g', num2str(g)];
model = svmtrain(t_train, p_train, cmd);

%%  �������
T_sim1 = svmpredict(t_train, p_train, model);
T_sim2 = svmpredict(t_test , p_test , model);

%%  ��������
error1 = sum((T_sim1' == T_train)) / M * 100;
error2 = sum((T_sim2' == T_test )) / N * 100;

%%  ��������
[T_train, index_1] = sort(T_train);
[T_test , index_2] = sort(T_test );

T_sim1 = T_sim1(index_1);
T_sim2 = T_sim2(index_2);

%%  ����ģ��
modelFilename = fullfile(outputFolder, 'svm_model.mat');
save(modelFilename, 'model');


% %%  ��ͼ
% figure
% plot(1: M, T_train, 'b-O', 1: M, T_sim1, 'r-*', 'LineWidth', 1)
% legend('��ʵֵ', 'Ԥ��ֵ')
% xlabel('Ԥ������')
% ylabel('Ԥ����')
% string = {'ѵ����Ԥ�����Ա�'; ['׼ȷ��=' num2str(error1) '%']};
% title(string)
% grid
% saveas(gcf, fullfile(outputFolder, 'Train_Prediction_Comparison.png'));
% % close;
% 
% figure
% plot(1: N, T_test, 'b-O', 1: N, T_sim2, 'r-x', 'LineWidth', 1)
% legend('��ʵֵ', 'Ԥ��ֵ')
% xlabel('Ԥ������')
% ylabel('Ԥ����')
% string = {'���Լ�Ԥ�����Ա�'; ['׼ȷ��=' num2str(error2) '%']};
% title(string)
% grid
% saveas(gcf, fullfile(outputFolder, 'Test_Prediction_Comparison.png'));
% % close;
  
%% ��ͼ
figure
scatter(1:M, T_train, 'b', 'O');  % ����ѵ������ʵֵɢ��ͼ
hold on
scatter(1:M, T_sim1, 'r', '*');        % ����ѵ����Ԥ��ֵɢ��ͼ
hold off
legend('True Values', 'Predicted Values')
xlabel('Sample')
ylabel('Prediction Results')
string = {'Comparison of Training Set Predictions'; ['Accuracy=' num2str(error1) '%']};
title(string)
grid
% xticks(1:300:M);  % ���� x ��̶ȣ�ÿ�� 300 ��������ʾһ���̶�
% yticks([1 2 3]);  % ֻ��ʾ y ���ϵ����� 1��2��3
saveas(gcf, fullfile(outputFolder, 'Train_Prediction_Comparison.fig'));
% saveas(gcf, fullfile(outputFolder, 'Train_Prediction_Comparison.jpg'));
print(gcf, '-dpng', '-r600', fullfile(outputFolder, 'Train_Prediction_Comparison.png'))
print(gcf, '-dpng', '-r300', fullfile(outputFolder, 'Train_Prediction_Comparison.jpg'))

% ���Ʋ��Լ�ɢ��ͼ
figure
scatter(1:N, T_test, 'b', 'O');  % ���Ʋ��Լ���ʵֵɢ��ͼ
hold on
scatter(1:N, T_sim2, 'r', '*');        % ���Ʋ��Լ�Ԥ��ֵɢ��ͼ
hold off
legend('True Values', 'Predicted Values')
xlabel('Sample')
ylabel('Prediction Results')
string = {'Comparison of Test Set Predictions'; ['Accuracy=' num2str(error2) '%']};
title(string)
grid
% xticks(0:300:M);  % ���� x ��̶ȣ�ÿ�� 300 ��������ʾһ���̶�
% yticks([1 2 3]);  % ֻ��ʾ y ���ϵ����� 1��2��3
saveas(gcf, fullfile(outputFolder, 'Test_Prediction_Comparison.fig'));
% saveas(gcf, fullfile(outputFolder, 'Test_Prediction_Comparison.jpg'));
print(gcf, '-dpng', '-r600', fullfile(outputFolder, 'Test_Prediction_Comparison.png'))
print(gcf, '-dpng', '-r300', fullfile(outputFolder, 'Test_Prediction_Comparison.jpg'))
%%  ��������
figure
cm = confusionchart(T_train, T_sim1);
cm.Title = 'Confusion Matrix for Train Data';
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
saveas(gcf, fullfile(outputFolder, 'Confusion_Matrix_Train.fig'));
% saveas(gcf, fullfile(outputFolder, 'Confusion_Matrix_Train.jpg'));
print(gcf, '-dpng', '-r600', fullfile(outputFolder, 'Confusion_Matrix_Train.png'))
print(gcf, '-dpng', '-r300', fullfile(outputFolder, 'Confusion_Matrix_Train.jpg'))
% close;
    
figure
cm = confusionchart(T_test, T_sim2);
cm.Title = 'Confusion Matrix for Test Data';
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
saveas(gcf, fullfile(outputFolder, 'Confusion_Matrix_Test.fig'));
% saveas(gcf, fullfile(outputFolder, 'Confusion_Matrix_Train.jpg'));
print(gcf, '-dpng', '-r600', fullfile(outputFolder, 'Confusion_Matrix_Test.png'))
print(gcf, '-dpng', '-r300', fullfile(outputFolder, 'Confusion_Matrix_Test.jpg'))
% close;