
### What

Babushka is a humble tool for automating computing chores. For each dependency (dep) of the job to do, a test, and the code to make that test pass -- test-driven sysadmin.

```ruby
dep 'on git branch', :branch do
  requires 'git'
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

That's an expository dep that can achieve the modest goal of being on the correct git branch. Notice the parameter denoted by the :branch symbol, and the clear separation of test, in the `met?` block, and code, in `meet`.

Running this dep when a branch change is required shows how babushka does its work in blocks of met/meet/met: a failing test, an action blindly taken, and then the same test again, hopefully passing now as a result.

    $ bin/babushka.rb 'on git branch' branch=stable
    on git branch {
      git {
        'git' runs from /usr/bin.
        ✓ git is 2.3.8, which is >= 1.6.
      } ✓ git
      Currently on master.
      meet {
        Checking out stable... done.
      }
      Currently on stable.
    } ✓ on git branch

If we're already on the right branch, though, the initial test is already passing, and so there's no work to do.

    $ bin/babushka.rb 'on git branch' branch=stable
    on git branch {
      git {
        'git' runs from /usr/bin.
        ✓ git is 2.3.8, which is >= 1.6.
      } ✓ git
      Currently on stable.
    } ✓ on git branch

There are other things to learn about, like dep requirements (shown above), dep templates, dep sources, and the few remaining words in babushka's DSL, but this is the important bit. If you string a few dozen deps like this one together, you can provision a server from scratch, or do anything else you like.

There is much more detailed documentation on [the website](http://babushka.me), along with per-method documentation which can be viewed [here](http://babushka.me/rdoc).


### Installing

Babushka is most easily installed using `babushka.me/up`, a shell script that installs babushka via git (and its dependencies, ruby and git, via your system's package manager if required). It's safe to run on existing systems, and intended to be used as the first shell command on a new system too. You can install babushka this way using `curl` or `wget`:

    sh -c "`curl https://babushka.me/up`"

If you'd rather install manually, all you need to do is clone [the git repo](https://github.com/benhoskings/babushka) (or extract an archive of it), and if you like, link `bin/babushka.rb` into your path as 'babushka'.

Check [the install documentation](http://babushka.me/installing), for the full details on customising the installation, including locking to specific versions and installing from forks using `babushka.me/up`.


### Supported systems

Babushka itself should run on any Unix; there's nothing in the core of babushka that requires anything other than unix, ruby, and git.

I develop babushka against OS X and Ubuntu, so homebrew and apt are the best-supported package managers. There is also some yum (RedHat/Fedora/CentOS) and pacman (Arch) support, thanks to others' contributions. On other systems, specific operations (like installing a package using that system's package manager) will fail with an error message, but otherwise babushka should run fine. In any case, patches are most welcome.


### Acknowledgements

Babushka takes advantage of these ruby libraries:

- [fancypath](http://github.com/tred/fancypath/), by [Myles Byrne](http://twitter.com/quackingduck) & [Chris Lloyd](http://twitter.com/chrislloyd), for more concise path handling in deps;
- [inkan](https://github.com/pat/inkan), by [Pat Allan](http://twitter.com/pat), for tracking changes to rendered files;
- [Text::Levenshtein](https://github.com/threedaymonk/text), by [Paul Battley](http://twitter.com/threedaymonk), for suggested typo corrections.

Thanks very much to everyone who's contributed to babushka, whether by submitting patches, discussing design ideas with me, testing, or just giving their feedback.

Rather than a list of contributors here, which inevitably falls out of date, check [the contributors page](https://github.com/benhoskings/babushka/graphs/contributors). For other contributions, version-bumping commits always detail what changed and who helped out.


### License

Babushka is licensed under the three-clause BSD license, except for `lib/levenshtein/levenshtein.rb`, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license can be found at the top of `lib/levenshtein/levenshtein.rb`.
