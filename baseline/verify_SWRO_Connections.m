function verify_SWRO_Connections(model)
%VERIFY_SWRO_CONNECTIONS Check top-level subsystem port wiring in the SWRO model.
% This checks that every top-level subsystem input and output has a signal line.
% It does not validate the physical correctness of the process assumptions.
if nargin < 1 || isempty(model)
    model = 'SWRO_Modular_Baseline';
end
if ~bdIsLoaded(model)
    load_system(model);
end
blocks = find_system(model,'SearchDepth',1,'Type','Block');
issues = {};
for k = 1:numel(blocks)
    block = blocks{k};
    try
        type = get_param(block,'BlockType');
    catch
        continue;
    end
    if ~strcmp(type,'SubSystem') && ~strcmp(type,'Outport')
        continue;
    end
    ph = get_param(block,'PortHandles');
    for j = 1:numel(ph.Inport)
        line = get_param(ph.Inport(j),'Line');
        if isempty(line) || line == -1
            issues{end+1} = sprintf('%s input port %d is unconnected',block,j); %#ok<AGROW>
        end
    end
    % Top-level output ports must have an incoming signal as well.
    if strcmp(type,'Outport')
        line = get_param(ph.Inport(1),'Line');
        if isempty(line) || line == -1
            issues{end+1} = sprintf('%s has no source signal',block); %#ok<AGROW>
        end
    end
end
if ~isempty(issues)
    fprintf(2,'SWRO top-level connectivity audit FAILED:\n');
    for k = 1:numel(issues), fprintf(2,'  - %s\n',issues{k}); end
    error('SWRO:DisconnectedSubsystemPorts', ...
        'Repair the listed top-level connections before trusting model output.');
end
fprintf('SWRO top-level connectivity audit passed: all subsystem inputs and model outputs are wired.\n');
end
