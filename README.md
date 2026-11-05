# SWRO Desalination Model

## Important: where the printed results come from

This archive contains three distinct things, and their outputs must not be confused:

1. **Baseline MATLAB calculation** (`baseline/swro_baseline_calculation.m`) computes the reference values directly from a vector of fixed parameters. `validate_SWRO_Baseline.m` runs this function and compares its values to the reference CSV. These results do **not** come from Simulink.
2. **Simulink block model** (`baseline/build_SWRO_Modular_Baseline.m`) is a separate signal-flow implementation. The runner simulates it only if Simulink is installed and available. The revised runner performs a top-level wiring audit before simulation. A successful reference-table comparison alone does not prove that the Simulink model ran.
3. **Membrane-transport example** (`membrane/run_swro_demo.m`) is another standalone calculation with illustrative coefficients. Its plotted and printed results also do **not** come from the Simulink diagram.

The Simulink model is a fixed-condition, steady-state signal model, not a dynamic plant model. In particular, the UF pressure boundary and RO feed pressure are imposed by constants; the UF inlet-pressure signal is terminated, and chemical dosing/control/CIP functions are inactive placeholders. Those assumptions are shown in the diagram and are not plant-control functionality.

These educational models are not validated against plant measurements and are not suitable for plant design, guarantees, or operational control.

## Files

- `RUN_SWRO_PROJECT.m` — one-command entry point.
- `baseline/SWRO_Parameters.m` — fixed baseline inputs and signal names.
- `baseline/swro_baseline_calculation.m` — independent baseline calculation function.
- `baseline/validate_SWRO_Baseline.m` — compares the independent calculation with the reference CSV and saves its outputs.
- `baseline/build_SWRO_Modular_Baseline.m` — constructs the editable Simulink model.
- `baseline/verify_SWRO_Connections.m` — checks that every top-level subsystem input and model output has a signal connection.
- `membrane/run_swro_demo.m` and `membrane/swro_steady_state.m` — independent membrane-transport example.
- `data/SWRO_Baseline_Inputs.csv` and `data/SWRO_Baseline_Reference.csv` — example inputs and benchmark values.

## Requirements and run

MATLAB is required for the `.m` files. Simulink is required to build, audit and run the block diagram. Without Simulink, the standalone calculations can still run; their success is not a Simulink test.

1. Extract the ZIP and set MATLAB's Current Folder to the project root (the folder containing this README and `RUN_SWRO_PROJECT.m`).
2. Run:

```matlab
RUN_SWRO_PROJECT
```

The baseline comparison and membrane example execute independently. If Simulink is available, the runner builds the model when no `.slx` exists, audits its top-level subsystem connections, then simulates it. The runner preserves and reports Simulink errors instead of treating the standalone calculation as a successful model simulation.

To audit an already-built model manually:

```matlab
addpath('baseline')
verify_SWRO_Connections('SWRO_Modular_Baseline')
```

To rebuild manually, from the project root:

```matlab
cd baseline
build_SWRO_Modular_Baseline
```

The builder asks before replacing an existing model. The audit checks top-level wiring only; it cannot certify internal process physics, parameter validity, or correctness of every calculation. Inspect individual subsystem interiors and assumptions for those checks.

## Outputs

- `baseline/SWRO_Baseline_Results.csv` — 27 outputs from the standalone MATLAB reference calculation (not from Simulink).
- `baseline/SWRO_Modular_Baseline.slx` — generated Simulink model, if Simulink is available.
- `membrane/swro_profile.csv` — profile from the standalone membrane example.

Rerunning a step may overwrite its generated output file.
