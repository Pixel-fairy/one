function build_SWRO_Modular_Baseline(forceRebuild)
if nargin < 1, forceRebuild = false; end

here = fileparts(mfilename('fullpath'));
addpath(here);
P = SWRO_Parameters();
model = 'SWRO_Modular_Baseline';
modelFile = fullfile(here,[model '.slx']);

if bdIsLoaded(model)
    if forceRebuild
        close_system(model,0);
    elseif strcmp(get_param(model,'Dirty'),'on')
        answer = questdlg([model ' has unsaved edits. Save and close it ', ...
            'before rebuilding?'], 'Open model', ...
            'Save and close','Cancel','Cancel');
        if ~strcmp(answer,'Save and close')
            fprintf('Cancelled; the open model was left unchanged.\n');
            return;
        end
        save_system(model);
    end
    close_system(model,0);
end
if exist(modelFile,'file')
    if forceRebuild
        delete(modelFile);
    else
        answer = questdlg([modelFile ' already exists. Replace it?'], ...
            'Replace model','Replace','Cancel','Cancel');
        if ~strcmp(answer,'Replace')
            fprintf('Cancelled; existing model file was not replaced.\n');
            return;
        end
        delete(modelFile);
    end
end

new_system(model);
open_system(model);
set_param(model,'StopTime','1','SolverType','Fixed-step', ...
    'Solver','FixedStepDiscrete','FixedStep','1', ...
    'SaveOutput','on','OutputSaveName','yout', ...
    'SignalLogging','on','SignalLoggingName','logsout', ...
    'BlockReduction','off');

makeSub(model,'01_Intake_System',{}, ...
    {'Q_RAW','TDS_RAW','TSS_RAW','T_RAW','P_RAW'},[45 175 175 315]);
makeSub(model,'02_Pretreatment', ...
    {'Q_RAW','TDS_RAW','TSS_RAW','T_RAW','P_RAW', ...
     'DOSING_ENABLE_COMMAND','CONTROL_ENABLE_COMMAND'}, ...
    {'Q_DAF','TSS_DAF','Q_DMF','TSS_DMF','Q_CF','TSS_CF', ...
     'Q_UF_PERMEATE','Q_UF_REJECT','TSS_UF_PERMEATE','TSS_UF_REJECT', ...
     'P_UF','T_UF','Q_LOSSES','TDS_UF_PERMEATE'},[245 145 455 350]);
makeSub(model,'03_High_Pressure_Feed', ...
    {'Q_UF_PERMEATE','TDS_UF_PERMEATE','TSS_UF_PERMEATE','T_UF','P_UF'}, ...
    {'Q_RO_FEED','TDS_RO_FEED','TSS_RO_FEED','P_RO_FEED','T_RO_FEED'}, ...
    [520 175 680 315]);
makeSub(model,'04_RO_Pressure_Vessels', ...
    {'Q_RO_FEED','TDS_RO_FEED','P_RO_FEED','T_RO_FEED'}, ...
    {'Q_PERMEATE','TDS_PERMEATE','T_PERMEATE','Q_BRINE', ...
     'TDS_BRINE','P_BRINE','T_BRINE'},[735 145 915 350]);
makeSub(model,'05_Post_Treatment', ...
    {'Q_PERMEATE','TDS_PERMEATE','T_PERMEATE'}, ...
    {'Q_PRODUCT','TDS_PRODUCT','T_PRODUCT'},[970 175 1115 300]);
makeSub(model,'06_Product_Water',{'Q_PRODUCT','TDS_PRODUCT','T_PRODUCT'}, ...
    {'Q_DISTRIBUTION','TDS_DISTRIBUTION','T_DISTRIBUTION'}, ...
    [1170 175 1330 300]);
makeSub(model,'07_Brine_Management', ...
    {'Q_BRINE','TDS_BRINE','P_BRINE','T_BRINE'}, ...
    {'Q_DISCHARGE','TDS_DISCHARGE','P_DISCHARGE','T_DISCHARGE'}, ...
    [970 410 1135 535]);
makeSub(model,'08_Energy_Performance', ...
    {'Q_RAW','Q_LOSSES','Q_UF_REJECT','Q_RO_FEED','TDS_RO_FEED', ...
     'P_RAW','P_RO_FEED','Q_PERMEATE','TDS_PERMEATE','Q_BRINE', ...
     'TDS_BRINE','P_BRINE'}, ...
    {'PUMP_POWER_KW','ERD_RECOVERED_KW','SEC_KWH_M3', ...
     'PLANT_RECOVERY_PERCENT','RO_RECOVERY_PERCENT', ...
     'RO_WATER_BALANCE_ERROR','RO_SALT_BALANCE_ERROR', ...
     'PLANT_WATER_BALANCE_ERROR'},[1170 390 1415 570]);

buildIntake([model '/01_Intake_System'],P);

buildPretreatment([model '/02_Pretreatment'],P);

buildHPFeed([model '/03_High_Pressure_Feed'],P);

buildRO([model '/04_RO_Pressure_Vessels'],P);
buildPostTreatment([model '/05_Post_Treatment']);
buildProductWater([model '/06_Product_Water']);
buildBrineManagement([model '/07_Brine_Management'],P);
buildEnergy([model '/08_Energy_Performance'],P);

styleBlock(model,'01_Intake_System','lightBlue');
styleBlock(model,'02_Pretreatment','cyan');
styleBlock(model,'03_High_Pressure_Feed','orange');
styleBlock(model,'04_RO_Pressure_Vessels','cyan');
styleBlock(model,'05_Post_Treatment','green');
styleBlock(model,'06_Product_Water','lightBlue');
styleBlock(model,'07_Brine_Management','orange');
styleBlock(model,'08_Energy_Performance','yellow');

connectNamed(model,'01_Intake_System/1','02_Pretreatment/1', ...
    'S2 Screened Seawater','blue');
connect(model,'01_Intake_System/2','02_Pretreatment/2');
connect(model,'01_Intake_System/3','02_Pretreatment/3');
connect(model,'01_Intake_System/4','02_Pretreatment/4');
connect(model,'01_Intake_System/5','02_Pretreatment/5');
connectNamed(model,'02_Pretreatment/7','03_High_Pressure_Feed/1', ...
    'S4 UF Permeate','blue');
connect(model,'02_Pretreatment/14','03_High_Pressure_Feed/2');
connect(model,'02_Pretreatment/9','03_High_Pressure_Feed/3');
connect(model,'02_Pretreatment/12','03_High_Pressure_Feed/4');
connect(model,'02_Pretreatment/11','03_High_Pressure_Feed/5');
connectNamed(model,'03_High_Pressure_Feed/1','04_RO_Pressure_Vessels/1', ...
    'S6 RO Feed','blue');
