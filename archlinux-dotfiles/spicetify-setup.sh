paru -S spotify
paru -S spicetify-bin

sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R

timeout 10 spotify
qs -c noctalia-shell ipc call toast send '{"title": "Spicetify Setting up", "body": "Do NOT Close Spotify", "icon": "warning", "duration": "10000"}'

cd spicetify-themes
cp -r * ~/.config/spicetify/Themes

spicetify config current_theme text && spicetify apply && spicetify config color_scheme dracula && spicetify apply


