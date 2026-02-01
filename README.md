# hls-restreamer

This docker setup allows you to bypass rai iptv streams relinker cdn and geoblocking. Very useful for a Xibo signage setup.
To ensure maximum compatibility, add &output=16 at the end of the rai mediapolis relinker url.

If you're using Pangolin proxy, enable Enable Sticky Sessions.

Run:
docker compose build && docker compose up -d.
