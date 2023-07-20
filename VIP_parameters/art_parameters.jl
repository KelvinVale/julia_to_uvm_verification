vip_name = "art"

packet_vec = [
  [true, "bit", "[7:0]", "data_to_send"],
  [false, "bit", "[7:0]", "data_received"]]

signals_if_config = [
  ["logic", "1", "art_ready_o"],
  ["logic", "1", "art_valid_i"],
  ["logic", "[7:0]", "art_data_i"],
  ["logic", "[7:0]", "art_data_o"], ]

rst_is_negedge_sensitive = true

if_vec = ["clk", ["rst_n", rst_is_negedge_sensitive], signals_if_config]

# Descomentar a mudar APENAS SE NECESSÁRIO!!!
pkg_vec = ["sequence_lib", "sequencer", "packet", "agent", "driver"]
vec_classes = ["sequence_lib", "sequencer", "packet", "pkg", "if", "agent", "monitor"]
# Descomentar a mudar APENAS SE NECESSÁRIO!!!