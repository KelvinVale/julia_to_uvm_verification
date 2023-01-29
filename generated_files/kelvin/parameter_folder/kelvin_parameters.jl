vip_name = "kelvin"

packet_vec = [
  [true, "bit", "[7:0]", "data_to_send"],
  [false, "bit", "[7:0]", "data_received"]]

signals_if_config = [
  ["logic", "1", "kelvin_ready_o"],
  ["logic", "1", "kelvin_valid_i"],
  ["logic", "[7:0]", "kelvin_data_i"],
  ["logic", "[7:0]", "kelvin_data_o"], ]

rst_is_negedge_sensitive = true

if_vec = ["clk", ["rst_n", rst_is_negedge_sensitive], signals_if_config]

# Descomentar a mudar APENAS SE NECESSÁRIO!!!
# pkg_vec = ["sequence_lib", "sequencer", "packet", "agent", "monitor", "driver"]
# vec_classes = ["sequence_lib", "sequencer", "packet", "pkg", "if", "agent", "driver", "monitor"]
# Descomentar a mudar APENAS SE NECESSÁRIO!!!