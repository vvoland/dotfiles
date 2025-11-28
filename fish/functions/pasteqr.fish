function pasteqr --wraps='pbpaste | qrencode -t UTF8' --description 'alias pasteqr=pbpaste | qrencode -t UTF8'
    cpaste | qrencode -t UTF8 $argv
end
