babushka
---

So you just wrote a sweet web app, and you want to put it online? Awesome.

    I'll just add a vhost. Oh, and a unix user, and copy the config from that other app. Or was it a different one? Oh well, that worked. Wait, why can't I log in from my testing box? I'm sure I added that SSH key. And where is that shell alias? Oh crap, I only added that on dev the other day. Ohh, I can log in if I chmod 700 my .ssh dir. Why the 500s? Oh lol, forgot to add a new DB user.

A little too close to home?

If you ever do something more than once, you're doing it wrong.

Deploying a webapp or setting up a new user account or setting up automated backups aren't hard. They just depend on a bunch of other things being in place, like a database or a gem. Which in turn have their own dependencies, and so on.


how is dep formed?
===

Deps (dependencies) are really simple. They're deliberately as concise as possible, so you can quickly write it once and then never do that job manually again.

Example: to get a rails app running.. 

    dep 'rails app' do
      requires 'gems installed', 'vhost enabled', 'webserver running', 'migrated db'
    end

... you just need to satisfy those four requirements. Each of which depend on a few other things, and so on. Another example:

    dep 'passwordless ssh logins' do
      requires 'user exists'
      met? { grep your_ssh_public_key, '~/.ssh/authorized_keys' }
      meet {
        shell 'mkdir -p ~/.ssh'
        append_to_file your_ssh_public_key, "~/.ssh/authorized_keys"
        shell 'chmod 700 ~/.ssh'
        shell 'chmod 600 ~/.ssh/authorized_keys'
      }
    end

Don't worry about your_ssh_public_key - Babushka will ask for it when it needs the value.

So in general it's like this, and that's the way it is:

    dep 'something you want to do' do
      requires 'something else', 'a bunch of other dependencies', 'like this one'
      met? {
        # is this dependency already met?
      }
      meet {
        # this code gets run if it isn't.
      }
    end

Not very tricky.

Each dep(endency) only has to know its immediate needs, and nothing else. The big, frustrating, prohibitive, sidetracking tree of dependencies just works itself out.

Say you want DB backups. Just ask for them. Babushka works out which deps are met, which aren't, asks you for what it needs, and tees it up:

    > ruby bin/babushka.rb 'db backups'
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

Nice.

what are there deps for?
===

Pretty much whatever I've needed. That means that there are lots missing, and the ones there are may well not be right for you.

But a dep is so easy to write or modify, you can do up a quick one for just about anything and pop it in ~/.babushka/deps. Send me the good ones and I'll include em!

