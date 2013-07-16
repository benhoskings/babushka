# babushka: test-driven sysadmin.

_[Detailed documentation](http://babushka.me), [rdocs](http://babushka.me/rdoc), [mailing list](http://babushka.me/mailing_list)_

A lot of the tech jobs we do manually aren't challenging or fun, but they're quite particular and have to be done just right -- they're chores. Things that are important to do, but that are better automated than done manually.

That's what babushka is for. Once you describe a job using its DSL, babushka can not only accomplish each part of the job, but also check if each part is already satisfied. For each component of the job, a test, along with the code to make that test pass -- test-driven sysadmin.


# installing

Babushka is best installed using `babushka.me/up`, a script that installs babushka via git (and some dependencies via your system's package manager). It's safe to run on existing systems, and intended to be used as the first shell command on a new system too. You can install babushka this way using `curl` or `wget`:

    sh -c "`curl https://babushka.me/up`"

If you'd rather install manually, all you need to do is clone [the git repo](https://github.com/benhoskings/babushka) (or extract an archive of it), and if you like, link `bin/babushka.rb` into your path as 'babushka'. See [the relevant page in the docs](http://babushka.me/installing) for more information on installing babushka.

Babushka should run on any Unix. OS X and Ubuntu are fully supported, including their respective package managers, homebrew and apt. There is some yum (RedHat/Fedora/CentOS) and pacman (Arch) support, but I'm not familiar with those systems so it might be incomplete. Patches are most welcome.


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