connect(model,'03_High_Pressure_Feed/2','04_RO_Pressure_Vessels/2');
connect(model,'03_High_Pressure_Feed/4','04_RO_Pressure_Vessels/3');
connect(model,'03_High_Pressure_Feed/5','04_RO_Pressure_Vessels/4');
connectNamed(model,'04_RO_Pressure_Vessels/1','05_Post_Treatment/1', ...
    'S7 RO Permeate','blue');
connect(model,'04_RO_Pressure_Vessels/2','05_Post_Treatment/2');
connect(model,'04_RO_Pressure_Vessels/3','05_Post_Treatment/3');
connectNamed(model,'05_Post_Treatment/1','06_Product_Water/1', ...
    'S9 Treated Product Water','blue');
connect(model,'05_Post_Treatment/2','06_Product_Water/2');
connect(model,'05_Post_Treatment/3','06_Product_Water/3');

connectNamed(model,'04_RO_Pressure_Vessels/4','07_Brine_Management/1', ...
    'S8 RO Brine','brown');
connect(model,'04_RO_Pressure_Vessels/5','07_Brine_Management/2');
connect(model,'04_RO_Pressure_Vessels/6','07_Brine_Management/3');
connect(model,'04_RO_Pressure_Vessels/7','07_Brine_Management/4');

connect(model,'01_Intake_System/1','08_Energy_Performance/1');
connect(model,'02_Pretreatment/13','08_Energy_Performance/2');
connect(model,'02_Pretreatment/8','08_Energy_Performance/3');
connect(model,'03_High_Pressure_Feed/1','08_Energy_Performance/4');
connect(model,'03_High_Pressure_Feed/2','08_Energy_Performance/5');
connect(model,'01_Intake_System/5','08_Energy_Performance/6');
connect(model,'03_High_Pressure_Feed/4','08_Energy_Performance/7');
connect(model,'04_RO_Pressure_Vessels/1','08_Energy_Performance/8');
connect(model,'04_RO_Pressure_Vessels/2','08_Energy_Performance/9');
connect(model,'04_RO_Pressure_Vessels/4','08_Energy_Performance/10');
connect(model,'04_RO_Pressure_Vessels/5','08_Energy_Performance/11');
connect(model,'04_RO_Pressure_Vessels/6','08_Energy_Performance/12');

rootOuts = {'Q_PRODUCT_OUT','TDS_PRODUCT_OUT','Q_DISTRIBUTION_OUT', ...
    'Q_DISCHARGE_OUT','TDS_DISCHARGE_OUT','PUMP_POWER_KW_OUT', ...
    'ERD_RECOVERED_KW_OUT','SEC_KWH_M3_OUT','PLANT_RECOVERY_PERCENT_OUT', ...
    'RO_RECOVERY_PERCENT_OUT','RO_WATER_BALANCE_ERROR_OUT', ...
    'RO_SALT_BALANCE_ERROR_OUT','PLANT_WATER_BALANCE_ERROR_OUT'};
rootSrcs = {'05_Post_Treatment/1','05_Post_Treatment/2', ...
    '06_Product_Water/1','07_Brine_Management/1', ...
    '07_Brine_Management/2','08_Energy_Performance/1', ...
    '08_Energy_Performance/2','08_Energy_Performance/3', ...
    '08_Energy_Performance/4','08_Energy_Performance/5', ...
    '08_Energy_Performance/6','08_Energy_Performance/7', ...
    '08_Energy_Performance/8'};
for k=1:numel(rootOuts)
    xpos = 1460 + 5*mod(k-1,2);
    ypos = 40 + 32*(k-1);
    add_block('simulink/Ports & Subsystems/Out1',[model '/' rootOuts{k}], ...
        'Port',num2str(k),'Position',[xpos ypos xpos+35 ypos+18]);
    if k==4
        connectNamed(model,rootSrcs{k},[rootOuts{k} '/1'], ...
            'S10 Brine to Outfall','brown');
    else
        connect(model,rootSrcs{k},[rootOuts{k} '/1']);
    end
end

sensorNames = {'Q_RAW','Q_DAF','TSS_DAF','Q_DMF','TSS_DMF','Q_CF','TSS_CF', ...
    'Q_UF_PERMEATE','Q_UF_REJECT','TSS_UF_PERMEATE','TSS_UF_REJECT', ...
    'Q_RO_FEED','TSS_RO_FEED','P_RO_FEED','Q_PERMEATE','TDS_PERMEATE', ...
    'Q_BRINE','TDS_BRINE','PUMP_POWER_KW','ERD_RECOVERED_KW','SEC_KWH_M3'};
makeSub(model,'09_Instrumentation',sensorNames,sensorNames,[45 470 370 830]);
buildPass([model '/09_Instrumentation'],sensorNames,sensorNames);
styleBlock(model,'09_Instrumentation','lightBlue');
sensorSources = {'01_Intake_System/1','02_Pretreatment/1','02_Pretreatment/2', ...
    '02_Pretreatment/3','02_Pretreatment/4','02_Pretreatment/5', ...
    '02_Pretreatment/6','02_Pretreatment/7','02_Pretreatment/8', ...
    '02_Pretreatment/9','02_Pretreatment/10','03_High_Pressure_Feed/1', ...
    '03_High_Pressure_Feed/3','03_High_Pressure_Feed/4','04_RO_Pressure_Vessels/1','04_RO_Pressure_Vessels/2', ...
    '04_RO_Pressure_Vessels/4','04_RO_Pressure_Vessels/5','08_Energy_Performance/1', ...
    '08_Energy_Performance/2','08_Energy_Performance/3'};
for k=1:numel(sensorNames)
    connect(model,sensorSources{k},sprintf('09_Instrumentation/%d',k));
end

addMuxScope(model,'Flow_Mux',[1 2 4 6 8 9 12 15 17], ...
    [420 455 425 735],[465 475 550 520]);
addMuxScope(model,'TSS_Mux',[3 5 7 10 11 13], ...
    [420 755 425 875],[465 770 550 815]);
addMuxScope(model,'TDS_Mux',[16 18], ...
    [615 455 620 510],[665 470 750 515]);
addMuxScope(model,'Performance_Mux',[19 20 21], ...
    [615 565 620 640],[665 580 750 625]);

makeSub(model,'10_Control_System',{'Control_Enable_Command'}, ...
    {'Control_Enable_Status'},[560 850 725 910]);
buildPass([model '/10_Control_System'], ...
    {'Control_Enable_Command'},{'Control_Enable_Status'});
