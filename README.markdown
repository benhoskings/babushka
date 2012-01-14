# babushka: test-driven sysadmin.

- _docs: http://babushka.me_
- _rdocs: http://babushka.me/rdoc_

A lot of the tech jobs we do manually aren't challenging or fun, but they're quite particular and have to be done just right -- they're chores. Things that are important to do, but that are better automated than done manually.

That's what babushka is for. Once you describe a job using its DSL, babushka can not only accomplish each part of the job, but also check if each part is already satisfied. For each component of the job, a test, along with the code to make that test pass -- test-driven sysadmin.


# installing

Installing is really easy. All it takes is one command, and it can be the first command you run on the machine. (Babushka will happily install on any machine though, not just new ones.)

If you have curl (OS X):

    bash -c "`curl babushka.me/up`"

If you have wget (Ubuntu):

    bash -c "`wget -O - babushka.me/up`"

Babushka should run on any Unix. OS X and Ubuntu are fully supported, including their respective package managers, homebrew and apt. There is some yum (RedHat/Fedora/CentOS) and pacman (Arch) support, but I'm not familiar with those systems so it might be incomplete. Patches are most welcome.


# kicking the tyres

Once the install process has finished, you're ready to rock. If you have a Mac, maybe a good example is to install homebrew. To do that, we run the dependency (in babushka parlance, 'dep') called `homebrew`:

    babushka homebrew

Another example. Here's how you could check that your rubygems install is up to date and in the right place. This demonstrates how babushka works: it's the goal (rubygems set up well) that's important. You can safely run this whether rubygems is outdated, up to date, or missing, and babushka will work out what tasks need to be done in order to achieve the end goal. The `rubygems` dep handles that.

    babushka rubygems

Things like rubygems and homebrew aren't hard to install on their own, but with babushka it's _really_ easy, and _fast_. But more importantly, you know the job is being done just right, every time.

(These deps aren't special, they're just bundled along with babushka because I like to ship package manager support.)

OK, something more complex now---a vhosting nginx. Since there's not much point configuring nginx until it's installed, this dep `requires` another called `nginx.src` that does the actual install (i.e. downloading and building the source). That means calling this one will include the installation if it's not already present (i.e. if `nginx.src` is unmet).

    babushka benhoskings:'configured.nginx'

Then you can set up each virtualhost with another dep (which itself requires `configured.nginx`). In fact, you could call just this one, and leave the one above: configuring a vhost requires the global config, which in turn requires the install.

The idea is that you can talk solely about your actual goal, without regard for the dependencies -- they'll all be pulled in as required.

    babushka benhoskings:'vhost configured.nginx'

That's how I set up my production machines. If something isn't working, you have a list of things that _aren't_ the culprit: everything in the output with a green ✓ beside it. Conversely, if babushka can detect the problem, the failing dep will have a red ✗ beside it instead, which leads you straight to the cause of the problem. Test-driven sysadmin!


# nothing up my sleeve…

Creating and sharing this knowledge is central to babushka. It's all very well to run `babushka rubygems` and have it do a job for you, but the real power is in babushka's ability to automate whatever chore you want, not just ones that others have thought of already.

To that end, I've tried really hard to make the process quick and satisfying. If you spend a little bit of time getting the feel for babushka's DSL, you'll be cranking out deps just like the rubygems, homebrew, and nginx ones above.


## yeah, but how?

A dep is one single piece of a larger task. A little nugget of code that does just one thing, and does it right. Here's a babushka dep, at its most generic.

    dep 'name', :argument do
      requires 'other deps'.with('args'), 'whatever they might be'
      met? {
        # is this dependency already met?
      }
      meet {
        # this code gets run if it isn't.
      }
    end

The important bit here is that when you're writing a dep, you don't have to think about context at all, just the one little task it's doing in isolation. As long as your `requires` are correct, you can leave the overall structure to babushka and just write each little dep separately. When you run `babushka name`, babushka uses the `requires` in each dep to assemble a tree of deps and achieve the end goal you're after.

The idea is to keep a clean separation between `met?` and `meet`: the code in `met?` should do nothing except just check whether the dep is met and return a boolean, and `meet` should unconditionally satisfy the dep without doing any checks.

