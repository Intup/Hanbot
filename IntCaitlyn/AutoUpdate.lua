local url = 'https://raw.githubusercontent.com/Intup/Internal/master/IntCaitlyn/main.lua'
local dest = hanbot.luapath..'/IntCaitlyn/main.lua'
local success = network.download_file(url, dest)
chat.print('Updates were made to the files: main and common');