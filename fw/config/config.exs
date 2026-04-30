# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

firmware_config =
  if Mix.target() == :rpi0_2 do
    [rootfs_overlay: "rootfs_overlay", fwup_conf: "config/fwup_rpi0.conf"]
  else
    [rootfs_overlay: "rootfs_overlay"]
  end

config :nerves, :firmware, firmware_config

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1773442371"
import_config "../../timberee/config/config.exs"

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end
