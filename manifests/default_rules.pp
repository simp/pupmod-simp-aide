# A helper class to keep the main AIDE class relatively readable.
#
# @param default_rules
#   A set of default rules to include. If this is set, the internal
#   defaults will be overridden.
#
# @param ruledir
#   The directory in which the default rules file will be written.
#
# @author https://github.com/simp/pupmod-simp-aide/graphs/contributors
#
class aide::default_rules (
  Variant[Array[String[1]],String] $default_rules = $aide::default_rules,
  Stdlib::Absolutepath             $ruledir       = $aide::ruledir
) {

  assert_private()

  if $default_rules =~ String {
    $_rules = $default_rules
  }
  else {
    $_rules = join($default_rules, "\n")
  }

  aide::rule { 'default':
    ruledir => $ruledir,
    rules   => $_rules
  }
}
