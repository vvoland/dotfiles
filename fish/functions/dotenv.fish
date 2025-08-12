function dotenv
  eval (cat .env | sed 's/^/export /') $argv
end
