#!/bin/bash
# V2ray for Alwaysdata.com

TMP_DIRECTORY=$(mktemp -d)
UUID=${UUID:-`uuidgen`}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
URL=${USER}.alwaysdata.net

wget -q -O $TMP_DIRECTORY/config.json https://raw.githubusercontent.com/gglluukk/V2ray-for-AlwaysData/main/config.json
wget -q -O $TMP_DIRECTORY/v2ray-linux-64.zip https://github.com/v2fly/v2ray-core/releases/download/v5.37.0/v2ray-linux-64.zip
rm -f v2ray
unzip -oq -d $HOME $TMP_DIRECTORY/v2ray-linux-64.zip v2ray

sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#$VMESS_WSPATH#g;s#VLESS_WSPATH#$VLESS_WSPATH#g;s#10000#8300#g;s#20000#8400#g;s#127.0.0.1#0.0.0.0#g" $TMP_DIRECTORY/config.json
/bin/cp -f $TMP_DIRECTORY/config.json $HOME
rm -rf $HOME/admin/tmp/*.*

# preserve orgiginal admin
if [ ! -d admin.orig ] ; then
    mv admin admin.orig
    cp -av admin.orig admin
fi

cat > admin/config/apache/sites.conf<<-EOF


##
## Subdomain ${USER}.alwaysdata.net (0000000)
##

<VirtualHost *>
ServerName ${USER}.alwaysdata.net

ProxyRequests off
ProxyPreserveHost On
ProxyPass "/vmess" "ws://services-${USER}.alwaysdata.net:8300/vmess"
ProxyPassReverse "/vmess" "ws://services-${USER}.alwaysdata.net:8300/vmess"
ProxyPass "/vless" "ws://services-${USER}.alwaysdata.net:8400/vless"
ProxyPassReverse "/vless" "ws://services-${USER}.alwaysdata.net:8400/vless

## Site 000000, static - address ${USER}.alwaysdata.net (0000000)

<Location />
  RemoveHandler .php
</Location>


## Site 000000, static - address ${USER}.alwaysdata.net (0000000)
DocumentRoot "/home/${USER}/www/"
</VirtualHost>

EOF

vmlink=vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"${USER}@AlwaysData\",\"add\":\"$URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$URL\",\"path\":\"$VMESS_WSPATH\",\"tls\":\"tls\"}" | base64 -w 0)
vllink="vless://"$UUID"@"$URL":443?encryption=none&security=tls&type=ws&host="$URL"&path="$VLESS_WSPATH"#${USER}@AlwaysData"

qrencode -o $HOME/www/M$UUID.png $vmlink
qrencode -o $HOME/www/L$UUID.png $vllink

# preserve original/modified index.html
if [ ! -f www/index.html.orig ] ; then
    mv www/index.html www/index.html.orig
    chmod 000 www/index.html.orig
fi

cat > $HOME/www/index.html<<-EOF
<html>
<head>
    <title>Redirecting...</title>
    <meta http-equiv="refresh" content="0;url=https://www.alwaysdata.com/">
    <link rel="canonical" href="https://www.alwaysdata.com/">
    <script>window.location.href = "https://www.alwaysdata.com/";</script>    
</head>
<body><center><br><br><br><br><br>
        <p>If you are not redirected automatically: <a href="https://www.alwaysdata.com/">click here</a>.</p>
</body>
</html>
EOF

cat > $HOME/www/$UUID.html<<-EOF
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Alwaysdata</title>
<style type="text/css">
body {
      font-family: Geneva, Arial, Helvetica, san-serif;
    }
div {
      margin: 0 auto;
      text-align: left;
      white-space: pre-wrap;
      word-break: break-all;
      max-width: 80%;
      margin-bottom: 10px;
}
</style>
</head>
<body bgcolor="#FFFFFF" text="#000000">
<div><font color="#009900"><b>Ссылка протокола VMESS：</b></font></div>
<div>$vmlink</div>
<div><font color="#009900"><b>QR-код протокола VMESS：</b></font></div>
<div><img src="/M$UUID.png"></div>
<div><font color="#009900"><b>Ссылка протокола VLESS：</b></font></div>
<div>$vllink</div>
<div><font color="#009900"><b>QR-код протокола VLESS：</b></font></div>
<div><img src="/L$UUID.png"></div>
</body>
</html>
EOF

clear

echo -e "\e[32m### V2ray for AlwaysData.com\e[0m"

echo -e "\n\e[33mПожалуйста, СКОПИРУЙТЕ следующий зеленый текст в SERVICE Command*:\n\e[0m"
echo -e "\e[32m./v2ray run -config config.json\e[0m"
echo -e "\n\e[33mНажмите на следующую ссылку, чтобы получить информацию о узле:\n\e[0m"
echo -e "\e[32mhttps://$URL/$UUID.html\n\e[0m"
