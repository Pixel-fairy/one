function validate_SWRO_Baseline()
P = SWRO_Parameters();
y = swro_baseline_calculation(P.SimulinkInput);
here = fileparts(mfilename('fullpath'));
referenceFile = fullfile(here,'..','data','SWRO_Baseline_Reference.csv');
R = readtable(referenceFile);
actual = zeros(height(R),1);
absError = zeros(height(R),1);
for k = 1:height(R)
    if iscell(R.OutputName)
        outputName = R.OutputName{k};
        displayName = R.DisplayName{k};
    else
        outputName = char(R.OutputName(k));
        displayName = char(R.DisplayName(k));
    end
    idx = find(strcmp(P.OutputNames,outputName),1);
    if isempty(idx)
        error('Reference output name not found in model: %s',outputName);
    end
    actual(k) = y(idx);
    absError(k) = abs(actual(k)-R.ReferenceValue(k));
end
fprintf('SWRO baseline comparison with reference values\n');
fprintf('%-30s %16s %16s %14s\n','Metric','Calculated','Reference','Abs. error');
for k = 1:height(R)
    if iscell(R.DisplayName)
        displayName = R.DisplayName{k};
    else
        displayName = char(R.DisplayName(k));
    end
    fprintf('%-30s %16.6f %16.6f %14.6g\n',displayName, ...
        actual(k),R.ReferenceValue(k),absError(k));
end
fprintf('\nBalance residuals:\n');
fprintf('RO water balance:  %.6g m^3/h\n',y(25));
fprintf('RO salt balance:   %.6g mg/h\n',y(26));
fprintf('Plant water:       %.6g m^3/h\n',y(27));
if any(absError > R.Tolerance)
    warning('One or more values are outside the reference tolerances.');
else
    fprintf('\nPASS: all reference values are within tolerance.\n');
end
if max(abs(y(25:27))) > 1e-6
    warning('A material-balance residual exceeded the numerical tolerance.');
end
results = table(P.OutputNames(:),y(:), ...
    'VariableNames',{'Output','Value'});
resultFile = fullfile(here,'SWRO_Baseline_Results.csv');
writetable(results,resultFile);
fprintf('Saved all baseline outputs to %s\n',resultFile);
end
