### Archived

I don't intend to do any further work on babushka (in fact I haven't done so in some time).

I had the idea and [started working on the project](https://github.com/benhoskings/babushka/commit/f007e2c86ddb0729896814f6baac75673f8d7beb) in 2009. At the time docker and even vagrant were yet to be conceived. In part I wanted to build a simpler, small-scale alternative to the likes of chef and puppet, and in part it started as a bit of an experiment in how far I could hone a ruby DSL and to what extent I could lean on it to do useful work. I had a ball working on it and learned a hell of a lot, and I'm proud of the fact that the initial design proved sound. I'm less proud of certain parts of the implementation - hoowee would I write a few bits of that code differently today - but then we were all young once.

These days things are very different. With modern containers and the immutability they provide, along with tools like terraform, kubernetes and so on, babushka and its mutation-based approach is quite dated. In fact requiring good old babushka for serious infrastructure work today could be considered a kind of warning sign.

As for setting up a new laptop and so on, I've learned the long way that a dumb shell script that copies some preferences into place, runs a few `defaults write` commands, and so on, along with a few manual steps, is much easier to maintain. The more an automated process reaches into MacOS the more quickly it will fall out of compatibility, and in any case setting up a new machine is a rare enough occurrence for me that it's not worth aiming for perfect automation.

Thanks to everyone who's contributed and made use of it over the years. As always if you'd like to make use of it in any way, go for your life - I just don't intend to make any more changes to this main repo. Well maybe one rainy day I'll refactor the hairy bits - we'll see.

Cheers and all the best.

---

### What

Babushka is a commandline tool for automating computing chores. Each distinct part of the job is expressed as a dependency (dep), which comprises a test and the code to make that test pass.

```ruby
dep 'on git branch', :branch do
  met? {
    current_branch = shell('git branch').split("\n").collapse(/^\* /).first
    log "Currently on #{current_branch}."
    current_branch == branch
  }
  meet {
    log_shell("Checking out #{branch}", 'git', 'checkout', branch)
  }
end
```

Above is an expository dep that can achieve the modest goal of being on the correct git branch (note the parameter denoted by the :branch symbol). It's built using the two DSL words `met?` and `meet`, which contain each dep's logic, separating the test (is the dependency met?) from the code (meet the dependency).

Running this dep when a branch change is required shows how babushka does its work in blocks of met/meet/met: a failing test, an action blindly taken, and then the same test again, passing now as a result.

    $ bin/babushka.rb 'on git branch' branch=stable
    on git branch {
      Currently on master.
      meet {
        Checking out stable... done.
      }
      Currently on stable.
    } ✓ on git branch

If we're already on the right branch, though, the initial test is already passing, and so there's no work to do.

    $ bin/babushka.rb 'on git branch' branch=stable
    on git branch {
      Currently on stable.
    } ✓ on git branch

That's all very well for one isolated task. To achieve something bigger, tasks have to trigger other ones, which is where the third DSL word `requires` comes in.

```ruby
dep 'on git branch', :branch do
  requires 'git'
  # ...
```

Before babushka processes a dep in the met/meet/met fashion described above, all its requirements are processed to completion in the same way. That reflects reality: asking if we're on the right git branch doesn't even make sense if git isn't installed.

    $ bin/babushka.rb 'on git branch' branch=stable
    on git branch {
      git {
        'git' runs from /usr/bin.
        ✓ git is 2.3.8, which is >= 1.6.
      } ✓ git
      Currently on stable.
    } ✓ on git branch

The complentary DSL word `requires_when_unmet` can be used to specify dependencies required only when a given dep is found to be unmet, and that can be skipped when the dep is already met. (Build tools are a good example of such a requirement.)

There are other things to learn about, like dep templates, dep sources, and the few remaining words in babushka's DSL, but the above is the nut of it. If you string a few dozen deps like this one together, you can provision a server from scratch, or do anything else you like.

There is much more detailed documentation on [the website](http://babushka.me), along with per-method documentation which can be viewed [here](http://babushka.me/rdoc).


### Installing

Babushka is most easily installed using `babushka.me/up`, a shell script that installs babushka via git (and its dependencies, ruby and git, via your system's package manager if required). It's safe to run on existing systems, and intended to be used as the first shell command on a new system too. You can install babushka this way using `curl` or `wget`:

    sh -c "`curl https://babushka.me/up`"

If you'd rather install manually, all you need to do is clone [the git repo](https://github.com/benhoskings/babushka) (or extract an archive of it) and if you like, link `bin/babushka.rb` into your path as 'babushka'.

Check [the install documentation](http://babushka.me/installing) for details on customising the installation, including locking to specific versions and installing from forks using `babushka.me/up`.


### Supported systems

Babushka itself should run on any Unix; there's nothing in the core of babushka that requires anything other than unix, ruby, and git.

I develop babushka on macOS and use it primarily on Ubuntu, so homebrew and apt are the best-supported package managers. There is also some yum (RedHat/Fedora/CentOS) and pacman (Arch) support, thanks to others' contributions. On other systems, specific operations (like installing a package using that system's package manager) will fail with an error message, but otherwise babushka should run fine. In any case, patches are most welcome.


### Acknowledgements

Babushka takes advantage of these ruby libraries:

- [fancypath](http://github.com/tred/fancypath/), by [Myles Byrne](http://twitter.com/quackingduck) & [Chris Lloyd](http://twitter.com/chrislloyd), for more concise path handling in deps;
- [inkan](https://github.com/pat/inkan), by [Pat Allan](http://twitter.com/pat), for tracking changes to rendered files;
- [Text::Levenshtein](https://github.com/threedaymonk/text), by [Paul Battley](http://twitter.com/threedaymonk), for suggested typo corrections.

Thanks very much to everyone who's contributed to babushka, whether by submitting patches, discussing design ideas with me, testing, or just giving their feedback.

A list of contributors here inevitably falls out of date - [the contributors page](https://github.com/benhoskings/babushka/graphs/contributors) contains the full list. In addition, the version-bumping commits always detail what changed and who helped out in their commit messages.


### License

Babushka is licensed under the three-clause BSD license, except for `lib/levenshtein/levenshtein.rb`, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license can be found at the top of `lib/levenshtein/levenshtein.rb`.
