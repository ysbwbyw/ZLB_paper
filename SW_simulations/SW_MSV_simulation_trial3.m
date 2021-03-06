clear;clc;close all;
% rng(11);
%variable order: mc zcap rk k1   q c inve y lab pinf w r kp 
N=10000;numVar=24;numShocks=7;numEndo=17;numExo=7;numBackward=7;numForward=7;
eig_crit=0.999;
eig_eps=0.01;
eig_mult=(1-eig_crit)*2/pi;
%burn_in=round(0.9*N);
burn_in=2;
backward_indices=[6 7 8 10 11 12 13];
forward_indices=[3 5 6 7 9 10 11];
%fixed parameteters
parameters(1,:)   = [0.025,0.025];     %delta
parameters(2,:)      = [0.18,0.18];    % G 
parameters(3,:)    =[1.5,1.5];       % phi_w 
parameters(4,:)   = [10,10];        %curv_p
parameters(5,:)   = [10,10];         %curv_w
 
%nominal and real frictions
parameters(6,:)  = [5.5,5.5] ;    %phi
parameters(7,:)  =[1.4,1.4] ;      %sigma_c
parameters(8,:)  =  [0.71,0.71];   %lambda 
parameters(9,:)  =  [0.74,0.74] ; %xi_w
parameters(10,:) = [1.92,1.92];        %sigma_l 
parameters(11,:) =  [0.66,0.66];      %xi_p 
parameters(12,:) =  [0.59,0.59] ;     %iota_w
parameters(13,:) =  [0.23,0.23];         %iota_p
parameters(14,:) = [0.1,0.1] ;   %psi
parameters(15,:) = [1.5,1.5]; %phi_p

%policy related parameters

parameters(16,:)    =   [2,0];   %r_pi
parameters(17,:)    =  [0.82,0]; %rho
parameters(18,:)    =   [0.08,0];%0.0746;    %r_y
parameters(19,:)    =  [0.22,0];     %r_dy

%SS related parameters
parameters(20,:)    = [0.8,0.8] ;    %pi_bar
parameters(21,:)    = [0.16,0.16];       %beta_const
parameters(22,:)    = [-0.1,-0.1];     %l_bar
parameters(23,:)    = [0.43,0.43];         %gamma_bar
parameters(24,:)    = [0.19,0.19] ;    %alpha

% %shock persistence
parameters(25,:) = [0.96,0.96];      %rho_a
parameters(26,:) =[0.18,0.18];  %rho_b
parameters(27,:) =[0.98,0.98];   %rho_g
parameters(28,:) =[0.71,0.71];   %rho_i
parameters(29,:) =  [0.13,0.13];   %rho_r
parameters(30,:) =  [0.15,0.15];  %rho_p
parameters(31,:) =[0.10,0.10];%rho_w 
% parameters(32,:) = [0.25,0.25] ;    %mu_p 
% parameters(33,:) =[0.25,0.25];    %mu_w

parameters(32,:) =  [0.53,0.53]      ;  %rho_ga

%shock standard deviations
parameters(33,:)=[0.45,0.45];  %sigma_a
parameters(34,:)=  [0.24,0.24];  %sigma_b
parameters(35,:)= [0.52,0.52]; %sigma_g
parameters(36,:)=  [0.45,0.45] ;   %sigma_i
parameters(37,:)=[0.24,0.08];   %sigma_r
parameters(38,:)= [0.14,0.14];  %sigma_p
parameters(39,:)=   [0.24,0.24];   %sigma_w
regime=nan(N,1);%regime parameter: 0 if not at ZLB, 1 if at ZLB;
regime(1)=1;
gain=0.001;
p_11=1;p_22=0; 
Q=[p_11,1-p_11;1-p_22,p_22];
ergodic_states=[(1-p_22)/(2-p_11-p_22);(1-p_11)/(2-p_11-p_22)];


[AA1, BB1, CC1, DD1, EE1 ,RHO1 ,FF1, GG1 ,E1 ,F1] =SW_sysmat_MSV_filter(parameters(:,1));
[AA2, BB2, CC2, DD2, EE2, RHO2, FF2 ,GG2, E2, F2]=SW_sysmat_MSV_filter(parameters(:,2));

AA1_inv=AA1^(-1);AA2_inv=AA2^(-1);

SIGMA1=diag(parameters(end-numShocks+1:end,1))^2;
SIGMA2=diag(parameters(end-numShocks+1:end,2))^2;

errors1=mvnrnd(zeros(numShocks,1),SIGMA1,N)';
errors2=mvnrnd(zeros(numShocks,1),SIGMA2,N)';

XX=nan(numVar,N);
XX(:,1) =zeros(numVar,1);
%----
beta_tt=zeros(numEndo,numEndo);
alpha_tt=zeros(numEndo,1);
cc_tt=zeros(numEndo,numShocks);
rr_tt=10*eye(numBackward+numExo+1,numBackward+numExo+1);
%rr_tt=nearestSPD(rr_tt);
%--------------
load('initial_beliefs.mat');
beta_tt=beta_init;
cc_tt=cc_init;
rr_tt=rr_init;

pr_flag=zeros(N,1);
largest_eig1=zeros(N,1);
largest_eig2=zeros(N,1);

index=0;
eig_max=zeros(N,1);
eig_max1=zeros(N,1);
eig_max2=zeros(N,1);

update_matrices;

for tt=2:N

regime(tt)=findRegime(regime(tt-1),p_11,p_22);
      
XX(:,tt) = regime(tt)*( gamma1_1*XX(:,tt-1)+gamma2_1+gamma3_1*errors1(:,tt))+...
    (1-regime(tt))*( gamma1_2*XX(:,tt-1)+gamma2_2+gamma3_2*errors2(:,tt)); 

update_beliefs;
%update_matrices;

%eig_max1(tt)=max(abs(eigs(gamma1_1,1)),abs(eigs(gamma1_2,1)));
%gamma1_1=increase_eigenvalue(gamma1_1,eig_eps,10e-5);
%gamma1_1=reduce_eigenvalue(gamma1_1,eig_crit,eig_eps);
%gamma1_2=increase_eigenvalue(gamma1_2,eig_eps,10e-5);
%gamma1_2=reduce_eigenvalue(gamma1_2,eig_crit,eig_eps);

%try
%eig_max2(tt)=max(abs(eigs(gamma1_1,1)),abs(eigs(gamma1_2,1)));
%catch
%    eig_max2(tt)=1.01;
%end

%eig_max(tt)=max(eig_max1(tt),eig_max2(tt));

%if eig_max1(tt)>eig_max2(tt)
%    pr_flag(tt)=1;
%end






%-------------------------------------
%report diagnostics every 500 periods
 index=index+1;
 if index==500
 disp(['projection facility activity:',num2str(mean(pr_flag(1:tt)))]);
 disp(['Largest eigenvalue:',num2str(abs(eig_max(tt)))]);
  disp(tt);
   index=0;
 end

learning_matrix(tt,:,:)=[alpha_tt(forward_indices)...
    beta_tt(forward_indices,backward_indices) cc_tt(forward_indices,:)]';


end

figure('Name','intercepts');
plot(squeeze(learning_matrix(burn_in:end,1,:)),'color','black');

figure('Name','lagged inflation');
plot(squeeze(learning_matrix(burn_in:end,5,:)),'color','black');

figure('Name','lagged consumption');
plot(squeeze(learning_matrix(burn_in:end,2,:)),'color','black');

figure('Name','lagged interest rate');
plot(squeeze(learning_matrix(burn_in:end,7,:)),'color','black');

figure('Name','Inflation');
plot(XX(10,:),'color','black');