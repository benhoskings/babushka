babushka
===

test-driven sysadmin.
---

> Deploy time! I'll just add a vhost. Oh, and a unix user, and copy the config from that other app. Or was it a different one? Oh well, that worked. Wait, why can't I log in from my testing box? I'm sure I added that SSH key. And where is that shell alias? Oh crap, I only added that on dev the other day. Ohh, I can log in if I chmod 700 my .ssh dir. Why the 500s? Oh lol, forgot to add a new DB user.

Deploying a webapp or setting up a new user account or configuring automated backups aren't hard. They're made up of lots of simple little jobs that have to be done just right.


if only it were this easy (it is)
---

    ⚡ babushka 'postgres backups'
    postgres backups {
      postgres software {
        homebrew {
          homebrew binary in place {
            homebrew installed {
              writable install location {
                install location exists {
                } √ install location exists
                admins can sudo {
                  admin group {
                  } √ admin group
                } √ admins can sudo
              } √ writable install location
              homebrew git {
                homebrew bootstrap {
                  √ writable install location (cached)
                  build tools {
                    llvm in path {
                      xcode tools {
                      } √ xcode tools
                    } √ llvm in path
                    build tools / met? not defined.
                  } √ build tools
                  'brew' runs from /usr/local/bin.
                } √ homebrew bootstrap
                √ system has git-1.6.5 brew
                'git' runs from /usr/local/bin.
              } √ homebrew git
            } √ homebrew installed
          } √ homebrew binary in place
          √ build tools (cached)
          homebrew / met? not defined.
        } √ homebrew
        √ system has postgresql-8.4.0 brew
        'psql' runs from /usr/local/bin.
      } √ postgres software
      not already met.
      offsite host for postgres backups [backups@napier.hoskings.net]? 
      √ publickey login to backups@napier.hoskings.net.
      Rendered /usr/local/bin/postgres_offsite_backup.
    } √ postgres backups
    ⚡


how is dep formed?
---

A dep (dependency) is something that you want to automate, like add a user account, or build a webserver, or install a gem. Deps depend on other deps.

Each dep is really small and simple. A little nugget of code that does just one thing, and does it right.

Deps are defined using a DSL. It's very concise, so you can quickly write a dep and then never do its job manually again.

For example, to enable a virtual host, you symlink a file. Pretty trivial, and easy enough to do manually - but if you write a dep, you not only get it right every time, you can automate it as part of a more complex process.

    dep 'vhost enabled' do
      requires 'vhost configured'
      met? { "#{vhosts}/on/#{var :domain}.conf".p.exists? }
      meet { sudo "ln -sf '#{vhosts}/#{var :domain}.conf' '#{vhosts}/on/#{var :domain}.conf'" }
      after { restart_nginx }
    end

The important bit here is that when you're writing a dep, you don't have to think about context at all, just the one little task it's doing in isolation. As long as your `requires` are correct, you can leave the overall structure to babushka and just write each little dep separately. When you run `babushka dep_name`, babushka works its way down through all the `requires` in your dep, and in those deps, and so on, checking and running each as needed.

Any dep can depend on any number of other deps. A given dep can be required by multiple others and babushka will sort it all out. So, you don't have to think about the hierarchy, just each little piece on its own.

This isn't only about deploying webapps though. Deps like to do anything that you don't.

    dep 'user setup' do
      requires 'user shell setup', 'passwordless ssh logins', 'public key', 'vim'
    end

    dep 'passwordless ssh logins' do
      requires 'user exists'
      met? { grep var(:your_ssh_public_key), '~/.ssh/authorized_keys' }
      before { shell 'mkdir -p ~/.ssh; chmod 700 ~/.ssh' }
      meet { append_to_file var(:your_ssh_public_key), "~/.ssh/authorized_keys" }
      after { shell 'chmod 600 ~/.ssh/authorized_keys' }
    end

Don't worry about the `your_ssh_public_key` var - babushka will ask you for it when it needs the value.

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

The idea is to keep a clean separation between `met?` and `meet`: the code in `met?` should do nothing except just check whether the dep is met and return a boolean, and `meet` should unconditionally satisfy the dep without doing any checks.

If you find you're checking for the presence of some condition in your `meet` block, that means you're trying to do too much in a single dep, and you should be splitting your dep up into smaller ones. Remember, deps are small, self-contained and context-free - the smaller and more focused, the better.


what are there deps for?
---

Pretty much whatever I've needed. That means that there are lots missing, and the ones there are may well not be right for you.

Because of this, babushka only contains the deps that it needs to know how to install itself, and set up a bare minimum of software like `ruby` and `git`. Everything else is stored separately, in dep sources, which you can think of like gem sources (although they're a bit different - each dep source is a babushka-managed git repo).

By default, babushka adds my dep source, but you can add your own, or multiple other ones, or remove mine if you like, just like managing gem sources. All you have to do is

    babushka sources -a git://github.com/someone else's/awesome deps.git

And they're available straight away (`babushka list` to see what's there). To pull the latest updates for all sources, just run a

    babushka pull

You can drop deps you write in `~/.babushka/deps`, and babushka will load those too.


n.b.
---

A dep run any code. Run deps of unknown origin at your own risk, and when choosing dep sources to add, use the best security there is---a network of trust.

Many deps will change your system irreversibly, which is kind of the whole point, but it has to be said anyway. Use caution and always have a backup.


acknowledgements
----------------
Babushka makes use of [Fancypath](http://github.com/tred/fancypath/), by [Myles Byrne](http://www.myles.id.au/) & [Chris Lloyd](http://thelincolnshirepoacher.com/). It's how I made the paths so fancy.
Thanks to my rubyist friends who've helped with brainstorming and testing---the likes of [@glenmaddern](http://twitter.com/glenmaddern), [@nathan_scott](http://twitter.com/nathan_scott), [@odaeus](http://twitter.com/odaeus), [@aussiegeek](http://twitter.com/aussiegeek), [@bjeanes](http://twitter.com/bjeanes), [@chendo](http://twitter.com/chendo), [@ryanbigg](http://twitter.com/ryanbigg) & [@drnic](http://twitter.com/drnic)

license
-------

Babushka is licensed under the BSD license, except for the following exception:

lib/support/levenshtein.rb, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license at the top of lib/support/levenshtein.rb.
