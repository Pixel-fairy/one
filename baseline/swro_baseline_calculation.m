function y = swro_baseline_calculation(u)

Qraw = u(1); TDSraw = u(2); TSSraw = u(3); Traw = u(4); Praw = u(5);
DAFrem = u(6); DAFloss = u(7);
DMFrem = u(8); DMFloss = u(9);
CFrem = u(10); CFloss = u(11);
UFrec = u(12); UFrem = u(13); UFpressure = u(14); UFdp = u(15);
ROrec = u(16); ROrej = u(17); PRO = u(18); Pperm = u(19);
ERDeff = u(20); PERD = u(21); PERDout = u(22); pumpeff = u(23);

Qdaf = Qraw*(1-DAFloss);
TSSdaf = TSSraw*(1-DAFrem);
Qdmf = Qdaf*(1-DMFloss);
TSSdmf = TSSdaf*(1-DMFrem);
Qcf = Qdmf*(1-CFloss);
TSScf = TSSdmf*(1-CFrem);

Qufp = Qcf*UFrec;
Qufr = Qcf-Qufp;
TSSufp = TSScf*(1-UFrem);
if Qufr > 0
    TSSufr = (Qcf*TSScf-Qufp*TSSufp)/Qufr;
else
    TSSufr = 0;
end

Qrof = Qufp;
TDSrof = TDSraw;
Qp = Qrof*ROrec;
Qb = Qrof-Qp;
Cp = TDSrof*(1-ROrej);
if Qb > 0
    Cb = (Qrof*TDSrof-Qp*Cp)/Qb;
else
    Cb = 0;
end

Qproduct = Qp;
Qdischarge = Qb;

Phyd = Qrof*(PRO-u(5))/36;
Ppump = Phyd/pumpeff;
PERDhyd = Qb*(PERD-PERDout)/36*ERDeff;
SEC = (Ppump-PERDhyd)/Qp;
plantRecovery = Qp/Qraw*100;
roRecovery = Qp/Qrof*100;

roWaterErr = Qrof-(Qp+Qb);
roSaltErr = Qrof*TDSrof-(Qp*Cp+Qb*Cb);
pretreatmentLoss = (Qraw-Qdaf)+(Qdaf-Qdmf)+(Qdmf-Qcf);
plantWaterErr = Qraw-(pretreatmentLoss+Qufr+Qp+Qb);

y = zeros(27,1);
y(1) = Qraw;
y(2) = Qdaf;
y(3) = TSSdaf;
y(4) = Qdmf;
y(5) = TSSdmf;
y(6) = Qcf;
y(7) = TSScf;
y(8) = Qufp;
y(9) = Qufr;
y(10) = TSSufp;
y(11) = TSSufr;
y(12) = Qrof;
y(13) = PRO;
y(14) = Qp;
y(15) = Cp;
y(16) = Qb;
y(17) = Cb;
y(18) = Qproduct;
y(19) = Qdischarge;
y(20) = plantRecovery;
y(21) = roRecovery;
y(22) = Ppump;
y(23) = PERDhyd;
y(24) = SEC;
y(25) = roWaterErr;
y(26) = roSaltErr;
y(27) = plantWaterErr;
end
