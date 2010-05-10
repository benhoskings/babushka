# babushka: test-driven sysadmin.

When you spend time researching something new, it's pretty easy to forget what you found, and have to re-research it again next time.

A lot of the tech jobs we do manually aren't challenging or fun, but they're finicky and have to be done just right. They're chores. Things that are important to do, but that are better automated than done manually by us people, right? After all, that's what is supposed to happen in the future. And the future is good, because in the future, we'll all have jetpants. So, onward.

The idea is this: you take a job that you'd rather not do manually, and describe it to babushka using its DSL. The way it works, babushka not only knows how to accomplish each part of the job, it also knows how to check if each part is already done. You're teaching babushka to achieve an end goal with whatever runtime conditions you throw at it, not just to perform the task that would get you there from the very start.


# installing

Installing is really easy on supported systems (currently, OS X and Ubuntu). All it takes is one command, and it can be the first command you run on the machine. (Babushka will happily install on any machine though, not just new ones.)

If you have curl (OS X):

    bash -c "`curl -L babushka.me/up`"

If you have wget (Ubuntu):

    bash -c "`wget -O - babushka.me/up`"


# kicking the tyres

Once the install process has finished, you're ready to rock. If you have a Mac, maybe a good example is to install homebrew. To do that, we run the dependency (in babushka parlance, 'dep') called `homebrew`:

    babushka homebrew

Or check that your rubygems install is looking good - latest version + gem sources. This demonstrates how babushka works: it's the goal (rubygems set up well) that's important. You can safely run this whether rubygems is outdated, up to date, or missing, and babushka will work out what tasks need to be done in order to achieve the end goal. The `rubygems` dep handles that for us:

    babushka rubygems

Things like rubygems and homebrew aren't hard to install on their own, but with babushka it's _really_ easy, and _fast_. But more importantly, you know the job is being done just right, every time.

OK, something more complex now---a full nginx/passenger stack.

    babushka 'webserver configured'

Then you can set up each virtualhost with

    babushka 'vhost configured'

That's how I set up all my production machines. If something isn't working, you have a list of things that aren't the culprit: everything in the output with a green √ beside it. Conversely, if babushka can detect the problem, the failing dep will have a red × beside it instead, which leads you straight to the cause of the problem. Test-driven sysadmin!


# nothing up my sleeve…

Creating and sharing this knowledge is central to babushka. It's all very well to run `babushka rubygems` and have it do a job for you, but the real power is in babushka's ability to automate whatever chore you want, not just ones that others have thought of already.

To that end, I've tried really hard to make the process quick and satisfying. If you spend a little bit of time getting the feel for how to efficiently use babushka's DSL, you'll be cranking out deps just like the `babushka` and `homebrew` ones above.


## yeah, but how?

A dep is one single piece of a larger task. A little nugget of code that does just one thing, and does it right. Here's a babushka dep, at its most generic.

    dep 'name' do
      requires 'other deps', 'whatever they might be'
      met? {
        # is this dependency already met?
      }
      meet {
        # this code gets run if it isn't.
      }
    end

The important bit here is that when you're writing a dep, you don't have to think about context at all, just the one little task it's doing in isolation. As long as your `requires` are correct, you can leave the overall structure to babushka and just write each little dep separately. When you run `babushka name`, babushka uses the `requires` in each dep to assemble a dep hierarchy and achieve the end goal you're after.

The idea is to keep a clean separation between `met?` and `meet`: the code in `met?` should do nothing except just check whether the dep is met and return a boolean, and `meet` should unconditionally satisfy the dep without doing any checks.

Right, here's one I prepared earlier. Given you're on a Mac with Xcode installed, this dep knows how to achieve the goal of having llvm available in the PATH.

    dep 'llvm in path', :for => :snow_leopard do
      requires 'xcode tools'
      met? { which 'llvm-gcc-4.2' }
      meet {
        in_dir('/usr/local/bin') {|path|
          shell "ln -s /Developer/usr/llvm-gcc-4.2/bin/llvm* .", :sudo => !path.writable?
        }
      }
    end

All the common logic is handled by babushka, which means that all the code in the dep is specific to the job at hand. The idea is maximising that signal-to-noise ratio: as much of the code in the dep above should be talking about llvm, not about other things that can be inferred elsewhere.

Notice that there's no conditional or nested logic within the dep. That's by design: the more declarative things are, the more composable and re-interpretable they are later.

If you find you're checking for the presence of some condition in your `meet` block, it probably means you're trying to do too much in a single dep, and you should be splitting it up into smaller ones. Remember, deps are small, self-contained and context-free - the more focused, the better.


