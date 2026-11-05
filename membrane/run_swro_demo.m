function run_swro_demo()

clear; clc; close all;

here = fileparts(mfilename('fullpath'));
dataDir = fullfile(here,'..','data');
baselineInputs = readtable(fullfile(dataDir,'SWRO_Baseline_Inputs.csv'));
baselineReference = readtable(fullfile(dataDir,'SWRO_Baseline_Reference.csv'));
p.feed_flow_m3s = named_numeric_value(baselineInputs,'Name','RO_FEED_FLOW_M3H','Value')/3600;
p.feed_salinity_kgm3 = named_numeric_value(baselineInputs,'Name','RO_FEED_TDS_MGL','Value')/1000;
p.feed_temp_C = named_numeric_value(baselineInputs,'Name','RO_FEED_TEMPERATURE_C','Value');
p.feed_pressure_bar = named_numeric_value(baselineInputs,'Name','RO_FEED_PRESSURE_BAR','Value');
p.permeate_pressure_bar = named_numeric_value(baselineInputs,'Name','RO_PERMEATE_PRESSURE_BAR','Value');
p.membrane_area_m2 = 5000;
p.pressure_drop_bar = 1.1;
p.A_LMH_bar = 1.2;
p.B_LMH = 0.10;
p.k_LMH = 100;
p.pump_eff = 0.85;
p.ERD_eff = 0.95;
p.auxiliary_kW = 0;
p.n_steps = 400;

r = swro_steady_state(p);
s = r.summary;

fprintf('\nSWRO steady-state baseline results (simplified model)\n');
fprintf('-----------------------------------------------------\n');
fprintf('Feed flow:                 %8.3f m^3/s (%8.1f m^3/h)\n', p.feed_flow_m3s, p.feed_flow_m3s*3600);
fprintf('Permeate flow:             %8.3f m^3/s (%8.1f m^3/h)\n', s.permeate_flow_m3s, s.permeate_flow_m3h);
fprintf('Brine flow:                %8.3f m^3/s\n', s.brine_flow_m3s);
fprintf('Recovery:                  %8.2f %%\n', s.recovery_percent);
fprintf('Product salinity:          %8.3f kg/m^3\n', s.product_salinity_kgm3);
fprintf('Brine salinity:            %8.3f kg/m^3\n', s.brine_salinity_kgm3);
fprintf('Salt rejection:            %8.2f %%\n', s.salt_rejection_percent);
fprintf('Average water flux:        %8.2f LMH\n', s.average_flux_LMH);
fprintf('High-pressure pump power:  %8.2f kW\n', s.pump_power_kW);
fprintf('Recovered power estimate:  %8.2f kW\n', s.energy_recovery_kW);
fprintf('Net electric power:        %8.2f kW\n', s.net_power_kW);
fprintf('Specific energy estimate:  %8.2f kWh/m^3\n\n', s.specific_energy_kWh_m3);

referencePermeate_m3h = named_numeric_value(baselineReference,'OutputName','Q_PERMEATE','ReferenceValue');
referenceRecovery_percent = named_numeric_value(baselineReference,'OutputName','RO_RECOVERY_PERCENT','ReferenceValue');
referenceProductSalinity_kgm3 = named_numeric_value(baselineReference,'OutputName','TDS_PERMEATE','ReferenceValue')/1000;
fprintf('Comparison with fixed baseline reference targets:\n');
fprintf('%-28s %14s %14s %14s\n', ...
    'Metric','Physics model','Reference','Difference');
fprintf('%-28s %14.2f %14.2f %14.2f\n', ...
    'Permeate flow (m^3/h)',s.permeate_flow_m3h,referencePermeate_m3h, ...
    s.permeate_flow_m3h-referencePermeate_m3h);
fprintf('%-28s %13.2f%% %13.2f%% %13.2f%%\n', ...
    'RO recovery',s.recovery_percent,referenceRecovery_percent, ...
    s.recovery_percent-referenceRecovery_percent);
fprintf('%-28s %14.2f %14.2f %14.2f\n', ...
    'Product TDS (mg/L)',s.product_salinity_kgm3*1000, ...
    referenceProductSalinity_kgm3*1000, ...
    (s.product_salinity_kgm3-referenceProductSalinity_kgm3)*1000);
fprintf(['Differences are expected: this model calculates membrane transport, ', ...
    'while the reference baseline fixes RO recovery and salt rejection.\n', ...
    'Membrane area and transport coefficients are illustrative and not tuned.\n\n']);

figure('Name','SWRO steady-state profiles','Color','w');
subplot(2,2,1);
plot(r.profile.area_m2, r.profile.pressure_bar,'LineWidth',1.8); grid on;
xlabel('Cumulative membrane area (m^2)'); ylabel('Pressure (bar)'); title('Feed pressure');
subplot(2,2,2);
plot(r.profile.area_m2, r.profile.feed_salinity_kgm3,'LineWidth',1.8); grid on;
xlabel('Cumulative membrane area (m^2)'); ylabel('Bulk salinity (kg/m^3)'); title('Concentration in feed channel');
subplot(2,2,3);
plot(r.profile.area_m2, r.profile.permeate_cumulative_m3s*3600,'LineWidth',1.8); grid on;
xlabel('Cumulative membrane area (m^2)'); ylabel('Cumulative permeate (m^3/h)'); title('Permeate production');
subplot(2,2,4);
plot((r.profile.area_m2(1:end-1)+r.profile.area_m2(2:end))/2, r.profile.local_flux_LMH,'LineWidth',1.8); grid on;
xlabel('Cumulative membrane area (m^2)'); ylabel('Local water flux (LMH)'); title('Local membrane flux');

profileTable = table(r.profile.area_m2, r.profile.feed_flow_m3s, ...
    r.profile.feed_salinity_kgm3, r.profile.pressure_bar, ...
    r.profile.permeate_cumulative_m3s, ...
    'VariableNames', {'Area_m2','FeedFlow_m3s','FeedSalinity_kgm3', ...
    'Pressure_bar','CumulativePermeate_m3s'});
writetable(profileTable,'swro_profile.csv');
fprintf('Saved profile data to swro_profile.csv in the current folder.\n');
end

function value = named_numeric_value(T,keyColumn,key,valueColumn)
keys = T.(keyColumn);
if iscell(keys)
    idx = find(strcmp(keys,key),1);
else
    idx = find(strcmp(keys,key),1);
end
if isempty(idx)
    error('Data key %s was not found in the input CSV.',key);
end
values = T.(valueColumn);
value = values(idx);
end
