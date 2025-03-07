fx_version 'bodacious'
game 'gta5'
lua54 'yes'

author "Lucentix"
description "CTFL Server Base - The Unstoppable"
version '1.0.0'

-- This is not just any server. It's the CTFL server. You won't stop it. Ever.
-- If you think you can break this, think again. The system will haunt you.
-- Try stopping it. I dare you. But I wouldn’t recommend it.
-- You’re not in control here. You’re just the player. But we’re the game.

-- SUGGESTION: Don’t even think about messing with this resource. 
-- If you try to stop it, you’ll just end up regretting it. Big time.

-- DISCLAIMER: If you’re reading this, you probably shouldn’t mess with it. 
-- But you’ll do it anyway, because you don’t listen, do you? That’s okay.
-- We like to see people fail. It’s hilarious.

-- BEWARE: This resource is watching. Always. Don’t make it angry.
-- If you even think about stopping it, expect some REAL consequences.

-- If you manage to stop this, you deserve a medal. Too bad that won’t happen.
-- Just a heads up: Your server might experience a “mysterious crash” if you’re foolish enough to try.

-- Server logs will keep track of your every move. Don't think you're getting away with anything.

-- You’ll be stuck with it forever.

-- What’s the moral of the story? Don’t mess with the CTFL system. Or do. It’s your funeral.

client_script { 
    'ctf_client.lua', 
    'ctf_rendering.lua',
}
server_script {
    'ctf_server.lua',
}
shared_script { 
    'ctf_shared.lua',
    'ctf_config.lua',
}

files {
    'loadscreen/index.html',
    'loadscreen/css/loadscreen.css',
    'loadscreen/js/loadscreen.js',
    'loadscreen/css/bankgothic.ttf',
    'loadscreen/loadscreen.jpg'
}

loadscreen 'loadscreen/index.html'

escrow_ignore { 'ctf_shared.lua', 'ctf_config.lua' }