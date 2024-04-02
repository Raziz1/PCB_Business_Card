%% NFC Equivalent Circuit
NFC_IC_circuit= circuit('NFC_IC_Circuit');
C1 = add(NFC_IC_circuit,[3 0],capacitor(5.0E-11)); % 50pF
R1 = add(NFC_IC_circuit,[3 0],resistor(100000)); % 100k ohms
setports(NFC_IC_circuit,[3 0])
disp(NFC_IC_circuit)

%% Network Matching Circuit
ckt = circuit('Network_Matching_Circuit');

%R2 = resistor(1.17, 'R2');
L1 = inductor(0.0000026, 'L1');
C2 = capacitor(2e-12,'C2');
add(ckt,[1 3],L1);
%add(ckt,[2 3],R2);
add(ckt,[3 0],C2);
setports(ckt,[1 0],[3 0]);
disp(ckt)
save('Network_Matching_Circuit.mat','ckt');

