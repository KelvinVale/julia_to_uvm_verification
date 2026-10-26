# julia_to_uvm_verification

A small Julia code generator that turns a short parameter file into a ready-to-compile **UVM verification environment** for one or more signal-level interfaces.

From a few lines describing an interface (clock, reset, signals and the transaction fields), it generates the complete verification IP (VIP), a base test, a top-level testbench and a stub DUT, so you can start a new testbench from a working skeleton instead of copying and renaming boilerplate.

## What it generates

For each VIP listed in the configuration:

| File | Content |
|---|---|
| `<vip>_if.sv` | SystemVerilog interface with your signals, reset task and `send_to_dut` / `collect_packet` task skeletons |
| `<vip>_packet.sv` | `uvm_sequence_item` with `rand` fields, field macros and `convert2string()` |
| `<vip>_sequence_lib.sv` | Base sequence (raises/drops objections) and a `random_seq` |
| `<vip>_sequencer.sv` | `uvm_sequencer` parameterized with the packet |
| `<vip>_driver.sv` | `uvm_driver` that waits for reset release and drives items through the interface |
| `<vip>_monitor.sv` | `uvm_monitor` that collects packets and publishes them on an analysis port |
| `<vip>_agent.sv` | Active/passive `uvm_agent` that builds and connects the components above |
| `<vip>_pkg.sv` | Package with the `virtual interface` typedefs and the `include`s in dependency order |

Shared across all VIPs:

| File | Content |
|---|---|
| `test_top/tests.sv` | `base_test` (instantiates every agent) and `random_test` (starts `random_seq` on every sequencer) |
| `test_top/top.sv` | Top module with clock/reset generation, interface instances, DUT instance, `uvm_config_db` hookup and `run_test` |
| `rtl/stub.sv` | Empty DUT whose ports are derived from the interfaces' signals |

## How it works

```
VIP_parameters/<vip>_parameters.jl
        │
        ▼
 vip_files_gen()  ──►  generated_files/<vip>/sv/*.sv
        │                       │
        │                       ▼
        │              stub_gen()  ──►  generated_files/rtl/stub.sv
        │                                generated_files/rtl/stub_parameters.jl
        ▼                                         │
 test_gen()  ──►  generated_files/test_top/tests.sv        │
                                                           ▼
                                   top_gen()  ──►  generated_files/test_top/top.sv
```

Each generator is a pure string-template function (`gen_*_base`) in [code_generate_functions.jl](code_generate_functions.jl). Interface signals and packet fields are expanded into the templates with small line generators, so adding or removing a signal in the parameter file is enough to regenerate everything consistently.

## Repository layout

```
run_script.jl                  Entry point: runs the four generation steps in order
code_generate_parameters.jl    Global switches: which VIPs, which steps, reset behavior
global_vectors.jl              Default list of classes and package include order
code_generate_functions.jl     All templates and generation logic
VIP_parameters/                One <vip>_parameters.jl per interface (the files you edit)
generated_files/               Output (recreated on every run)
```

## Requirements

- [Julia](https://julialang.org/downloads/) **1.10** (tested). The scripts rely on `include` inside functions and do not run on Julia 1.12 yet (`UndefVarError ... world age`); use `juliaup add 1.10` and run with `julia +1.10`.
- A SystemVerilog simulator with UVM support to compile the generated files.

No Julia packages are needed; only the standard library is used.

## Quick start

Run everything from the repository root, since paths are relative:

```bash
julia run_script.jl
```

The sample configuration generates three VIPs (`vip_test`, `art`, `kelvin`), the stub, the tests and the top file under `generated_files/`.

> **Note:** by default the whole `generated_files/` folder is deleted and recreated on each run (`reset_generated_files_folder = true`). Keep hand-written code outside of it, or turn the flag off.

## Creating your own VIP

1. Create `VIP_parameters/<name>_parameters.jl`:

   ```julia
   vip_name = "uart"

   # is_rand? | type | width | name
   packet_vec = [
     [true,  "bit", "[7:0]", "data_to_send"],
     [false, "bit", "[7:0]", "data_received"]]

   # type | width | name   ("1" for a single bit)
   signals_if_config = [
     ["logic", "1",     "uart_ready_o"],
     ["logic", "1",     "uart_valid_i"],
     ["logic", "[7:0]", "uart_data_i"],
     ["logic", "[7:0]", "uart_data_o"]]

   rst_is_negedge_sensitive = true  # active-low reset

   # [clock_name, [reset_name, active_low?], signals]
   if_vec = ["clk", ["rst_n", rst_is_negedge_sensitive], signals_if_config]
   ```

2. Register it in [code_generate_parameters.jl](code_generate_parameters.jl):

   ```julia
   vip_names     = ["uart"]   # VIPs to generate
   stub_if_names = ["uart"]   # VIPs wired into stub, tests and top
   ```

3. Run `julia run_script.jl`.

### Configuration reference

**`code_generate_parameters.jl`**

| Variable | Meaning |
|---|---|
| `vip_names` | VIPs whose files are generated |
| `stub_if_names` | VIPs connected to the stub DUT, the tests and the top module |
| `run_vip_gen`, `run_stub_gen`, `run_test_gen`, `run_top_gen` | Enable or skip each generation step |
| `reset_generated_files_folder` | Delete `generated_files/` before generating |

**Per-VIP file**

| Variable | Shape |
|---|---|
| `packet_vec` | `[is_rand, type, width, name]` per field |
| `signals_if_config` | `[type, width, name]` per interface signal |
| `if_vec` | `[clock_name, [reset_name, is_active_low], signals_if_config]` |
| `pkg_vec` *(optional)* | Components to `include` in the package; order is resolved automatically (packet → sequence library → monitor/sequencer/driver → agent) |
| `vec_classes` *(optional)* | Classes to generate for this VIP; overrides the default in `global_vectors.jl` |

**Signal direction.** The stub infers port direction from the signal name: `_i` becomes `input`, `_o` becomes `output reg`. Names without either suffix are emitted as `NOTYPE` and need to be fixed by hand.

**Clock and reset.** All VIPs in one run share a single clock and reset, so keep `clk` and `rst_n` the same in every parameter file.

## Next steps after generation

The output is a structurally complete skeleton, not a finished testbench. You still provide:

- the protocol logic inside `send_to_dut` and `collect_packet` in `<vip>_if.sv`;
- packet constraints (`// Type your constraints!` in `<vip>_packet.sv`);
- the DUT, replacing `rtl/stub.sv`;
- scoreboards, coverage and any additional sequences.

## Known limitations

- **Driver not generated by default.** The default `vec_classes` in [global_vectors.jl](global_vectors.jl) does not contain `"driver"`, while the default `pkg_vec` includes it. Add `"driver"` to `vec_classes` (globally, or per VIP in its parameter file) to generate `<vip>_driver.sv`.
- Julia 1.12 is not supported (see Requirements).
- Only single-clock, single-reset environments are supported.
- No scoreboard, functional coverage or register layer is generated.

## License

Released under the [MIT License](LICENSE).
