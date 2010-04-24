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


# basic babushka-fu

Then you're ready to start running deps. If you have a Mac, maybe a good example is to install homebrew.

    babushka homebrew

Or check that your rubygems install is looking good - latest version + gem sources. This demonstrates how babushka works: it's the goal (rubygems set up well) that's important. You can safely run this whether or not you have rubygems installed, and babushka will work out what tasks need to be done (i.e. which deps are already met, and which need to be met) in order to achieve the end goal.

    babushka rubygems

Things like rubygems and homebrew aren't hard to install on their own, but with babushka it's _really_ easy, and _fast_. But more importantly, you know the job is being done just right, every time.

If rubygems or homebrew aren't working, you have a list of things that aren't the culprit: everything in the output with a green √ beside it. Conversely, if they stop working in the future, you can re-run babushka, and if something it can detect is broken, that step will have a red × instead. Test-driven sysadmin!

Here's how it works. Babushka knows how to install TextMate bundles, given just the URL. This code is a dep written using the babushka DSL, and it handles the whole process.

    tmbundle 'Cucumber.tmbundle' do
      source 'git://github.com/bmabey/cucumber-tmbundle.git'
    end

Notice there's no imperative code there at all -- just declarations. That's what the DSL aims for. Instead of saying "do this, then do this, then do this", the code should say "here's a description of the problem, now you work it out."

That means that babushka isn't just blindly running a bunch of code to make things happen. Each step of the way, it's checking what should be done, and only doing the bits that aren't done already. (In babushka parlance, it's only meeting dependencies that aren't already met.) If you have already have TextMate installed, babushka notices and just installs the bundle.

    Cucumber.tmbundle {
      TextMate.app {
        Found at /Applications/TextMate.app.
      } √ TextMate.app
      not already met.
      Cloning from git://github.com/bmabey/cucumber-tmbundle.git... done.
      Cucumber.tmbundle met.
    } √ Cucumber.tmbundle

But if you don't, that's an unmet dependency, so it gets pulled in too.

    Cucumber.tmbundle {
      TextMate.app {
        not already met.
        Downloading http://download-b.macromates.com/TextMate_1.5.9.dmg... done.
        Attaching TextMate_1.5.9.dmg... done.
        Found TextMate.app in the DMG, copying to /Applications... done.
        Detaching TextMate_1.5.9.dmg... done.
        Found at /Applications/TextMate.app.
        TextMate.app met.
      } √ TextMate.app
      not already met.
      Cloning from git://github.com/bmabey/cucumber-tmbundle.git... done.
      Cucumber.tmbundle met.
    } √ Cucumber.tmbundle


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