styleBlock(model,'10_Control_System','white');
addConstant(model,'Control_Disabled',0,[560 815 635 840]);
connect(model,'Control_Disabled/1','10_Control_System/1');
add_block('simulink/Sinks/Terminator',[model '/Control_Status_Terminator'], ...
    'Position',[750 870 770 890]);
connect(model,'10_Control_System/1','Control_Status_Terminator/1');

buildUtilitiesSupport(model,[785 650 1590 845]);
connectNamed(model,'11_Utilities_Support/1','02_Pretreatment/6', ...
    'Chemical dosing enable (disabled)','green','-');
connectNamed(model,'10_Control_System/1','02_Pretreatment/7', ...
    'Control signal (disabled)','red','--');

titleNote = Simulink.Annotation(model, ...
    'SWRO DIGITAL TWIN  |  BASELINE ITERATION 1  |  STEADY-STATE');
titleNote.Position = [45 25 1000 50];
try, titleNote.FontSize=16; titleNote.FontWeight='bold'; titleNote.ForegroundColor='blue'; catch, end
legendNote = Simulink.Annotation(model, ...
    'PROCESS SIGNALS: blue  |  MAIN BRINE-FLOW SIGNAL: brown  |  CHEMICAL: green  |  CONTROL: red dashed');
legendNote.Position = [45 75 1100 35];
try, legendNote.FontSize=10; legendNote.BackgroundColor='lightBlue'; catch, end
connectionNote = Simulink.Annotation(model, ...
    ['The visible lines are actual Simulink signal connections. Each water stream is a bundle ', ...
     'of scalar values (flow, TDS, TSS, pressure, temperature); the labeled Q line marks the stream.']);
connectionNote.Position = [45 112 1370 25];
try, connectionNote.FontSize=9; connectionNote.ForegroundColor='blue'; catch, end
scopeNote = Simulink.Annotation(model, ...
    ['PFD-style signal model: lines carry calculated signals, not physical water. ', ...
     'Chemical dosing, CIP, and control are inactive placeholders in this baseline.']);
scopeNote.Position = [45 925 1280 35];
try, scopeNote.FontSize=10; scopeNote.BackgroundColor='yellow'; catch, end

streamNote = Simulink.Annotation(model, sprintf([ ...
    'STREAM LIST\nS1 Raw seawater\nS2 Screened seawater\n', ...
    'S3 Cartridge-filtered water\nS4 UF permeate\nS5 High-pressure feed\n', ...
    'S6 RO feed\nS7 Permeate\nS8 Brine\nS9 Treated product\n', ...
    'S10 Brine outfall\nS11 Optional return (inactive)']));
streamNote.Position = [45 975 380 190];
try, streamNote.FontSize=9; streamNote.BackgroundColor='white'; catch, end

instrumentNote = Simulink.Annotation(model, sprintf([ ...
    'INSTRUMENT TAGS (EXAMPLES)\nFT-001 Intake flow\nLT-001 Intake level\n', ...
    'PT-001 Intake pressure\nDPT-001 Filter differential pressure\n', ...
    'PT-003 RO feed pressure\nCT-002 Permeate conductivity\n', ...
    'CT-003 Product conductivity\nLT-002 Product tank level\n', ...
    'FT-004 Brine discharge flow']));
instrumentNote.Position = [445 975 380 190];
try, instrumentNote.FontSize=9; instrumentNote.BackgroundColor='lightBlue'; catch, end

legendCard = Simulink.Annotation(model, sprintf([ ...
    'LEGEND\nBlue: feed / permeate / product signals\n', ...
    'Brown: brine / concentrate signals\nGreen: chemical-dose enable (zero)\n', ...
    'Red dashed: disabled control signal\nScope groups: flow, TSS, TDS, performance\n', ...
    'All instruments are ideal taps in this iteration']));
legendCard.Position = [845 975 380 190];
try, legendCard.FontSize=9; legendCard.BackgroundColor='white'; catch, end

abbreviationNote = Simulink.Annotation(model, sprintf([ ...
    'ABBREVIATIONS\nRO: Reverse Osmosis\nSWRO: Seawater RO\n', ...
    'FT: Flow transmitter; PT: Pressure transmitter\n', ...
    'LT: Level transmitter; CT: Conductivity transmitter\n', ...
    'DPT: Differential-pressure transmitter\nCIP: Clean in Place\n', ...
    'MCC: Motor Control Center; PLC/DCS: Control system\n', ...
    'ERD/PX: Energy-recovery device / pressure exchanger']));
abbreviationNote.Position = [1245 975 380 190];
try, abbreviationNote.FontSize=9; abbreviationNote.BackgroundColor='white'; catch, end

set_param(model,'SimulationCommand','update');
try
    lineHandles = find_system(model,'FindAll','on','Type','line');
    fprintf('Simulink signal-line objects created: %d\n',numel(lineHandles));
catch lineCheckError
    fprintf('Line count could not be queried (%s); run verify_SWRO_Connections.\n', ...
        lineCheckError.message);
end
save_system(model,modelFile);
open_system(model);
try, set_param(model,'ZoomFactor','FitSystem'); catch, end
fprintf('\nCreated modular model: %s\n',modelFile);
fprintf('Run validate_SWRO_Baseline.m for direct MATLAB reference checks.\n');
fprintf(['This is a fixed-condition baseline; the control subsystem is inactive ', ...
    'and no dynamic hydraulics are represented.\n']);
end

function makeSub(parent,name,inNames,outNames,pos)
path = [parent '/' name];
add_block('simulink/Ports & Subsystems/Subsystem',path,'Position',pos);
blocks = find_system(path,'SearchDepth',1,'Type','Block');
for j=1:numel(blocks)
    if ~strcmp(blocks{j},path), delete_block(blocks{j}); end
end
for j=1:numel(inNames)
    y=30+32*(j-1);
    add_block('simulink/Ports & Subsystems/In1',[path '/' inNames{j}], ...
        'Port',num2str(j),'Position',[25 y 55 y+18]);
end
for j=1:numel(outNames)
    y=30+30*(j-1);
    add_block('simulink/Ports & Subsystems/Out1',[path '/' outNames{j}], ...
        'Port',num2str(j),'Position',[500 y 535 y+18]);
end
end

