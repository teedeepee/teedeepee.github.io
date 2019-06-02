#!/bin/bash
#Install or upgrade docker containers
#Copy this file as vm-docker.sh onto the virtual machine, then chmod +x vm-docker.sh to make it executable, then ./vm-docker.sh
#Or type into the command line: bash <(curl -s https://raw.githubusercontent.com/teedeepee/teedeepee.github.io/master/vm-docker.sh)

function fn-update-vm {
	printf "\n\e[7m Updating repositories, upgrading packages, and cleaning up \e[0m \n\n"
	sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
}

clear
printf "\n\e[7m 0. Choose which docker container to install: \e[0m \n\n"
PS3="> "
options=("initialize-vm" "update-vm" "install-ethereum" "install-nzbget" "install-plex" "install-sonarr" "install-tor" "quit")
select opt in "${options[@]}";
do
	case $opt in

		initialize-vm)
			clear
			printf "\n\e[7m INITIALIZING THE VM \e[0m \n\n"
			printf "\n\e[7m Setting the timezone \e[0m \n\n"
			sudo timedatectl set-timezone Asia/Singapore
			printf "\n\e[7m Updating repositories \e[0m \n\n"
			sudo apt update
			printf "\n\e[7m Installing the NFS helper \e[0m \n\n"
			sudo apt -y install nfs-common
			printf "\n\e[7m Installing packages to allow apt to use a repository over HTTPS \e[0m \n\n"
			sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
			printf "\n\e[7m Adding Docker's official GPG key \e[0m \n\n"
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
			printf "\n\e[7m Verifying that the key's uid belongs to Docker \e[0m \n\n"
			sudo apt-key fingerprint 0EBFCD88
			printf "\n\e[7m Setting up the Docker repository \e[0m \n\n"
			sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu cosmic stable"
			printf "\n\e[7m Updating repositories \e[0m \n\n"
			sudo apt update
			printf "\n\e[7m Installing the latest version of Docker CE \e[0m \n\n"
			sudo apt -y install docker-ce docker-ce-cli containerd.io
			printf "\n\e[7m Cleaning up \e[0m \n\n"
			sudo apt -y autoremove && sudo apt -y autoclean
			printf "\n\e[7m Checking that Docker is correctly installed \e[0m \n\n"
			docker run hello-world
			printf "\n\e[7m Installing Watchtower to automatically update Docker containers \e[0m \n\n"
			docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock v2tec/watchtower
			printf "\n\e[7m Confirming that Watchtower is running \e[0m \n\n"
			docker ps
			printf "\n\e[7m FINISHED INITIALIZING THE VM \e[0m \n\n"
			break
			;;

		update-vm)
			clear
			printf "\n\e[7m UPDATING THE VM \e[0m \n\n"
			fn-update-vm
			printf "\n\e[7m FINISHED UPDATING THE VM \e[0m \n\n"
			break
			;;

		install-ethereum)
			clear
			printf "\n\e[7m INSTALLING ETHEREUM \e[0m \n\n"
			printf "\n\e[7m Updating repositories, upgrading packages, and cleaning up \e[0m \n\n"
			sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
			printf "\n\e[7m Pulling the latest Ethereum Docker image \e[0m \n\n"
			docker pull ethereum/client-go:latest
			printf "\n\e[7m Removing any existing Ethereum Docker container \e[0m \n\n"
			docker stop ethereum || true && docker rm ethereum || true
			printf "\n\e[7m Removing any existing Ethereum Docker volume \e[0m \n\n"
			docker volume rm ethereum
			printf "\n\e[7m Re-creating the Ethereum Docker volume \e[0m \n\n"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/crypto/ethereum/ ethereum
			printf "\n\e[7m Re-creating the Ethereum Docker container \e[0m \n\n"
			docker create --name=ethereum --restart unless-stopped -p 8545:8545 -p 30303:30303 -v ethereum:/root ethereum/client-go
			printf "\n\e[7m Starting the Ethereum Docker container \e[0m \n\n"
			docker start ethereum
			sleep 5s
			printf "\n\e[7m Displaying the log \e[0m \n\n"
			docker logs ethereum
			printf "\n\e[7m FINISHED INSTALLING ETHEREUM \e[0m \n\n"
			break
			;;
			
		install-nzbget)
			clear
			printf "\n\e[7m INSTALLING NZBGET \e[0m \n\n"
			printf "\n\e[7m Updating repositories, upgrading packages, and cleaning up \e[0m \n\n"
			sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
			printf "\n\e[7m Pulling the latest Nzbget docker image \e[0m \n\n"
			docker pull linuxserver/nzbget:latest
			printf "\n\e[7m Removing any existing Nzbget docker container \e[0m \n\n"
			docker stop nzbget || true && docker rm nzbget || true
			printf "\n\e[7m Removing any existing Nzbget Docker volume \e[0m \n\n"
			docker volume rm nzbget-config && docker volume rm nzbget-downloads
			printf "\n\e[7m Re-creating the Nzbget Docker volume \e[0m \n\n"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/nzbget/config nzbget-config
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/nzbget/downloads nzbget-downloads
			printf "\n\e[7m Re-creating the Nzbget docker container \e[0m \n\n"
			docker create --name=nzbget --restart unless-stopped -p 6789:6789 -v nzbget-config:/config -v nzbget-downloads:/downloads
			printf "\n\e[7m Starting the Nzbget docker container \e[0m \n\n"
			docker start nzbget
			sleep 5s
			printf "\n\e[7m Displaying the log \e[0m \n\n"
			docker logs nzbget
			printf "\n\e[7m FINISHED INSTALLING NZBGET \e[0m \n\n"
			break
			;;

		install-plex)
			#If the Plex server cannot be found, read https://support.plex.tv/articles/200288586-installation/#toc-2
			clear
			printf "\n\e[7m INSTALLING PLEX \e[0m \n\n"
			printf "\n\e[7m Updating repositories, upgrading packages, and cleaning up \e[0m \n\n"
			sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
			printf "\n\e[7m Pulling the latest Plex Docker image \e[0m \n\n"
			docker pull linuxserver/plex:latest
			printf "\n\e[7m Removing any existing Plex Docker container \e[0m \n\n"
			docker stop plex || true && docker rm plex || true
			printf "\n\e[7m Removing any existing Plex Docker volume \e[0m \n\n"
			docker volume rm plex-config && docker volume rm plex-transcode && docker volume rm plex-audio && docker volume rm plex-shows && docker volume rm plex-movies
			printf "\n\e[7m Re-creating the Plex Docker volumes \e[0m \n\n"
			#Make sure the remote folders exist on the NAS and are not empty (even if it means creating an empty Temp folder inside them)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/plex/config plex-config
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/plex/transcode plex-transcode
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/audio plex-audio
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/shows plex-shows
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/movies plex-movies
			printf "\n\e[7m Re-creating the Plex Docker container \e[0m \n\n"
			docker create --name=plex --net=host --restart unless-stopped -v plex-config:/config -v plex-transcode:/transcode -v plex-audio:/audio -v plex-shows:/data/shows -v plex-movies:/data/movies linuxserver/plex
			printf "\n\e[7m Starting the Plex Docker container \e[0m \n\n"
			docker start plex
			sleep 5s
			printf "\n\e[7m Displaying the log \e[0m \n\n"
			docker logs plex
			printf "\n\e[7m Go to http://vm-docker:32400/web/index.html to access Plex \e[0m \n\n"
			printf "\n\e[7m FINISHED INSTALLING PLEX \e[0m \n\n"
			break
			;;
			
		install-sonarr)
			clear
			printf "\n\e[7m INSTALLING SONARR \e[0m \n\n"
			printf "\n\e[7m Updating repositories, upgrading packages, and cleaning up \e[0m \n\n"
			sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
			printf "\n\e[7m Pulling the latest Sonarr docker image \e[0m \n\n"
			docker pull linuxserver/sonarr:latest
			printf "\n\e[7m Removing any existing Sonarr docker container \e[0m \n\n"
			docker stop sonarr || true && docker rm sonarr || true
			printf "\n\e[7m Removing any existing Sonarr Docker volume \e[0m \n\n"
			docker volume rm sonarr-config && docker volume rm sonarr-downloads && docker volume rm sonarr-shows
			printf "\n\e[7m Re-creating the Sonarr Docker volume \e[0m \n\n"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/sonarr/config sonarr-config
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/sonarr/downloads sonarr-downloads
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/media/video/shows sonarr-shows
			printf "\n\e[7m Re-creating the Sonarr docker container \e[0m \n\n"
			docker create --name=sonarr --restart unless-stopped -p 8989:8989 -v sonarr-config:/config -v sonarr-downloads:/downloads -v sonarr-shows:/tv linuxserver/sonarr
			printf "\n\e[7m Starting the Sonarr docker container \e[0m \n\n"
			docker start sonarr
			sleep 5s
			printf "\n\e[7m Displaying the log \e[0m \n\n"
			docker logs sonarr
			printf "\n\e[7m FINISHED INSTALLING SONARR \e[0m \n\n"
			break
			;;
			
		install-tor)
			clear
			printf "\n\e[7m INSTALLING TOR \e[0m \n\n"
			printf "\n\e[7m Updating repositories, upgrading packages, and cleaning up \e[0m \n\n"
			sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt -y autoclean
			printf "\n\e[7m Pulling the latest Tor docker image \e[0m \n\n"
			docker pull chriswayg/tor-server:latest
			printf "\n\e[7m Removing any existing Tor docker container \e[0m \n\n"
			docker stop tor || true && docker rm tor || true
			printf "\n\e[7m Removing any existing Tor Docker volume \e[0m \n\n"
			docker volume rm tor
			printf "\n\e[7m Re-creating the Tor Docker volume \e[0m \n\n"
			#Make sure the remote folder exists on the NAS and is not empty (even if it means creating an empty Temp folder inside it)
			docker volume create --driver local --opt type=nfs --opt o=addr=synology-1,rw,vers=4 --opt device=:/volume1/tor tor
			printf "\n\e[7m Re-creating the Tor docker container \e[0m \n\n"
			docker create --name=tor --restart unless-stopped -e CONTACT_EMAIL=R2XRAp6Mc7Fg33q4LhT6c74u7@anche.no -e TOR_NICKNAME=Tor4 -v tor:/var/lib/tor chriswayg/tor-server
			printf "\n\e[7m Starting the Tor docker container \e[0m \n\n"
			docker start tor
			sleep 5s
			printf "\n\e[7m Displaying the log \e[0m \n\n"
			docker logs tor
			printf "\n\e[7m FINISHED INSTALLING TOR \e[0m \n\n"
			break
			;;

		quit)
			printf "\n\e[7m QUITTING \e[0m \n\n"
			break
			;;
			
		*)
			printf "\n\e[7m INVALID OPTION. PLEASE CHOOSE ANOTHER ONE \e[0m \n\n"
			;;
			
	esac
done
