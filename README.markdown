# babushka: test-driven sysadmin.

When you spend time researching something new, it's pretty easy to forget what you found, and have to re-research it again next time.

A lot of the tech jobs we do manually aren't challenging or fun, but they're finicky and have to be done just right. They're chores. Things that are important to do, but that are better automated than done manually by us people, right? After all, that's what is supposed to happen in the future. And the future is good, because in the future, we'll all have jetpants. So, onward.

The idea is this: you take a job that you'd rather not do manually, and describe it to babushka using its DSL. These descriptions are structured so babushka not only knows how to accomplish each part of the job, it also knows how to check if each part is already done along the way. You're teaching babushka to achieve an end goal, not just to perform the task that would get you there from the very start.


# installing

Installing is really easy on any system. All it takes is one command, and it can be the first command you run on the machine. (Babushka will happily install on any machine though, not just new ones.)

If you have curl (OS X):

    bash -c "`curl -L babushka.me/up`"

If you have wget (Ubuntu):

    bash -c "`wget -O - babushka.me/up`"


## how is dep formed?

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


## what are there deps for?

Pretty much whatever I've needed. That means that there are lots missing, and the ones there are may well not be right for you.

Because of this, babushka only contains the deps that it needs to know how to install itself, and set up a bare minimum of software like `ruby` and `git`. Everything else is stored separately, in dep sources, which you can think of like gem sources (although they're a bit different - each dep source is a babushka-managed git repo).

By default, babushka adds my dep source, but you can add your own, or multiple other ones, or remove mine if you like, just like managing gem sources. All you have to do is

    babushka sources -a git://github.com/someone else's/awesome deps.git

And they're available straight away (`babushka list` to see what's there). To pull the latest updates for all sources, just run a

    babushka pull

If you want to write deps just for yourself that you don't plan to push online, just create a local git repo for them and add that as a source, like so:

    mkdir ~/babushka-deps; cd ~/babushka-deps; git init
    babushka sources -a super-secret ~/babushka-deps

If you'd rather edit the live versions of those deps, you can find them in `/usr/local/babushka/sources/super-secret`. Don't forget to commit your changes though!

You can also put project-specific deps in `./babushka_deps`, and babushka will load those too whenever you run it from that directory.


## n.b.

A dep can run any code. Run deps of unknown origin at your own risk, and when choosing dep sources to add, use the best security there is: a network of trust.

Many deps will change your system irreversibly, which is kind of the whole point, but it has to be said anyway. Use caution and always have a backup.


## acknowledgements

[Fancypath](http://github.com/tred/fancypath/), by [Myles Byrne](http://www.myles.id.au/) & [Chris Lloyd](http://thelincolnshirepoacher.com/). It's how I made the paths so fancy.

[Levenshtein](http://raa.ruby-lang.org/project/levenshtein/), for typo correction. Thanks to [Paul Battley](http://twitter.com/threedaymonk) for letting me dual-license it under BSD.

Thanks to my rubyist friends who've helped with brainstorming and testing---the likes of [@glenmaddern](http://twitter.com/glenmaddern), [@nathan_scott](http://twitter.com/nathan_scott), [@odaeus](http://twitter.com/odaeus), [@aussiegeek](http://twitter.com/aussiegeek), [@bjeanes](http://twitter.com/bjeanes), [@chendo](http://twitter.com/chendo), [@ryanbigg](http://twitter.com/ryanbigg) & [@drnic](http://twitter.com/drnic).


## license

Babushka is licensed under the BSD license, except for the following exception:

lib/support/levenshtein.rb, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license at the top of lib/support/levenshtein.rb.
