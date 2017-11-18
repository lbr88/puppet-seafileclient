class seafileclient {
  apt::key { 'seafile':
    id      => '8756C4F765C9AC3CB6B85D62379CE192D401AB61',
    server  => 'hkp://keyserver.ubuntu.com:80',
  }
  if ($facts['os']['name'] == 'Debian') {
    apt::source { 'seafile':
      comment => 'seadrive/seafile cli repo',
      location => "http://deb.seadrive.org",
      release => $facts['os']['distro']['codename'],
      repos => "main",
    }
  }
  elsif ($facts['os']['name'] == 'Ubuntu') {
    package { 'software-properties-common':
      ensure => 'present',
    }
    apt::ppa { 'ppa:seafile/seafile-client':
      ensure => 'present',
    }
    apt::source { 'seafile':
      ensure => absent,
    }
  } else {
    fail("os not supported")
  }
  package { "seafile-cli":
    ensure => present,
  }
}
