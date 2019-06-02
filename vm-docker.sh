#!/bin/bash
#Install or upgrade docker containers
#Copy this file as vm-docker.sh onto the virtual machine, then chmod +x vm-docker.sh to make it executable, then ./vm-docker.sh
#Or type into the command line: bash <(curl -s https://raw.githubusercontent.com/teedeepee/teedeepee.github.io/master/vm-docker.sh)

#FUNCTIONS DEFINITION

fn-update-vm () {
	clear
	fn-printf "Updating repositories, upgrading packages, and cleaning up"
	sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
}

fn-printf () {
	printf "\n\e[7m $1 \e[0m \n\n"
}

#CASES

clear
fn-printf "What do you want to do?"
PS3="> "
options=("initialize-vm" "update-vm" "install-ethereum" "install-nzbget" "install-plex" "install-radarr" "install-sonarr" "install-tor" "quit")
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
			fn-printf "FINISHED INITIALIZING THE VM"
			break
			;;

		update-vm)
			fn-update-vm
			fn-printf "FINISHED UPDATING THE VM"
			break
			;;

		install-ethereum)
			fn-update-vm
			fn-printf "Pulling the latest Ethereum docker image"
			docker pull ethereum/client-go:latest
			fn-printf "Removing any existing Ethereum docker container"
			docker stop ethereum || true && docker rm ethereum || true
			fn-printf "Removing any existing Ethereum docker volume"
			docker volume rm ethereum
			fn-printf "Re-creating the Ethereum docker volume"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/crypto/ethereum/ ethereum
			fn-printf "Re-creating the Ethereum docker container"
			docker create --name=ethereum --restart unless-stopped -p 8545:8545 -p 30303:30303 -v ethereum:/root ethereum/client-go
			fn-printf "Starting the Ethereum docker container"
			docker start ethereum
			sleep 5s
			fn-printf "Displaying the log"
			docker logs ethereum
			fn-printf "FINISHED INSTALLING ETHEREUM"
			break
			;;
			
		install-nzbget)
			fn-update-vm
			fn-printf "Pulling the latest Nzbget docker image"
			docker pull linuxserver/nzbget:latest
			fn-printf "Removing any existing Nzbget docker container"
			docker stop nzbget || true && docker rm nzbget || true
			fn-printf "Removing any existing Nzbget docker volume"
			docker volume rm nzbget-config && docker volume rm nzbget-downloads
			fn-printf "Re-creating the Nzbget docker volume"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/nzbget/config nzbget-config
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/nzbget/downloads nzbget-downloads
			fn-printf "Re-creating the Nzbget docker container"
			docker create --name=nzbget --restart unless-stopped -p 6789:6789 -v nzbget-config:/config -v nzbget-downloads:/downloads
			fn-printf "Starting the Nzbget docker container"
			docker start nzbget
			sleep 5s
			fn-printf "Displaying the log"
			docker logs nzbget
			fn-printf "FINISHED INSTALLING NZBGET"
			break
			;;

		install-plex)
			#If the Plex server cannot be found, read https://support.plex.tv/articles/200288586-installation/#toc-2
			fn-update-vm
			fn-printf "Pulling the latest Plex docker image"
			docker pull linuxserver/plex:latest
			fn-printf "Removing any existing Plex docker container"
			docker stop plex || true && docker rm plex || true
			fn-printf "Removing any existing Plex docker volume"
			docker volume rm plex-config && docker volume rm plex-transcode && docker volume rm plex-audio && docker volume rm plex-shows && docker volume rm plex-movies
			fn-printf "Re-creating the Plex docker volumes"
			#Make sure the remote folders exist on the NAS and are not empty (even if it means creating an empty Temp folder inside them)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/plex/config plex-config
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/plex/transcode plex-transcode
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/audio plex-audio
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/shows plex-shows
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/movies plex-movies
			fn-printf "Re-creating the Plex docker container"
			docker create --name=plex --net=host --restart unless-stopped -v plex-config:/config -v plex-transcode:/transcode -v plex-audio:/audio -v plex-shows:/data/shows -v plex-movies:/data/movies linuxserver/plex
			fn-printf "Starting the Plex docker container"
			docker start plex
			sleep 5s
			fn-printf "Displaying the log"
			docker logs plex
			fn-printf "Go to http://vm-docker:32400/web/index.html to access Plex"
			fn-printf "FINISHED INSTALLING PLEX"
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
				docker create --name=$name --restart unless-stopped -p 7878:7878 -v $name-config:/config -v $name-downloads:/downloads -v $name-movies:/movies linuxserver/$name
			fn-printf "Starting the $name docker container"
				docker start $name
				sleep 5s
			fn-printf "Displaying the log"
				docker logs $name
			fn-printf "Finished installing $name"
			break
			;;

		install-sonarr)
			fn-update-vm
			fn-printf "Pulling the latest Sonarr docker image"
			docker pull linuxserver/sonarr:latest
			fn-printf "Removing any existing Sonarr docker container"
			docker stop sonarr || true && docker rm sonarr || true
			fn-printf "Removing any existing Sonarr docker volume"
			docker volume rm sonarr-config && docker volume rm sonarr-downloads && docker volume rm sonarr-shows
			fn-printf "Re-creating the Sonarr docker volume"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/sonarr/config sonarr-config
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/sonarr/downloads sonarr-downloads
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/shows sonarr-shows
			fn-printf "Re-creating the Sonarr docker container"
			docker create --name=sonarr --restart unless-stopped -p 8989:8989 -v sonarr-config:/config -v sonarr-downloads:/downloads -v sonarr-shows:/tv linuxserver/sonarr
			fn-printf "Starting the Sonarr docker container"
			docker start sonarr
			sleep 5s
			fn-printf "Displaying the log"
			docker logs sonarr
			fn-printf "FINISHED INSTALLING SONARR"
			break
			;;
			
		install-tor)
			fn-update-vm
			fn-printf "Pulling the latest Tor docker image"
			docker pull chriswayg/tor-server:latest
			fn-printf "Removing any existing Tor docker container"
			docker stop tor || true && docker rm tor || true
			fn-printf "Removing any existing Tor docker volume"
			docker volume rm tor
			fn-printf "Re-creating the Tor docker volume"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/tor tor
			fn-printf "Re-creating the Tor docker container"
			docker create --name=tor --restart unless-stopped -e CONTACT_EMAIL=R2XRAp6Mc7Fg33q4LhT6c74u7@anche.no -e TOR_NICKNAME=Tor4 -v tor:/var/lib/tor chriswayg/tor-server
			fn-printf "Starting the Tor docker container"
			docker start tor
			sleep 5s
			fn-printf "Displaying the log"
			docker logs tor
			fn-printf "FINISHED INSTALLING TOR"
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
				docker create --name=$name --restart unless-stopped -e TRANSMISSION_WEB_HOME=/combustion-release/ -p 9091:9091 -p 51413:51413 -p 51413:51413/udp -v $name-config:/config -v $name-downloads:/downloads -v $name-movies:/movies linuxserver/$name
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
