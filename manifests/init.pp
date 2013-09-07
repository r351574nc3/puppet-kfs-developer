# = Class: kfsdeveloper
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
class kfsdeveloper {
    $home      = "/home/kuali"
    $workspace = "${home}/workspace"
    $settings  = "${home}/kuali/main/dev"
    $username  = "kuldemo"
    $schema    = $username
    $password  = "kuldemo"

    Exec {
         path => "/usr/java/apache-maven/bin:/usr/java/apache-ant/bin:/home/vagrant/.rvm/gems/ruby-1.9.3-p194/bin:/home/vagrant/.rvm/gems/ruby-1.9.3-p194@global/bin:/home/vagrant/.rvm/rubies/ruby-1.9.3-p194/bin:/home/vagrant/.rvm/bin:/usr/lib64/ccache:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/vagrant/.rvm/bin:/sbin:/usr/sbin:/home/vagrant/.local/bin:/home/vagrant/bin"
     }

    group { "eclipse":
        ensure => present,
    }

    user { "kuali":
        password   => 'kuali',
        groups     => ['wheel', 'eclipse'],
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

    package { "mariadb-server" :
        ensure => installed
    }

    service { "mysqld" :
        ensure     => running,
        enable     => true,
        require    => Package["mariadb-server"],
        subscribe  => File['my.cnf']
    }

    file { 'my.cnf' :
        path    => '/etc/my.cnf',
        ensure  => file,
        require => Package['mariadb-server'],
        source  => "puppet:///modules/kfsdeveloper/my.cnf",
        notify  => Archive::Download["apache-maven-3.1.0-bin.tar.gz"]
    }
    
    archive::download { "apache-maven-3.1.0-bin.tar.gz" :
        ensure        => present,
        url           => "http://apache.osuosl.org/maven/maven-3/3.1.0/binaries/apache-maven-3.1.0-bin.tar.gz",
        digest_string => "e251cf1a584b4a5f13ae118abaacd08a",
        notify        => Archive::Extract["apache-maven-3.1.0-bin"]
    }

    archive::extract { "apache-maven-3.1.0-bin" :
        ensure     => present,
        target     => "/usr/java",
        require    => Archive::Download["apache-maven-3.1.0-bin.tar.gz"],
        notify     => Archive::Download["apache-ant-1.9.2-bin.tar.gz"]
    }

    file { "/usr/java/apache-maven" :
        ensure => link,
        target => "/usr/java/apache-maven-3.1.0"
    }

    file { "/usr/bin/mvn" :
        ensure => link,
        target => "/usr/java/apache-maven-3.1.0/bin/mvn"
    }

    archive::download { "apache-ant-1.9.2-bin.tar.gz" :
        ensure        => present,
        url           => "http://apache.osuosl.org//ant/binaries/apache-ant-1.9.2-bin.tar.gz",
        digest_string => "9a2826a1819aa128629778217af36c55",
        require       => Archive::Extract["apache-maven-3.1.0-bin"],
        notify        => Archive::Extract["apache-ant-1.9.2-bin"]
    }

    archive::extract { "apache-ant-1.9.2-bin" :
        ensure     => present,
        target     => "/usr/java",
        require    => Archive::Download["apache-ant-1.9.2-bin.tar.gz"]
    }

    file { "/usr/java/apache-ant" :
        ensure => link,
        target => "/usr/java/apache-ant-1.9.2",
        require => Archive::Extract["apache-ant-1.9.2-bin"]
    }

    file { "/usr/bin/ant" :
        ensure  => link,
        target  => "/usr/java/apache-ant/bin/ant",
        require => File["/usr/java/apache-ant"]
    }

    file { [ "${home}/kuali", "${home}/kuali/main",
             "${settings}", "${workspace}" ] :
        ensure  => directory,
        owner   => kuali,
        group   => kuali,
        notify  => Exec['svn-checkout-kfs']
    }       

    exec { "svn-checkout-kfs" :
        command  => "svn co https://svn.kuali.org/repos/kfs/tags/releases/release-4-1-1/ ${workspace}/kfs-4.1.1",
        user     => 'kuali',
        creates  => "${workspace}/kfs-4.1.1",
        timeout  => "720",
        require  => File["${workspace}"],
        notify   => [ File['SpringContext.java'],
                      File['PurchasingDocument.java'],
                      File['BatchSortUtil.java'],
                      File['BatchSortServiceImpl.java'] ]
    }

    file { 'kfs' :
        ensure  => link, 
        path    => "${workspace}/kfs",
        target  => "${workspace}/kfs-4.1.1",
        require => Exec['svn-checkout-kfs']
    }

    file { "${workspace}/kfs-4.1.1":
        ensure => "directory",
        owner  => "kuali",
        group  => "kuali",
        require => Exec['svn-checkout-kfs']
    }

    file { 'MessageBuilder.java':
        path    => '/home/kuali/workspace/kfs/work/src/org/kuali/kfs/sys/MessageBuilder.java',
        owner   => 'kuali',
        group   => 'kuali',
        ensure  => present,
        require => File['kfs'],
        source  => "puppet:///modules/kfsdeveloper/MessageBuilder.java",
    }

    file { 'SpringContext.java':
        path    => '/home/kuali/workspace/kfs/work/src/org/kuali/kfs/sys/context/SpringContext.java',
        owner   => 'kuali',
        group   => 'kuali',
        ensure  => present,
        require => Exec['svn-checkout-kfs'],
        source  => "puppet:///modules/kfsdeveloper/SpringContext.java",
    }

    file { 'PurchasingDocument.java':
        path    => '/home/kuali/workspace/kfs/work/src/org/kuali/kfs/module/purap/document/PurchasingDocument.java',
        owner   => 'kuali',
        group   => 'kuali',
        ensure  => present,
        require => Exec['svn-checkout-kfs'],
        source  => "puppet:///modules/kfsdeveloper/PurchasingDocument.java",
    }

    file { 'BatchSortServiceImpl.java':
        path    => '/home/kuali/workspace/kfs/work/src/org/kuali/kfs/gl/batch/service/impl/BatchSortServiceImpl.java',
        owner   => 'kuali',
        group   => 'kuali',
        ensure  => present,
        require => Exec['svn-checkout-kfs'],
        source  => "puppet:///modules/kfsdeveloper/BatchSortServiceImpl.java",
    }

    file { 'BatchSortUtil.java':
        path    => '/home/kuali/workspace/kfs/work/src/org/kuali/kfs/gl/batch/BatchSortUtil.java',
        owner   => 'kuali',
        group   => 'kuali',
        ensure  => present,
        require => Exec['svn-checkout-kfs'],
        source  => "puppet:///modules/kfsdeveloper/BatchSortUtil.java",
    }

    exec { "svn-checkout-impex" :
        command  => "svn co https://svn.kuali.org/repos/foundation/db-utils/branches/clover-integration ${workspace}/kul-cfg-dbs",
        creates  => "${workspace}/kul-cfg-dbs",
        timeout  => "720",
        require  => File["${workspace}"],
        user     => 'kuali'
    }

    file { "${workspace}/kul-cfg-dbs":
        ensure => "directory",
        owner  => "kuali",
        group  => "kuali",
        require => Exec['svn-checkout-impex']
    }

    exec { "svn-checkout-kfs-cfg-dbs" :
        command  => "svn co http://svn.kuali.org/repos/kfs/legacy/cfg-dbs/branches/release-5-0/ ${workspace}/kfs-cfg-dbs",
        creates  => "${workspace}/kfs-cfg-dbs",
        timeout  => "720",
        require  => File["${workspace}"],
        user     => 'kuali'
    }

    file { "${workspace}/kfs-cfg-dbs":
        ensure => "directory",
        owner  => "kuali",
        group  => "kuali",
        require => Exec['svn-checkout-kfs-cfg-dbs']
    }


    file { "datasets" :
        ensure  => directory,
        owner   => kuali,
        group   => kuali,       
        path    => "${workspace}/datasets",
        require => Exec["svn-checkout-kfs-cfg-dbs"],
        notify  => File["datasets-rice"]
    }

    file { "datasets-rice" :
        ensure  => link,
        owner   => kuali,
        group   => kuali,
        path    => "${workspace}/datasets/rice",
        target  => "${workspace}/kfs-cfg-dbs/rice-demo",
        require => Exec["svn-checkout-kfs-cfg-dbs"],
        notify  => File["datasets-kfs"]
    }

    file { "datasets-kfs" :
        ensure  => link,
        owner   => kuali,
        group   => kuali,
        path    => "${workspace}/datasets/kfs-demo",
        target  => "${workspace}/kfs-cfg-dbs/demo",
        require => Exec["svn-checkout-kfs-cfg-dbs"],
        notify  => Exec["chown-workspace"]
    }

    exec { "chown-workspace" :
        command => "chown -R kuali:kuali ${workspace}",
        unless  => "[ `stat -c %U ${workspace}` == kuali ]",
        require => Exec['svn-checkout-kfs-cfg-dbs']
    }

    file { "demo-impex-build-properties" :
        ensure  => present,
        owner   => kuali,
        group   => kuali,
        mode    => 0755,
        content => template('impex-build-properties.erb'),
        path    => "${workspace}/impex-build.properties"
    }

    file { "kfs-build.properties" :
        ensure  => present,
        owner   => kuali,
        group   => kuali,
        mode    => 0755,
        source  => 'puppet:///modules/kfsdeveloper/kfs-build.properties',
        path    => "${home}/kfs-build.properties"
    }

    file { "demo-kfs-build-properties" :
        ensure  => present,
        owner   => kuali,
        group   => kuali,
        mode    => 0755,
        path    => "${workspace}/kfs-build.properties",
        content => template('kfs-build-properties.erb'),
        require => File['kfs-build.properties']
    }

    exec { "dist-local" :
        command  => "ant dist-local",
        cwd      => "${workspace}/kfs",
        require  => File["kfs"]
        user     => 'kuali'
    }
    exec { "demo-impex-load" :
        command  => "ant -Dimpex.properties.file=${workspace}/impex-build.properties drop-schema create-schema import",
        timeout  => "3600",
        cwd      => "${workspace}/kul-cfg-dbs/impex",
        require  => [ File["demo-impex-build-properties"], 
                      File["demo-kfs-build-properties"],
                      Archive::Extract["apache-ant-1.9.2-bin"], 
                      File['datasets-kfs'],
                      File['datasets-rice'],
                      File["/usr/bin/ant"], 
                      File['SpringContext.java'],
                      File['PurchasingDocument.java'],
                      File['BatchSortUtil.java'],
                      File['BatchSortServiceImpl.java'],
                      Exec['dist-local'] ]
        user     => 'kuali'
    }
}
