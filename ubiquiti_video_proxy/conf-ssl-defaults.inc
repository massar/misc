# See https://cipherli.st/ for many details here
# Note that these properties can change quickly too

ssl_stapling		on;
ssl_stapling_verify	on;
ssl_trusted_certificate	/www/nginx/ssl/cacerts.pem;

# Needed for OCSP stapling
resolver 8.8.8.8 valid=300s;
resolver_timeout 5s;

# Enable a 20 MiB SSL session cache
ssl_session_cache               shared:SSL:20m;
ssl_session_timeout             10m;

# Disable Session Tickets
ssl_session_tickets		off;

# SSL ciphers
ssl_prefer_server_ciphers	on;
ssl_protocols			TLSv1.2;
ssl_ciphers			"EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";

# Diffie-Hellman parameters
# Generated with: openssl dhparam -out dhparam.pem 4096
ssl_dhparam			/www/nginx/ssl/dhparam.pem;

# Security headers
add_header X-Content-Type-Options "nosniff";
add_header X-Frame-Options "DENY";
add_header X-XSS-Protection "1; mode=block";

