# Include this module to provide an Array of Hashes of factname/value pairs
module FactGroups
  def FactGroups.factgroups

    permafacts = {
      # for auditd/templates/base.erb:
      :hardwaremodel     => 'x86_64',
      :root_audit_level  => 'none',
      :grub_version      => '0',
      # for auditd/manifests/init.pp:
      :uid_min           => 500,
    }

    factgroups = [
      {
        :operatingsystem => 'RedHat',
        :operatingsystemmajrelease => '7'
      },
      {
        :operatingsystem => 'RedHat',
        :operatingsystemmajrelease => '6'
      },
      {
        :operatingsystem => 'CentOS',
        :operatingsystemmajrelease => '7'
      },
      {
        :operatingsystem => 'CentOS',
        :operatingsystemmajrelease => '6'
      },
    ]

    factgroups.map!{ |factgroup|
      factgroup.merge!( permafacts )
    }
  end

end