function buildIntake(path,P)
streamInputs = {'Q_IN','TDS_IN','TSS_IN','T_IN','P_IN'};
streamOutputs = {'Q_OUT','TDS_OUT','TSS_OUT','T_OUT','P_OUT'};
makeSub(path,'Intake_Structure',streamInputs,streamOutputs,[245 65 385 195]);
makeSub(path,'Coarse_Screen',streamInputs,streamOutputs,[425 65 565 195]);
makeSub(path,'Fine_Screen',streamInputs,streamOutputs,[605 65 745 195]);
buildPass([path '/Intake_Structure'],streamInputs,streamOutputs);
buildPass([path '/Coarse_Screen'],streamInputs,streamOutputs);
buildPass([path '/Fine_Screen'],streamInputs,streamOutputs);
styleBlock(path,'Intake_Structure','lightBlue');
styleBlock(path,'Coarse_Screen','lightBlue');
styleBlock(path,'Fine_Screen','lightBlue');
addConst(path,'Raw_Flow',P.Q_RAW,[130 35 200 60]);
addConst(path,'Raw_TDS',P.TDS_RAW,[130 80 200 105]);
addConst(path,'Raw_TSS',P.TSS_RAW,[130 125 200 150]);
addConst(path,'Raw_Temperature',P.T_RAW,[130 170 200 195]);
addConst(path,'Raw_Pressure',P.P_RAW,[130 215 200 240]);
rawBlocks = {'Raw_Flow','Raw_TDS','Raw_TSS','Raw_Temperature','Raw_Pressure'};
connectNamed(path,'Raw_Flow/1','Intake_Structure/1','S1 Raw Seawater','blue');
for k=2:5, wire(path,[rawBlocks{k} '/1'],sprintf('Intake_Structure/%d',k)); end
for k=1:5, wire(path,sprintf('Intake_Structure/%d',k),sprintf('Coarse_Screen/%d',k)); end
wire(path,'Coarse_Screen/1','Fine_Screen/1');
for k=2:5, wire(path,sprintf('Coarse_Screen/%d',k),sprintf('Fine_Screen/%d',k)); end
rawOutputs = {'Q_RAW','TDS_RAW','TSS_RAW','T_RAW','P_RAW'};
connectNamed(path,'Fine_Screen/1','Q_RAW/1','S2 Screened Seawater','blue');
for k=2:5, wire(path,sprintf('Fine_Screen/%d',k),[rawOutputs{k} '/1']); end
end

function buildPretreatment(path,P)
pretIn = {'Q_IN','TDS_IN','TSS_IN','T_IN','P_IN'};
makeSub(path,'Chemical_Dosing_Placeholder', ...
    [pretIn {'DOSING_ENABLE','CONTROL_ENABLE'}], ...
    {'Q_OUT','TDS_OUT','TSS_OUT','T_OUT','P_OUT'},[70 55 205 210]);
buildPass([path '/Chemical_Dosing_Placeholder'],pretIn, ...
    {'Q_OUT','TDS_OUT','TSS_OUT','T_OUT','P_OUT'});
inactiveCommands = {'DOSING_ENABLE','CONTROL_ENABLE'};
for k=6:7
    termName = sprintf('Inactive_Command_Terminator_%d',k-5);
    add_block('simulink/Sinks/Terminator',[path '/Chemical_Dosing_Placeholder/' termName], ...
        'Position',[70 240+35*(k-6) 90 260+35*(k-6)]);
    wire([path '/Chemical_Dosing_Placeholder'], ...
        [inactiveCommands{k-5} '/1'],[termName '/1']);
end
styleBlock(path,'Chemical_Dosing_Placeholder','green');
makeSub(path,'DAF',pretIn,{'Q_OUT','TDS_OUT','TSS_OUT','T_OUT','P_OUT'},[235 55 365 210]);
makeSub(path,'DMF',{'Q_IN','TDS_IN','TSS_IN','T_IN','P_IN'}, ...
    {'Q_OUT','TDS_OUT','TSS_OUT','T_OUT','P_OUT'},[400 55 530 210]);
makeSub(path,'Cartridge_Filter',{'Q_IN','TDS_IN','TSS_IN','T_IN','P_IN'}, ...
    {'Q_OUT','TDS_OUT','TSS_OUT','T_OUT','P_OUT'},[565 55 695 210]);
makeSub(path,'UF',{'Q_IN','TDS_IN','TSS_IN','T_IN','P_IN'}, ...
    {'Q_PERMEATE','TDS_PERMEATE','TSS_PERMEATE','T_PERMEATE', ...
     'P_PERMEATE','Q_REJECT','TSS_REJECT'},[735 55 865 270]);
buildFilter([path '/DAF'],1-P.DAF_WATER_LOSS,1-P.DAF_TSS_REMOVAL);
buildFilter([path '/DMF'],1-P.DMF_WATER_LOSS,1-P.DMF_TSS_REMOVAL);
buildFilter([path '/Cartridge_Filter'],1-P.CF_WATER_LOSS,1-P.CF_TSS_REMOVAL);
buildUF([path '/UF'],P);
styleBlock(path,'DAF','lightBlue');
styleBlock(path,'DMF','lightBlue');
styleBlock(path,'Cartridge_Filter','lightBlue');
styleBlock(path,'UF','cyan');

wire(path,'Q_RAW/1','Chemical_Dosing_Placeholder/1');
wire(path,'TDS_RAW/1','Chemical_Dosing_Placeholder/2');
wire(path,'TSS_RAW/1','Chemical_Dosing_Placeholder/3');
wire(path,'T_RAW/1','Chemical_Dosing_Placeholder/4');
wire(path,'P_RAW/1','Chemical_Dosing_Placeholder/5');
wire(path,'DOSING_ENABLE_COMMAND/1','Chemical_Dosing_Placeholder/6');
wire(path,'CONTROL_ENABLE_COMMAND/1','Chemical_Dosing_Placeholder/7');
for k=1:5, wire(path,sprintf('Chemical_Dosing_Placeholder/%d',k),sprintf('DAF/%d',k)); end
for k=1:5, wire(path,sprintf('DAF/%d',k),sprintf('DMF/%d',k)); end
for k=1:5, wire(path,sprintf('DMF/%d',k),sprintf('Cartridge_Filter/%d',k)); end
connectNamed(path,'Cartridge_Filter/1','UF/1','S3 Cartridge-Filtered Water','blue');
for k=2:5, wire(path,sprintf('Cartridge_Filter/%d',k),sprintf('UF/%d',k)); end

wire(path,'DAF/1','Q_DAF/1'); wire(path,'DAF/3','TSS_DAF/1');
wire(path,'DMF/1','Q_DMF/1'); wire(path,'DMF/3','TSS_DMF/1');
wire(path,'Cartridge_Filter/1','Q_CF/1'); wire(path,'Cartridge_Filter/3','TSS_CF/1');
wire(path,'UF/1','Q_UF_PERMEATE/1'); wire(path,'UF/2','TDS_UF_PERMEATE/1');
wire(path,'UF/3','TSS_UF_PERMEATE/1'); wire(path,'UF/4','T_UF/1');
wire(path,'UF/5','P_UF/1'); wire(path,'UF/6','Q_UF_REJECT/1');
wire(path,'UF/7','TSS_UF_REJECT/1');
addSum(path,'loss_calc','+-',[865 135 895 180]);
wire(path,'Q_RAW/1','loss_calc/1');
wire(path,'Cartridge_Filter/1','loss_calc/2');
end