## let's get declarative

The basic dep, with just `requires`, `met?` and `meet`, is all you need to describe an end goal. But this generic nature of `met?` and `meet` means just as they're general purpose, they can lack focus. For example, installing an app using the system's package manager has a predictable `met?` block---check whether the package is present and its binaries are in the path.

A lot of chores are variations on a theme like this, or just too cumbersome to do repeatedly at a low level. So babushka provides a way to write dep templates, or _meta deps_, that can be reused later. These meta deps allow you to focus the DSL, and make it even more concise.

    meta :tmbundle, :for => :osx do
      accepts_list_for :source

      template {
        requires 'TextMate.app'
        helper :path do
          '~/Library/Application Support/TextMate/Bundles' / name
        end
        met? { path.dir? }
        before { shell "mkdir -p #{path.parent}" }
        meet {
          source.each {|uri|
            git uri, :dir => name, :prefix => path.parent
          }
        }
        after { shell %Q{osascript -e 'tell app "TextMate" to reload bundles'} }
      }
    end

Notice how the contents of the `template` block looks like a normal dep. That's cause it is---the meta dep is a factory, that takes values defined by `accepts_list_for` (in this case, `source`) and produces regular deps at runtime under the covers.

For example, Babushka ships with a meta dep that knows how to install TextMate bundles, given just the URL. All the actual logic, including the code for `met?` and `meet`, is wrapped up in the meta dep. Given the `tmbundle` meta dep, this dep handles the cucumber bundle:

    tmbundle 'Cucumber.tmbundle' do
      source 'git://github.com/bmabey/cucumber-tmbundle.git'
    end

Notice there's no imperative code there at all---just declarations. That's what the DSL aims for. Instead of saying "do this, then do this, then do this", the code should say "here's a description of the problem, now you work it out." Also notice that there's no TextMate-specific logic. Adding this extra level of abstraction means all that's left are the specifics for _this_ TextMate bundle.


# a runtime example

All that means that babushka isn't just blindly running a bunch of code to make things happen. Each step of the way, it's checking what should be done, and only doing the bits that aren't done already. (In babushka parlance, it's only meeting dependencies that aren't already met.)

If you already have TextMate installed, babushka notices and just installs the bundle.

    Cucumber.tmbundle {
      TextMate.app {
        Found at /Applications/TextMate.app.
      } √ TextMate.app
      not already met.
      Cloning from git://github.com/bmabey/cucumber-tmbundle.git... done.
      Cucumber.tmbundle met.
    } √ Cucumber.tmbundle

But if you don't have TextMate, that's an unmet dependency, so it gets pulled in too.

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


## what are there deps for?

Well, babushka only contains the deps that it needs to know how to install itself, and set up a bare minimum of software like `ruby` and `git`. Everything else is stored separately, in dep sources, which you can think of like gem sources (although they're a bit different - each dep source is a babushka-managed git repo).

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

A dep can run any code. Run deps of unknown origin at your own risk, and when choosing dep sources to add, use the only real security there is: a network of trust.

Many deps will change your system irreversibly, which is kind of the whole point, but it has to be said anyway. Use caution and always have a backup.


## acknowledgements

[Fancypath](http://github.com/tred/fancypath/), by [Myles Byrne](http://www.myles.id.au/) & [Chris Lloyd](http://thelincolnshirepoacher.com/). It's how I made the paths so fancy.

[Levenshtein](http://raa.ruby-lang.org/project/levenshtein/), for typo correction. Thanks to [Paul Battley](http://twitter.com/threedaymonk) for letting me dual-license it under BSD.

Thanks to my rubyist friends who've helped with brainstorming and testing---the likes of [@glenmaddern](http://twitter.com/glenmaddern), [@nathan_scott](http://twitter.com/nathan_scott), [@brentsnook](http://twitter.com/brentsnook), [@dgoodlad](http://twitter.com/dgoodlad), [@odaeus](http://twitter.com/odaeus), [@lachlanhardy](http://twitter.com/lachlanhardy), [@aussiegeek](http://twitter.com/aussiegeek), [@bjeanes](http://twitter.com/bjeanes), [@chendo](http://twitter.com/chendo), [@ryanbigg](http://twitter.com/ryanbigg) & [@drnic](http://twitter.com/drnic).


## license

Babushka is licensed under the BSD license, except for the following exception:

lib/support/levenshtein.rb, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license at the top of lib/support/levenshtein.rb.
