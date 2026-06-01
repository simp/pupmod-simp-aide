# frozen_string_literal: true

# Reports the version of the installed AIDE binary (e.g. '0.16' or '0.17.4').
#
# This is used to select the correct verbosity directive in aide.conf: the
# `verbose` option was removed in AIDE 0.17 and replaced by the `log_level`
# and `report_level` options. The two directive styles are mutually exclusive
# and an unknown directive is a fatal config error, so the module must know
# the installed version before rendering the configuration.
#
# The fact resolves to `nil` when AIDE is not installed (the binary cannot be
# found). On the first Puppet run of a fresh install the package has not yet
# been applied, so the fact is unavailable and the module omits the verbosity
# directive entirely until the next run.
Facter.add('aide_version') do
  confine { Facter::Core::Execution.which('aide') }

  setcode do
    output = Facter::Core::Execution.execute('aide --version 2>&1', timeout: 10)
    match = output&.match(%r{aide\s+v?(\d+\.\d+(?:\.\d+)?)}i)
    match[1] if match
  end
end