function buildFilter(path,qFactor,tssFactor)
addGain(path,'Flow_Loss_Model',qFactor,[175 60 230 90]);
addGain(path,'TSS_Removal_Model',tssFactor,[175 115 230 145]);
wire(path,'Q_IN/1','Flow_Loss_Model/1'); wire(path,'Flow_Loss_Model/1','Q_OUT/1');
wire(path,'TDS_IN/1','TDS_OUT/1');
wire(path,'TSS_IN/1','TSS_Removal_Model/1'); wire(path,'TSS_Removal_Model/1','TSS_OUT/1');
wire(path,'T_IN/1','T_OUT/1'); wire(path,'P_IN/1','P_OUT/1');
end

function buildUF(path,P)
addConst(path,'UF_Recovery',P.UF_RECOVERY,[165 205 220 230]);
addConst(path,'UF_TSS_Passage',1-P.UF_TSS_REMOVAL,[165 245 220 270]);
addConst(path,'UF_Feed_Pressure',P.UF_FEED_PRESSURE,[165 295 220 320]);
addConst(path,'UF_Pressure_Drop',P.UF_PRESSURE_DROP,[165 335 220 360]);
addProduct(path,'UF_Permeate_Flow','**',[250 45 285 85]);
wire(path,'Q_IN/1','UF_Permeate_Flow/1');
wire(path,'UF_Recovery/1','UF_Permeate_Flow/2');
wire(path,'UF_Permeate_Flow/1','Q_PERMEATE/1');
addSum(path,'UF_Reject_Flow','+-',[335 55 365 105]);
wire(path,'Q_IN/1','UF_Reject_Flow/1'); wire(path,'Q_PERMEATE/1','UF_Reject_Flow/2');
wire(path,'UF_Reject_Flow/1','Q_REJECT/1');
wire(path,'TDS_IN/1','TDS_PERMEATE/1');
addProduct(path,'UF_TSS_Permeate','**',[250 125 285 165]);
wire(path,'TSS_IN/1','UF_TSS_Permeate/1');
wire(path,'UF_TSS_Passage/1','UF_TSS_Permeate/2');
wire(path,'UF_TSS_Permeate/1','TSS_PERMEATE/1');
addProduct(path,'feed_TSS_mass','**',[250 185 285 225]);
wire(path,'TSS_IN/1','feed_TSS_mass/1'); wire(path,'Q_IN/1','feed_TSS_mass/2');
addProduct(path,'perm_TSS_mass','**',[335 175 370 215]);
wire(path,'Q_PERMEATE/1','perm_TSS_mass/1'); wire(path,'TSS_PERMEATE/1','perm_TSS_mass/2');
addSum(path,'reject_TSS_mass','+-',[400 185 430 240]);
wire(path,'feed_TSS_mass/1','reject_TSS_mass/1'); wire(path,'perm_TSS_mass/1','reject_TSS_mass/2');
addProduct(path,'reject_TSS_concentration','*/',[455 185 490 235]);
wire(path,'reject_TSS_mass/1','reject_TSS_concentration/1');
wire(path,'Q_REJECT/1','reject_TSS_concentration/2');
wire(path,'reject_TSS_concentration/1','TSS_REJECT/1');
wire(path,'T_IN/1','T_PERMEATE/1');
addSum(path,'UF_Pressure_Out','+-',[335 285 365 335]);
wire(path,'UF_Feed_Pressure/1','UF_Pressure_Out/1');
wire(path,'UF_Pressure_Drop/1','UF_Pressure_Out/2');
wire(path,'UF_Pressure_Out/1','P_PERMEATE/1');

add_block('simulink/Sinks/Terminator',[path '/UF_Input_Pressure_Terminator'], ...
    'Position',[85 355 105 375]);
wire(path,'P_IN/1','UF_Input_Pressure_Terminator/1');
end

function buildHPFeed(path,P)
makeSub(path,'High_Pressure_Feed_Pump', ...
    {'Q_IN','TDS_IN','TSS_IN','T_IN'}, ...
    {'Q_OUT','TDS_OUT','TSS_OUT','P_OUT','T_OUT'},[205 65 365 220]);
makeSub(path,'Pressure_Exchange_ERD', ...
    {'Q_IN','TDS_IN','TSS_IN','P_IN','T_IN'}, ...
    {'Q_OUT','TDS_OUT','TSS_OUT','P_OUT','T_OUT'},[430 65 600 220]);
pumpPath = [path '/High_Pressure_Feed_Pump'];
wire(pumpPath,'Q_IN/1','Q_OUT/1');
wire(pumpPath,'TDS_IN/1','TDS_OUT/1');
wire(pumpPath,'TSS_IN/1','TSS_OUT/1');
wire(pumpPath,'T_IN/1','T_OUT/1');
pxPath = [path '/Pressure_Exchange_ERD'];
buildPass(pxPath,{'Q_IN','TDS_IN','TSS_IN','P_IN','T_IN'}, ...
    {'Q_OUT','TDS_OUT','TSS_OUT','P_OUT','T_OUT'});
wire(path,'Q_UF_PERMEATE/1','High_Pressure_Feed_Pump/1');
wire(path,'TDS_UF_PERMEATE/1','High_Pressure_Feed_Pump/2');
wire(path,'TSS_UF_PERMEATE/1','High_Pressure_Feed_Pump/3');
wire(path,'T_UF/1','High_Pressure_Feed_Pump/4');
connectNamed(path,'High_Pressure_Feed_Pump/1','Pressure_Exchange_ERD/1', ...
    'S5 High-Pressure Feed','blue');
wire(path,'High_Pressure_Feed_Pump/2','Pressure_Exchange_ERD/2');
wire(path,'High_Pressure_Feed_Pump/3','Pressure_Exchange_ERD/3');
wire(path,'High_Pressure_Feed_Pump/4','Pressure_Exchange_ERD/4');
wire(path,'High_Pressure_Feed_Pump/5','Pressure_Exchange_ERD/5');
wire(path,'Pressure_Exchange_ERD/1','Q_RO_FEED/1');
wire(path,'Pressure_Exchange_ERD/2','TDS_RO_FEED/1');
wire(path,'Pressure_Exchange_ERD/3','TSS_RO_FEED/1');
wire(path,'Pressure_Exchange_ERD/4','P_RO_FEED/1');
wire(path,'Pressure_Exchange_ERD/5','T_RO_FEED/1');
addConst([path '/High_Pressure_Feed_Pump'],'RO_Feed_Pressure_Boundary', ...
    P.RO_FEED_PRESSURE,[145 250 215 275]);
