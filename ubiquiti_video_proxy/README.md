# Ubiquiti Unifi Video - controller behind HTTPS proxy (nginx)

This directory contains a few Nginx configuration snippets for putting a Ubiquiti UniFi Video controller behind a HTTP proxy (nginx).

This allows for custom SSL certificates to be installed easily and shared with other configuration elements.

It also allows actually having the controller in a firewalled network, only allowing the HTTP server to talk to it.

## Caveats

### Live View

Note that at the moment (3.1.2) there is at least one issue with the Live View: the hostname in one of the UI requests, something like:
```
 https://example.com:7443/api/2.0/stream/<stream-id>/2/url
```
causes the result to be:

```
{"data":[{"rtmpPath":"rtmp://controller.example.com:1935/live","wsPath":"ws://controller.example.com:7445","wssPath":"wss://controller.example.com:7446","streamName":"cxC5fgtw7TvYicBmAe"}],"meta":{"totalCount":1,"filteredCount":1}}
```

And then the requests for the live view end up at the wrong host (controller.example.com and not our example.com proxy).

Bug report is filed, hopefully they enable a setting for configuring the external hostname.

### iOS / iPhone app

The iPhone app still needs port 7080 (plaintext HTTP) for some requests it seems, hence why it is included.
It would indeed be much better if that did not have to be open at all...

Bug report about that is also filed.

