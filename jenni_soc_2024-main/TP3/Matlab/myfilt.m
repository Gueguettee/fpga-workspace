clear; close all; clc;
% TP3 - SOPC Testbench avec fichiers de sitmuli et résultats
% Construction d'un filtre FIR 

fe = 1e6;      % fréquence d'échantillonnage
fc = fe/7;     % fréquence de coupure
wc = 2*pi*fc;
A = 1;
td = 0;
tht = (-12*1/fe:1/fe:12*1/fe); % 25 valeurs pour le filtre
ht = A*wc/pi*sin(wc*(tht-td))./(wc*(tht-td));
ht(round(length(ht)/2))=A*wc/pi; % traitement de la limite

%Quantification des coefficients 
%(0.9 : évite les dépassements dues aux ondulations de la bande passante)
b=floor(0.9*ht/sum(ht)*(2^15-1));

% Affichage des coefficients du vecteur b
figure('name','FIR coefficients')
stem((1:1:25),b)
ylabel('b coeff.')
grid on

%% Test du filtre avec un sweep de 0 à 500KHz en 0.5s
t = (0:1/fe:0.5);
sweep = floor(chirp(t,0,0.5,fe/2)*(2^15-1));

signal_out = myfir(sweep,b);

figure('name','Test of the FIR (16bits signed integer values)')
plot(t,signal_out,'b')
xlabel('t [s]')
ylabel('sweep filtré')
grid on

%% Génération des fichiers pour le testbench (5000 samples)
N=5000;
% fichier des coefficiants du filtre
writefile(b,'coeff');
writefile(signal_out(1:N),'ref');
% fichier de stimuli
writefile(sweep(1:N),'stimuli');

figure('name','Signals generated for TestBench')
plot(sweep(1:N))
hold on
plot(signal_out(1:N),'r')
grid on

%% Plot the two result

ref2 = readtable("ref2.dat");
ref2 = table2array(ref2);

figure('name','Comparaison between two results')
plot(sweep(1:N))
hold on
plot(signal_out(1:N),'r')
hold on
plot(ref2(1:N),'g')
grid on