wire([path '/High_Pressure_Feed_Pump'], ...
    'RO_Feed_Pressure_Boundary/1','P_OUT/1');
styleBlock(path,'High_Pressure_Feed_Pump','orange');
styleBlock(path,'Pressure_Exchange_ERD','orange');
add_block('simulink/Sinks/Terminator',[path '/UF_Pressure_Terminator'], ...
    'Position',[100 230 120 250]);
wire(path,'P_UF/1','UF_Pressure_Terminator/1');
end

function buildPostTreatment(path)
signals = {'Q_IN','TDS_IN','T_IN'};
makeSub(path,'pH_Adjustment',signals,{'Q_OUT','TDS_OUT','T_OUT'},[70 55 210 170]);
makeSub(path,'Remineralization',signals,{'Q_OUT','TDS_OUT','T_OUT'},[260 55 410 170]);
makeSub(path,'Final_Disinfection',signals,{'Q_OUT','TDS_OUT','T_OUT'},[460 55 615 170]);
buildPass([path '/pH_Adjustment'],signals,{'Q_OUT','TDS_OUT','T_OUT'});
buildPass([path '/Remineralization'],signals,{'Q_OUT','TDS_OUT','T_OUT'});
buildPass([path '/Final_Disinfection'],signals,{'Q_OUT','TDS_OUT','T_OUT'});
styleBlock(path,'pH_Adjustment','green');
styleBlock(path,'Remineralization','green');
styleBlock(path,'Final_Disinfection','green');
inputNames = {'Q_PERMEATE','TDS_PERMEATE','T_PERMEATE'};
for k=1:3, wire(path,[inputNames{k} '/1'],sprintf('pH_Adjustment/%d',k)); end
for k=1:3, wire(path,sprintf('pH_Adjustment/%d',k),sprintf('Remineralization/%d',k)); end
for k=1:3, wire(path,sprintf('Remineralization/%d',k),sprintf('Final_Disinfection/%d',k)); end
outputNames = {'Q_PRODUCT','TDS_PRODUCT','T_PRODUCT'};
for k=1:3, wire(path,sprintf('Final_Disinfection/%d',k),[outputNames{k} '/1']); end
end

function buildProductWater(path)
signals = {'Q_IN','TDS_IN','T_IN'};
makeSub(path,'Product_Water_Tank',signals, ...
    {'Q_OUT','TDS_OUT','T_OUT'},[220 65 420 205]);
buildPass([path '/Product_Water_Tank'],signals,{'Q_OUT','TDS_OUT','T_OUT'});
styleBlock(path,'Product_Water_Tank','lightBlue');
inputNames = {'Q_PRODUCT','TDS_PRODUCT','T_PRODUCT'};
for k=1:3, wire(path,[inputNames{k} '/1'],sprintf('Product_Water_Tank/%d',k)); end
outputNames = {'Q_DISTRIBUTION','TDS_DISTRIBUTION','T_DISTRIBUTION'};
for k=1:3, wire(path,sprintf('Product_Water_Tank/%d',k),[outputNames{k} '/1']); end
end

function buildBrineManagement(path,P)
signals = {'Q_IN','TDS_IN','P_IN','T_IN'};
makeSub(path,'Energy_Recovery_Device',signals, ...
    {'Q_OUT','TDS_OUT','P_OUT','T_OUT'},[70 55 225 190]);
makeSub(path,'Brine_Cooler',signals, ...
    {'Q_OUT','TDS_OUT','P_OUT','T_OUT'},[285 55 425 190]);
makeSub(path,'Outfall_Diffuser',signals, ...
    {'Q_OUT','TDS_OUT','P_OUT','T_OUT'},[485 55 635 190]);
wire([path '/Energy_Recovery_Device'],'Q_IN/1','Q_OUT/1');
wire([path '/Energy_Recovery_Device'],'TDS_IN/1','TDS_OUT/1');
wire([path '/Energy_Recovery_Device'],'T_IN/1','T_OUT/1');
add_block('simulink/Sinks/Terminator', ...
    [path '/Energy_Recovery_Device/Pressure_Input_Terminator'], ...
    'Position',[45 235 65 255]);
wire([path '/Energy_Recovery_Device'], ...
    'P_IN/1','Pressure_Input_Terminator/1');
buildPass([path '/Brine_Cooler'],signals,{'Q_OUT','TDS_OUT','P_OUT','T_OUT'});
buildPass([path '/Outfall_Diffuser'],signals,{'Q_OUT','TDS_OUT','P_OUT','T_OUT'});
addConst([path '/Energy_Recovery_Device'],'ERD_Outlet_Pressure', ...
    P.ERD_OUTLET_PRESSURE,[95 235 165 260]);
wire([path '/Energy_Recovery_Device'],'ERD_Outlet_Pressure/1','P_OUT/1');
styleBlock(path,'Energy_Recovery_Device','orange');
styleBlock(path,'Brine_Cooler','lightBlue');
styleBlock(path,'Outfall_Diffuser','lightBlue');
inputNames = {'Q_BRINE','TDS_BRINE','P_BRINE','T_BRINE'};
for k=1:4, wire(path,[inputNames{k} '/1'],sprintf('Energy_Recovery_Device/%d',k)); end
for k=1:4, wire(path,sprintf('Energy_Recovery_Device/%d',k),sprintf('Brine_Cooler/%d',k)); end
for k=1:4, wire(path,sprintf('Brine_Cooler/%d',k),sprintf('Outfall_Diffuser/%d',k)); end
outputNames = {'Q_DISCHARGE','TDS_DISCHARGE','P_DISCHARGE','T_DISCHARGE'};
for k=1:4, wire(path,sprintf('Outfall_Diffuser/%d',k),[outputNames{k} '/1']); end
end

