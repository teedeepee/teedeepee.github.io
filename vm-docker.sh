#!/bin/bash
#Install or upgrade docker containers
#Copy this file as vm-docker.sh onto the virtual machine, then chmod +x vm-docker.sh to make it executable, then ./vm-docker.sh
#Or type into the command line: bash <(curl -s https://raw.githubusercontent.com/teedeepee/teedeepee.github.io/master/vm-docker.sh)

#FUNCTIONS DEFINITION

fn-update-vm () {
	clear
	fn-printf "Updating repositories, upgrading packages, and cleaning up"
	sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
	fn-printf "Finished updating"
}

fn-printf () {
	printf "\n\e[7m $1 \e[0m \n\n"
}

#CASES

clear
fn-printf "What do you want to do?"
PS3="> "
options=("initialize-vm" "update-vm" "install-ethereum" "install-nzbget" "install-plex" "install-radarr" "install-sonarr" "install-tor" "install-transmission" "quit")
select opt in "${options[@]}";
do
	case $opt in

		initialize-vm)
			clear
			fn-printf "Setting the timezone"
				sudo timedatectl set-timezone Asia/Singapore
			fn-printf "Updating repositories"
				sudo apt update
			fn-printf "Installing the NFS helper"
				sudo apt -y install nfs-common
			fn-printf "Installing packages to allow apt to use a repository over HTTPS"
				sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
			fn-printf "Adding docker's official GPG key"
				curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
			fn-printf "Verifying that the key's uid belongs to docker"
				sudo apt-key fingerprint 0EBFCD88
			fn-printf "Setting up the docker repository"
				sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu cosmic stable"
			fn-printf "Updating repositories"
				sudo apt update
			fn-printf "Installing the latest version of docker CE"
				sudo apt -y install docker-ce docker-ce-cli containerd.io
			fn-printf "Cleaning up"
				sudo apt -y autoremove && sudo apt -y autoclean
			fn-printf "Checking that docker is correctly installed"
				docker run hello-world
			fn-printf "Installing Watchtower to automatically update docker containers"
				docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock v2tec/watchtower
			fn-printf "Confirming that Watchtower is running"
				docker ps
			fn-printf "Finished initializing the VM"
			break
			;;

		update-vm)
			fn-update-vm
			break
			;;
						
		install-ethereum)
			name=ethereum
			fn-update-vm
			fn-printf "Pulling the latest $name docker image"
				docker pull $name/client-go:latest
			fn-printf "Removing any existing $name docker container"
				docker stop $name || true && docker rm $name || true
			fn-printf "Removing any existing $name docker volume"
				docker volume rm $name
			fn-printf "Re-creating the $name docker volume" #Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/crypto/$name $name
			fn-printf "Re-creating the $name docker container"
				docker create --name=$name --restart unless-stopped -p 8545:8545 -p 30303:30303 -v $name:/root $name/client-go
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name"
			break
			;;
						
		install-nzbget)
			name=nzbget
			fn-update-vm
			fn-printf "Pulling the latest $name docker image"
				docker pull linuxserver/$name:latest
			fn-printf "Removing any existing $name docker container"
				docker stop $name || true && docker rm $name || true
			fn-printf "Removing any existing $name docker volume"
				docker volume rm $name-config && docker volume rm $name-downloads
			fn-printf "Re-creating the $name docker volume" #Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/config $name-config
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/downloads $name-downloads
			fn-printf "Re-creating the $name docker container"
				docker create --name=$name --restart unless-stopped -e VERSION=docker -p 6789:6789 -v $name-config:/config -v $name-downloads:/downloads linuxserver/$name
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name"
			break
			;;
						
		install-plex)
			name=plex
			fn-update-vm
			fn-printf "Pulling the latest $name docker image"
				docker pull linuxserver/$name:latest
			fn-printf "Removing any existing $name docker container"
				docker stop $name || true && docker rm $name || true
			fn-printf "Removing any existing $name docker volume"
				docker volume rm $name-config && docker volume rm $name-transcode && docker volume rm $name-audio && docker volume rm $name-shows && docker volume rm $name-movies
			fn-printf "Re-creating the $name docker volume" #Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/config $name-config
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/transcode $name-transcode
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/audio $name-audio
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/movies $name-movies
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/shows $name-shows
			fn-printf "Re-creating the $name docker container"
				docker create --name=$name --net=host --restart unless-stopped -e VERSION=docker -v $name-config:/config -v $name-transcode:/transcode -v $name-audio:/audio -v $name-movies:/movies -v $name-shows:/shows linuxserver/$name
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name" #If the Plex server cannot be found at http://vm-docker:32400/web/index.html, read https://support.plex.tv/articles/200288586-installation/#toc-2
			break
			;;
						
		install-radarr)
			name=radarr
			fn-update-vm
			fn-printf "Pulling the latest $name docker image"
				docker pull linuxserver/$name:latest
			fn-printf "Removing any existing $name docker container"
				docker stop $name || true && docker rm $name || true
			fn-printf "Removing any existing $name docker volume"
				docker volume rm $name-config && docker volume rm $name-downloads && docker volume rm $name-movies
			fn-printf "Re-creating the $name docker volume" #Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/config $name-config
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/downloads $name-downloads
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/movies $name-movies
			fn-printf "Re-creating the $name docker container"
				docker create --name=$name --restart unless-stopped -e VERSION=docker -p 7878:7878 -v $name-config:/config -v $name-downloads:/downloads -v $name-movies:/movies linuxserver/$name
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name"
			break
			;;
						
		install-sonarr)
			name=sonarr
			fn-update-vm
			fn-printf "Pulling the latest $name docker image"
				docker pull linuxserver/$name:latest
			fn-printf "Removing any existing $name docker container"
				docker stop $name || true && docker rm $name || true
			fn-printf "Removing any existing $name docker volume"
				docker volume rm $name-config && docker volume rm $name-downloads && docker volume rm $name-shows
			fn-printf "Re-creating the $name docker volume" #Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/config $name-config
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/downloads $name-downloads
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/shows $name-shows
			fn-printf "Re-creating the $name docker container"
				docker create --name=$name --restart unless-stopped -e VERSION=docker -p 8989:8989 -v $name-config:/config -v $name-downloads:/downloads -v $name-shows:/tv linuxserver/$name
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name"
			break
			;;

		install-tor)
			name=tor-server
			fn-update-vm
			fn-printf "Pulling the latest $name docker image"
				docker pull chriswayg/$name:latest
			fn-printf "Removing any existing $name docker container"
				docker stop $name || true && docker rm $name || true
			fn-printf "Removing any existing $name docker volume"
				docker volume rm $name-config
			fn-printf "Re-creating the $name docker volume" #Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/crypto/$name $name
			fn-printf "Re-creating the $name docker container"
				docker create --name=$name --restart unless-stopped -e CONTACT_EMAIL=R2XRAp6Mc7Fg33q4LhT6c74u7@anche.no -e TOR_NICKNAME=Tor4 -v $name:/var/lib/tor chriswayg/$name
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name"
			break
			;;
	
		install-transmission)
			name=transmission
			fn-update-vm
			fn-printf "Pulling the latest $name docker image"
				docker pull linuxserver/$name:latest
			fn-printf "Removing any existing $name docker container"
				docker stop $name || true && docker rm $name || true
			fn-printf "Removing any existing $name docker volume"
				docker volume rm $name-config && docker volume rm $name-downloads && docker volume rm $name-watch
			fn-printf "Re-creating the $name docker volume" #Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/config $name-config
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/downloads $name-downloads
				docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/$name/watch $name-watch
			fn-printf "Re-creating the $name docker container"
				docker create --name=$name --restart unless-stopped -e VERSION=docker -e TRANSMISSION_WEB_HOME=/combustion-release/ -p 9091:9091 -p 51413:51413 -p 51413:51413/udp -v $name-config:/config -v $name-downloads:/downloads -v $name-movies:/movies linuxserver/$name
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name"
			break
			;;

		quit)
			fn-printf "QUITTING"
			break
			;;
			
		*)
			fn-printf "INVALID OPTION. PLEASE CHOOSE ANOTHER ONE"
			;;
			
	esac
done
