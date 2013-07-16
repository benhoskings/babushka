# babushka: test-driven sysadmin.

_[Detailed documentation](http://babushka.me), [rdocs](http://babushka.me/rdoc), [mailing list](http://babushka.me/mailing_list)_

A lot of the tech jobs we do manually aren't challenging or fun, but they're quite particular and have to be done just right -- they're chores. Things that are important to do, but that are better automated than done manually.

That's what babushka is for. Once you describe a job using its DSL, babushka can not only accomplish each part of the job, but also check if each part is already satisfied. For each component of the job, a test, along with the code to make that test pass -- test-driven sysadmin.


# installing

Babushka is best installed using `babushka.me/up`, a script that installs babushka via git (and some dependencies via your system's package manager). It's safe to run on existing systems, and intended to be used as the first shell command on a new system too. You can install babushka this way using `curl` or `wget`:

    sh -c "`curl https://babushka.me/up`"

If you'd rather install manually, all you need to do is clone [the git repo](https://github.com/benhoskings/babushka) (or extract an archive of it), and if you like, link `bin/babushka.rb` into your path as 'babushka'. See [the relevant page in the docs](http://babushka.me/installing) for more information on installing babushka.

Babushka should run on any Unix. OS X and Ubuntu are fully supported, including their respective package managers, homebrew and apt. There is some yum (RedHat/Fedora/CentOS) and pacman (Arch) support, but I'm not familiar with those systems so it might be incomplete. Patches are most welcome.


## yeah, but how?

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

[Levenshtein](http://raa.ruby-lang.org/project/levenshtein/), for typo correction. Thanks to [Paul Battley](http://twitter.com/threedaymonk) for letting me dual-license it under the MIT license.

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

Babushka is licensed under the three-clause BSD license, except for `lib/levenshtein/levenshtein.rb`, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license can be found at the top of `lib/levenshtein/levenshtein.rb`.