function buildRO(path,P)
addConst(path,'RO_Recovery',P.RO_RECOVERY,[120 195 180 220]);
addConst(path,'RO_Salt_Rejection',P.RO_SALT_REJECTION,[120 235 180 260]);
addProduct(path,'Permeate_Flow','**',[190 40 225 80]);
wire(path,'Q_RO_FEED/1','Permeate_Flow/1');
wire(path,'RO_Recovery/1','Permeate_Flow/2');
wire(path,'Permeate_Flow/1','Q_PERMEATE/1');
addSum(path,'Brine_Flow','+-',[275 45 305 95]);
wire(path,'Q_RO_FEED/1','Brine_Flow/1'); wire(path,'Q_PERMEATE/1','Brine_Flow/2');
wire(path,'Brine_Flow/1','Q_BRINE/1');
addConst(path,'Unit_Salt_Passage',1,[120 285 175 310]);
addGain(path,'Negative_Salt_Rejection',-1,[190 220 250 250]);
wire(path,'RO_Salt_Rejection/1','Negative_Salt_Rejection/1');
addSum(path,'Salt_Passage','+-',[275 205 305 255]);
wire(path,'Unit_Salt_Passage/1','Salt_Passage/1');
wire(path,'Negative_Salt_Rejection/1','Salt_Passage/2');
addProduct(path,'Permeate_TDS','**',[190 115 225 155]);
wire(path,'TDS_RO_FEED/1','Permeate_TDS/1');
wire(path,'Salt_Passage/1','Permeate_TDS/2');
wire(path,'Permeate_TDS/1','TDS_PERMEATE/1');
wire(path,'T_RO_FEED/1','T_PERMEATE/1'); wire(path,'T_RO_FEED/1','T_BRINE/1');
addProduct(path,'Feed_Salt_Rate','**',[190 275 225 315]);
addProduct(path,'Permeate_Salt_Rate','**',[275 275 310 315]);
wire(path,'Q_RO_FEED/1','Feed_Salt_Rate/1'); wire(path,'TDS_RO_FEED/1','Feed_Salt_Rate/2');
wire(path,'Q_PERMEATE/1','Permeate_Salt_Rate/1'); wire(path,'TDS_PERMEATE/1','Permeate_Salt_Rate/2');
addSum(path,'Brine_Salt_Rate','+-',[350 275 380 330]);
wire(path,'Feed_Salt_Rate/1','Brine_Salt_Rate/1');
wire(path,'Permeate_Salt_Rate/1','Brine_Salt_Rate/2');
addProduct(path,'Brine_TDS','*/',[405 275 440 325]);
wire(path,'Brine_Salt_Rate/1','Brine_TDS/1'); wire(path,'Q_BRINE/1','Brine_TDS/2');
wire(path,'Brine_TDS/1','TDS_BRINE/1');
addConst(path,'ERD_Brine_Pressure',P.ERD_BRINE_PRESSURE,[300 150 365 175]);
wire(path,'ERD_Brine_Pressure/1','P_BRINE/1');
end

function buildEnergy(path,P)

addSum(path,'Pump_Pressure_Rise','+-',[145 45 175 100]);
wire(path,'P_RO_FEED/1','Pump_Pressure_Rise/1'); wire(path,'P_RAW/1','Pump_Pressure_Rise/2');
addProduct(path,'Pump_Hydraulic_Power_Base','**',[205 45 240 90]);
wire(path,'Q_RO_FEED/1','Pump_Hydraulic_Power_Base/1');
wire(path,'Pump_Pressure_Rise/1','Pump_Hydraulic_Power_Base/2');
addGain(path,'Pump_Power_kW',1/(36*P.PUMP_EFFICIENCY),[270 45 335 80]);
wire(path,'Pump_Hydraulic_Power_Base/1','Pump_Power_kW/1'); wire(path,'Pump_Power_kW/1','PUMP_POWER_KW/1');

addConst(path,'ERD_Outlet_Pressure',P.ERD_OUTLET_PRESSURE,[145 165 210 190]);
addSum(path,'ERD_Pressure_Drop','+-',[245 150 275 205]);
wire(path,'P_BRINE/1','ERD_Pressure_Drop/1'); wire(path,'ERD_Outlet_Pressure/1','ERD_Pressure_Drop/2');
addProduct(path,'ERD_Hydraulic_Power_Base','**',[300 150 335 195]);
wire(path,'Q_BRINE/1','ERD_Hydraulic_Power_Base/1'); wire(path,'ERD_Pressure_Drop/1','ERD_Hydraulic_Power_Base/2');
addGain(path,'ERD_Power_kW',P.ERD_EFFICIENCY/36,[365 150 425 185]);
wire(path,'ERD_Hydraulic_Power_Base/1','ERD_Power_kW/1'); wire(path,'ERD_Power_kW/1','ERD_RECOVERED_KW/1');

addSum(path,'Net_Power','+-',[365 50 395 100]);
wire(path,'PUMP_POWER_KW/1','Net_Power/1'); wire(path,'ERD_RECOVERED_KW/1','Net_Power/2');
addProduct(path,'SEC','*/',[425 50 460 100]);
wire(path,'Net_Power/1','SEC/1'); wire(path,'Q_PERMEATE/1','SEC/2'); wire(path,'SEC/1','SEC_KWH_M3/1');
addProduct(path,'Plant_Recovery','*/',[145 275 180 320]);
wire(path,'Q_PERMEATE/1','Plant_Recovery/1'); wire(path,'Q_RAW/1','Plant_Recovery/2');
addGain(path,'Plant_Recovery_Percent',100,[205 275 265 305]);
wire(path,'Plant_Recovery/1','Plant_Recovery_Percent/1'); wire(path,'Plant_Recovery_Percent/1','PLANT_RECOVERY_PERCENT/1');
addProduct(path,'RO_Recovery_Calc','*/',[300 270 335 315]);
wire(path,'Q_PERMEATE/1','RO_Recovery_Calc/1'); wire(path,'Q_RO_FEED/1','RO_Recovery_Calc/2');
addGain(path,'RO_Recovery_Percent',100,[360 270 420 300]);
wire(path,'RO_Recovery_Calc/1','RO_Recovery_Percent/1'); wire(path,'RO_Recovery_Percent/1','RO_RECOVERY_PERCENT/1');
addSum(path,'RO_Water_Balance','+--',[145 365 175 420]);
wire(path,'Q_RO_FEED/1','RO_Water_Balance/1'); wire(path,'Q_PERMEATE/1','RO_Water_Balance/2'); wire(path,'Q_BRINE/1','RO_Water_Balance/3');
wire(path,'RO_Water_Balance/1','RO_WATER_BALANCE_ERROR/1');
addProduct(path,'RO_Feed_Salt','**',[205 365 240 405]);
addProduct(path,'RO_Permeate_Salt','**',[205 425 240 465]);
addProduct(path,'RO_Brine_Salt','**',[205 485 240 525]);
wire(path,'Q_RO_FEED/1','RO_Feed_Salt/1'); wire(path,'TDS_RO_FEED/1','RO_Feed_Salt/2');
wire(path,'Q_PERMEATE/1','RO_Permeate_Salt/1'); wire(path,'TDS_PERMEATE/1','RO_Permeate_Salt/2');
wire(path,'Q_BRINE/1','RO_Brine_Salt/1'); wire(path,'TDS_BRINE/1','RO_Brine_Salt/2');
addSum(path,'RO_Salt_Balance','+--',[275 380 305 445]);
wire(path,'RO_Feed_Salt/1','RO_Salt_Balance/1');
wire(path,'RO_Permeate_Salt/1','RO_Salt_Balance/2');
wire(path,'RO_Brine_Salt/1','RO_Salt_Balance/3');
wire(path,'RO_Salt_Balance/1','RO_SALT_BALANCE_ERROR/1');
addSum(path,'Plant_Water_Balance','+----',[350 385 380 480]);
wire(path,'Q_RAW/1','Plant_Water_Balance/1');
wire(path,'Q_LOSSES/1','Plant_Water_Balance/2');
wire(path,'Q_UF_REJECT/1','Plant_Water_Balance/3');
wire(path,'Q_PERMEATE/1','Plant_Water_Balance/4');
wire(path,'Q_BRINE/1','Plant_Water_Balance/5');
wire(path,'Plant_Water_Balance/1','PLANT_WATER_BALANCE_ERROR/1');
end

