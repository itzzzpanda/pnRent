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
    'client.lua'
}

server_scripts {
    'server.lua',
    '@oxmysql/lib/MySQL.lua',
}

ui_page "webv2/dist/index.html"

files {
    'locales/*.json',
    'config.lua',
    
	"webv2/dist/**",
    "webv2/dist/assets/*.*",
	"webv2/dist/assets/**/*.*"
}

dependency 'ox_lib'

