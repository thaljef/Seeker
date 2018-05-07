define synopsys::seeker::sensor($server = $title, $project_key, $sensor_key, $api_token) {

	package { 'curl':
		ensure => 'installed'
	}

	package { 'unzip':
		ensure => 'installed'
	}

        $api_url     = "$server/rest/api/latest/sensors"
        $auth_header = "Authorization: Bearer $api_token"
        $post_data   = "key=$sensor_key&osFamily=LINUX&projectKey=$project_key"
  
        notice("curl -X POST --header '$auth_header' -d '$post_data' '$api_url'")
	exec { 'create_sensor_key':
		command  => "curl -X POST --header '$auth_header' -d '$post_data' '$api_url'",
                provider => 'shell',
	}

        # TODO: find a better way to make a temp directory that
        # will always be empty and deleted if work is successful.

	$seeker_temp_dir = '/tmp/seeker'    

	file { 'create_seeker_temp_dir':
		path    => $seeker_temp_dir,
		ensure  => directory,
                purge   => true,
                recurse => true,
                force   => true,
	}

        $installer_params = "downloadWith=curl&projectKey=$project_key&sensorKey=$sensor_key"
	$installer_url    = "$server/rest/api/latest/installers/scripts/LINUX?$installer_params"
		
	notice("curl -X GET -fsSL '$installer_url' | /bin/sh")
        exec { 'seeker_installer':
		command  => "curl -X GET -fsSL '$installer_url' | /bin/sh",
                provider => 'shell',
                umask    => '022',
                cwd      => $seeker_temp_dir,
                creates  => '/usr/local/seeker',
		require  => [Exec[create_sensor_key], Package[unzip], Package[curl], File[create_seeker_temp_dir]]
	}

    	service { 'SeekerSensor':
      		enable  => true,
      		ensure  => 'running',
      		require => [Exec['seeker_installer']],
	}
}