function buildPass(path,inNames,outNames)
for j=1:numel(inNames)
    wire(path,[inNames{j} '/1'],[outNames{j} '/1']);
end
end

function buildUtilitiesSupport(model,pos)
makeSub(model,'11_Utilities_Support',{}, {'DOSING_ENABLE_COMMAND'},pos);
panel = [model '/11_Utilities_Support'];
addConst(panel,'Chemical_Dosing_Enable_Disabled',0,[740 160 795 185]);
wire(panel,'Chemical_Dosing_Enable_Disabled/1','DOSING_ENABLE_COMMAND/1');
names = {'Chemical_Storage_Dosing','CIP_System','Instrument_Air', ...
    'Electrical_MCC','PLC_DCS_Support'};
labels = {'Chemical storage & dosing (inactive)', ...
    'CIP clean-in-place (inactive)','Instrument air (placeholder)', ...
    'Electrical & MCC (placeholder)','PLC/DCS monitoring (placeholder)'};
colors = {'green','yellow','lightBlue','orange','lightBlue'};
for k=1:numel(names)
    x = 25 + (k-1)*145;
    childPath = [panel '/' names{k}];
    makeSub(panel,names{k},{},{},[x 60 x+130 145]);
    styleBlock(panel,names{k},colors{k});
    note = Simulink.Annotation(childPath,labels{k});
    note.Position = [15 25 150 55];
end
panelNote = Simulink.Annotation(panel, ...
    'Utility/support equipment is shown for PFD context; no chemistry, CIP, or electrical dynamics are active.');
panelNote.Position = [25 15 450 35];
styleBlock(model,'11_Utilities_Support','lightBlue');
end

function addMuxScope(model,name,channelIndices,muxPosition,scopePosition)
muxName = [name '_Mux'];
scopeName = [name '_Scope'];
add_block('simulink/Signal Routing/Mux',[model '/' muxName], ...
    'Inputs',num2str(numel(channelIndices)),'Position',muxPosition);
for j=1:numel(channelIndices)
    connect(model,sprintf('09_Instrumentation/%d',channelIndices(j)), ...
        sprintf('%s/%d',muxName,j));
end
add_block('simulink/Sinks/Scope',[model '/' scopeName], ...
    'Position',scopePosition);
connect(model,[muxName '/1'],[scopeName '/1']);
end

function addConst(parent,name,val,pos)
add_block('simulink/Sources/Constant',[parent '/' name], ...
    'Value',num2str(val,16),'Position',pos);
end
function styleBlock(parent,name,colorName)
blockPath = [parent '/' name];
set_param(blockPath,'BackgroundColor',colorName,'ForegroundColor','black', ...
    'FontSize','12','ShowName','on');
try, set_param(blockPath,'ShowPortLabels','FromPortSignal'); catch, end
end
function addGain(parent,name,val,pos)
add_block('simulink/Math Operations/Gain',[parent '/' name], ...
    'Gain',num2str(val,16),'Position',pos);
end
function addSum(parent,name,signs,pos)
add_block('simulink/Math Operations/Sum',[parent '/' name], ...
    'Inputs',signs,'Position',pos);
end
function addProduct(parent,name,inputs,pos)
add_block('simulink/Math Operations/Product',[parent '/' name], ...
    'Inputs',inputs,'Position',pos);
end
function wire(parent,src,dst)
if isempty(strfind(src,'/')), src=[src '/1']; end
if isempty(strfind(dst,'/')), dst=[dst '/1']; end
connect(parent,src,dst);
end
function connect(parent,src,dst)
lineHandle = addSignalLine(parent,src,dst);
try, set_param(lineHandle,'ForegroundColor','blue'); catch, end
try, set_param(lineHandle,'LineWidth','2'); catch, end
end

function connectNamed(parent,src,dst,signalName,colorName,lineStyle)
if nargin<6, lineStyle='-'; end
lineHandle = addSignalLine(parent,src,dst);
try
    set_param(lineHandle,'ForegroundColor',colorName,'LineStyle',lineStyle);
catch

    try, set_param(lineHandle,'ForegroundColor',colorName); catch, end
end
try, set_param(lineHandle,'LineWidth','3'); catch, end
try, set_param(lineHandle,'Name',signalName); catch, end
end

function lineHandle = addSignalLine(parent,src,dst)
if isempty(strfind(src,'/')), src=[src '/1']; end
if isempty(strfind(dst,'/')), dst=[dst '/1']; end
try
    lineHandle = add_line(parent,src,dst,'autorouting','on');
catch pathError
    [srcBlock,srcPort] = splitPortReference(src);
    [dstBlock,dstPort] = splitPortReference(dst);
    srcHandles = get_param([parent '/' srcBlock],'PortHandles');
    dstHandles = get_param([parent '/' dstBlock],'PortHandles');
    if srcPort > numel(srcHandles.Outport) || dstPort > numel(dstHandles.Inport)
        error('SWRO:PortIndex','Requested port number is outside the block port range.');
    end
    try
        lineHandle = add_line(parent,srcHandles.Outport(srcPort), ...
            dstHandles.Inport(dstPort),'autorouting','on');
    catch handleError
        error('SWRO:ConnectionFailed', ...
            'Failed to connect %s to %s in %s. Path error: %s Handle error: %s', ...
            src,dst,parent,pathError.message,handleError.message);
    end
end
end

function [blockName,portNumber] = splitPortReference(reference)
slash = strfind(reference,'/');
if isempty(slash)
    error('SWRO:BadPortReference','Expected block/port reference, got: %s',reference);
end
lastSlash = slash(end);
blockName = reference(1:lastSlash-1);
portNumber = str2double(reference(lastSlash+1:end));
if isempty(blockName) || ~isfinite(portNumber) || portNumber < 1 || ...
        portNumber ~= floor(portNumber)
    error('SWRO:BadPortReference','Invalid block/port reference: %s',reference);
end
end
