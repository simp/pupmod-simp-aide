# Ownership and permissions of a directory the module manages
type Aide::DirAttributes = Struct[{
  owner => String[1],
  group => String[1],
  mode  => Stdlib::Filemode,
}]
