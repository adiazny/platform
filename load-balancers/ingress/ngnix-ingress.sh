#!/usr/bin/env bash
clear

deploy() {
    # Create a simple NGINX deployment using kubectl and name it nginx-web
    echo -e "\n*******************************************************************************************************************"
    echo -e "Deploying the NGINX pod"
    echo -e "*******************************************************************************************************************"
    kubectl create deployment nginx-web --image bitnami/nginx

    # Create a service that exposes the Deployment on port 8080 called nginx-web

    echo -e "\n*******************************************************************************************************************"
    echo -e "Creating the NGINX service"
    echo -e "*******************************************************************************************************************"
    kubectl expose deployment nginx-web --port 8080 --target-port 8080

    # Find IP address of Docker Host
    # We need to know the IP of the Host since we use nip.io for name resolution.  Nip.ip names follow the standard <url>.<host ip>.nip.io
    # For example, if you wanted to have two Ingress rules, one for a sales web site and one for an ordering website, and your Host IP is 192.168.1.1
    # your nip.io names would be sales.192.168.1.1.nip.io and ordering.192.168.1.1.nip.io
    # This does assume that the first IP found is the correct IP address of the Host.  In a multi-homed system you may need to use a different
    # IP address, but we have no easy way to know the correct IP to use if there are multiple IP addresses on a Host system.
    echo -e "\n \n*******************************************************************************************************************"
    echo -e "Finding the IP address of the host to create the nip.io Ingress rule"
    echo -e "*******************************************************************************************************************"
    export hostip=$(ifconfig -l | xargs -n1 ipconfig getifaddr)
    echo -e "\nFound the Host IP: $hostip"

    # Use the IP ddress tht was found in the last step to create a new Ingress rule using nip.io
    # We use the IP that we found and envsubst a template called ingress.yaml that will change the value in the Ingress rule
    # to use the IP address of the host.
    echo -e "\n*******************************************************************************************************************"
    echo -e "Creating the Ingress rule using $hostip"
    echo -e "*******************************************************************************************************************\n"
    sleep 2
    kubectl -n default apply -f ingress.yaml

    # Use the IP found in the previous step:
    # Summarize the KinD deployment and show the user an example of a nip.io address that can be used for Ingress rules.
    echo -e "\n \n*******************************************************************************************************************"
    echo -e "Ingress URL Rule: webserver.$hostip.nip.io \n"
    echo -e "\nYou can now browse to the NGINX pod using the nip.io domain from any machine on your local network"
    echo -e "******************************************************************************************************************* \n\n"
}

cleanup() {
    echo -e "\n \n*******************************************************************************************************************"
    echo -e "Cleaning up ingress resources"
    echo -e "\n \n*******************************************************************************************************************"
    kubectl delete deployment nginx-web
    kubectl delete svc nginx-web
    kubectl delete ingress nginx-ingress
}

if [[ "$1" == "cleanup" ]]; then
    cleanup
    exit 0
fi

deploy