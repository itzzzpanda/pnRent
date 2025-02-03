fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'pnRent'
description 'Simple rent menu with UI inspired by Nopixel 4.0'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
     "@vrp/client/Tunnel.lua",
    "@vrp/client/Proxy.lua",
    'client.lua',
}

server_scripts {
    "@vrp/lib/utils.lua",
    'server.lua',
    '@oxmysql/lib/MySQL.lua'
}

ui_page "web/index.html"

files {
    'locales/*.json',
    'config.lua',
    'web/**'
}

dependency 'ox_lib'