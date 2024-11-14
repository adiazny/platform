# Resources

## nip.ios
https://nip.io/s

## Traefik.me

https://traefik.me/

## Layer 4 vs Layer 7
https://www.haproxy.com/blog/layer-4-vs-layer-7-load-balancing

## Dnsmasq
https://www.stevenrombauts.be/2018/01/use-dnsmasq-instead-of-etc-hosts/

```
To start dnsmasq now and restart at startup:
  sudo brew services start dnsmasq
Or, if you don't want/need a background service you can just run:
  /opt/homebrew/opt/dnsmasq/sbin/dnsmasq --keep-in-foreground -C /opt/homebrew/etc/dnsmasq.conf -7 /opt/homebrew/etc/dnsmasq.d,\*.conf
```