Right, here's one I prepared earlier. Given you're on a Mac with Xcode installed, this dep knows how to achieve the goal of having llvm available in the PATH.

    dep 'llvm in path', :for => :snow_leopard do
      requires 'xcode tools'
      met? { which 'llvm-gcc-4.2' }
      meet {
        cd('/usr/local/bin') {|path|
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

For example, Babushka ships with a meta dep that knows how to install TextMate bundles, given just the URL. All the actual logic, including the code for `met?` and `meet`, is wrapped up in the meta dep.

    meta :tmbundle, :for => :osx do
      accepts_value_for :source
      
      template {
        requires 'TextMate.app'
        def path
          '~/Library/Application Support/TextMate/Bundles' / name
        end
        met? { path.dir? }
        before { path.parent.mkdir }
        meet { git source, :to => path }
        after { shell %Q{osascript -e 'tell app "TextMate" to reload bundles'} }
      }
    end

Notice how the contents of the `template` block looks like a normal dep. That's cause it is---the meta dep is a factory, that accepts a value defined by `accepts_value_for` (in this case, `source`) and produces regular deps at runtime under the covers.

Given the `tmbundle` meta dep, this dep handles the cucumber bundle:

    dep 'Cucumber.tmbundle' do
      source 'https://github.com/bmabey/cucumber-tmbundle.git'
    end

Notice there's no imperative code there at all---just declarations. That's what the DSL aims for. Instead of saying "do this, then do this, then do this", the code should say "here's a description of the problem, now you work it out." Also notice that there's no TextMate-specific logic. Adding this extra level of abstraction means all that's left are the specifics for _this_ TextMate bundle.


# a runtime example

All that means that babushka isn't just blindly running a bunch of code to make things happen. Each step of the way, it's checking what should be done, and only doing the bits that aren't done already. (In babushka parlance, it's only meeting dependencies that aren't already met.)

If you already have TextMate installed, babushka notices and just installs the bundle.

    Cucumber.tmbundle {
      TextMate.app {
        Found at /Applications/TextMate.app.
      } ✓ TextMate.app
      meet {
        Cloning from https://github.com/bmabey/cucumber-tmbundle.git... done.
      }
    } ✓ Cucumber.tmbundle

But if you don't have TextMate, that's an unmet dependency, so it gets pulled in too.

    Cucumber.tmbundle {
      TextMate.app {
        meet {
          Downloading http://download-b.macromates.com/TextMate_1.5.9.dmg... done.
          Attaching TextMate_1.5.9.dmg... done.
          Found TextMate.app in the DMG, copying to /Applications... done.
          Detaching TextMate_1.5.9.dmg... done.
        }
        Found at /Applications/TextMate.app.
      } ✓ TextMate.app
      meet {
        Cloning from https://github.com/bmabey/cucumber-tmbundle.git... done.
      }
    } ✓ Cucumber.tmbundle


## dep sources

Babushka only contains the deps that it needs to know how to install itself, and set up a bare minimum of software like package managers, `ruby` and `git`. Everything else is stored separately, in _dep sources_. A dep source is a babushka-managed git repo that contains a bunch of ruby files.

The organisation and naming of the files within the source is completely up to you - babushka will recursively load all the .rb files it can find in the source, in alphabetical order.

You can define deps and templates in the same source, arranged however you like. You don't have to worry about having templates loaded before deps that are defined against them, because the load is a two-stage process that first reads every file and sets up the templates, and then defines all the deps that were found.

The best way manage your own source is to make <tt>~/.babushka/deps</tt> a git repo, and push it to <tt>https://github.com/username/babushka-deps.git</tt>.

To run deps from others' sources, you don't need to add the source explicitly. Just prefix the dep name with the correct username:

    babushka conversation:coffeescript.src

The dep source will be cloned into <tt>~/.babushka/sources/conversation</tt>, or updated if it's already there, and then babushka will search for a dep called "coffeescript" within that source. Because of this partitioning, you don't have to worry about naming conflicts with other people; everything is per-source.

If you want to rename a source, or add one with a custom URL, you can add sources manually like this:

    babushka sources -a custom-name git://example.com/custom/url.git

That will make the source available in <tt>~/.babushka/sources/custom-name</tt>.

There's no configuration file for dep sources; the only state is stored in the contents of <tt>~/.babushka/sources</tt>. Specifically, the source names are the directory names, and the URLs are the locations of the corresponding 'origin' git remotes.

Because of this, you can safely add, remove, rename and edit the directories and repositories in there as much as you like---but importantly, *babushka assumes it has free run of <tt>~/.babushka/sources</tt>, and won't hesitate to `git reset --hard`. If you leave uncommitted or unpushed changes in a source, they'll be lost when that source is updated.*

If you want to write deps just for yourself that you don't plan to push online, just drop them in <tt>~/.babushka/deps</tt>. If you'd rather keep them elsewhere, like in <tt>~/src</tt> or similar, you can symlink the directory into <tt>~/.babushka/deps</tt>.

Finally, babushka also loads deps from `./babushka-deps` in the directory from which it was run. This is a good place for project-specific deps, because you can keep them within the project's source control.


## n.b.

A dep can run any code. Run deps of unknown origin at your own risk, and when choosing deps and dep sources, use the only real security there is: a network of trust.

Many deps will change your system irreversibly, which is kind of the whole point, but it has to be said anyway. Use caution and always have a backup.


## acknowledgements

[Fancypath](http://github.com/tred/fancypath/), by [Myles Byrne](http://www.myles.id.au/) & [Chris Lloyd](http://thelincolnshirepoacher.com/). It's how I made the paths so fancy.

[Levenshtein](http://raa.ruby-lang.org/project/levenshtein/), for typo correction. Thanks to [Paul Battley](http://twitter.com/threedaymonk) for letting me dual-license it under BSD.

Thanks to my rubyist friends who've helped with brainstorming and testing---the likes of
[@glenmaddern](http://twitter.com/glenmaddern),
[@nathan_scott](http://twitter.com/nathan_scott),
[@notahat](http://twitter.com/notahat),
[@quamen](http://twitter.com/quamen),
[@dgoodlad](http://twitter.com/dgoodlad),
[@chrisberkhout](http://twitter.com/chrisberkhout),
[@pat](http://twitter.com/pat),
[@brentsnook](http://twitter.com/brentsnook),
[@odaeus](http://twitter.com/odaeus),
[@lachlanhardy](http://twitter.com/lachlanhardy),
[@aussiegeek](http://twitter.com/aussiegeek),
[@bjeanes](http://twitter.com/bjeanes),
[@chendo](http://twitter.com/chendo),
[@ryanbigg](http://twitter.com/ryanbigg) &
[@drnic](http://twitter.com/drnic).


## license

Babushka is licensed under the BSD license, except for the following exception:

lib/support/levenshtein.rb, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license at the top of lib/support/levenshtein.rb.
