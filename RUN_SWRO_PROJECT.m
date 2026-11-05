function RUN_SWRO_PROJECT()
projectRoot = fileparts(mfilename('fullpath'));
baselineDir = fullfile(projectRoot,'baseline');
membraneDir = fullfile(projectRoot,'membrane');
modelName = 'SWRO_Modular_Baseline';
modelFile = fullfile(baselineDir,[modelName '.slx']);
if ~exist(baselineDir,'dir') || ~exist(membraneDir,'dir')
    error('Project folders are missing. Extract the complete project ZIP.');
end
previousFolder = pwd;
restoreFolder = onCleanup(@() cd(previousFolder));
addpath(baselineDir,membraneDir);
fprintf('\nSTEP 1: Baseline calculation and reference comparison\n');
cd(baselineDir);
validate_SWRO_Baseline();
fprintf('\nSTEP 2: Simulink model\n');
if isempty(which('new_system'))
    fprintf('Simulink is not installed or available; skipping this step.\n');
else
    try
        fprintf('Rebuilding the Simulink model from source (replacing any stale SLX)...\n');
        build_SWRO_Modular_Baseline(true);
        if ~exist(modelFile,'file')
            error('The model builder did not create %s.',modelFile);
        end
        % The baseline validation above is independent of Simulink.
        % Audit the actual diagram before accepting a Simulink run.
        verify_SWRO_Connections(modelName);
        simOut = sim(modelName,'ReturnWorkspaceOutputs','on');
        assignin('base','SWRO_SimOutput',simOut);
        fprintf('Simulation completed. Output variable: SWRO_SimOutput\n');
        disp(simOut);
    catch ME
        fprintf(2,'Simulink stage failed:\n%s\n', ...
            getReport(ME,'extended','hyperlinks','off'));
        fprintf(2,'Baseline calculation is complete; share this full error for help.\n');
    end
end
fprintf('\nSTEP 3: Membrane-transport example\n');
cd(membraneDir);
run_swro_demo();
fprintf('\nAll available project steps finished.\n');
fprintf('Baseline CSV: %s\n',fullfile(baselineDir,'SWRO_Baseline_Results.csv'));
fprintf('Membrane CSV: %s\n',fullfile(membraneDir,'swro_profile.csv'));
if exist(modelFile,'file')
    fprintf('Simulink model: %s\n',modelFile);
end
end
