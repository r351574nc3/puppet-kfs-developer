# = Class: kfs-developer
#
# Install KFS workspace for developers along with any dependencies.
#
# == Parameters:
#
#
# == Actions:
#
# == Requires:
#   - Module['Archive']
#
class kfs-developer {
	$home      = "/home/kuali"
	$workspace = "${home}/workspace"
    $username  = "kuldemo"
    $schema    = $username
    $password  = "kuldemo"

    Exec {
         path => "/home/vagrant/.rvm/gems/ruby-1.9.3-p194/bin:/home/vagrant/.rvm/gems/ruby-1.9.3-p194@global/bin:/home/vagrant/.rvm/rubies/ruby-1.9.3-p194/bin:/home/vagrant/.rvm/bin:/usr/lib64/ccache:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/vagrant/.rvm/bin:/sbin:/usr/sbin:/home/vagrant/.local/bin:/home/vagrant/bin"
     }

    group { "eclipse":
        ensure => present,
    }

	user { "kuali":
		groups     => 'kuali',
		password   => ['kuali', 'wheel', 'admin', 'eclipse'],
		comment    => 'kuali',
		ensure     => present,
		provider   => 'useradd',
		managehome => true
	}

	package { "subversion" : 
		ensure => installed
	}

	package { "tomcat" :
		ensure  => installed,
        require => Package["glibc.i686"]
	}

	package { "mysql-server" :
		ensure => installed
	}

	service { "mysqld" :
		ensure     => running,
		enable     => true,
		require    => Package["mysql-server"],
        subscribe  => File['my.cnf']
	}

    file { 'my.cnf' :
        path    => '/etc/my.cnf',
        ensure  => file,
        require => Package['mysql-server'],
        source  => "puppet://kfs-developer/my.cnf",
        notify  => Archive::Download["apache-maven-3.0.4-bin.tar.gz"]
    }
    
    archive::download { "apache-maven-3.0.4-bin.tar.gz" :
	    ensure        => present,
	    url           => "http://apache.osuosl.org/maven/maven-3/3.0.4/binaries/apache-maven-3.0.4-bin.tar.gz",
	    digest_string => "e513740978238cb9e4d482103751f6b7",
        notify        => Archive::Extract["apache-maven-3.0.4-bin"]
    }

    archive::extract { "apache-maven-3.0.4-bin" :
        ensure     => present,
        target     => "/usr/java",
        require    => Archive::Download["apache-maven-3.0.4-bin.tar.gz"]
    }

    file { "/usr/java/apache-maven" :
    	ensure => link,
    	target => "/usr/java/apache-maven-3.0.4"
    }

    file { "/usr/bin/mvn" :
    	ensure => link,
    	target => "/usr/java/apache-maven/bin/mvn"
    }

    archive::download { "apache-ant-1.8.4-bin.tar.gz" :
	    ensure        => present,
	    url           => "http://apache.osuosl.org//ant/binaries/apache-ant-1.8.4-bin.tar.gz",
	    digest_string => "f5975145d90efbbafdcabece600f716b",
	    require       => Archive::Extract["apache-maven-3.0.4-bin"]
    }

    archive::extract { "apache-ant-1.8.4-bin" :
        ensure     => present,
        target     => "/usr/java",
        require    => Archive::Download["apache-ant-1.8.4-bin.tar.gz"]
    }

    file { "/usr/java/apache-ant" :
    	ensure => link,
    	target => "/usr/java/apache-ant-1.8.4"
    }

    file { "/usr/bin/ant" :
    	ensure => link,
    	target => "/usr/java/apache-ant/bin/ant"
    }

    file { "${workspace}" : 
        ensure  => directory,
        owner   => "kuali",
        group   => "kuali",
        notify  => Exec['svn-checkout-kfs']
    }		

    exec { "svn-checkout-kfs" :
	    command  => "svn co https://svn.kuali.org/repos/kfs/trunk ${workspace}/kfs-5.0",
	    creates  => "${workspace}/kfs-5.0",
	    timeout  => "720",
	    require  => File["${workspace}"]
    }

    file { 'kfs' :
        ensure  => link, 
        path    => "${workspace}/kfs",
        target  => "${workspace}/kfs-5.0",
        require => Exec['svn-checkout-kfs']
    }

    file { 'MessageBuilder.java':
        path    => '/home/kuali/workspace/kfs/work/src/org/kuali/kfs/sys/MessageBuilder.java',
        owner   => 'kuali',
        group   => 'kuali',
        ensure  => file,
        require => File['kfs'],
        source  => "puppet://kfs-developer/MessageBuilder.java",
    }

    exec { "svn-checkout-impex" :
	    command  => "svn co https://svn.kuali.org/repos/foundation/db-utils/branches/clover-integration ${workspace}/kul-cfg-dbs",
	    creates  => "${workspace}/kul-cfg-dbs",
	    timeout  => "720",
	    require  => File["${workspace}"]
    }

    exec { "svn-checkout-kfs-cfg-dbs" :
	    command  => "svn co http://svn.kuali.org/repos/kfs/legacy/cfg-dbs/branches/release-5-0/ ${workspace}/kfs-cfg-dbs",
	    creates  => "${workspace}/kfs-cfg-dbs",
	    timeout  => "720",
	    require  => File["${workspace}"]
    }

    file { "datasets" :
        ensure  => directory,
        path    => "${workspace}/datasets",
        require => Exec["svn-checkout-kfs-cfg-dbs"],
        notify  => File["datasets-rice"]
    }

    file { "datasets-rice" :
        ensure  => link,
        path    => "${workspace}/datasets/rice",
        target  => "${workspace}/kfs-cfg-dbs/rice-demo",
        require => Exec["svn-checkout-kfs-cfg-dbs"],
        notify  => File["datasets-kfs"]
    }

    file { "datasets-kfs" :
        ensure  => link,
        path    => "${workspace}/datasets/kfs-demo",
        target  => "${workspace}/kfs-cfg-dbs/demo",
        require => Exec["svn-checkout-kfs-cfg-dbs"],
        notify  => Exec["chown-workspace"]
    }

    exec { "chown-workspace" :
        command => "chown -R kuali:kuali ${workspace}",
        unless  => "[ `stat -c %U ${workspace}` == kuali ]",
        require => Exec['svn-checkout-kfs-cfg-dbs'],
    }

    file { "demo-impex-build-properties" :
        ensure  => present,
        owner   => kuali,
        group   => kuali,
        mode    => 0755,
        content => template('impex-build-properties.erb'),
        path    => "${workspace}/impex-build.properties",
        notify  => Exec["demo-impex-load"]
    }

    file { "demo-kfs-build-properties" :
        ensure  => present,
        owner   => kuali,
        group   => kuali,
        mode    => 0755,
        path    => "${workspace}/kfs-build.properties",
        content => template('puppet://modules/kfs-developer/kfs-build-properties.erb'),
        notify  => Exec["demo-impex-load"]
    }

    exec { "demo-impex-load" :
	    command  => "ant drop-schema create-schema import",
	    timeout  => "3600",
        cwd      => "${workspace}/kul-cfg-dbs/impex",
	    require  => File["demo-impex-build-properties"]
    }
}
