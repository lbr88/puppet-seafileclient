define seafileclient::repo (
  String $id = $name,
  String $server,
  String $path,
  String $serverusername,
  String $serverpassword,
  $unixuser = root,
  $unixgroup = root,
  $managepermissions = false,
  $homedir = '/root',
  $datadir = "$homedir/.seafile-client",
  $cfgdir = "$homedir/.ccnet",
  Enum['sync','download'] $method = 'sync',
) {
  include ::seafileclient
  $seafcli = "/usr/bin/seaf-cli"
  $seafparam = "-c ${cfgdir}"

  file { "$datadir":
    ensure => directory,
#    notify => Exec["seafile-init-$unixuser"],
    owner => $unixuser,
    group => $unixgroup,
    require => Package['seafile-cli'],
  } ~>
  exec { "seafile-init-$unixuser":
    command => "$seafcli init -c $cfgdir -d $datadir",
    path => ['/usr/bin','/bin'],
    cwd => "$homedir",
    user => $unixuser,
    creates => "$cfgdir",
#    notify => Service["seafile-daemon-$unixuser"],
  } ->
  service { "seafile-daemon-$unixuser":
    pattern => "seaf-daemon --daemon -c $cfgdir -d $datadir/seafile-data -w $datadir/seafile",
    ensure => running,
    hasstatus => true,
    hasrestart => false,
    binary => "/usr/bin/seaf-daemon",
    provider => 'base',
    start => "sudo -u $unixuser $seafcli start $seafparam",
    stop => "sudo -u $unixuser $seafcli stop $seafparam",
    status => "sudo -u $unixuser $seafcli status $seafparam",
    require => Exec["seafile-init-$unixuser"],
  }


  if ($method == 'sync') {
    file { "$path":
      ensure => directory,
      owner => $unixuser,
      group => $unixgroup,
    }
  }
  exec { "addrepo_$id":
    command => "sleep 5; $seafcli $method $seafparam -s $server -u $serverusername -p $serverpassword -d $path -l $id",
    path => ['/usr/bin','/bin'],
    cwd => "$homedir",
    user => $unixuser,
    environment=> ["HOME=${homedir}"],
    provider => shell,
    #refreshonly => true,
    unless => "sleep 2; $seafcli list $seafparam | /bin/grep $id",
    require => [
      Service["seafile-daemon-$unixuser"],
      Package['seafile-cli'],
    ]
  }
  if ( $managepermissions == true ) and ($unixuser != undef) and ($unixgroup != undef) {
    exec {'seafile_chown':
      command => "/usr/bin/find $path \( ! -user $unixuser -o ! -group $unixgroup \) -exec /bin/chown $unixuser:$unixgroup {} \;",
      require => Exec["addrepo_$id"],
    }
  }
}
