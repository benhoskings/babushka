
Detailed documentation: http://babushka.me
rdocs: http://babushka.me/rdoc
Mailing list: http://babushka.me/mailing_list

A lot of the tech jobs we do manually aren't challenging or fun, but they're quite particular and have to be done just right -- they're chores. Things that are important to do, but that are better automated than done manually.

That's what babushka is for. Once you describe a job using its DSL, babushka can not only accomplish each part of the job, but also check if each part is already satisfied. For each component of the job, a test, along with the code to make that test pass -- test-driven sysadmin.


### Installing

Babushka is best installed using `babushka.me/up`, a script that installs babushka via git (and some dependencies via your system's package manager). It's safe to run on existing systems, and intended to be used as the first shell command on a new system too. You can install babushka this way using `curl` or `wget`:

    sh -c "`curl https://babushka.me/up`"

If you'd rather install manually, all you need to do is clone [the git repo](https://github.com/benhoskings/babushka) (or extract an archive of it), and if you like, link `bin/babushka.rb` into your path as 'babushka'. See [the relevant page in the docs](http://babushka.me/installing) for more information on installing babushka.

Babushka should run on any Unix. OS X and Ubuntu are fully supported, including their respective package managers, homebrew and apt. There is some yum (RedHat/Fedora/CentOS) and pacman (Arch) support, but I'm not familiar with those systems so it might be incomplete. Patches are most welcome.


### Acknowledgements

Babushka takes advantage of these ruby libraries:

- [fancypath](http://github.com/tred/fancypath/), by [Myles Byrne](http://twitter.com/quackingduck) & [Chris Lloyd](http://twitter.com/chrislloyd), for more concise path handling in deps;
- [inkan](https://github.com/pat/inkan), by [Pat Allan](http://twitter.com/pat), for tracking changes to rendered files;
- [levenshtein](http://raa.ruby-lang.org/project/levenshtein/), by [Paul Battley](http://twitter.com/threedaymonk), for suggested typo corrections.

Thanks very much to everyone who's contributed to babushka, whether by submitting patches, discussing design ideas with me, testing, or just giving their feedback.

Rather than a list of contributors here, which inevitably falls out of date, check [the contributors page](https://github.com/benhoskings/babushka/graphs/contributors). For other contributions, version-bumping commits always detail what changed and who helped out.


### License

Babushka is licensed under the three-clause BSD license, except for `lib/levenshtein/levenshtein.rb`, which is licensed under the MIT license.

The BSD license can be found in full in the LICENSE file, and the MIT license can be found at the top of `lib/levenshtein/levenshtein.rb`.
