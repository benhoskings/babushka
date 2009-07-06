babushka
===

> Deploy time! I'll just add a vhost. Oh, and a unix user, and copy the config from that other app. Or was it a different one? Oh well, that worked. Wait, why can't I log in from my testing box? I'm sure I added that SSH key. And where is that shell alias? Oh crap, I only added that on dev the other day. Ohh, I can log in if I chmod 700 my .ssh dir. Why the 500s? Oh lol, forgot to add a new DB user.

Deploying a webapp or setting up a new user account or configuring automated backups aren't hard. They're made up of lots of simple little jobs that have to be done just right.


if only it were this easy (hint: it is)
---

    $ ruby bin/babushka.rb 'db backups'
    db backups {
      db software {
        db in path {
          not required on Linux.
        } √ db in path
        apt {
        } √ apt
        √ system has postgresql deb
        √ system has postgresql-client deb
        √ system has libpq-dev deb
        √ 'psql' runs from /usr/bin.
      } √ db software
      db backups not already met.
      offsite host for db backups? backups@slice.corkboard.cc
      √ publickey login to backups@slice.corkboard.cc.
      Rendered /usr/local/bin/postgres_offsite_backup.
      db backups met.
    } √ db backups


how is dep formed?
---

A dep (dependency) is something that you want to do, like add a user account, or build a webserver, or install a gem. Deps depend on other deps.

Each dep is really small and simple. A little nugget of code that does one thing and does it right. They're deliberately as concise as possible, so you can quickly write it once and then never do that job manually again.

Example: to get a rails app running..

    dep 'rails app' do
      requires 'gems installed', 'vhost enabled', 'webserver running', 'migrated db'
    end

... you just need to satisfy those four requirements. Each of which depend on a few other things, and so on. So 'vhost enabled' from above:

    dep 'vhost enabled' do
      requires 'vhost configured'
      met? { File.exists? "#{vhosts}/on/#{domain}.conf" }
      meet { sudo "ln -sf '#{vhosts}/#{domain}.conf' '#{vhosts}/on/#{domain}.conf'" }
      after { restart_webserver }
    end

Any dep can depend on any number of other ones. A given dep can be required by multiple others and it all comes out in the wash. If you accidentally a loop, Babushka will let you know. So you don't have to think about the heirachy, just each little piece on its own.

This isn't only about deploying webapps though. Deps like to do anything that you don't.

    dep 'user setup' do
      requires 'user shell setup', 'passwordless ssh logins', 'public key', 'vim'
    end

    dep 'passwordless ssh logins' do
      requires 'user exists'
      met? { grep your_ssh_public_key, '~/.ssh/authorized_keys' }
      meet {
        shell 'mkdir -p ~/.ssh'
        append_to_file your_ssh_public_key.end_with("\n"), "~/.ssh/authorized_keys"
        shell 'chmod 700 ~/.ssh'
        shell 'chmod 600 ~/.ssh/authorized_keys'
      }
    end

Don't worry about your_ssh_public_key - Babushka will ask for it when it needs the value.

So in general:

    dep 'something you want to do' do
      requires 'something else', 'and another dependency', 'like this one'
      met? {
        # is this dependency already met?
      }
      meet {
        # this code gets run if it isn't.
      }
    end


what are there deps for?
---

Pretty much whatever I've needed. That means that there are lots missing, and the ones there are may well not be right for you.

But a dep is so easy to write or modify, you can do up a quick one for just about anything and pop it in ~/.babushka/deps. Send me the good ones and I'll include em!


n.b.
---

Babushka is new, in flux, and has approximately 0% test coverage. Also, many deps will change your system irreversibly, which is kind of the whole point, but it has to be said anyway. Use caution and always have a backup.
